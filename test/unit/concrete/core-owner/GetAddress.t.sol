// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardCoreOwner} from "../../../utils/WizardCoreOwner.sol";

contract Unit_Concrete_CoreOwner_GetAddress_Test_ is Unit_Shared_Test_ {
    using WizardCoreOwner for Vm;

    /*//////////////////////////////////////////////////////////////
                             REVERTING TEST
    //////////////////////////////////////////////////////////////*/

    /// @notice Test to revert when trying to get an address for an identifier that is not allocated.
    function test_RevertWhen_GetAddress_Because_NoAddressForIdentifier() public {
        vm.expectRevert("No address for identifier");
        coreOwner.getAddress(bytes32(uint256(10)));
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test to get an address for a corresponding identifier.
    function test_GetAddress() public view {
        assertEq(coreOwner.getAddress(bytes32("FEE_RECEIVER")), feeReceiver);
    }
}
