// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {DefaultValues as DEF} from "../../../utils/DefaultValues.sol";

import {ITokenLocker} from "../../../../contracts/interfaces/ITokenLocker.sol";
import {IncentiveVoting} from "../../../../contracts/IncentiveVoting.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardIncentiveVoting} from "../../../utils/WizardIncentiveVoting.sol";

contract Unit_Concrete_IncentiveVoting_RegisterAccountWeightAndVote_ is Unit_Shared_Test_ {
    using WizardIncentiveVoting for IncentiveVoting;

    /*//////////////////////////////////////////////////////////////
                            REVERTING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test Register Account Weight and Vote under following conditions:
    /// - Call Register Account Weight and Vote without any locks
    /// - No locks found (because there are no locks at all), then revert
    function test_RevertWhen_RegisterAccountWeightAndVote_Because_NoActiveLocks_DueTo_NoLocks() public {
        vm.expectRevert("No active locks");
        incentiveVoting.registerAccountWeightAndVote(address(this), 0, new IncentiveVoting.Vote[](0));
    }

    /// @notice Test Register Account Weight and Vote under following conditions:
    /// - Skip one period to be sure that we are not at epoch 0
    /// - Lock 1 ether of token for 5 weeks on TokenLocker
    /// - Register account weight, but only fecthing locks higher than the one just made.
    /// - No locks are found, then revert
    function test_RevertWhen_RegisterAccountWeightAndVote_Because_NoActiveLocks_DueTo_TooHighMinEpoch()
        public
        lock(
            Modifier_Lock({
                skipBefore: 1 weeks,
                user: address(this),
                amountToLock: DEF.LOCK_AMOUNT,
                duration: DEF.LOCK_DURATION_W,
                skipAfter: 0
            })
        )
    {
        vm.expectRevert("No active locks");
        incentiveVoting.registerAccountWeightAndVote(address(this), 10, new IncentiveVoting.Vote[](0));
    }

    /// @notice Test Register Account Weight and Vote under following conditions:
    /// - Skip one period to be sure that we are not at epoch 0
    /// - Lock 1 ether of token for 5 weeks on TokenLocker
    /// - Register account weight
    /// - Call Register Account Weight and Vote with a vote that has 0 points
    /// - Revert because vote is higher than MAX_PCT
    function test_RevertWhen_RegisterAccountWeightAndVote_Because_ExceedMaxPoint()
        public
        lock(
            Modifier_Lock({
                skipBefore: 1 weeks,
                user: address(this),
                amountToLock: DEF.LOCK_AMOUNT,
                duration: DEF.LOCK_DURATION_W,
                skipAfter: 0
            })
        )
        addReceiver
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
    {
        IncentiveVoting.Vote[] memory votes = new IncentiveVoting.Vote[](1);
        votes[0] = IncentiveVoting.Vote({id: 1, points: incentiveVoting.MAX_PCT() + 1});
        vm.expectRevert("Exceeded max vote points");
        incentiveVoting.registerAccountWeightAndVote(address(this), 0, votes);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test Register Account Weight and Vote under following conditions:
    /// - Skip one period to be sure that we are not at epoch 0
    /// - Lock 1 ether of token for 5 weeks on TokenLocker
    /// - Register account weight
    /// - No previous votes, account not frozen, single position
    function test_RegisterAccountWeightAndVote_When_NoPreviousVotes_NoVotes_NotFrozen_SinglePosition()
        public
        lock(
            Modifier_Lock({
                skipBefore: 1 weeks,
                user: address(this),
                amountToLock: DEF.LOCK_AMOUNT,
                duration: DEF.LOCK_DURATION_W,
                skipAfter: 0
            })
        )
    {
        // Assertions before
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataFrozenWeightBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(0), uint16(0)]);
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), 0);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), 0);

        // Expected emits
        ITokenLocker.LockData[] memory locks = new ITokenLocker.LockData[](1);
        locks[0] = ITokenLocker.LockData({amount: DEF.LOCK_AMOUNT, epochsToUnlock: DEF.LOCK_DURATION_W});
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.AccountWeightRegistered(address(this), 1, 0, locks);
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.NewVotes(address(this), 1, new IncentiveVoting.Vote[](0), 0);

        // Main call
        incentiveVoting.registerAccountWeightAndVote(address(this), 0, new IncentiveVoting.Vote[](0));

        // Assertions after
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataFrozenWeightBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(0), uint16(0)]);
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), DEF.LOCK_AMOUNT);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), DEF.LOCK_DURATION_W);
    }

    /// @notice Test Register Account Weight and Vote under following conditions:
    /// - Skip one period to be sure that we are not at epoch 0
    /// - Lock 1 ether of token for 5 weeks and 2 ethers of tokens for 10 weeks on TokenLocker
    /// - Register account weight
    /// - No previous votes, account not frozen, single position
    function test_RegisterAccountWeightAndVote_When_NoPreviousVotes_NoVotes_NotFrozen_MultiplePositions_FullLocks()
        public
        lockMany(
            Modifier_LockMany({
                skipBefore: 1 weeks,
                user: address(this),
                amountToLock: [uint64(DEF.LOCK_AMOUNT), 2 * uint64(DEF.LOCK_AMOUNT), 0, 0, 0],
                duration: [uint8(DEF.LOCK_DURATION_W), 2 * uint8(DEF.LOCK_DURATION_W), 0, 0, 0],
                skipAfter: 0
            })
        )
    {
        // Assertions before
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataFrozenWeightBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(0), uint16(0)]);
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), 0);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), 0);

        // Expected emits
        ITokenLocker.LockData[] memory locks = new ITokenLocker.LockData[](2);
        locks[0] = ITokenLocker.LockData({amount: DEF.LOCK_AMOUNT * 2, epochsToUnlock: DEF.LOCK_DURATION_W * 2});
        locks[1] = ITokenLocker.LockData({amount: DEF.LOCK_AMOUNT, epochsToUnlock: DEF.LOCK_DURATION_W});
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.AccountWeightRegistered(address(this), 1, 0, locks);
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.NewVotes(address(this), 1, new IncentiveVoting.Vote[](0), 0);

        // Main call
        incentiveVoting.registerAccountWeightAndVote(address(this), 0, new IncentiveVoting.Vote[](0));

        // Assertions after
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataFrozenWeightBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 2);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(0), uint16(0)]);
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), 2 * DEF.LOCK_AMOUNT);
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 1), 1 * DEF.LOCK_AMOUNT);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), 2 * DEF.LOCK_DURATION_W);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 1), 1 * DEF.LOCK_DURATION_W);
    }

    /// @notice Test Register Account Weight and Vote under following conditions:
    /// - Skip one period to be sure that we are not at epoch 0
    /// - Lock 1 ether of token for 5 weeks and 2 ethers of tokens for 10 weeks on TokenLocker
    /// - Register account weight, but only fecthing locks higher than 7 weeks, to dodge the 5 weeks lock.
    /// - No previous votes, account not frozen, single position
    function test_RegisterAccountWeightAndVote_When_NoPreviousVotes_NoVotes_NotFrozen_MultiplePositions_PartialLocks()
        public
        lockMany(
            Modifier_LockMany({
                skipBefore: 1 weeks,
                user: address(this),
                amountToLock: [uint64(DEF.LOCK_AMOUNT), 2 * uint64(DEF.LOCK_AMOUNT), 0, 0, 0],
                duration: [uint8(DEF.LOCK_DURATION_W), 2 * uint8(DEF.LOCK_DURATION_W), 0, 0, 0],
                skipAfter: 0
            })
        )
    {
        // Assertions before
        // No need to assert, exactly the same as the `test_RegisterAccountWeightAndVote_When_NoPreviousVotes_NotFrozen_MultiplePositions`.

        // Expected emits
        ITokenLocker.LockData[] memory locks = new ITokenLocker.LockData[](1);
        locks[0] = ITokenLocker.LockData({amount: DEF.LOCK_AMOUNT * 2, epochsToUnlock: DEF.LOCK_DURATION_W * 2});
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.AccountWeightRegistered(address(this), 1, 0, locks);
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.NewVotes(address(this), 1, new IncentiveVoting.Vote[](0), 0);

        // Main call
        incentiveVoting.registerAccountWeightAndVote(address(this), 10, new IncentiveVoting.Vote[](0));

        // Assertions after
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataFrozenWeightBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(0), uint16(0)]);
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), 2 * DEF.LOCK_AMOUNT);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), 2 * DEF.LOCK_DURATION_W);
    }

    /// @notice Test Register Account Weight and Vote under following conditions:
    /// - Skip one period to be sure that we are not at epoch 0
    /// - Lock 1 ether of token for 5 weeks on TokenLocker
    /// - Freeze account
    /// - Register account weight
    /// - No previous votes, account not frozen, single position
    function test_RegisterAccountWeightAndVote_When_NoPreviousVotes_NoVotes_Frozen()
        public
        lock(
            Modifier_Lock({
                skipBefore: 1 weeks,
                user: address(this),
                amountToLock: DEF.LOCK_AMOUNT,
                duration: DEF.LOCK_DURATION_W,
                skipAfter: 0
            })
        )
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
    {
        // Assertions before
        // No need to assert, exactly the same as the `test_RegisterAccountWeightAndVote_When_NoPreviousVotes_NotFrozen_SinglePosition`.

        uint256 maxLockEpochs = incentiveVoting.MAX_LOCK_EPOCHS();
        uint256 weight = DEF.LOCK_AMOUNT * maxLockEpochs;
        // Expected emits
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.AccountWeightRegistered(address(this), 1, weight, new ITokenLocker.LockData[](0));
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.NewVotes(address(this), 1, new IncentiveVoting.Vote[](0), 0);

        // Main call

        incentiveVoting.registerAccountWeightAndVote(address(this), 0, new IncentiveVoting.Vote[](0));

        // Assertions after
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataFrozenWeightBySlotReading(address(this)), weight);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(0), uint16(0)]);
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), 0);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), 0);
    }

    /// @notice Test Register Account Weight and Vote under following conditions:
    /// - Lock 1 ether of token for 5 weeks on TokenLocker
    /// - Register new receiver
    /// - Freeze account
    /// - Receiver Weight is already up to date.
    /// - Full weight in one receiver
    function test_RegisterAccountWeightAndVote_When_NoPreviousVotes_SingleVote_Frozen_MaxPoints()
        public
        lock(
            Modifier_Lock({
                skipBefore: 1 weeks,
                user: address(this),
                amountToLock: DEF.LOCK_AMOUNT,
                duration: DEF.LOCK_DURATION_W,
                skipAfter: 0
            })
        )
        addReceiver
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
    {
        // Assertions before
        // Account data
        // No need to assert, exactly the same as the `test_RegisterAccountWeightAndVote_When_NoPreviousVotes_NotFrozen_SinglePosition`.
        // Receiver data
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), 1);
        // Total data
        assertEq(incentiveVoting.getTotalUpdateEpochBySlotReading(), 0);
        assertEq(incentiveVoting.getTotalEpochWeightsBySlotReading(1), 0);

        uint256 maxLockEpochs = incentiveVoting.MAX_LOCK_EPOCHS();
        uint256 weight = DEF.LOCK_AMOUNT * maxLockEpochs;
        uint256 maxPoints = incentiveVoting.MAX_PCT();
        IncentiveVoting.Vote[] memory votes = new IncentiveVoting.Vote[](1);
        votes[0] = IncentiveVoting.Vote({id: 1, points: maxPoints});

        // Expected emits
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.AccountWeightRegistered(address(this), 1, weight, new ITokenLocker.LockData[](0));
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.NewVotes(address(this), 1, votes, maxPoints);

        // Main call
        incentiveVoting.registerAccountWeightAndVote(address(this), 0, votes);

        // Assertions after
        // Account data
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataFrozenWeightBySlotReading(address(this)), weight);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), maxPoints);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(1), uint16(maxPoints)]);
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), 0);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), 0);
        // Receiver data
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(1, 1), weight);
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(1), 0); // 0 Decay as all weight is frozen
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), 1);
        // Total data
        assertEq(incentiveVoting.getTotalUpdateEpochBySlotReading(), 1);
        assertEq(incentiveVoting.getTotalEpochWeightsBySlotReading(1), weight);
    }

    /// @notice Test Register Account Weight and Vote under following conditions:
    /// - Lock 1 ether of token for 5 weeks on TokenLocker
    /// - Register new receiver
    /// - Freeze account
    /// - Receiver Weight is already up to date.
    /// - Half weight in one receiver
    function test_RegisterAccountWeightAndVote_When_NoPreviousVotes_SingleVote_Frozen_HalfPoints()
        public
        lock(
            Modifier_Lock({
                skipBefore: 1 weeks,
                user: address(this),
                amountToLock: DEF.LOCK_AMOUNT,
                duration: DEF.LOCK_DURATION_W,
                skipAfter: 0
            })
        )
        addReceiver
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
    {
        // Assertions before
        // No need to assert, exactly the same as the `test_RegisterAccountWeightAndVote_When_NoPreviousVotes_SingleVote_Frozen_MaxPoints`.

        uint256 maxLockEpochs = incentiveVoting.MAX_LOCK_EPOCHS();
        uint256 weight = DEF.LOCK_AMOUNT * maxLockEpochs;
        uint256 points = incentiveVoting.MAX_PCT() / 2;
        IncentiveVoting.Vote[] memory votes = new IncentiveVoting.Vote[](1);
        votes[0] = IncentiveVoting.Vote({id: 1, points: points});

        // Expected emits
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.AccountWeightRegistered(address(this), 1, weight, new ITokenLocker.LockData[](0));
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.NewVotes(address(this), 1, votes, points);

        // Main call
        incentiveVoting.registerAccountWeightAndVote(address(this), 0, votes);

        // Assertions after
        // Account data
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataFrozenWeightBySlotReading(address(this)), weight);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), points);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(1), uint16(points)]);
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), 0);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), 0);
        // Receiver data
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(1, 1), weight / 2);
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(1), 0); // 0 Decay as all weight is frozen
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), 1);
        // Total data
        assertEq(incentiveVoting.getTotalUpdateEpochBySlotReading(), 1);
        assertEq(incentiveVoting.getTotalEpochWeightsBySlotReading(1), weight / 2);
    }

    /// @notice Test Register Account Weight and Vote under following conditions:
    /// - Lock 1 ether of token for 5 weeks, 2 ethers of tokens for 10 weeks on TokenLocker
    /// - Register 2 new receivers
    /// - Freeze account
    /// - Receiver Weight is already up to date.
    /// - 30% weight in one receiver
    /// - 70% weight in the other receiver
    function test_RegisterAccountWeightAndVote_When_NoPreviousVotes_MultipleVotes_Frozen_MaxPoints()
        public
        lock(
            Modifier_Lock({
                skipBefore: 1 weeks,
                user: address(this),
                amountToLock: DEF.LOCK_AMOUNT,
                duration: DEF.LOCK_DURATION_W,
                skipAfter: 0
            })
        )
        addReceiver
        addReceiver
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
    {
        // Assertions before
        // No need to assert, exactly the same as the `test_RegisterAccountWeightAndVote_When_NoPreviousVotes_SingleVote_Frozen_MaxPoints`.

        uint256 maxLockEpochs = incentiveVoting.MAX_LOCK_EPOCHS();
        uint256 weight = DEF.LOCK_AMOUNT * maxLockEpochs;
        uint256 maxPoints = incentiveVoting.MAX_PCT();
        IncentiveVoting.Vote[] memory votes = new IncentiveVoting.Vote[](2);
        votes[0] = IncentiveVoting.Vote({id: 1, points: maxPoints * 3 / 10});
        votes[1] = IncentiveVoting.Vote({id: 2, points: maxPoints * 7 / 10});
        IncentiveVoting.Vote[] memory votesExpected = new IncentiveVoting.Vote[](2);
        votesExpected[0] = IncentiveVoting.Vote({id: 1, points: maxPoints * 3 / 10});
        votesExpected[1] = IncentiveVoting.Vote({id: 2, points: maxPoints * 7 / 10});

        // Expected emits
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.AccountWeightRegistered(address(this), 1, weight, new ITokenLocker.LockData[](0));
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.NewVotes(address(this), 1, votesExpected, maxPoints);

        // Main call
        incentiveVoting.registerAccountWeightAndVote(address(this), 0, votes);

        // Assertions after
        // Account data
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataFrozenWeightBySlotReading(address(this)), weight);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), maxPoints);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 2);
        assertEq(
            incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1),
            [uint16(1), uint16(votesExpected[0].points)]
        );
        assertEq(
            incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 2),
            [uint16(2), uint16(votesExpected[1].points)]
        );
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), 0);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), 0);
        // Receiver data
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(1, 1), votes[0].points * weight / maxPoints);
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(2, 1), votes[1].points * weight / maxPoints);
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(1), 0); // 0 Decay as all weight is frozen
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(2), 0); // 0 Decay as all weight is frozen
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), 1);
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(2), 1);
        // Total data
        assertEq(incentiveVoting.getTotalUpdateEpochBySlotReading(), 1);
        assertEq(incentiveVoting.getTotalEpochWeightsBySlotReading(1), weight);
    }

    /// @notice Test Register Account Weight and Vote under following conditions:
    /// - Lock 1 ether of token for 5 weeks on TokenLocker
    /// - Register new receiver
    /// - Receiver Weight is already up to date.
    /// - Full weight in one receiver
    function test_RegisterAccountWeightAndVote_When_NoPreviousVotes_SingleVote_NotFrozen_MaxPoints_SingleLocks()
        public
        lock(
            Modifier_Lock({
                skipBefore: 1 weeks,
                user: address(this),
                amountToLock: DEF.LOCK_AMOUNT,
                duration: DEF.LOCK_DURATION_W,
                skipAfter: 0
            })
        )
        addReceiver
    {
        // Assertions before
        // Account data
        // No need to assert, exactly the same as the `test_RegisterAccountWeightAndVote_When_NoPreviousVotes_NoVotes_NotFrozen_SinglePosition`.
        // Receiver data
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(1), 0);
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), 1);
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(1, 1), 0);
        assertEq(incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, 1), 0);
        // Total data
        assertEq(incentiveVoting.getTotalUpdateEpochBySlotReading(), 0);
        assertEq(incentiveVoting.getTotalEpochWeightsBySlotReading(1), 0);

        ITokenLocker.LockData[] memory locks = new ITokenLocker.LockData[](1);
        locks[0] = ITokenLocker.LockData({amount: DEF.LOCK_AMOUNT, epochsToUnlock: DEF.LOCK_DURATION_W});
        uint256 weight = locks[0].amount * locks[0].epochsToUnlock;

        IncentiveVoting.Vote[] memory votes = new IncentiveVoting.Vote[](1);
        votes[0] = IncentiveVoting.Vote({id: 1, points: incentiveVoting.MAX_PCT()});

        // Expected emits
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.AccountWeightRegistered(address(this), 1, 0, locks);
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.NewVotes(address(this), 1, votes, votes[0].points);

        // Main call
        incentiveVoting.registerAccountWeightAndVote(address(this), 0, votes);

        // Assertions after
        // Account data
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataFrozenWeightBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), votes[0].points);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 1);
        assertEq(
            incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(1), uint16(votes[0].points)]
        );
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), DEF.LOCK_AMOUNT);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), DEF.LOCK_DURATION_W);
        // Receiver data
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(1, 1), weight);
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(1), DEF.LOCK_AMOUNT);
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), 1);
        // Total data
        assertEq(incentiveVoting.getTotalDecayRateBySlotReading(), DEF.LOCK_AMOUNT);
        assertEq(incentiveVoting.getTotalUpdateEpochBySlotReading(), 1);
        assertEq(incentiveVoting.getTotalEpochWeightsBySlotReading(1), weight);
        assertEq(incentiveVoting.getTotalEpochUnlocksBySlotReading(1), 0);
        assertEq(incentiveVoting.getTotalEpochUnlocksBySlotReading(DEF.LOCK_DURATION_W + 1), DEF.LOCK_AMOUNT); // +1 due to epoch skipped before
    }

    /// @notice Test Register Account Weight and Vote under following conditions:
    /// - Lock 1 ether of token for 5 weeks and 2 ethers of tokens for 10 weeks on TokenLocker
    /// - Register 2 new receivers
    /// - Receiver Weight is already up to date.
    /// - 30% weight in one receiver
    /// - 70% weight in the other receiver
    function test_RegisterAccountWeightAndVote_When_NoPreviousVotes_MultipleVotes_NotFrozen_MaxPoints_MultipleLocks()
        public
        lockMany(
            Modifier_LockMany({
                skipBefore: 1 weeks,
                user: address(this),
                amountToLock: [uint64(DEF.LOCK_AMOUNT), 2 * uint64(DEF.LOCK_AMOUNT), 0, 0, 0],
                duration: [uint8(DEF.LOCK_DURATION_W), 2 * uint8(DEF.LOCK_DURATION_W), 0, 0, 0],
                skipAfter: 0
            })
        )
        addReceiver
        addReceiver
    {
        // Assertions before
        // No need to assert, exactly the same as the `test_RegisterAccountWeightAndVote_When_NoPreviousVotes_NoVotes_NotFrozen_MultiplePositions_FullLocks`.

        uint256 maxPoints = incentiveVoting.MAX_PCT();
        IncentiveVoting.Vote[] memory votes = new IncentiveVoting.Vote[](2);
        votes[0] = IncentiveVoting.Vote({id: 1, points: maxPoints * 3 / 10});
        votes[1] = IncentiveVoting.Vote({id: 2, points: maxPoints * 7 / 10});

        ITokenLocker.LockData[] memory locks = new ITokenLocker.LockData[](2);
        locks[0] = ITokenLocker.LockData({amount: 2 * DEF.LOCK_AMOUNT, epochsToUnlock: 2 * DEF.LOCK_DURATION_W});
        locks[1] = ITokenLocker.LockData({amount: DEF.LOCK_AMOUNT, epochsToUnlock: DEF.LOCK_DURATION_W});
        uint256 weight = locks[0].amount * locks[0].epochsToUnlock + locks[1].amount * locks[1].epochsToUnlock;

        // Expected emits
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.AccountWeightRegistered(address(this), 1, 0, locks);
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.NewVotes(address(this), 1, votes, maxPoints);

        // Main call
        incentiveVoting.registerAccountWeightAndVote(address(this), 0, votes);

        // Assertions after
        // Account data
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataFrozenWeightBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), maxPoints);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 2);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 2);
        assertEq(
            incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(1), uint16(votes[0].points)]
        );
        assertEq(
            incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 2), [uint16(2), uint16(votes[1].points)]
        );
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), locks[0].amount);
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 1), locks[1].amount);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), locks[0].epochsToUnlock);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 1), locks[1].epochsToUnlock);
        // Receiver data
        assertEq(
            incentiveVoting.getReceiverDecayRateBySlotReading(1),
            locks[0].amount * votes[0].points / maxPoints + locks[1].amount * votes[0].points / maxPoints
        );
        assertEq(
            incentiveVoting.getReceiverDecayRateBySlotReading(2),
            locks[0].amount * votes[1].points / maxPoints + locks[1].amount * votes[1].points / maxPoints
        );
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), 1);
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(2), 1);
        assertEq(
            incentiveVoting.getReceiverEpochWeightsBySlotReading(1, 1),
            (locks[0].amount * votes[0].points / maxPoints) * locks[0].epochsToUnlock
                + (locks[1].amount * votes[0].points / maxPoints) * locks[1].epochsToUnlock
        );
        assertEq(
            incentiveVoting.getReceiverEpochWeightsBySlotReading(2, 1),
            (locks[0].amount * votes[1].points / maxPoints) * locks[0].epochsToUnlock
                + (locks[1].amount * votes[1].points / maxPoints) * locks[1].epochsToUnlock
        );
        assertEq(incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, 1), 0);
        assertEq(
            incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, 1 + locks[1].epochsToUnlock),
            locks[1].amount * votes[0].points / maxPoints
        );
        assertEq(
            incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, 1 + locks[0].epochsToUnlock),
            locks[0].amount * votes[0].points / maxPoints
        );
        assertEq(incentiveVoting.getReceiverEpocUnlocksBySlotReading(2, 1), 0);
        assertEq(
            incentiveVoting.getReceiverEpocUnlocksBySlotReading(2, 1 + locks[1].epochsToUnlock),
            locks[1].amount * votes[1].points / maxPoints
        );
        assertEq(
            incentiveVoting.getReceiverEpocUnlocksBySlotReading(2, 1 + locks[0].epochsToUnlock),
            locks[0].amount * votes[1].points / maxPoints
        );
        // Total data
        assertEq(incentiveVoting.getTotalDecayRateBySlotReading(), locks[0].amount + locks[1].amount);
        assertEq(incentiveVoting.getTotalUpdateEpochBySlotReading(), 1);
        assertEq(incentiveVoting.getTotalEpochWeightsBySlotReading(1), weight);
        assertEq(incentiveVoting.getTotalEpochUnlocksBySlotReading(1), 0);
        assertEq(incentiveVoting.getTotalEpochUnlocksBySlotReading(1 + locks[1].epochsToUnlock), locks[1].amount);
        assertEq(incentiveVoting.getTotalEpochUnlocksBySlotReading(1 + locks[0].epochsToUnlock), locks[0].amount);
    }

    /// @notice Test Register Account Weight and Vote under following conditions:
    /// - Lock 1 ether of token for 5 weeks on TokenLocker
    /// - Register 2 new receivers
    /// - Freeze
    /// - Register account weight and vote full points on receiver 1.
    /// - Skip no time
    /// - Register account weight and vote full points on receiver 2.
    function test_RegisterAccountWeightAndVote_When_PreviousVotes_TransferedToNewReceiver_Frozen_MaxPoints_Directly()
        public
        lock(
            Modifier_Lock({
                skipBefore: 1 weeks,
                user: address(this),
                amountToLock: DEF.LOCK_AMOUNT,
                duration: DEF.LOCK_DURATION_W,
                skipAfter: 0
            })
        )
        addReceiver
        addReceiver
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
        registerAccountWeightAndVote(
            Modifier_RegisterAccountWeightAndVote({
                skipBefore: 0,
                account: address(this),
                minEpochs: 0,
                votes: [
                    [uint256(1), uint256(DEF.MAX_VOTE)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)]
                ],
                skipAfter: 0
            })
        )
    {
        // Assertions before
        // No need to assert, exactly the same as the `test_RegisterAccountWeightAndVote_When_NoPreviousVotes_SingleVote_Frozen_MaxPoints`.
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 1); // Ensure that we have a vote

        uint256 frozenWeight = DEF.LOCK_AMOUNT * incentiveVoting.MAX_LOCK_EPOCHS();

        IncentiveVoting.Vote[] memory votes = new IncentiveVoting.Vote[](1);
        votes[0] = IncentiveVoting.Vote({id: 2, points: incentiveVoting.MAX_PCT()});

        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.ClearedVotes(address(this), 1);
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.AccountWeightRegistered(address(this), 1, frozenWeight, new ITokenLocker.LockData[](0));
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.NewVotes(address(this), 1, votes, votes[0].points);

        // Main call
        incentiveVoting.registerAccountWeightAndVote(address(this), 0, votes);

        // Assertions after
        // Account data
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataFrozenWeightBySlotReading(address(this)), frozenWeight);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), votes[0].points);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 1);
        assertEq(
            incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(2), uint16(votes[0].points)]
        ); // Vote substituted
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), 0);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), 0);
        // Receiver data
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(1), 0); // 0 Decay as no weight
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(2), 0); // 0 Decay as all weight is frozen
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), 1);
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(2), 1);
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(1, 1), 0);
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(2, 1), frozenWeight);
        assertEq(incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, 1), 0); // No unlock as frozen
        assertEq(incentiveVoting.getReceiverEpocUnlocksBySlotReading(2, 1), 0); // No unlock as frozen
        // Total data
        assertEq(incentiveVoting.getTotalDecayRateBySlotReading(), 0); // 0 Decay as all weight is frozen
        assertEq(incentiveVoting.getTotalUpdateEpochBySlotReading(), 1);
        assertEq(incentiveVoting.getTotalEpochWeightsBySlotReading(1), frozenWeight);
        assertEq(incentiveVoting.getTotalEpochUnlocksBySlotReading(1), 0); // No unlock as frozen
    }

    /// @notice Test Register Account Weight and Vote under following conditions:
    /// - Lock 1 ether of token for 5 weeks on TokenLocker
    /// - Register 2 new receivers
    /// - Freeze
    /// - Register account weight and vote full points on receiver 1.
    /// - Skip 2 weeks
    /// - Register account weight and vote full points on receiver 2.
    function test_RegisterAccountWeightAndVote_When_PreviousVotes_TransferedToNewReceiver_Frozen_MaxPoints_After2Weeks()
        public
        lock(
            Modifier_Lock({
                skipBefore: 1 weeks,
                user: address(this),
                amountToLock: DEF.LOCK_AMOUNT,
                duration: DEF.LOCK_DURATION_W,
                skipAfter: 0
            })
        )
        addReceiver
        addReceiver
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
        registerAccountWeightAndVote(
            Modifier_RegisterAccountWeightAndVote({
                skipBefore: 0,
                account: address(this),
                minEpochs: 0,
                votes: [
                    [uint256(1), uint256(DEF.MAX_VOTE)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)]
                ],
                skipAfter: 2 weeks
            })
        )
    {
        // Assertions before
        // No need to assert, almost the same as the `test_RegisterAccountWeightAndVote_When_NoPreviousVotes_SingleVote_Frozen_MaxPoints`.
        assertEq(getWeek(), 3); // 2 weeks skipped + 1 week before
        uint256 newEpoch = 3;

        uint256 frozenWeight = DEF.LOCK_AMOUNT * incentiveVoting.MAX_LOCK_EPOCHS();

        IncentiveVoting.Vote[] memory votes = new IncentiveVoting.Vote[](1);
        votes[0] = IncentiveVoting.Vote({id: 2, points: incentiveVoting.MAX_PCT()});

        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.ClearedVotes(address(this), newEpoch);
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.AccountWeightRegistered(
            address(this), newEpoch, frozenWeight, new ITokenLocker.LockData[](0)
        );
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.NewVotes(address(this), newEpoch, votes, votes[0].points);

        // Main call
        incentiveVoting.registerAccountWeightAndVote(address(this), 0, votes);

        // Assertions after
        // Account data
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), 3);
        assertEq(incentiveVoting.getLockDataFrozenWeightBySlotReading(address(this)), frozenWeight);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), votes[0].points);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 1);
        assertEq(
            incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(2), uint16(votes[0].points)]
        ); // Vote substituted
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), 0);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), 0);
        // Receiver data
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(1), 0); // 0 Decay as no weight
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(2), 0); // 0 Decay as all weight is frozen
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), 3);
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(2), 3);
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(1, 3), 0);
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(1, 2), frozenWeight);
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(2, 3), frozenWeight);
        assertEq(incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, 3), 0); // No unlock as frozen
        assertEq(incentiveVoting.getReceiverEpocUnlocksBySlotReading(2, 3), 0); // No unlock as frozen
        // Total data
        assertEq(incentiveVoting.getTotalDecayRateBySlotReading(), 0); // 0 Decay as all weight is frozen
        assertEq(incentiveVoting.getTotalUpdateEpochBySlotReading(), 3);
        assertEq(incentiveVoting.getTotalEpochWeightsBySlotReading(1), frozenWeight);
        assertEq(incentiveVoting.getTotalEpochWeightsBySlotReading(2), frozenWeight);
        assertEq(incentiveVoting.getTotalEpochWeightsBySlotReading(3), frozenWeight);
        assertEq(incentiveVoting.getTotalEpochUnlocksBySlotReading(3), 0); // No unlock as frozen
    }

    /// @notice Test Register Account Weight and Vote under following conditions:
    /// - Lock 1 ether of token for 5 weeks and 2 ethers of tokens for 10 weeks on TokenLocker
    /// - Register 2 new receivers
    /// - Register account weight and vote 30% points on receiver 1 and 70% points on receiver 2.
    /// - Skip 2 weeks
    /// - Register account weight and vote 80% points on receiver 1 and 10% points on receiver 2, 10% remaining points.
    function test_RegisterAccountWeightAndVote_When_PreviousVotes_UpdateVotes_NotFrozen_MaxPoints_After2Weeks()
        public
        lockMany(
            Modifier_LockMany({
                skipBefore: 1 weeks,
                user: address(this),
                amountToLock: [uint64(DEF.LOCK_AMOUNT), 2 * uint64(DEF.LOCK_AMOUNT), 0, 0, 0],
                duration: [uint8(DEF.LOCK_DURATION_W), 2 * uint8(DEF.LOCK_DURATION_W), 0, 0, 0],
                skipAfter: 0
            })
        )
        addReceiver
        addReceiver
        registerAccountWeightAndVote(
            Modifier_RegisterAccountWeightAndVote({
                skipBefore: 0,
                account: address(this),
                minEpochs: 0,
                votes: [
                    [uint256(1), uint256(DEF.MAX_VOTE * 3 / 10)],
                    [uint256(2), uint256(DEF.MAX_VOTE * 7 / 10)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)]
                ],
                skipAfter: 2 weeks
            })
        )
    {
        // Assertions before
        // No need to assert, almost the same as the `test_RegisterAccountWeightAndVote_When_NoPreviousVotes_MultipleVotes_NotFrozen_MaxPoints_MultipleLocks`.

        assertEq(getWeek(), 3); // 2 weeks skipped + 1 week before
        uint256 epochSkipped = 2;
        uint256 newEpoch = 1 + epochSkipped;

        uint256 maxPoints = incentiveVoting.MAX_PCT();
        IncentiveVoting.Vote[] memory votes = new IncentiveVoting.Vote[](2);
        votes[0] = IncentiveVoting.Vote({id: 1, points: maxPoints * 8 / 10});
        votes[1] = IncentiveVoting.Vote({id: 2, points: maxPoints * 1 / 10});
        uint256 totalPoints = votes[0].points + votes[1].points;

        ITokenLocker.LockData[] memory locks = new ITokenLocker.LockData[](2);
        locks[0] =
            ITokenLocker.LockData({amount: 2 * DEF.LOCK_AMOUNT, epochsToUnlock: 2 * DEF.LOCK_DURATION_W - epochSkipped});
        locks[1] = ITokenLocker.LockData({amount: DEF.LOCK_AMOUNT, epochsToUnlock: DEF.LOCK_DURATION_W - epochSkipped});

        // Expected emits
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.ClearedVotes(address(this), newEpoch);
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.AccountWeightRegistered(address(this), newEpoch, 0, locks);
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.NewVotes(address(this), newEpoch, votes, totalPoints);

        // Main call
        incentiveVoting.registerAccountWeightAndVote(address(this), 0, votes);

        // Assertions after
        // Account data
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), newEpoch);
        assertEq(incentiveVoting.getLockDataFrozenWeightBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), totalPoints);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 2);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 2);
        assertEq(
            incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(1), uint16(votes[0].points)]
        );
        assertEq(
            incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 2), [uint16(2), uint16(votes[1].points)]
        );
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), locks[0].amount);
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 1), locks[1].amount);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), locks[0].epochsToUnlock);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 1), locks[1].epochsToUnlock);
        // Receiver data
        assertEq(
            incentiveVoting.getReceiverDecayRateBySlotReading(1),
            locks[0].amount * votes[0].points / maxPoints + locks[1].amount * votes[0].points / maxPoints
        );
        assertEq(
            incentiveVoting.getReceiverDecayRateBySlotReading(2),
            locks[0].amount * votes[1].points / maxPoints + locks[1].amount * votes[1].points / maxPoints
        );
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), newEpoch);
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(2), newEpoch);
        assertEq(
            incentiveVoting.getReceiverEpochWeightsBySlotReading(1, newEpoch - 1),
            (locks[0].amount * 3_000 / maxPoints) * (locks[0].epochsToUnlock + 1)
                + (locks[1].amount * 3_000 / maxPoints) * (locks[1].epochsToUnlock + 1)
        );
        assertEq(
            incentiveVoting.getReceiverEpochWeightsBySlotReading(2, newEpoch - 1),
            (locks[0].amount * 7_000 / maxPoints) * (locks[0].epochsToUnlock + 1)
                + (locks[1].amount * 7_000 / maxPoints) * (locks[1].epochsToUnlock + 1)
        );
        assertEq(
            incentiveVoting.getReceiverEpochWeightsBySlotReading(1, newEpoch),
            (locks[0].amount * votes[0].points / maxPoints) * locks[0].epochsToUnlock
                + (locks[1].amount * votes[0].points / maxPoints) * locks[1].epochsToUnlock
        );
        assertEq(
            incentiveVoting.getReceiverEpochWeightsBySlotReading(2, newEpoch),
            (locks[0].amount * votes[1].points / maxPoints) * locks[0].epochsToUnlock
                + (locks[1].amount * votes[1].points / maxPoints) * locks[1].epochsToUnlock
        );
        assertEq(incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, newEpoch), 0);
        assertEq(
            incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, newEpoch + locks[1].epochsToUnlock),
            locks[1].amount * votes[0].points / maxPoints
        );
        assertEq(
            incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, newEpoch + locks[0].epochsToUnlock),
            locks[0].amount * votes[0].points / maxPoints
        );
        assertEq(incentiveVoting.getReceiverEpocUnlocksBySlotReading(2, newEpoch), 0);
        assertEq(
            incentiveVoting.getReceiverEpocUnlocksBySlotReading(2, newEpoch + locks[1].epochsToUnlock),
            locks[1].amount * votes[1].points / maxPoints
        );
        assertEq(
            incentiveVoting.getReceiverEpocUnlocksBySlotReading(2, newEpoch + locks[0].epochsToUnlock),
            locks[0].amount * votes[1].points / maxPoints
        );
        // Total data
        assertEq(
            incentiveVoting.getTotalDecayRateBySlotReading(),
            locks[0].amount * votes[0].points / maxPoints + locks[1].amount * votes[0].points / maxPoints
                + locks[0].amount * votes[1].points / maxPoints + locks[1].amount * votes[1].points / maxPoints
        );
        assertEq(incentiveVoting.getTotalUpdateEpochBySlotReading(), newEpoch);
        assertEq(
            incentiveVoting.getTotalEpochWeightsBySlotReading(newEpoch - 1),
            (locks[0].amount * 3_000 / maxPoints) * (locks[0].epochsToUnlock + 1)
                + (locks[1].amount * 3_000 / maxPoints) * (locks[1].epochsToUnlock + 1)
                + (locks[0].amount * 7_000 / maxPoints) * (locks[0].epochsToUnlock + 1)
                + (locks[1].amount * 7_000 / maxPoints) * (locks[1].epochsToUnlock + 1)
        );
        assertEq(
            incentiveVoting.getTotalEpochWeightsBySlotReading(newEpoch),
            (locks[0].amount * votes[0].points / maxPoints) * locks[0].epochsToUnlock
                + (locks[1].amount * votes[0].points / maxPoints) * locks[1].epochsToUnlock
                + (locks[0].amount * votes[1].points / maxPoints) * locks[0].epochsToUnlock
                + (locks[1].amount * votes[1].points / maxPoints) * locks[1].epochsToUnlock
        );
        assertEq(incentiveVoting.getTotalEpochUnlocksBySlotReading(newEpoch), 0);
        assertEq(
            incentiveVoting.getTotalEpochUnlocksBySlotReading(newEpoch + locks[1].epochsToUnlock),
            locks[1].amount * votes[0].points / maxPoints + locks[1].amount * votes[1].points / maxPoints
        );
        assertEq(
            incentiveVoting.getTotalEpochUnlocksBySlotReading(newEpoch + locks[0].epochsToUnlock),
            locks[0].amount * votes[0].points / maxPoints + locks[0].amount * votes[1].points / maxPoints
        );
    }

    /// @notice Test Register Account Weight and Vote under following conditions:
    /// - Lock 1 ether of token for 5 weeks and 2 ethers of tokens for 10 weeks on TokenLocker
    /// - Register 2 new receivers
    /// - Register account weight and vote 30% points on receiver 1 and 70% points on receiver 2.
    /// - Skip 6 weeks, lock 1 expired
    /// - Register account weight and vote 80% points on receiver 1 and 10% points on receiver 2, 10% remaining points.
    function test_RegisterAccountWeightAndVote_When_PreviousVotes_OneLockExpired()
        public
        lockMany(
            Modifier_LockMany({
                skipBefore: 1 weeks,
                user: address(this),
                amountToLock: [uint64(DEF.LOCK_AMOUNT), 2 * uint64(DEF.LOCK_AMOUNT), 0, 0, 0],
                duration: [uint8(DEF.LOCK_DURATION_W), 2 * uint8(DEF.LOCK_DURATION_W), 0, 0, 0],
                skipAfter: 0
            })
        )
        addReceiver
        addReceiver
        registerAccountWeightAndVote(
            Modifier_RegisterAccountWeightAndVote({
                skipBefore: 0,
                account: address(this),
                minEpochs: 0,
                votes: [
                    [uint256(1), uint256(DEF.MAX_VOTE * 3 / 10)],
                    [uint256(2), uint256(DEF.MAX_VOTE * 7 / 10)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)]
                ],
                skipAfter: 6 weeks
            })
        )
    {
        // Assertions before
        // No need to assert, almost the same as the `test_RegisterAccountWeightAndVote_When_NoPreviousVotes_MultipleVotes_NotFrozen_MaxPoints_MultipleLocks`.

        uint256 epochSkipped = 6;
        uint256 newEpoch = 1 + epochSkipped;
        assertEq(getWeek(), newEpoch); // 6 weeks skipped + 1 week before

        uint256 maxPoints = incentiveVoting.MAX_PCT();
        IncentiveVoting.Vote[] memory votes = new IncentiveVoting.Vote[](2);
        votes[0] = IncentiveVoting.Vote({id: 1, points: maxPoints * 8 / 10});
        votes[1] = IncentiveVoting.Vote({id: 2, points: maxPoints * 1 / 10});
        uint256 totalPoints = votes[0].points + votes[1].points;

        ITokenLocker.LockData[] memory locks = new ITokenLocker.LockData[](1);
        locks[0] =
            ITokenLocker.LockData({amount: 2 * DEF.LOCK_AMOUNT, epochsToUnlock: 2 * DEF.LOCK_DURATION_W - epochSkipped});

        // Expected emits
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.ClearedVotes(address(this), newEpoch);
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.AccountWeightRegistered(address(this), newEpoch, 0, locks);
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.NewVotes(address(this), newEpoch, votes, totalPoints);

        // Main call
        incentiveVoting.registerAccountWeightAndVote(address(this), 0, votes);

        // Assertions after
        // Account data
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), newEpoch);
        assertEq(incentiveVoting.getLockDataFrozenWeightBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), totalPoints);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 2);
        assertEq(
            incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(1), uint16(votes[0].points)]
        );
        assertEq(
            incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 2), [uint16(2), uint16(votes[1].points)]
        );
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), locks[0].amount);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), locks[0].epochsToUnlock);
        // Receiver data
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(1), locks[0].amount * votes[0].points / maxPoints);
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(2), locks[0].amount * votes[1].points / maxPoints);
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), newEpoch);
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(2), newEpoch);
        assertEq(
            incentiveVoting.getReceiverEpochWeightsBySlotReading(1, newEpoch - 1),
            (locks[0].amount * 3_000 / maxPoints) * (locks[0].epochsToUnlock + 1)
        );
        assertEq(
            incentiveVoting.getReceiverEpochWeightsBySlotReading(2, newEpoch - 1),
            (locks[0].amount * 7_000 / maxPoints) * (locks[0].epochsToUnlock + 1)
        );
        assertEq(
            incentiveVoting.getReceiverEpochWeightsBySlotReading(1, newEpoch),
            (locks[0].amount * votes[0].points / maxPoints) * locks[0].epochsToUnlock
        );
        assertEq(
            incentiveVoting.getReceiverEpochWeightsBySlotReading(2, newEpoch),
            (locks[0].amount * votes[1].points / maxPoints) * locks[0].epochsToUnlock
        );
        assertEq(incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, newEpoch), 0);
        assertEq(
            incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, epochSkipped), DEF.LOCK_AMOUNT * 3_000 / maxPoints
        ); // Assert at epoch 6 (1 + 5), epoch unlock is correct (even this is in the past)
        assertEq(
            incentiveVoting.getReceiverEpocUnlocksBySlotReading(2, epochSkipped), DEF.LOCK_AMOUNT * 7_000 / maxPoints
        ); // Assert at epoch 6 (1 + 5), epoch unlock is correct (even this is in the past)
        assertEq(
            incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, newEpoch + locks[0].epochsToUnlock),
            locks[0].amount * votes[0].points / maxPoints
        );
        assertEq(
            incentiveVoting.getReceiverEpocUnlocksBySlotReading(2, newEpoch + locks[0].epochsToUnlock),
            locks[0].amount * votes[1].points / maxPoints
        );
        // Total data
        assertEq(
            incentiveVoting.getTotalDecayRateBySlotReading(),
            locks[0].amount * votes[0].points / maxPoints + locks[0].amount * votes[1].points / maxPoints
        );
        assertEq(incentiveVoting.getTotalUpdateEpochBySlotReading(), newEpoch);
        assertEq(
            incentiveVoting.getTotalEpochWeightsBySlotReading(newEpoch - 2),
            (locks[0].amount * 3_000 / maxPoints) * (locks[0].epochsToUnlock + 2)
                + (DEF.LOCK_AMOUNT * 3_000 / maxPoints) * (1)
                + (locks[0].amount * 7_000 / maxPoints) * (locks[0].epochsToUnlock + 2)
                + (DEF.LOCK_AMOUNT * 7_000 / maxPoints) * (1)
        );
        assertEq(
            incentiveVoting.getTotalEpochWeightsBySlotReading(newEpoch - 1),
            (locks[0].amount * 3_000 / maxPoints) * (locks[0].epochsToUnlock + 1)
                + (locks[0].amount * 7_000 / maxPoints) * (locks[0].epochsToUnlock + 1)
        );
        assertEq(
            incentiveVoting.getTotalEpochWeightsBySlotReading(newEpoch),
            (locks[0].amount * votes[0].points / maxPoints) * locks[0].epochsToUnlock
                + (locks[0].amount * votes[1].points / maxPoints) * locks[0].epochsToUnlock
        );
        assertEq(incentiveVoting.getTotalEpochUnlocksBySlotReading(newEpoch), 0);
        assertEq(
            incentiveVoting.getTotalEpochUnlocksBySlotReading(newEpoch + locks[0].epochsToUnlock),
            locks[0].amount * votes[0].points / maxPoints + locks[0].amount * votes[1].points / maxPoints
        );
        assertEq(
            incentiveVoting.getTotalEpochUnlocksBySlotReading(newEpoch + locks[0].epochsToUnlock),
            locks[0].amount * votes[0].points / maxPoints + locks[0].amount * votes[1].points / maxPoints
        );
    }
}
