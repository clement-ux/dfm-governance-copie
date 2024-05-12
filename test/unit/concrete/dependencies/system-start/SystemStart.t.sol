// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {MockSystemStart} from "../../../../utils/mocks/MockSystemStart.sol";
import {CoreOwner} from "../../../../../contracts/CoreOwner.sol";
import {Unit_Shared_Test_} from "../../../shared/Shared.sol";

contract Unit_Concrete_DelegatedOps_ is Unit_Shared_Test_ {
    MockSystemStart systemStart;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

        vm.warp(1714608000); // 2024-05-02T00:00:00+00:00 --  Thursday 2nd of May 2024 at 00:00:00 UTC
        coreOwner = new CoreOwner(multisig, feeReceiver, 0);
        systemStart = new MockSystemStart(address(coreOwner));
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_StartTime() public view {
        assertEq(systemStart.getStartTime(), coreOwner.START_TIME());
    }

    function test_GetWeek_When_NoStartOffset() public {
        assertEq(systemStart.getWeek_(), 0);
        skip(1 days);
        assertEq(systemStart.getWeek_(), 0);
        skip(1 days);
        assertEq(systemStart.getWeek_(), 0);
        skip(5 days);
        assertEq(systemStart.getWeek_(), 1);
        skip(1 weeks);
        assertEq(systemStart.getWeek_(), 2);
    }

    function test_GetWeek_When_WithStartOffset() public {
        // Redeploy with a 3 day start offset
        coreOwner = new CoreOwner(multisig, feeReceiver, 3 days);
        systemStart = new MockSystemStart(address(coreOwner));

        assertEq(systemStart.getWeek_(), 0);
        skip(1 days);
        assertEq(systemStart.getWeek_(), 0);
        skip(1 days);
        assertEq(systemStart.getWeek_(), 0);
        skip(5 days);
        assertEq(systemStart.getWeek_(), 1);
        skip(1 weeks);
        assertEq(systemStart.getWeek_(), 2);
    }

    function test_GetDay_When_NoStartOffset() public {
        assertEq(systemStart.getDay_(), 0);
        skip(1 seconds);
        assertEq(systemStart.getDay_(), 0);
        skip(1 hours);
        assertEq(systemStart.getDay_(), 0);

        vm.warp(1714608000); // 2024-05-02T00:00:00+00:00 --  Thursday 2nd of May 2024 at 00:00:00 UTC
        skip(1 days);
        assertEq(systemStart.getDay_(), 1);
        skip(1 days);
        assertEq(systemStart.getDay_(), 2);
        skip(5 days);
        assertEq(systemStart.getDay_(), 7);
        skip(1 weeks);
        assertEq(systemStart.getDay_(), 14);
    }

    function test_GetDay_When_WithStartOffset() public {
        // Redeploy with a 3 day start offset
        uint256 offset = 302401; // 3 days, 12 hours, 1 second
        coreOwner = new CoreOwner(multisig, feeReceiver, offset);
        systemStart = new MockSystemStart(address(coreOwner));

        assertEq(systemStart.getDay_(), 3);
        skip(1 seconds);
        assertEq(systemStart.getDay_(), 3);
        skip(1 hours);
        assertEq(systemStart.getDay_(), 3);

        vm.warp(1714608000); // 2024-05-02T00:00:00+00:00 --  Thursday 2nd of May 2024 at 00:00:00 UTC
        skip(1 days);
        assertEq(systemStart.getDay_(), 4);
        skip(1 days);
        assertEq(systemStart.getDay_(), 5);
        skip(5 days);
        assertEq(systemStart.getDay_(), 10);
        skip(1 weeks);
        assertEq(systemStart.getDay_(), 17);
    }
}
