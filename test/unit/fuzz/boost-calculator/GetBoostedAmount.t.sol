// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {console} from "forge-std/console.sol";

import {getBoostable, getBoostedAmount} from "../../../utils/free-functions/BoostCalculator.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";

/**
 *  maxBoost
 *  Multiplier
 *      ^
 *      |            |               |
 *      |                           /-----------------
 *      |            |             / |
 *      |                         /
 *      |            |           /   |
 *      |                       /
 *      |            |         /     |
 *      |                     /
 *      |            |       /       |
 *      |                   /
 *      |            |     /         |
 *      |                 /
 *      |            |   /           |
 *      |               /
 *      |            | /             |
 *    1-|-------------/
 *      |            |               |
 *     -+----------------------------------------> total = amount + previousAmount
 *      |       maxBoostable       fullDecay
 *
 */
contract Unit_Fuzz_BoostCalculator_GetBoostedAmount_ is Unit_Shared_Test_ {
    uint256 totalSupply = 1e18;
    uint256 decayPct = 10000;
    uint256 maxBoostPct = 10000;

    function test_Fuzz_GetBoostedAmount(
        uint256 amount,
        uint256 previousAmount,
        uint256 lockPct,
        uint256 maxBoostMul,
        uint256 totalEpochEmissions
    ) public view {
        // Cannot claim more than total supply
        amount = _bound(amount, 0, totalSupply);

        // Cannot be higher than total supply minus amount to be claimed now
        previousAmount = _bound(previousAmount, 0, totalSupply - amount);

        // Lock percentage should be between 2 and 1e9, 0 doesn't happen, 1 return amount / maxBoostMul at beginning.
        lockPct = _bound(lockPct, 2, 1e9);

        // Max boost multiplier should be between 2 and 10.
        maxBoostMul = _bound(maxBoostMul, 2, 10);

        // Total epoch emissions should be between 0 and total supply.
        totalEpochEmissions = _bound(totalEpochEmissions, 0, totalSupply / 1);

        uint256 total = amount + previousAmount;

        // Get max boostable and full decay
        (uint256 maxBoostable, uint256 fullDecay) = getBoostable(totalEpochEmissions, lockPct, maxBoostPct, decayPct);

        // Main call
        uint256 adjustedAmount = getBoostedAmount(amount, previousAmount, lockPct, maxBoostMul, maxBoostable, fullDecay);

        if (maxBoostable >= total) {
            // Case 1: entire claim receives max boost
            assertEq(adjustedAmount, amount, "maxBoostable < total");
        } else if (fullDecay <= previousAmount) {
            // Case 2: entire claim receives no boost
            assertEq(adjustedAmount, amount / maxBoostMul, "fullDecay > previousAmount");
            if (adjustedAmount != 0) assertLt(adjustedAmount, amount, "fullDecay > previousAmount (bis)");
        } else {
            uint256 adjustedAmount_;
            uint256 amount_ = amount;

            // Left part of the curve (left from maxBoostable)
            if (previousAmount < maxBoostable) {
                adjustedAmount_ = maxBoostable - previousAmount;
                amount_ -= adjustedAmount_;
                previousAmount = maxBoostable;
            }

            // Right part of the curve (right from fullDecay)
            if (total > fullDecay) {
                adjustedAmount_ += (total - fullDecay) / maxBoostMul;
                amount_ -= (total - fullDecay);
                total = amount_ + previousAmount;
            }

            uint256 decay = fullDecay - maxBoostable;

            // Simplified calculation if remaining claim is the entire decay amount
            if (amount_ == decay) {
                adjustedAmount_ += ((decay / maxBoostMul) * (maxBoostMul + 1)) / 2;

                assertEq(adjustedAmount, adjustedAmount_, "amount == decay");
            }

            // In the middle of the curve. (right from maxBoostable and left from fullDecay)
            if (adjustedAmount != 0) assertLt(adjustedAmount, amount, "amount != decay");
            else assertLe(adjustedAmount, amount, "amount != decay (bis)");
        }
    }
}
