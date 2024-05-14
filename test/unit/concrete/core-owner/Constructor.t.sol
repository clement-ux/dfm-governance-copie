// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {CoreOwner} from "../../../../contracts/CoreOwner.sol";

import {Unit_Shared_Test_} from "../../shared/Shared.sol";

contract Unit_Concrete_CoreOwner_SetAddress_Test_ is Unit_Shared_Test_ {
    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();
        vm.warp(1714953600); // 2024-05-06T00:00:11+00:00 -- Monday 6th of May 2024 at 00:00:00 UTC
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test contract deployment with the correct owner, correct fee receiver no start offset.
    function test_Constructor_When_StartOffset_IsZero() public {
        // Main interaction
        coreOwner = new CoreOwner(multisig, feeReceiver, 0);

        // Assertions
        assertEq(coreOwner.owner(), multisig);
        assertEq(coreOwner.getAddress(bytes32("FEE_RECEIVER")), feeReceiver);
        assertEq(coreOwner.START_TIME(), block.timestamp / 7 days * 7 days);
    }

    /// @notice Test contract deployment with the correct owner, correct fee receiver and a start offset of 2 days.
    function test_Constructor_When_StartOffset_IsLowerThan_DaysElapsedFromRoundedTimestamp() public {
        // Main interaction
        coreOwner = new CoreOwner(multisig, feeReceiver, 2 days);

        // Assertions
        assertEq(coreOwner.owner(), multisig);
        assertEq(coreOwner.getAddress(bytes32("FEE_RECEIVER")), feeReceiver);
        assertEq(coreOwner.START_TIME(), (block.timestamp / 7 days) * 7 days - 2 days);
    }

    /// @notice Test contract deployment with the correct owner, correct fee receiver and a start offset of 5 days.
    /// 5 days start offset will be rolled over to 2 days after last rounded timestamp.
    function test_Constructor_When_StartOffset_IsGreaterThan_DaysElapsedFromRoundedTimestamp() public {
        // Main interaction
        coreOwner = new CoreOwner(multisig, feeReceiver, 5 days);

        // Assertions
        assertEq(coreOwner.owner(), multisig);
        assertEq(coreOwner.getAddress(bytes32("FEE_RECEIVER")), feeReceiver);
        assertEq(coreOwner.START_TIME(), block.timestamp / 7 days * 7 days + 2 days); // 5 days - 7 days -> + 2 days
    }
}
