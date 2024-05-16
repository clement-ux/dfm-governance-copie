// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// @notice Copy pasted implementation of _getBoostable function from BoostCalculator contract
function getBoostable(uint256 totalEpochEmissions, uint256 lockPct, uint256 maxBoostPct, uint256 decayPct)
    pure
    returns (uint256, uint256)
{
    uint256 maxBoostable = (totalEpochEmissions * lockPct * maxBoostPct) / 1e11;
    uint256 fullDecay = maxBoostable + (totalEpochEmissions * lockPct * decayPct) / 1e11;
    return (maxBoostable, fullDecay);
}

/// @notice Copy pasted implementation of _getBoostedAmount function from BoostCalculator contract
function getBoostedAmount(
    uint256 amount,
    uint256 previousAmount,
    uint256 lockPct,
    uint256 maxBoostMul,
    uint256 maxBoostable,
    uint256 fullDecay
) pure returns (uint256 adjustedAmount) {
    // we use 1 to indicate no lock weight: no boost
    if (lockPct == 1) return amount / maxBoostMul;

    uint256 total = amount + previousAmount;

    // entire claim receives max boost
    if (maxBoostable >= total) return amount;

    // entire claim receives no boost
    if (fullDecay <= previousAmount) return amount / maxBoostMul;

    // apply max boost for partial claim
    if (previousAmount < maxBoostable) {
        adjustedAmount = maxBoostable - previousAmount;
        amount -= adjustedAmount;
        previousAmount = maxBoostable;
    }

    // apply no boost for partial claim
    if (total > fullDecay) {
        adjustedAmount += (total - fullDecay) / maxBoostMul;
        amount -= (total - fullDecay);
        total = amount + previousAmount;
    }

    // simplified calculation if remaining claim is the entire decay amount
    uint256 decay = fullDecay - maxBoostable;
    if (amount == decay) return adjustedAmount + ((decay / maxBoostMul) * (maxBoostMul + 1)) / 2;

    /**
     * calculate adjusted amount when the claim spans only part of the decay. we can
     *             visualize the decay calculation as a right angle triangle:
     *
     * the X axis runs from 0 to `(fullDecay - maxBoostable) / MAX_BOOST_MULTIPLIER`
     * the Y axis runs from 1 to `MAX_BOOST_MULTIPLER`
     *
     *             we slice the triangle at two points along the x axis, based on the previously claimed
     *             amount and the new amount to claim. we then divide this new shape into another right
     *             angle triangle and a rectangle, calculate and sum the areas. the sum is the final
     *             adjusted amount.
     */

    // x axis calculations (+1e9 precision multiplier)
    // length of the original triangle
    uint256 unboostedTotal = (decay * 1e9) / maxBoostMul;
    // point for first slice
    uint256 claimStart = ((previousAmount - maxBoostable) * 1e9) / maxBoostMul;
    // point for second slice
    uint256 claimEnd = ((total - maxBoostable) * 1e9) / maxBoostMul;
    // length of the slice
    uint256 claimDelta = claimEnd - claimStart;

    // y axis calculations (+1e9 precision multiplier)
    uint256 ymul = 1e9 * (maxBoostMul - 1);
    // boost at the first slice
    uint256 boostStart = (ymul * (unboostedTotal - claimStart)) / unboostedTotal + 1e9;
    // boost at the 2nd slice
    uint256 boostEnd = (ymul * (unboostedTotal - claimEnd)) / unboostedTotal + 1e9;

    // area calculations
    // area of the new right angle triangle within our slice of the old triangle
    uint256 decayAmount = (claimDelta * (boostStart - boostEnd)) / 2;
    // area of the rectangular section within our slice of the old triangle
    uint256 fullAmount = claimDelta * boostEnd;

    // sum areas and remove precision multipliers
    adjustedAmount += (decayAmount + fullAmount) / 1e18;

    return adjustedAmount;
}
