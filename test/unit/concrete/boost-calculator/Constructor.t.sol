// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ILPLocker} from "../../../../contracts/interfaces/ILPLocker.sol";

import {BoostCalculator} from "../../../../contracts/BoostCalculator.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";

contract Unit_Concrete_BoostCalculator_Constructor_ is Unit_Shared_Test_ {
    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test constructor with valid parameters
    function test_BoostCalculator_Constructor() public asOwner {
        uint256 graceEpoch = 1;
        uint8 maxBoostMul = 2;
        uint16 maxBoostPct = 3;
        uint16 decayPct = 4;
        uint256 dayElsapsed = (block.timestamp - coreOwner.START_TIME()) / 1 days;

        // Expected events
        vm.expectEmit();
        emit BoostCalculator.BoostParamsSet(maxBoostMul, maxBoostPct, decayPct, dayElsapsed);

        // Main call
        boostCalculator = new BoostCalculator({
            _core: address(coreOwner),
            _locker: ILPLocker(address(lpLocker)),
            _graceEpochs: graceEpoch,
            _maxBoostMul: maxBoostMul,
            _maxBoostPct: maxBoostPct,
            _decayPct: decayPct
        });

        // Assertions after
        assertEq(address(boostCalculator.lpLocker()), address(lpLocker));
        assertEq(boostCalculator.MAX_BOOST_GRACE_EPOCHS(), graceEpoch + dayElsapsed);
        assertEq(boostCalculator.maxBoostMultiplier(), maxBoostMul);
        assertEq(boostCalculator.maxBoostablePct(), maxBoostPct);
        assertEq(boostCalculator.decayBoostPct(), decayPct);
    }
}
