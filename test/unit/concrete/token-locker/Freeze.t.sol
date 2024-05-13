// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {stdError} from "forge-std/StdError.sol";

import {TokenLockerBase} from "../../../../contracts/dependencies/TokenLockerBase.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardTokenLocker} from "../../../utils/WizardTokenLocker.sol";

contract Unit_Concrete_TokenLocker_Freeze_ is Unit_Shared_Test_ {
    using WizardTokenLocker for Vm;

    uint256 internal startTime;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

        startTime = coreOwner.START_TIME();
        govToken.approve(address(tokenLocker), UINT256_MAX);
    }

    /*//////////////////////////////////////////////////////////////
                             REVERTING TEST
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_Freeze_Because_Frozen()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 5, skipAfter: 0}))
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
    {
        vm.expectRevert("Lock is frozen");
        tokenLocker.freeze();
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Freeze_NoPosition() public {
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksFrozen(address(this), 0);
        tokenLocker.freeze();
    }

    /// @notice Test freeze, Using following conditions:
    /// - At epoch 0, lock 1 token for 5 epochs.
    /// - No timejump.
    /// - Freeze.
    function test_Freeze_RightAfterLocking()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
    {
        uint256 totalLockedBefore = 1 ether;
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as exactly the same as the test
        // `Unit_Concrete_TokenLocker_Lock_::test_Lock_SecondLock_SecondEpoch_WithUnlockOverlapping_WithoutUnlock`

        // Start at the beginning of next epoch
        uint256 epochToSkip = 0;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        // Main call
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksFrozen(address(this), 1 ether);
        tokenLocker.freeze();

        // Assertions
        uint256 weight = totalLockedBefore * tokenLocker.MAX_LOCK_EPOCHS();
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 0);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 0);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), totalLockedBefore);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), true);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), false);
    }

    /// @notice Test freeze, Using following conditions:
    /// - At epoch 0, lock 1 token for 5 epochs.
    /// - Timejump to epoch 2.
    /// - Freeze.
    function test_Freeze_TwoEpochAfterLock()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
    {
        uint256 totalLockedBefore = 1 ether;
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as exactly the same as the test
        // `Unit_Concrete_TokenLocker_Lock_::test_Lock_SecondLock_SecondEpoch_WithUnlockOverlapping_WithoutUnlock`

        // Start at the beginning of next epoch
        uint256 epochToSkip = 2;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        // Main call
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksFrozen(address(this), 1 ether);
        tokenLocker.freeze();

        // Assertions
        uint256 weight = totalLockedBefore * tokenLocker.MAX_LOCK_EPOCHS();
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 0);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 0);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), totalLockedBefore);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), true);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), false);
    }

    /// @notice Test freeze, Using following conditions:
    /// - At epoch 0, lock 1 token for 5 epochs.
    /// - Timejump to epoch 5.
    /// - Freeze.
    function test_Freeze_WhenUnlockHappenedInSameEpoch_SingleLock()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
    {
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as exactly the same as the test
        // `Unit_Concrete_TokenLocker_Lock_::test_Lock_SecondLock_SecondEpoch_WithUnlockOverlapping_WithoutUnlock`

        // Start at the beginning of next epoch
        uint256 epochToSkip = 5;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        // Main call
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksFrozen(address(this), 0);
        tokenLocker.freeze();

        // Assertions
        uint256 weight = 0;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 1 ether);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 1 ether);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 1 ether);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), true);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
    }

    /// @notice Test freeze, Using following conditions:
    /// - At epoch 0, lock 1 token for 5 epochs.
    /// - Timejump to epoch 6.
    /// - Freeze.
    function test_Freeze_WhenUnlockHappenedInPreviousEpoch_SingleLock()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
    {
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as exactly the same as the test
        // `Unit_Concrete_TokenLocker_Lock_::test_Lock_SecondLock_SecondEpoch_WithUnlockOverlapping_WithoutUnlock`

        // Start at the beginning of next epoch
        uint256 epochToSkip = 6;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        // Main call
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksFrozen(address(this), 0);
        tokenLocker.freeze();

        // Assertions
        uint256 weight = 0;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 1 ether);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch - 1), 0);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch - 1), 0);
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 1 ether);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 1 ether);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), true);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
    }

    /// @notice Test freeze, Using following conditions:
    /// - At epoch 0, lockMany: 1 token for 3 epochs and 2 tokens for 5 epochs.
    /// - Timejump to epoch 4.
    /// - Freeze.
    function test_Freeze_WhenUnlockHappenedInSameEpoch_MultipleLock()
        public
        lockMany(
            Modifier_LockMany({
                skipBefore: 0,
                user: address(this),
                amountToLock: [1 ether, 2 ether, 0, 0, 0],
                duration: [3, 5, 0, 0, 0],
                skipAfter: 0
            })
        )
    {
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as exactly the same as the test
        // `Unit_Concrete_ExtendMany_Lock_::test_ExtendMany_AllPositions_RightAfterLocking`

        // Start at the beginning of next epoch
        uint256 epochToSkip = 4;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        // Main call
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksFrozen(address(this), 2 ether);
        tokenLocker.freeze();

        // Assertions
        uint256 weight = 2 ether * tokenLocker.MAX_LOCK_EPOCHS();
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 1 ether);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 0);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 1 ether);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 0);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 1 ether);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 2 ether);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), true);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), false); // This is false because the freeze erase the bitmap.
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), false);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Timejump to epoch 250.
    /// - Lock 1 token for 5 epochs.
    /// - Freeze.
    function test_Freeze_WhenSystem_Is256()
        public
        lock(
            Modifier_Lock({skipBefore: 250 * EPOCH_LENGTH, user: address(this), amountToLock: 1 ether, duration: 10, skipAfter: 0})
        )
    {
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as exactly the same as the test
        // `Unit_Concrete_TokenLocker_Lock_::test_Lock_SecondLock_AccountEpochIsModulo256`

        // Start at the beginning of next epoch
        uint256 epochToSkip = 0;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        // Main call
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksFrozen(address(this), 1 ether);
        tokenLocker.freeze();

        // Assertions
        uint256 weight = 1 ether * tokenLocker.MAX_LOCK_EPOCHS();
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 260), 0);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 260), 0);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 1 ether);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), true);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 250), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 260), false);
    }
}
