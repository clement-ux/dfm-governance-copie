// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BoostCalculator} from "../../../../contracts/BoostCalculator.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";

contract Unit_Concrete_BoostCalculator_GetAccountBoostData_ is Unit_Shared_Test_ {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public DECAY_PCT;
    uint256 public MAX_BOOST_PCT;
    uint256 public DEFAULT_BOOST_MULTIPLIER;
    uint256 public constant DEFAULT_TOTAL_EMISSIONS = 100 ether;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

        DEFAULT_BOOST_MULTIPLIER = boostCalculator.maxBoostMultiplier();
        MAX_BOOST_PCT = boostCalculator.maxBoostablePct();
        DECAY_PCT = boostCalculator.decayBoostPct();
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test `getBoostedAmountWrite` when under the grace period
    function test_BoostCalculator_GetAccountBoostData_When_UnderGraceEpoch() public view {
        // Assertions before
        assertGe(boostCalculator.MAX_BOOST_GRACE_EPOCHS(), getDay()); // Ensure that we are under the grace period

        uint256 previousAmount = 123;
        // Main call
        (uint256 currentBoost, uint256 maxBoosted, uint256 boosted) =
            boostCalculator.getAccountBoostData(address(0), previousAmount, DEFAULT_TOTAL_EMISSIONS);

        // Assertions after
        assertEq(currentBoost, DEFAULT_BOOST_MULTIPLIER * 10000);
        assertEq(maxBoosted, DEFAULT_TOTAL_EMISSIONS - previousAmount);
        assertEq(boosted, DEFAULT_TOTAL_EMISSIONS - previousAmount);
    }

    /// @notice Test `getBoostedAmountWrite` when no positions on locker, but pending params.
    /// - Skip the grace period
    /// - Set pending params
    /// - Call `getAccountBoostData` with no positions on lp locker
    /// - Using 0 for pending params, to check that maxBoostedPct and decayPct are 0 too due to _getBoostable.
    function test_BoostCalculator_GetAccountBoostData_When_UpdatingParams()
        public
        setBoostParams(
            Modifier_SetBoostParams({
                skipBefore: (boostCalculator.MAX_BOOST_GRACE_EPOCHS()) * 1 days,
                maxBoostMul: 2,
                maxBoostPct: 0,
                decayPct: 0,
                skipAfter: 1 days
            })
        )
    {
        // Assertions before
        assertEq(boostCalculator.pendingMaxBoostMultiplier(), 2);
        assertEq(boostCalculator.pendingMaxBoostablePct(), 0);
        assertEq(boostCalculator.pendingDecayBoostPct(), 0);
        assertGt(boostCalculator.paramChangeEpoch(), 0);
        assertNotEq(boostCalculator.maxBoostMultiplier(), 2);
        assertNotEq(boostCalculator.maxBoostablePct(), 3);
        assertNotEq(boostCalculator.decayBoostPct(), 4);

        uint256 previousAmount = 123;
        // Main call
        (uint256 currentBoost, uint256 maxBoosted, uint256 boosted) =
            boostCalculator.getAccountBoostData(address(0), previousAmount, DEFAULT_TOTAL_EMISSIONS);

        // Assertions after
        assertEq(boostCalculator.pendingMaxBoostMultiplier(), 2);
        assertEq(boostCalculator.pendingMaxBoostablePct(), 0);
        assertEq(boostCalculator.pendingDecayBoostPct(), 0);
        assertGt(boostCalculator.paramChangeEpoch(), 0);
        assertNotEq(boostCalculator.maxBoostMultiplier(), 2);
        assertNotEq(boostCalculator.maxBoostablePct(), 3);
        assertNotEq(boostCalculator.decayBoostPct(), 4);

        assertEq(currentBoost, DEFAULT_BOOST_MULTIPLIER * 10000 / 2); // pendingMaxBoostMultiplier is used, so 10000 / 2 and not 10000 / 10
        assertEq(maxBoosted, 0);
        assertEq(boosted, 0);
    }

    /// @notice Test `getBoostedAmountWrite` when no positions on lp locker.
    /// - Skip grace period
    /// - Call `getBoostedAmountWrite` with no positions on lp locker
    /// - Amount claimed should be amount / DEFAULT_BOOST_MULTIPLIER because no boost, because no positions on lp locker
    function test_BoostCalculator_GetBoostedAmountWrite_When_NoPositionsOnLpLocker() public {
        // Skip grace period
        skip((boostCalculator.MAX_BOOST_GRACE_EPOCHS()) * 1 days);

        // Main call
        (uint256 currentBoost, uint256 maxBoosted, uint256 boosted) =
            boostCalculator.getAccountBoostData(address(0), 0, DEFAULT_TOTAL_EMISSIONS);

        uint256 maxBoosted_ = DEFAULT_TOTAL_EMISSIONS * 1 * MAX_BOOST_PCT / 1e11;
        uint256 boosted_ = maxBoosted_ + DEFAULT_TOTAL_EMISSIONS * 1 * DECAY_PCT / 1e11;
        // Assertions after
        assertEq(currentBoost, 10000);
        assertEq(maxBoosted, maxBoosted_);
        assertEq(boosted, boosted_);
    }
}
