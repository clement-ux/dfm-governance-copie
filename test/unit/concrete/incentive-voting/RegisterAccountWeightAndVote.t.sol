// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";

import {DefaultValues as DEF} from "../../../utils/DefaultValues.sol";

import {ITokenLocker} from "../../../../contracts/interfaces/ITokenLocker.sol";
import {IncentiveVoting} from "../../../../contracts/IncentiveVoting.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardIncentiveVoting} from "../../../utils/WizardIncentiveVoting.sol";

import {stdStorage, StdStorage} from "forge-std/Test.sol";

contract Unit_Concrete_IncentiveVoting_RegisterAccountWeightAndVote_ is Unit_Shared_Test_ {
    using WizardIncentiveVoting for IncentiveVoting;
    using stdStorage for StdStorage;

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
    /// - Full weight in one receiver
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
    function test_RegisterAccountWeightAndVote_When_NoPreviousVotes_SingleVote_NotFrozen_MaxPoints()
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
}
