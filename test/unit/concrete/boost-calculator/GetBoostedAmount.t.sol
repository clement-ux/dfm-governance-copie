// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BoostCalculator} from "../../../../contracts/BoostCalculator.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";

/// @notice Simple single test because `getBoostedAmount` do exactly the same as `getBoostedAmountWrite`.
/// Only difference is that `getBoostedAmount` pass a custom `amount` to be boosted, instead of uint256(maxBoostMultiplier) * 10000;
contract Unit_Concrete_BoostCalculator_GetBoostedAmount_ is Unit_Shared_Test_ {
    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/
    function test_BoostCalculator_GetBoostedAmount_When_UnderGracePeriod() public view {
        // Assertions before
        assertGe(boostCalculator.MAX_BOOST_GRACE_EPOCHS(), getDay()); // Ensure that we are under the grace period

        uint256 amount = 1 ether;
        uint256 previousAmount = 123;
        // Main call
        uint256 adjustedAmount = boostCalculator.getBoostedAmount(address(0), 1 ether, previousAmount, 100 ether);

        // Assertions after
        assertEq(adjustedAmount, amount);
    }
}
