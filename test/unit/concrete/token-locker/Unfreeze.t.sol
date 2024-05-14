// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {stdError} from "forge-std/StdError.sol";

import {TokenLockerBase} from "../../../../contracts/dependencies/TokenLockerBase.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardTokenLocker} from "../../../utils/WizardTokenLocker.sol";

contract Unit_Concrete_TokenLocker_Unfreeze_ is Unit_Shared_Test_ {
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

    function test_RevertWhen_Unfreeze_Because_NotFrozen() public {
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);

        vm.expectRevert("Locks already unfrozen");
        tokenLocker.unfreeze(false);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test the unfreeze function under the following conditions:
    /// - No position.
    /// - Freeze.
    /// - Unfreeze.
    function test_Unfreeze_WithNoPosition()
        public
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
    {
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), true);

        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksUnfrozen(address(this), 0);
        tokenLocker.unfreeze(false);

        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
    }

    /// @notice Test the unfreeze function under the following conditions:
    /// - Lock.
    /// - Freeze.
    /// - Skip 0 epochs.
    /// - Unfreeze.
    function test_Unfreeze_RightAfterLocking()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
    {
        uint256 totalLockedBefore = 1 ether;
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as exactly the same as the test `Unit_Concrete_TokenLocker_Extend_::test_Extend_All_RightAfterLocking`

        // Start at the beginning of next epoch
        uint256 epochToSkip = 0;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksUnfrozen(address(this), 1 ether);
        tokenLocker.unfreeze(false);

        // Assertions
        uint256 weight = totalLockedBefore * tokenLocker.MAX_LOCK_EPOCHS();
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), totalLockedBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 52), totalLockedBefore);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 52), totalLockedBefore);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), totalLockedBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 52), true);
    }
}
