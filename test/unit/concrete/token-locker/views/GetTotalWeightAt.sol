// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";

import {Unit_Shared_Test_} from "../../../shared/Shared.sol";
import {WizardTokenLocker} from "../../../../utils/WizardTokenLocker.sol";

contract Unit_Concrete_TokenLocker_GetTotalWeightAt_ is Unit_Shared_Test_ {
    using WizardTokenLocker for Vm;

    uint256 internal startTime;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

        startTime = coreOwner.START_TIME();
        govToken.approve(address(tokenLocker), MAX);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test the getTotalWeightAt function under the following conditions:
    /// - No position.
    /// - Get total weight for epoch 1 when at epoch 0.
    function test_GetTotalWeightAt_When_Epoch_IsGreaterThan_SystemEpoch() public view {
        assertEq(tokenLocker.getTotalWeightAt(1), 0);
    }

    /// @notice Test the getTotalWeightAt function under the following conditions:
    /// - Time jump 3 epochs
    /// - Locks 1 token for 5 epochs
    /// - Get total weight for epoch 3 when at epoch 3.
    function test_GetTotalWeightAt_When_LastUpdate_IsGreaterOrEqualThan_Epoch()
        public
        lock(Modifier_Lock({skipBefore: 3 weeks, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
    {
        // Assertions before
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), 3);

        assertEq(tokenLocker.getTotalWeightAt(3), 1 ether * 5);
    }

    /// @notice Test the getTotalWeightAt function under the following conditions:
    /// - Skip 2 epochs
    /// - Get total weight for epoch 1 when at epoch 0.
    function test_GetTotalWeightAt_When_Rate_IsEqualTo_Zero() public {
        skip(2 weeks);
        assertEq(tokenLocker.getTotalWeightAt(1), 0);
    }

    /// @notice Test the getTotalWeightAt function under the following conditions:
    /// - Time jump 3 epochs
    /// - Locks 1 token for 5 epochs
    /// - Get total weight for epoch 5 when at epoch 6.
    function test_GetTotalWeightAt_When_Epoch_IsGreaterThan_LastUpdate_BeforeLockExpire()
        public
        lock(Modifier_Lock({skipBefore: 3 weeks, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
    {
        skip(3 weeks);
        assertEq(tokenLocker.getTotalWeightAt(5), 1 ether * 3);
    }

    /// @notice Test the getTotalWeightAt function under the following conditions:
    /// - Time jump 3 epochs
    /// - Locks 1 token for 5 epochs
    /// - Get total weight for epoch 8 when at epoch 8.
    function test_GetTotalWeightAt_When_Epoch_IsGreaterThan_LastUpdate_UntilLockExpire()
        public
        lock(Modifier_Lock({skipBefore: 3 weeks, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
    {
        skip(6 weeks);
        assertEq(tokenLocker.getTotalWeightAt(8), 0);
    }

    /// @notice Same as previous tests, but not really necessary, only for coverage.
    function test_GetTotalWeight() public view {
        assertEq(tokenLocker.getTotalWeight(), 0);
    }
}
