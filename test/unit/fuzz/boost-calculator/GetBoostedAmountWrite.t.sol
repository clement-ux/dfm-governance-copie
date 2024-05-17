// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {BoostCalculator} from "../../../../contracts/BoostCalculator.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardBoostCalculator} from "../../../utils/WizardBoostCalculator.sol";

/// @dev Even this section is focused on the Boost calculator test, `_getBoostable()` and `_getBoostedAmount()`
/// will be tested with fuzzing in a separeted file.
contract Unit_Concrete_BoostCalculator_GetBoostedAmountWrite_ is Unit_Shared_Test_ {
    using WizardBoostCalculator for Vm;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public DECAY_PCT;
    uint256 public MAX_BOOST_PCT;
    uint256 public DEFAULT_BOOST_MULTIPLIER;
    uint256 public constant PRECISION_MULTIPLIER = 1e9;
    uint256 public constant DEFAULT_AMOUNT_TO_LOCK = 1 ether;
    uint256 public constant DEFAULT_DURATION_TO_LOCK_LP = 30;
    uint256 public constant DEFAULT_TOTAL_EMISSIONS = 100 ether;
    uint256 public constant DEFAULT_WEIGHT = DEFAULT_AMOUNT_TO_LOCK * DEFAULT_DURATION_TO_LOCK_LP;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

        DEFAULT_BOOST_MULTIPLIER = boostCalculator.maxBoostMultiplier();
        MAX_BOOST_PCT = boostCalculator.maxBoostablePct();
        DECAY_PCT = boostCalculator.decayBoostPct();
    }

    uint256 totalSupply = 1e28;
    uint256 decayPct = 10000;
    uint256 maxBoostPct = 10000;

    function getBoostable(uint256 totalEpochEmissions, uint256 lockPct, uint256 maxBoostPct, uint256 decayPct)
        public
        pure
        returns (uint256, uint256)
    {
        uint256 maxBoostable = (totalEpochEmissions * lockPct * maxBoostPct) / 1e11;
        uint256 fullDecay = maxBoostable + (totalEpochEmissions * lockPct * decayPct) / 1e11;
        return (maxBoostable, fullDecay);
    }

    function getDay() public view returns (uint256) {
        return (block.timestamp - coreOwner.START_TIME()) / 1 days;
    }

    /*
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
    */

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
        amountToLock1 = _bound(amountToLock1, 1, totalSupply);
        // Bound amount to lock, 0 if amountTo lock 1 is total supply, total supply - amount to lock 1 otherwise.
        amountToLock2 = amountToLock1 == totalSupply ? 0 : _bound(amountToLock2, 1, totalSupply - amountToLock1);
        // Total epoch emissions should be between 0 and total supply.
        totalEpochEmissions = _bound(totalEpochEmissions, 0, totalSupply);
        // Cannot claim more than total supply
        amountToClaim = _bound(amountToClaim, 0, totalSupply);
        // Cannot be higher than total supply minus amount to be claimed now
        previousAmount = _bound(previousAmount, 0, totalSupply - amountToClaim);

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

        uint256 total = amountToClaim + previousAmount;
        uint256 day = getDay() - 1;
        uint256 accountWeight = lpLocker.getAccountWeightAt(alice, day);
        uint256 totalWeight = lpLocker.getTotalWeightAt(day);
        totalWeight == 0 ? 1 : totalWeight;
        uint256 lockPct = 1e9 * accountWeight / totalWeight;
        lockPct = lockPct == 0 ? 1 : lockPct;
        (uint256 maxBoostable, uint256 fullDecay) = getBoostable(totalEpochEmissions, lockPct, maxBoostPct, decayPct);

        console.log("lockPct: %d", lockPct);
        console.log("maxBoostable: %d", maxBoostable);
        console.log("fullDecay: %d", fullDecay);

        // Get boosted Amount for Alice
        uint256 adjustedAmount = boostCalculator.getBoostedAmountWrite({
            account: alice,
            amount: amountToClaim,
            previousAmount: previousAmount,
            totalEpochEmissions: totalEpochEmissions
        });

        // Assertions
        if (lockPct == 1) {
            assertEq(adjustedAmount, amountToClaim / DEFAULT_BOOST_MULTIPLIER, "lockPct == 1");
            return;
        }
        if (maxBoostable >= total) {
            // Case 1: entire claim receives max boost
            assertEq(adjustedAmount, amountToClaim, "maxBoostable < total");
        }
        /*
        */
    }

    event log_named_uint256(string name, uint256 value);
}
