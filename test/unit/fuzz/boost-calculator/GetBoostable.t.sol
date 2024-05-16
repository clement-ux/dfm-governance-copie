// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {getBoostable} from "../../../utils/free-functions/BoostCalculator.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";

contract Unit_Fuzz_BoostCalculator_GetBoostable_ is Unit_Shared_Test_ {
    /// @notice Fuzz test for getBoostable function
    /// Ensure that FullDecay is always greater than or equal to MaxBoostable
    function test_Fuzz_BoostCalculator_getBoostable(
        uint256 totalEpochEmissions,
        uint256 lockPct,
        uint256 maxBoostPct,
        uint256 decayPct
    ) public pure {
        totalEpochEmissions = _bound(totalEpochEmissions, 0, 1e18);
        lockPct = _bound(lockPct, 0, 1e9);
        maxBoostPct = _bound(maxBoostPct, 0, 10000);
        decayPct = _bound(decayPct, 0, 10000);

        (uint256 maxBoostable, uint256 fullDecay) = getBoostable(totalEpochEmissions, lockPct, maxBoostPct, decayPct);

        assertGe(fullDecay, maxBoostable, "fullDecay <= maxBoostable");
    }

    /// @notice Avoid rounding division to zero
    /// Minimum incentives to distribute is 1e7 per epoch, if maxBoostPct is 10000 and decayPct is 10000
    function test_Fuzz_BoostCalculator_getBoostable_AvoidRoundedDivToZero(uint256 lockPct) public pure {
        uint256 totalEpochEmissions = 1e7;
        lockPct = _bound(lockPct, 2, 1e9);
        uint256 maxBoostPct = 10000;
        uint256 decayPct = 10000;
        (uint256 maxBoostable, uint256 fullDecay) = getBoostable(totalEpochEmissions, lockPct, maxBoostPct, decayPct);

        assertGt(fullDecay, 0, "fullDecay == 0");
        assertGt(maxBoostable, 0, "maxBoostable == 0");
    }
}
