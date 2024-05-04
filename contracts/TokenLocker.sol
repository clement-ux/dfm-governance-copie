// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./dependencies/TokenLockerBase.sol";
import "./interfaces/ILPLocker.sol";
import "./interfaces/IIncentiveVoting.sol";

/**
    @title Token Locker
    @notice Tokens can be locked in this contract to receive "lock weight",
            which is used within `AdminVoting` and `IncentiveVoting` to vote on
            core protocol operations.
 */
contract TokenLocker is TokenLockerBase {
    IIncentiveVoting public immutable incentiveVoter;
    ILPLocker public immutable lpLocker;
    IERC20 public immutable stableCoin;

    constructor(
        address core,
        IERC20 _token,
        IIncentiveVoting _voter,
        IERC20 _stableCoin,
        address _lpLocker,
        bool _penaltyWithdrawalsEnabled
    ) TokenLockerBase(core, _token, 7 days, 52, _penaltyWithdrawalsEnabled) {
        incentiveVoter = _voter;

        stableCoin = _stableCoin;
        lpLocker = ILPLocker(_lpLocker);
        stableCoin.approve(_lpLocker, type(uint256).max);
        _token.approve(_lpLocker, type(uint256).max);
    }

    /**
        @notice Unfreeze all locks for the caller
        @dev When an account's locks are unfrozen, the epochs-to-unlock decay normally.
             This is the default locking behaviour for each account. Unfreezing locks
             also updates the frozen status within `IncentiveVoter` - otherwise it could be
             possible for accounts to have a larger registered vote weight than their actual
             lock weight.
        @param keepIncentivesVote If true, existing incentive votes are preserved when updating
                                  the frozen status within `IncentiveVoter`. Voting with unfrozen
                                  weight uses significantly more gas than voting with frozen weight.
                                  If the caller has many active locks and/or many votes, it will be
                                  much cheaper to set this value to false.

     */
    function unfreeze(bool keepIncentivesVote) external {
        incentiveVoter.unfreeze(msg.sender, keepIncentivesVote);
        _unfreeze(msg.sender);
    }

    /**
        @notice Pay a penalty to withdraw locked tokens
        @dev Withdrawals are processed starting with the lock that will expire soonest.
             The penalty starts at 100% and decays linearly based on the number of epochs
             remaining until the tokens unlock. The exact calculation used is:

             [total amount] * [epochs to unlock] / MAX_LOCK_EPOCHS = [penalty amount]

        @param amountToWithdraw Amount to withdraw. This
                                is the same number of tokens that will be received; the
                                penalty amount is taken on top of this. Reverts if the
                                caller's locked balances are insufficient to cover both
                                the withdrawal and penalty amounts. Setting this value as
                                `type(uint256).max` withdrawals the entire available locked
                                balance, excluding any lock at `MAX_LOCK_EPOCHS` as the
                                penalty on this lock would be 100%.
        @return uint256 Amount of tokens withdrawn, penalty amount paid
     */
    function withdrawWithPenalty(uint256 amountToWithdraw) external returns (uint256, uint256) {
        (uint256 withdrawn, uint256 penalty) = _withdrawWithPenalty(amountToWithdraw);
        if (penalty > 0) incentiveVoter.clearRegisteredWeight(msg.sender);
        return (withdrawn, penalty);
    }

    function transferToLpLocker(
        LockData[] calldata locks,
        uint256 stableAmount,
        uint256 minReceived
    ) external returns (uint256 lockAmount, uint256 lockEpochs) {
        (uint256 govAmount, uint256 epoch) = _removeLocks(locks);

        uint256 maxLpEpochs = lpLocker.MAX_LOCK_EPOCHS();
        epoch *= 7;
        if (epoch > maxLpEpochs) epoch = maxLpEpochs;

        stableCoin.transferFrom(msg.sender, address(this), stableAmount);
        lockAmount = lpLocker.addLiquidityAndLock(msg.sender, govAmount, stableAmount, minReceived, epoch);

        return (lockAmount, epoch);
    }

    function _removeLocks(LockData[] calldata locks) internal returns (uint256 decreasedAmount, uint256 maxEpoch) {
        // update account weight
        uint256 accountWeight = _epochWeightWrite(msg.sender);
        uint256 systemEpoch = getEpoch();

        AccountData storage accountData = accountLockData[msg.sender];
        if (accountData.isFrozen) {
            require(locks.length == 1 && locks[0].epochsToUnlock == MAX_LOCK_EPOCHS);
            maxEpoch = MAX_LOCK_EPOCHS;

            decreasedAmount = locks[0].amount;
            uint256 decreasedWeight = decreasedAmount * MAX_LOCK_EPOCHS;

            accountData.frozen -= uint120(decreasedAmount);
            accountEpochWeights[msg.sender][systemEpoch] = uint128(accountWeight - decreasedWeight);
            totalEpochWeights[systemEpoch] = uint128(getTotalWeightWrite() - decreasedWeight);
        } else {
            uint120[65535] storage unlocks = accountEpochUnlocks[msg.sender];

            // copy maybe-updated bitfield entries to memory
            uint256[2] memory bitfield = [
                accountData.updateEpochs[systemEpoch / 256],
                accountData.updateEpochs[(systemEpoch / 256) + 1]
            ];

            uint256 decreasedWeight;

            // iterate locks and store intermediate values in memory where possible
            uint256 length = locks.length;
            for (uint256 i = 0; i < length; i++) {
                uint256 amount = locks[i].amount;
                uint256 epoch = locks[i].epochsToUnlock;
                require(amount > 0, "Amount must be nonzero");
                require(epoch > 0, "Min 1 epoch");
                require(epoch <= MAX_LOCK_EPOCHS, "Exceeds MAX_LOCK_EPOCHS");

                if (epoch > maxEpoch) maxEpoch = epoch;
                decreasedAmount += amount;
                decreasedWeight += amount * epoch;

                uint256 unlockEpoch = systemEpoch + epoch;
                uint256 previous = unlocks[unlockEpoch];
                unlocks[unlockEpoch] = uint120(previous - amount);
                totalEpochUnlocks[unlockEpoch] -= uint120(amount);

                if (previous == amount) {
                    uint256 idx = (unlockEpoch / 256) - (systemEpoch / 256);
                    bitfield[idx] = bitfield[idx] & ~(uint256(1) << (unlockEpoch % 256));
                }
            }

            // write updated bitfield to storage
            accountData.updateEpochs[systemEpoch / 256] = bitfield[0];
            accountData.updateEpochs[(systemEpoch / 256) + 1] = bitfield[1];

            // update account and total weight / decay storage values
            accountEpochWeights[msg.sender][systemEpoch] = uint128(accountWeight - decreasedWeight);
            totalEpochWeights[systemEpoch] = uint128(getTotalWeightWrite() - decreasedWeight);

            accountData.locked = uint120(accountData.locked - decreasedAmount);
            totalDecayRate = uint120(totalDecayRate - decreasedAmount);
        }

        return (decreasedAmount, maxEpoch);
    }
}
