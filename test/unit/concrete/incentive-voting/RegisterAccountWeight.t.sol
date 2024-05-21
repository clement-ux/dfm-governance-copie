// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";

import {DefaultValues as DEF} from "../../../utils/DefaultValues.sol";

import {ITokenLocker} from "../../../../contracts/interfaces/ITokenLocker.sol";
import {IncentiveVoting} from "../../../../contracts/IncentiveVoting.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardIncentiveVoting} from "../../../utils/WizardIncentiveVoting.sol";

import {stdStorage, StdStorage} from "forge-std/Test.sol";

contract Unit_Concrete_IncentiveVoting_RegisterAccountWeight_ is Unit_Shared_Test_ {
    using WizardIncentiveVoting for IncentiveVoting;
    using stdStorage for StdStorage;

    /*//////////////////////////////////////////////////////////////
                            REVERTING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test Register Account Weight under following conditions:
    /// - Call Register Account Weight without any locks
    /// - No locks found (because there are no locks at all), then revert
    function test_RevertWhen_RegisterAccountWeight_Because_NoActiveLocks_DueTo_NoLocks() public {
        vm.expectRevert("No active locks");
        incentiveVoting.registerAccountWeight(address(this), 0);
    }

    /// @notice Test Register Account Weight under following conditions:
    /// - Skip one period to be sure that we are not at epoch 0
    /// - Lock 1 ether of token for 5 weeks on TokenLocker
    /// - Register account weight, but only fecthing locks higher than the one just made.
    /// - No locks are found, then revert
    function test_RevertWhen_RegisterAccountWeight_Because_NoActiveLocks_DueTo_TooHighMinEpoch()
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
        incentiveVoting.registerAccountWeight(address(this), 10);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test Register Account Weight under following conditions:
    /// - Skip one period to be sure that we are not at epoch 0
    /// - Lock 1 ether of token for 5 weeks on TokenLocker
    /// - Register account weight
    /// - No previous votes, account not frozen, single position
    function test_RegisterAccountWeight_When_NoPreviousVotes_NotFrozen_SinglePosition()
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

        // Main call
        incentiveVoting.registerAccountWeight(address(this), 0);

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

    /// @notice Test Register Account Weight under following conditions:
    /// - Skip one period to be sure that we are not at epoch 0
    /// - Lock 1 ether of token for 5 weeks and 2 ethers of tokens for 10 weeks on TokenLocker
    /// - Register account weight
    /// - No previous votes, account not frozen, single position
    function test_RegisterAccountWeight_When_NoPreviousVotes_NotFrozen_MultiplePositions_FullLocks()
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

        // Main call
        incentiveVoting.registerAccountWeight(address(this), 0);

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

    /// @notice Test Register Account Weight under following conditions:
    /// - Skip one period to be sure that we are not at epoch 0
    /// - Lock 1 ether of token for 5 weeks and 2 ethers of tokens for 10 weeks on TokenLocker
    /// - Register account weight, but only fecthing locks higher than 7 weeks, to dodge the 5 weeks lock.
    /// - No previous votes, account not frozen, single position
    function test_RegisterAccountWeight_When_NoPreviousVotes_NotFrozen_MultiplePositions_PartialLocks()
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
        // No need to assert, exactly the same as the `test_RegisterAccountWeight_When_NoPreviousVotes_NotFrozen_MultiplePositions`.

        // Expected emits
        ITokenLocker.LockData[] memory locks = new ITokenLocker.LockData[](1);
        locks[0] = ITokenLocker.LockData({amount: DEF.LOCK_AMOUNT * 2, epochsToUnlock: DEF.LOCK_DURATION_W * 2});
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.AccountWeightRegistered(address(this), 1, 0, locks);

        // Main call
        incentiveVoting.registerAccountWeight(address(this), DEF.LOCK_DURATION_W + 1);

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

    /// @notice Test Register Account Weight under following conditions:
    /// - Skip one period to be sure that we are not at epoch 0
    /// - Lock 1 ether of token for 5 weeks on TokenLocker
    /// - Freeze account
    /// - Register account weight
    /// - No previous votes, account not frozen, single position
    function test_RegisterAccountWeight_When_NoPreviousVotes_Frozen()
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
        // No need to assert, exactly the same as the `test_RegisterAccountWeight_When_NoPreviousVotes_NotFrozen_SinglePosition`.

        uint256 maxLockEpochs = incentiveVoting.MAX_LOCK_EPOCHS();
        uint256 weight = DEF.LOCK_AMOUNT * maxLockEpochs;
        // Expected emits
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.AccountWeightRegistered(address(this), 1, weight, new ITokenLocker.LockData[](0));

        // Main call
        incentiveVoting.registerAccountWeight(address(this), 0);

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

    // More tests will be added once the _addVoteWeight function is tested.
}
