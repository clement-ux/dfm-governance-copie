// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {stdError} from "forge-std/StdError.sol";

import {TokenLockerBase} from "../../../../contracts/dependencies/TokenLockerBase.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardTokenLocker} from "../../../utils/WizardTokenLocker.sol";

contract Unit_Concrete_TokenLocker_Extend_ is Unit_Shared_Test_ {
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

    function test_RevertWhen_Extend_Because_Frozen()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 5, skipAfter: 0}))
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
    {
        vm.expectRevert("Lock is frozen");
        tokenLocker.extendLock(0, 0, 0);
    }

    function test_RevertWhen_Extend_Because_EpochIsZero() public {
        vm.expectRevert("Min 1 epoch");
        tokenLocker.extendLock(0, 0, 0);
    }

    function test_RevertWhen_Extend_Because_NewEpochExceedsMaxEpoch() public {
        uint256 maxEpoch = tokenLocker.MAX_LOCK_EPOCHS();
        vm.expectRevert("Exceeds MAX_LOCK_EPOCHS");
        tokenLocker.extendLock(0, 1, maxEpoch + 1);
    }

    function test_RevertWhen_Extend_Because_NewEpochIsLessThanCurrentEpoch() public {
        vm.expectRevert("newEpochs must be greater than epochs");
        tokenLocker.extendLock(0, 3, 2);
    }

    function test_RevertWhen_Extend_Because_NewEpochIsEqualToCurrentEpoch() public {
        vm.expectRevert("newEpochs must be greater than epochs");
        tokenLocker.extendLock(0, 3, 3);
    }

    function test_RevertWhen_Extend_Because_AmountIsNull() public {
        vm.expectRevert("Amount must be nonzero");
        tokenLocker.extendLock(0, 1, 2);
    }

    function test_RevertWhen_Extend_Because_NoLockAtExtendedEpoch() public {
        vm.expectRevert(stdError.arithmeticError);
        tokenLocker.extendLock(1, 1, 2);

        // uint256 changedEpoch = systemEpoch + _epochs;
        // uint256 previous = unlocks[changedEpoch];
        // It will revert here because _amount is previous is null
        // unlocks[changedEpoch] = uint32(previous - _amount);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test the extension of a lock with the total amount, right after locking
    function test_Extend_All_RightAfterLocking()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
    {
        // --- Assertions before --- //
        uint256 amountLockBefore = 1 ether;
        uint256 unlockTimestampBefore = 5;
        uint256 weightBefore = amountLockBefore * unlockTimestampBefore;
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountLockBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), oldEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), unlockTimestampBefore), amountLockBefore);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), weightBefore);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0), weightBefore);
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore),
            amountLockBefore
        );
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountLockBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), oldEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore), true);

        // Start at the beginning of next epoch
        uint256 epochToSkip = 0;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 amountToExtend = amountLockBefore;
        uint256 lockExtension = 2;
        uint256 newUnlockTimestamp = unlockTimestampBefore + lockExtension;
        uint256 currentEpoch = oldEpoch + epochToSkip;
        // --- Main call --- //
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LockExtended(address(this), amountToExtend, unlockTimestampBefore, newUnlockTimestamp);
        tokenLocker.extendLock(amountToExtend, unlockTimestampBefore, newUnlockTimestamp);

        // Assertions after
        uint256 weight = amountToExtend * newUnlockTimestamp;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountLockBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), unlockTimestampBefore), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), newUnlockTimestamp), amountToExtend);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore), 0);
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), newUnlockTimestamp),
            amountToExtend
        );
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountLockBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0); // Should remain the same
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false); // Should remain the same
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), newUnlockTimestamp), true);
    }

    /// @notice Test the extension of a lock with half the amount, right after locking
    function test_Extend_Half_RightAfterLocking()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 2 ether, duration: 5, skipAfter: 0}))
    {
        // --- Assertions before --- //
        uint256 amountLockBefore = 2 ether;
        uint256 unlockTimestampBefore = 5;
        uint256 weightBefore = amountLockBefore * unlockTimestampBefore;
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountLockBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), oldEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), unlockTimestampBefore), amountLockBefore);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), weightBefore);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0), weightBefore);
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore),
            amountLockBefore
        );
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountLockBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), oldEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore), true);

        // Start at the beginning of next epoch
        uint256 epochToSkip = 0;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 amountToExtend = amountLockBefore / 2;
        uint256 lockExtension = 2;
        uint256 newUnlockTimestamp = unlockTimestampBefore + lockExtension;
        uint256 currentEpoch = oldEpoch + epochToSkip;
        // --- Main call --- //
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LockExtended(address(this), amountToExtend, unlockTimestampBefore, newUnlockTimestamp);
        tokenLocker.extendLock(amountToExtend, unlockTimestampBefore, newUnlockTimestamp);

        // Assertions after
        uint256 weight =
            amountToExtend * newUnlockTimestamp + (amountLockBefore - amountToExtend) * unlockTimestampBefore;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountLockBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(
            vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), unlockTimestampBefore),
            amountLockBefore - amountToExtend
        );
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), newUnlockTimestamp), amountToExtend);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore),
            (amountLockBefore - amountToExtend)
        );
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), newUnlockTimestamp),
            amountToExtend
        );
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountLockBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0); // Should remain the same
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false); // Should remain the same
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), newUnlockTimestamp), true);
    }

    /// @notice Test the extension of a lock with the total amount, 2 epochs after locking
    function test_Extend_All_TwoEpochsAfterLocking()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
    {
        // No need to add assertions before as exactly the same as the test `test_Extend_All_RightAfterLocking`.
        uint256 amountLockBefore = 1 ether;
        uint256 unlockTimestampBefore = 5;
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;

        // Start at the beginning of next epoch
        uint256 epochToSkip = 2;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 amountToExtend = amountLockBefore;
        uint256 lockExtension = 2;
        uint256 newUnlockTimestamp = unlockTimestampBefore + lockExtension; // = 7
        uint256 currentEpoch = oldEpoch + epochToSkip;

        // --- Main call --- //
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LockExtended(
            address(this), amountToExtend, unlockTimestampBefore - epochToSkip, newUnlockTimestamp - epochToSkip
        );
        tokenLocker.extendLock(amountToExtend, unlockTimestampBefore - epochToSkip, newUnlockTimestamp - epochToSkip);

        // Assertions after
        uint256 weight = amountToExtend * (newUnlockTimestamp - epochToSkip);
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountLockBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), unlockTimestampBefore), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), newUnlockTimestamp), amountToExtend);
        assertEq(
            vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch - 1),
            amountLockBefore * (unlockTimestampBefore - (epochToSkip - 1))
        );
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(
            vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch - 1),
            amountLockBefore * (unlockTimestampBefore - (epochToSkip - 1))
        );
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore), 0);
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), newUnlockTimestamp),
            amountToExtend
        );
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountLockBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0); // Should remain the same
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false); // Should remain the same
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), unlockTimestampBefore), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), newUnlockTimestamp), true);
    }

    /// @notice Test the extension of a lock with the total amount Using following conditions:
    /// - At epoch 0 lock 1 token for 3 epochs
    /// - At epoch 0 lock 1 token for 5 epochs
    /// Timejump to epoch 4
    /// - At epoch 4 extend the lock of 1 token ending at epoch 5 for 2 extra epoch
    function test_Extend_All_WhenUnlockHappen()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 3, skipAfter: 0}))
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
    {
        // --- Assertions before --- //
        uint256 amountLockBefore = 2 ether;
        uint256 unlockTimestampBefore = 5;
        uint256 weightBefore = 1 ether * 3 + 1 ether * 5;
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountLockBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), oldEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 1 ether);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 1 ether);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), weightBefore);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0), weightBefore);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 1 ether);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 1 ether);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountLockBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), oldEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);

        // Start at the beginning of next epoch
        uint256 epochToSkip = 4;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 amountToExtend = 1 ether;
        uint256 lockExtension = 2;
        uint256 newUnlockTimestamp = unlockTimestampBefore + lockExtension; // 5 + 2 = 7
        uint256 currentEpoch = oldEpoch + epochToSkip;
        // --- Main call --- //
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LockExtended(
            address(this), amountToExtend, unlockTimestampBefore - epochToSkip, newUnlockTimestamp - epochToSkip
        );
        tokenLocker.extendLock(amountToExtend, unlockTimestampBefore - epochToSkip, newUnlockTimestamp - epochToSkip);

        // Assertions after
        uint256 weight = amountToExtend * (newUnlockTimestamp - epochToSkip);
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountToExtend);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 1 ether);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 7), 1 ether);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch - 1), 2 ether);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch - 1), 2 ether);
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 1 ether);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 7), 1 ether);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountToExtend);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 1 ether);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0); // Should remain the same
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false); // Should remain the same
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 7), true);
    }
}
