// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BoostCalculator} from "../../../../contracts/BoostCalculator.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";

contract Unit_Concrete_BoostCalculator_SetBoostParams_ is Unit_Shared_Test_ {
    /*//////////////////////////////////////////////////////////////
                             REVERTING TEST
    //////////////////////////////////////////////////////////////*/

    function test_BoostCalculator_RevertWhen_SetBoostParams_Because_InvalidMaxBoostMul() public asOwner {
        vm.expectRevert("Invalid maxBoostMul");
        boostCalculator.setBoostParams(0, 1, 2);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test setBoostParams with valid parameters
    function test_BoostCalculator_SetBoostParams() public asOwner {
        // Assertions before
        assertEq(boostCalculator.pendingMaxBoostMultiplier(), 0);
        assertEq(boostCalculator.pendingMaxBoostablePct(), 0);
        assertEq(boostCalculator.pendingDecayBoostPct(), 0);
        assertEq(boostCalculator.paramChangeEpoch(), 0);

        // Expected event
        vm.expectEmit({emitter: address(boostCalculator)});
        emit BoostCalculator.BoostParamsSet(1, 2, 3, 2);

        // Main Call
        boostCalculator.setBoostParams(1, 2, 3);

        // Assertions after
        assertEq(boostCalculator.pendingMaxBoostMultiplier(), 1);
        assertEq(boostCalculator.pendingMaxBoostablePct(), 2);
        assertEq(boostCalculator.pendingDecayBoostPct(), 3);
        assertEq(boostCalculator.paramChangeEpoch(), 2); // With 3.5 startOffset
    }
}
