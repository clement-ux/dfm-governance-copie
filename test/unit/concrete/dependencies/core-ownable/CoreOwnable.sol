// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {MockCoreOwnable} from "../../../../utils/mocks/MockCoreOwnable.sol";
import {Unit_Shared_Test_} from "../../../shared/Shared.sol";

contract Unit_Concrete_CoreOwnable_ is Unit_Shared_Test_ {
    MockCoreOwnable coreOwnable;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

        coreOwnable = new MockCoreOwnable(address(coreOwner));
    }

    /*//////////////////////////////////////////////////////////////
                             REVERTING TEST
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_OnlyOwner_Because_NotOwner() public {
        vm.expectRevert("Only owner");
        coreOwnable.testModifier_OnlyOwner();
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Constructor_CoreOwnable() public view {
        assertEq(address(coreOwnable.CORE_OWNER()), address(coreOwner));
    }

    function test_Owner() public view {
        assertEq(coreOwnable.owner(), address(coreOwner.owner()));
    }

    function test_onlyOwner() public asOwner {
        assertTrue(coreOwnable.testModifier_OnlyOwner());
    }
}
