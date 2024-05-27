// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./dependencies/DelegatedOps.sol";
import "./dependencies/SystemStart.sol";
import "./interfaces/ITokenLocker.sol";

/**
    @title Incentive Voting
    @author Prisma Finance
    @notice Users with token balances locked in `TokenLocker` may register their
            lock weights in this contract, and use this weight to vote on where
            new emissions will be released in the following epoch.
 */
contract IncentiveVoting is DelegatedOps, SystemStart {
    ITokenLocker public immutable tokenLocker;
    address public immutable vault;

    // Whole number representing 100% in the contracts
    uint256 public constant MAX_PCT = 10000;
    // Maximum number of epochs that tokens may be locked for
    uint256 public constant MAX_LOCK_EPOCHS = 52;

    struct AccountData {
        // system epoch when the account's lock weights were registered
        // used to offset `epochsToUnlock` when calculating vote weight
        // as it decays over time
        uint16 epoch;
        // total registered vote weight, only recorded when frozen.
        // for unfrozen weight, recording the total is unnecessary because the
        // value decays. throughout the code, we check if frozenWeight > 0 as
        // a way to indicate if a lock is frozen.
        uint128 frozenWeight;
        uint16 points;
        uint8 lockLength; // length of epochsToUnlock and lockedAmounts
        uint16 voteLength; // length of activeVotes
        // array of [(receiver id, points), ... ] stored as uint16[2] for optimal packing
        uint16[2][MAX_PCT] activeVotes;
        // arrays map to one another: lockedAmounts[0] unlocks in epochsToUnlock[0] epochs
        // values are sorted by time-to-unlock descending
        uint120[MAX_LOCK_EPOCHS] lockedAmounts;
        uint8[MAX_LOCK_EPOCHS] epochsToUnlock;
    }

    struct Vote {
        uint256 id;
        uint256 points;
    }

    struct LockData {
        uint256 amount;
        uint256 epochsToUnlock;
    }

    mapping(address => AccountData) accountLockData;

    // id -> receiver data
    uint120[65535] receiverDecayRate;
    uint16[65535] receiverUpdatedEpoch;
    // id -> epoch -> absolute vote weight
    uint128[65535][65535] receiverEpochWeights;
    // id -> epoch -> registered lock weight that is lost
    uint120[65535][65535] receiverEpochUnlocks;
    uint16 public receiverCount;

    uint120 totalDecayRate;
    uint16 totalUpdatedEpoch;
    uint128[65535] totalEpochWeights;
    uint120[65535] totalEpochUnlocks;

    // emitted each time an account's lock weight is registered
    event AccountWeightRegistered(
        address indexed account,
        uint256 indexed epoch,
        uint256 frozenBalance,
        ITokenLocker.LockData[] registeredLockData
    );
    // emitted each time an account submits one or more new votes. only includes
    // vote points for the current call, for a complete list of an account's votes
    // you must join all instances of this event that fired more recently than the
    // latest `ClearedVotes` for the the same account.
    event NewVotes(address indexed account, uint256 indexed epoch, Vote[] newVotes, uint256 totalPointsUsed);
    // emitted each time the votes for `account` are cleared
    event ClearedVotes(address indexed account, uint256 indexed epoch);

    constructor(address core, ITokenLocker _tokenLocker, address _vault) SystemStart(core) {
        tokenLocker = _tokenLocker;
        vault = _vault;
    }

    function registerNewReceiver() external returns (uint256) {
        require(msg.sender == vault, "Only Vault");
        uint256 id = receiverCount + 1;
        receiverUpdatedEpoch[id] = uint16(getWeek());
        receiverCount = uint16(id);
        return id;
    }

    function getAccountRegisteredLocks(
        address account
    ) external view returns (uint256 frozenWeight, LockData[] memory lockData) {
        return (accountLockData[account].frozenWeight, _getAccountLocks(account));
    }

    function getAccountCurrentVotes(address account) public view returns (Vote[] memory votes) {
        votes = new Vote[](accountLockData[account].voteLength);
        uint16[2][MAX_PCT] storage storedVotes = accountLockData[account].activeVotes;
        uint256 length = votes.length;
        for (uint256 i = 0; i < length; i++) {
            votes[i] = Vote({ id: storedVotes[i][0], points: storedVotes[i][1] });
        }
        return votes;
    }

    function getReceiverWeight(uint256 idx) external view returns (uint256) {
        return getReceiverWeightAt(idx, getWeek());
    }

    function getReceiverWeightAt(uint256 idx, uint256 epoch) public view returns (uint256) {
        if (idx > receiverCount) return 0;
        uint256 rate = receiverDecayRate[idx];
        uint256 updatedEpoch = receiverUpdatedEpoch[idx];
        if (epoch <= updatedEpoch) return receiverEpochWeights[idx][epoch];

        uint256 weight = receiverEpochWeights[idx][updatedEpoch];
        if (weight == 0) return 0;

        while (updatedEpoch < epoch) {
            updatedEpoch++;
            weight -= rate;
            rate -= receiverEpochUnlocks[idx][updatedEpoch];
        }

        return weight;
    }

    function getTotalWeight() external view returns (uint256) {
        return getTotalWeightAt(getWeek());
    }

    function getTotalWeightAt(uint256 epoch) public view returns (uint256) {
        uint256 rate = totalDecayRate;
        uint256 updatedEpoch = totalUpdatedEpoch;
        if (epoch <= updatedEpoch) return totalEpochWeights[epoch];

        uint256 weight = totalEpochWeights[updatedEpoch];
        if (weight == 0) return 0;

        while (updatedEpoch < epoch) {
            updatedEpoch++;
            weight -= rate;
            rate -= totalEpochUnlocks[updatedEpoch];
        }
        return weight;
    }

    function getReceiverWeightWrite(uint256 idx) public returns (uint256) {
        require(idx != 0 && idx <= receiverCount, "Invalid ID");
        uint256 epoch = getWeek();
        uint256 updatedEpoch = receiverUpdatedEpoch[idx];
        uint256 weight = receiverEpochWeights[idx][updatedEpoch];
        if (epoch == updatedEpoch) return weight;

        if (weight == 0) {
            receiverUpdatedEpoch[idx] = uint16(epoch);
            return 0;
        }

        uint256 rate = receiverDecayRate[idx];
        while (updatedEpoch < epoch) {
            updatedEpoch++;
            weight -= rate;
            receiverEpochWeights[idx][updatedEpoch] = uint128(weight);
            rate -= receiverEpochUnlocks[idx][updatedEpoch];
        }

        receiverDecayRate[idx] = uint120(rate);
        receiverUpdatedEpoch[idx] = uint16(epoch);

        return weight;
    }

    function getTotalWeightWrite() public returns (uint256) {
        uint256 epoch = getWeek();
        uint256 updatedEpoch = totalUpdatedEpoch;
        uint256 weight = totalEpochWeights[updatedEpoch];

        if (weight == 0) {
            totalUpdatedEpoch = uint16(epoch);
            return 0;
        }

        uint256 rate = totalDecayRate;
        while (updatedEpoch < epoch) {
            updatedEpoch++;
            weight -= rate;
            totalEpochWeights[updatedEpoch] = uint128(weight);
            rate -= totalEpochUnlocks[updatedEpoch];
        }

        totalDecayRate = uint120(rate);
        totalUpdatedEpoch = uint16(epoch);

        return weight;
    }

    function getReceiverVotePct(uint256 id, uint256 epoch) external returns (uint256) {
        epoch -= 1;
        getReceiverWeightWrite(id);
        getTotalWeightWrite();

        uint256 totalWeight = totalEpochWeights[epoch];
        if (totalWeight == 0) return 0;

        return (1e18 * uint256(receiverEpochWeights[id][epoch])) / totalWeight;
    }

    /**
        @notice Record the current lock weights for `account`, which can then
                be used to vote.
        @param minEpochs The minimum number of epochs-to-unlock to record weights
                        for. The more active lock epochs that are registered, the
                        more expensive it will be to vote. Accounts with many active
                        locks may wish to skip smaller locks to reduce gas costs.
     */
    function registerAccountWeight(address account, uint256 minEpochs) external callerOrDelegated(account) {
        AccountData storage accountData = accountLockData[account];
        Vote[] memory existingVotes;

        // if account has an active vote, clear the recorded vote
        // weights prior to updating the registered account weights
        if (accountData.voteLength > 0) {
            existingVotes = getAccountCurrentVotes(account);
            _handleVoteWeights(account, existingVotes, accountData.frozenWeight, sub);
        }

        // get updated account lock weights and store locally
        uint256 frozenWeight = _registerAccountWeight(account, minEpochs);

        // resubmit the account's active vote using the newly registered weights
        _handleVoteWeights(account, existingVotes, frozenWeight, add);
        // do not call `_storeAccountVotes` because the vote is unchanged
    }

    /**
        @notice Record the current lock weights for `account` and submit new votes
        @dev New votes replace any prior active votes
        @param minEpochs Minimum number of epochs-to-unlock to record weights for
        @param votes Array of tuples of (recipient id, vote points)
     */
    function registerAccountWeightAndVote(
        address account,
        uint256 minEpochs,
        Vote[] calldata votes
    ) external callerOrDelegated(account) {
        AccountData storage accountData = accountLockData[account];

        // if account has an active vote, clear the recorded vote
        // weights prior to updating the registered account weights
        if (accountData.voteLength > 0) {
            _handleVoteWeights(account, getAccountCurrentVotes(account), accountData.frozenWeight, sub);
            emit ClearedVotes(account, getWeek());
        }

        // get updated account lock weights and store locally
        uint256 frozenWeight = _registerAccountWeight(account, minEpochs);

        // adjust vote weights based on the account's new vote
        _handleVoteWeights(account, votes, frozenWeight, add);
        // store the new account votes
        _storeAccountVotes(account, accountData, votes, 0, 0);
    }

    /**
        @notice Vote for one or more recipients
        @dev * Each voter can vote with up to `MAX_PCT` points
             * It is not required to use every point in a single call
             * Votes carry over epoch-to-epoch and decay at the same rate as lock
               weight
             * The total weight is NOT distributed porportionally based on the
               points used, an account must allocate all points in order to use
               it's full vote weight
        @param votes Array of tuples of (recipient id, vote points)
        @param clearPrevious if true, the voter's current votes are cleared
                             prior to recording the new votes. If false, new
                             votes are added in addition to previous votes.
     */
    function vote(address account, Vote[] calldata votes, bool clearPrevious) external callerOrDelegated(account) {
        AccountData storage accountData = accountLockData[account];
        uint256 frozenWeight = accountData.frozenWeight;
        require(frozenWeight > 0 || accountData.lockLength > 0, "No registered weight");
        uint256 points;
        uint256 offset;

        // optionally clear previous votes
        if (clearPrevious) {
            _handleVoteWeights(account, getAccountCurrentVotes(account), frozenWeight, sub);
            emit ClearedVotes(account, getWeek());
        } else {
            points = accountData.points;
            offset = accountData.voteLength;
        }

        // adjust vote weights based on the new vote
        _handleVoteWeights(account, votes, frozenWeight, add);
        // store the new account votes
        _storeAccountVotes(account, accountData, votes, points, offset);
    }

    /**
        @notice Remove all active votes for the caller
     */
    function clearVote(address account) external callerOrDelegated(account) {
        AccountData storage accountData = accountLockData[account];
        uint256 frozenWeight = accountData.frozenWeight;
        _handleVoteWeights(account, getAccountCurrentVotes(account), frozenWeight, sub);
        accountData.voteLength = 0;
        accountData.points = 0;

        emit ClearedVotes(account, getWeek());
    }

    /**
        @notice Clear registered weight and votes for `account`
        @dev Called by `tokenLocker` when an account performs an early withdrawal
             of locked tokens, to prevent a registered weight > actual lock weight
     */
    function clearRegisteredWeight(address account) external returns (bool) {
        require(
            msg.sender == account || msg.sender == address(tokenLocker) || isApprovedDelegate[account][msg.sender],
            "Delegate not approved"
        );

        AccountData storage accountData = accountLockData[account];
        uint256 epoch = getWeek();
        uint256 length = accountData.lockLength;
        uint256 frozenWeight = accountData.frozenWeight;
        if (length > 0 || frozenWeight > 0) {
            if (accountData.voteLength > 0) {
                _handleVoteWeights(account, getAccountCurrentVotes(account), frozenWeight, sub);
                accountData.voteLength = 0;
                accountData.points = 0;
                emit ClearedVotes(account, epoch);
            }
            // lockLength and frozenWeight are never both > 0
            if (length > 0) accountData.lockLength = 0;
            else accountData.frozenWeight = 0;

            emit AccountWeightRegistered(account, epoch, 0, new ITokenLocker.LockData[](0));
        }

        return true;
    }

    /**
        @notice Set a frozen account weight as unfrozen
        @dev Callable only by the token locker. This prevents users from
             registering frozen locks, unfreezing, and having a larger registered
             vote weight than their actual lock weight.
     */
    function unfreeze(address account, bool keepVote) external returns (bool) {
        require(msg.sender == address(tokenLocker), "Only TokenLocker");
        AccountData storage accountData = accountLockData[account];
        uint256 frozenWeight = accountData.frozenWeight;

        // if frozenWeight == 0, the account was not registered so nothing needed
        if (frozenWeight > 0) {
            // clear previous votes
            Vote[] memory existingVotes;
            if (accountData.voteLength > 0) {
                existingVotes = getAccountCurrentVotes(account);
                _handleVoteWeightFrozen(existingVotes, frozenWeight, sub);
            }

            uint256 epoch = getWeek();
            accountData.epoch = uint16(epoch);
            accountData.frozenWeight = 0;

            uint amount = frozenWeight / MAX_LOCK_EPOCHS;
            accountData.lockedAmounts[0] = uint120(amount);
            accountData.epochsToUnlock[0] = uint8(MAX_LOCK_EPOCHS);
            accountData.lockLength = 1;

            // optionally resubmit previous votes
            if (existingVotes.length > 0) {
                if (keepVote) {
                    _handleVoteWeightUnfrozen(account, existingVotes, add);
                } else {
                    accountData.voteLength = 0;
                    accountData.points = 0;
                    emit ClearedVotes(account, epoch);
                }
            }

            ITokenLocker.LockData[] memory lockData = new ITokenLocker.LockData[](1);
            lockData[0] = ITokenLocker.LockData({ amount: amount, epochsToUnlock: MAX_LOCK_EPOCHS });
            emit AccountWeightRegistered(account, epoch, 0, lockData);
        }
        return true;
    }

    /**
        @dev Get the current registered lock weights for `account`, as an array
             of [(amount, epochs to unlock)] sorted by epochs-to-unlock descending.
     */
    function _getAccountLocks(address account) internal view returns (LockData[] memory lockData) {
        AccountData storage accountData = accountLockData[account];

        uint256 length = accountData.lockLength;
        uint256 systemEpoch = getWeek();
        uint256 accountEpoch = accountData.frozenWeight > 0 ? systemEpoch : accountData.epoch;
        uint8[MAX_LOCK_EPOCHS] storage epochsToUnlock = accountData.epochsToUnlock;
        uint120[MAX_LOCK_EPOCHS] storage amounts = accountData.lockedAmounts;

        lockData = new LockData[](length);
        uint256 idx;
        for (; idx < length; idx++) {
            uint256 unlockEpoch = epochsToUnlock[idx] + accountEpoch;
            if (unlockEpoch <= systemEpoch) {
                assembly {
                    mstore(lockData, idx)
                }
                break;
            }
            uint256 remainingEpochs = unlockEpoch - systemEpoch;
            uint256 amount = amounts[idx];
            lockData[idx] = LockData({ amount: amount, epochsToUnlock: remainingEpochs });
        }

        return lockData;
    }

    function _registerAccountWeight(address account, uint256 minEpochs) internal returns (uint256) {
        AccountData storage accountData = accountLockData[account];

        // get updated account lock weights and store locally
        (ITokenLocker.LockData[] memory lockData, uint256 frozen) = tokenLocker.getAccountActiveLocks(
            account,
            minEpochs
        );
        uint256 length = lockData.length;
        if (frozen > 0) {
            frozen *= MAX_LOCK_EPOCHS;
            accountData.frozenWeight = uint128(frozen);
        } else if (length > 0) {
            for (uint256 i = 0; i < length; i++) {
                uint256 amount = lockData[i].amount;
                uint256 epochsToUnlock = lockData[i].epochsToUnlock;
                accountData.lockedAmounts[i] = uint120(amount);
                accountData.epochsToUnlock[i] = uint8(epochsToUnlock);
            }
        } else {
            revert("No active locks");
        }
        uint256 epoch = getWeek();
        accountData.epoch = uint16(epoch);
        accountData.lockLength = uint8(length);

        emit AccountWeightRegistered(account, epoch, frozen, lockData);

        return frozen;
    }

    function _storeAccountVotes(
        address account,
        AccountData storage accountData,
        Vote[] calldata votes,
        uint256 points,
        uint256 offset
    ) internal {
        uint16[2][MAX_PCT] storage storedVotes = accountData.activeVotes;
        uint256 length = votes.length;
        for (uint256 i = 0; i < length; i++) {
            storedVotes[offset + i] = [uint16(votes[i].id), uint16(votes[i].points)];
            points += votes[i].points;
        }
        require(points <= MAX_PCT, "Exceeded max vote points");
        accountData.voteLength = uint16(offset + length);
        accountData.points = uint16(points);

        emit NewVotes(account, getWeek(), votes, points);
    }

    /**
        @dev Increases receiver and total weights, using a vote array and the
             registered weights of `msg.sender`. Account related values are not
             adjusted, they must be handled in the calling function.
     */
    function _handleVoteWeights(
        address account,
        Vote[] memory votes,
        uint256 frozenWeight,
        function (uint256, uint256) internal pure returns(uint256) op
    ) internal {
        if (votes.length > 0) {
            if (frozenWeight > 0) {
                _handleVoteWeightFrozen(votes, frozenWeight, op);
            } else {
                _handleVoteWeightUnfrozen(account, votes, op);
            }
        }
    }

    function _handleVoteWeightUnfrozen(
        address account,
        Vote[] memory votes,
        function (uint256, uint256) internal pure returns(uint256) op
    ) internal {
        LockData[] memory lockData = _getAccountLocks(account);
        uint256 lockLength = lockData.length;
        if(op == add) require(lockLength > 0, "Registered weight has expired");

        uint256 systemEpoch = getWeek();
        // Move calculation into separate function to avoid stack too deep error
        (uint256 totalWeight, uint256 totalDecay, uint256[MAX_LOCK_EPOCHS + 1] memory epochUnlocks) =
            _calculTotalWeightAndTotalDecay(votes.length, votes, lockLength, lockData, systemEpoch, op);

        for (uint256 i = 0; i < lockLength; i++) {
            uint256 epochsToUnlock = lockData[i].epochsToUnlock;
            totalEpochUnlocks[systemEpoch + epochsToUnlock] =
                uint120(op(totalEpochUnlocks[systemEpoch + epochsToUnlock], epochUnlocks[epochsToUnlock]));
        }
        totalEpochWeights[systemEpoch] = uint128(op(getTotalWeightWrite(), totalWeight));
        totalDecayRate = uint120(op(totalDecayRate, totalDecay));
    }

    function _calculTotalWeightAndTotalDecay(
        uint256 len,
        Vote[] memory votes,
        uint256 lockLength,
        LockData[] memory lockData,
        uint256 systemEpoch,
        function (uint256, uint256) internal pure returns(uint256) op
    ) internal returns (uint256 totalWeight, uint256 totalDecay, uint256[MAX_LOCK_EPOCHS + 1] memory epochUnlocks) {
        for (uint256 i = 0; i < len; i++) {
            uint256 id = votes[i].id;
            uint256 points = votes[i].points;
            uint256 weight = 0;
            uint256 decayRate = 0;

            for (uint256 x = 0; x < lockLength; x++) {
                uint256 epochsToUnlock = lockData[x].epochsToUnlock;
                uint256 amount = (lockData[x].amount * points) / MAX_PCT;

                receiverEpochUnlocks[id][systemEpoch + epochsToUnlock] =
                    uint120(op(receiverEpochUnlocks[id][systemEpoch + epochsToUnlock], amount));
                epochUnlocks[epochsToUnlock] += uint120(amount);
                weight += amount * epochsToUnlock;
                decayRate += amount;
            }
            receiverEpochWeights[id][systemEpoch] = uint128(op(getReceiverWeightWrite(id), weight));
            receiverDecayRate[id] = uint120(op(receiverDecayRate[id], decayRate));

            totalWeight += weight;
            totalDecay += decayRate;
        }
    }

    function _handleVoteWeightFrozen(
        Vote[] memory votes,
        uint256 frozenWeight,
        function (uint256, uint256) internal pure returns(uint256) op
    ) internal {
        uint256 systemEpoch = getWeek();

        uint256 totalWeight;
        uint256 length = votes.length;
        for (uint256 i = 0; i < length; i++) {
            (uint256 id, uint256 points) = (votes[i].id, votes[i].points);

            uint256 weight = (frozenWeight * points) / MAX_PCT;

            receiverEpochWeights[id][systemEpoch] = uint128(op(getReceiverWeightWrite(id), weight));

            totalWeight += weight;
        }

        totalEpochWeights[systemEpoch] = uint128(op(getTotalWeightWrite(), totalWeight));
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
}
