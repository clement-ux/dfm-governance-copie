// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardCoreOwner} from "../../../utils/WizardCoreOwner.sol";

contract Unit_Concrete_CoreOwner_SetAddress_Test_ is Unit_Shared_Test_ {
    using WizardCoreOwner for Vm;

    /*//////////////////////////////////////////////////////////////
                             REVERTING TEST
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_SetAddress_Because_NotOwner() public {
        vm.prank(alice);
        vm.expectRevert("Only owner");
        coreOwner.setAddress(bytes32(uint256(10)), alice);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test to set a new address for a corresponding identifier, when id is unallocated.
    function test_SetAddress_WhenAddressIsNull() public asOwner {
        bytes32 identifier = bytes32(uint256(10));

        // Assertions before
        assertEq(vm.getAddressRegirstyBSL(address(coreOwner), identifier), address(0));

        // Main interaction
        coreOwner.setAddress(identifier, alice);

        // Assertions after
        assertEq(vm.getAddressRegirstyBSL(address(coreOwner), identifier), alice);
    }

    /// @notice Test to set a new address for a corresponding identifier, when id is already allocated.
    function test_SetAddress_WhenOverWritting() public asOwner {
        bytes32 identifier = bytes32("FEE_RECEIVER"); // Already used in the constructor

        // Assertions before
        assertEq(vm.getAddressRegirstyBSL(address(coreOwner), identifier), feeReceiver);

        // Main interaction
        coreOwner.setAddress(identifier, alice);

        // Assertions after
        assertNotEq(alice, feeReceiver);
        assertEq(vm.getAddressRegirstyBSL(address(coreOwner), identifier), alice);
    }
}
