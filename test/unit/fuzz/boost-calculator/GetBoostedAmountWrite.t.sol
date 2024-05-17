// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {BoostCalculator} from "../../../../contracts/BoostCalculator.sol";
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
contract Unit_Fuzz_BoostCalculator_GetBoostedAmountWrite_ is Unit_Shared_Test_ {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public DEFAULT_DECAY_PCT;
    uint256 public DEFAULT_MAX_BOOST_PCT;
    uint256 public DEFAULT_BOOST_MULTIPLIER;
    uint256 public constant TOTAL_SUPPLY = 1e28;
    uint256 public constant PRECISION_MULTIPLIER = 1e9;
    uint256 public constant DEFAULT_DURATION_TO_LOCK_LP = 30;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

        DEFAULT_DECAY_PCT = boostCalculator.decayBoostPct();
        DEFAULT_MAX_BOOST_PCT = boostCalculator.maxBoostablePct();
        DEFAULT_BOOST_MULTIPLIER = boostCalculator.maxBoostMultiplier();
    }

    /*//////////////////////////////////////////////////////////////
                               FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Fuzz_GetBoostedAmountWrite(
        uint256 amountToLock1,
        uint256 amountToLock2,
        uint256 amountToClaim,
        uint256 previousAmount,
        uint256 totalEpochEmissions
    ) public {
        // Before all, skip grace period
        skip(boostCalculator.MAX_BOOST_GRACE_EPOCHS() * 1 days);

        // --- Bounding --- //
        // Bound amount to lock, 1 because 0 is not allowed, total supply because cannot lock max than it.
        amountToLock1 = _bound(amountToLock1, 1, TOTAL_SUPPLY);
        // Bound amount to lock, 0 if amountTo lock 1 is total supply, total supply - amount to lock 1 otherwise.
        amountToLock2 = amountToLock1 == TOTAL_SUPPLY ? 0 : _bound(amountToLock2, 1, TOTAL_SUPPLY - amountToLock1);
        // Total epoch emissions should be between 0 and total supply.
        totalEpochEmissions = _bound(totalEpochEmissions, 0, TOTAL_SUPPLY);
        // Cannot claim more than total supply
        amountToClaim = _bound(amountToClaim, 0, TOTAL_SUPPLY);
        // Cannot be higher than total supply minus amount to be claimed now
        previousAmount = _bound(previousAmount, 0, TOTAL_SUPPLY - amountToClaim);

        // --- Locking --- //
        // Alice Locks
        _modifierLock({
            _lock: Modifier_Lock({
                skipBefore: 0,
                user: alice,
                amountToLock: amountToLock1,
                duration: DEFAULT_DURATION_TO_LOCK_LP,
                skipAfter: 0
            }),
            _token: IERC20(address(lpToken))
        });
        // Carole Locks
        if (amountToLock2 > 0) {
            _modifierLock({
                _lock: Modifier_Lock({
                    skipBefore: 0,
                    user: carole,
                    amountToLock: amountToLock2,
                    duration: DEFAULT_DURATION_TO_LOCK_LP,
                    skipAfter: 0
                }),
                _token: IERC20(address(lpToken))
            });
        }
        // After locks, skip one day, do use previous day for `getBoostedAmountWrite()`
        skip(1 days);

        // --- Useful Variables --- //
        uint256 total = amountToClaim + previousAmount;
        uint256 day = getDay() - 1;
        uint256 accountWeight = lpLocker.getAccountWeightAt(alice, day);
        uint256 totalWeight = lpLocker.getTotalWeightAt(day);
        totalWeight == 0 ? 1 : totalWeight;
        uint256 lockPct = PRECISION_MULTIPLIER * accountWeight / totalWeight;
        lockPct = lockPct == 0 ? 1 : lockPct;
        (uint256 maxBoostable, uint256 fullDecay) =
            getBoostable(totalEpochEmissions, lockPct, DEFAULT_MAX_BOOST_PCT, DEFAULT_DECAY_PCT);

        // --- Main Call --- //
        // Get boosted Amount for Alice
        uint256 adjustedAmount = boostCalculator.getBoostedAmountWrite({
            account: alice,
            amount: amountToClaim,
            previousAmount: previousAmount,
            totalEpochEmissions: totalEpochEmissions
        });

        // --- Assertions --- //
        if (lockPct == 1) {
            // Case 0: no boost
            assertEq(adjustedAmount, amountToClaim / DEFAULT_BOOST_MULTIPLIER, "lockPct == 1");
            return;
        }
        if (maxBoostable >= total) {
            // Case 1: entire claim receives max boost
            assertEq(adjustedAmount, amountToClaim, "maxBoostable < total");
            return;
        }
        if (fullDecay <= previousAmount) {
            // Case 2: entire claim receives no boost
            assertEq(adjustedAmount, amountToClaim / DEFAULT_BOOST_MULTIPLIER, "fullDecay > previousAmount");
            if (adjustedAmount != 0) assertLt(adjustedAmount, amountToClaim, "fullDecay > previousAmount (bis)");
            return;
        } else {
            uint256 adjustedAmount_;
            uint256 amount_ = amountToClaim;

            // Left part of the curve (left from maxBoostable)
            if (previousAmount < maxBoostable) {
                adjustedAmount_ = maxBoostable - previousAmount;
                amount_ -= adjustedAmount_;
                previousAmount = maxBoostable;
            }

            // Right part of the curve (right from fullDecay)
            if (total > fullDecay) {
                adjustedAmount_ += (total - fullDecay) / DEFAULT_BOOST_MULTIPLIER;
                amount_ -= (total - fullDecay);
                total = amount_ + previousAmount;
            }

            uint256 decay = fullDecay - maxBoostable;

            // Case 3: remaining claim is the entire decay amount
            if (amount_ == decay) {
                adjustedAmount_ += ((decay / DEFAULT_BOOST_MULTIPLIER) * (DEFAULT_BOOST_MULTIPLIER + 1)) / 2;

                assertEq(adjustedAmount, adjustedAmount_, "amount == decay");
                return;
            }

            // Case4: In the middle of the curve. (right from maxBoostable and left from fullDecay)
            if (adjustedAmount != 0) assertLt(adjustedAmount, amountToClaim, "amount != decay");
            else assertLe(adjustedAmount, amountToClaim, "amount != decay (bis)");
        }
    }
}
