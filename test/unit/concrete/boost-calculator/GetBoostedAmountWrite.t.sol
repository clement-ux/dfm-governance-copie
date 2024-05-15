// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";

import {BoostCalculator} from "../../../../contracts/BoostCalculator.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardBoostCalculator} from "../../../utils/WizardBoostCalculator.sol";

/// @dev Even this section is focused on the Boost calculator test, `_getBoostable()` and `_getBoostedAmount()`
/// will be tested with fuzzing in a separeted file.
contract Unit_Concrete_BoostCalculator_GetBoostedAmountWrite_ is Unit_Shared_Test_ {
    using WizardBoostCalculator for Vm;

    uint256 public constant DEFAULT_AMOUNT_TO_LOCK = 1 ether;
    uint256 public constant DEFAULT_DURATION_TO_LOCK_LP = 30;
    uint256 public constant DEFAULT_TOTAL_EMISSIONS = 100 ether;
    uint256 public constant PRECISION_MULTIPLIER = 1e9;
    uint256 public MAX_BOOST_PCT;
    uint256 public DECAY_PCT;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

        MAX_BOOST_PCT = boostCalculator.maxBoostablePct();
        DECAY_PCT = boostCalculator.decayBoostPct();
    }

    /*//////////////////////////////////////////////////////////////
                    HELPERS (need to be moved elsewhere)
    //////////////////////////////////////////////////////////////*/

    function getDay() public view returns (uint256) {
        return (block.timestamp - coreOwner.START_TIME()) / 1 days;
    }

    function getBoostable(uint256 totalEpochEmissions, uint256 lockPct, uint256 maxBoostPct, uint256 decayPct)
        public
        pure
        returns (uint256, uint256)
    {
        uint256 maxBoostable = (totalEpochEmissions * lockPct * maxBoostPct) / 1e11;
        uint256 fullDecay = maxBoostable + (totalEpochEmissions * lockPct * decayPct) / 1e11;
        return (maxBoostable, fullDecay);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test `getBoostedAmountWrite` when under the grace period
    function test_BoostCalculator_GetBoostedAmountWrite_When_UnderGraceEpoch() public {
        // Assertions before
        assertGe(boostCalculator.MAX_BOOST_GRACE_EPOCHS(), getDay()); // Ensure that we are under the grace period

        // Main call
        uint256 boostedAmount = boostCalculator.getBoostedAmountWrite(address(0), 100 ether, 0, 0);

        // Assertions after
        assertEq(boostedAmount, 100 ether);
    }

    /// @notice Test `getBoostedAmountWrite` when no positions on locker, but pending params.
    /// - Skip the grace period
    /// - Set pending params
    /// - Call `getBoostedAmountWrite` with no positions on lp locker
    function test_BoostCalculator_GetBoostedAmountWrite_When_UpdatingParams()
        public
        setBoostParams(
            Modifier_SetBoostParams({
                skipBefore: (boostCalculator.MAX_BOOST_GRACE_EPOCHS()) * 1 days,
                maxBoostMul: 2,
                maxBoostPct: 3,
                decayPct: 4,
                skipAfter: 1 days
            })
        )
    {
        // Assertions before
        assertEq(boostCalculator.pendingMaxBoostMultiplier(), 2);
        assertEq(boostCalculator.pendingMaxBoostablePct(), 3);
        assertEq(boostCalculator.pendingDecayBoostPct(), 4);
        assertGt(boostCalculator.paramChangeEpoch(), 0);
        assertNotEq(boostCalculator.maxBoostMultiplier(), 2);
        assertNotEq(boostCalculator.maxBoostablePct(), 3);
        assertNotEq(boostCalculator.decayBoostPct(), 4);

        // Main call
        boostCalculator.getBoostedAmountWrite({
            account: address(0),
            amount: 0,
            previousAmount: 0,
            totalEpochEmissions: 0
        });

        // Assertions after
        assertEq(boostCalculator.pendingMaxBoostMultiplier(), 0);
        assertEq(boostCalculator.pendingMaxBoostablePct(), 0);
        assertEq(boostCalculator.pendingDecayBoostPct(), 0);
        assertEq(boostCalculator.paramChangeEpoch(), 0);
        assertEq(boostCalculator.maxBoostMultiplier(), 2);
        assertEq(boostCalculator.maxBoostablePct(), 3);
        assertEq(boostCalculator.decayBoostPct(), 4);

        assertEq(vm.getTotalEpochWeightBySlotReading(address(boostCalculator), getDay() - 1), 1);
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(boostCalculator), address(0), getDay() - 1), 1);
    }

    /// @notice Test `getBoostedAmountWrite` with a single position on the lp locker
    /// - Skip grace period
    /// - Lock LP to create a position
    /// - Skip 1 days
    /// - Claim less than maximum boostable, so amount claim == amount claimed
    function test_BoostCalculator_GetBoostedAmountWrite_When_SinglePositionsOnLpLocker()
        public
        lockLP(
            Modifier_Lock({
                skipBefore: (boostCalculator.MAX_BOOST_GRACE_EPOCHS()) * 1 days,
                user: address(this),
                amountToLock: DEFAULT_AMOUNT_TO_LOCK,
                duration: DEFAULT_DURATION_TO_LOCK_LP,
                skipAfter: 1 days
            })
        )
    {
        // Useful variables
        uint256 day = getDay();
        uint256 totalWeightLock = lpLocker.getTotalWeightAt(day - 1);
        uint256 lockPct = 1e9 * lpLocker.getAccountWeightAt(address(this), day - 1) / totalWeightLock;
        uint256 amountToClaim = 1e20;
        uint256 previousClaim = 0;
        uint256 total = amountToClaim + previousClaim;
        (uint256 maxBoostable,) = getBoostable(DEFAULT_TOTAL_EMISSIONS, lockPct, MAX_BOOST_PCT, DECAY_PCT);

        // Assertions before
        assertEq(totalWeightLock, DEFAULT_AMOUNT_TO_LOCK * DEFAULT_DURATION_TO_LOCK_LP);
        assertEq(lockPct, PRECISION_MULTIPLIER);
        assertGt(maxBoostable, total); // entire claim should receives max boost

        // --- Main call --- //
        uint256 amount = boostCalculator.getBoostedAmountWrite({
            account: address(this),
            amount: amountToClaim,
            previousAmount: previousClaim,
            totalEpochEmissions: DEFAULT_TOTAL_EMISSIONS
        });

        // Assertions after
        assertEq(vm.getTotalEpochWeightBySlotReading(address(boostCalculator), getDay() - 1), totalWeightLock);
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(boostCalculator), address(this), getDay() - 1), lockPct);
        assertEq(amount, amountToClaim);
    }

    // Need to do test for
    // - No positions on lp locker, but user claim something
    // - Multiple positions on lp locker, user claim after someone else (check global variable are stored correctly).
    // - and moore, stay tunned!
}
