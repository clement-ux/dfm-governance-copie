// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {CoreOwner} from "../../../../contracts/CoreOwner.sol";

import {Unit_Shared_Test_} from "../../shared/Shared.sol";

contract Unit_Concrete_CoreOwner_RevokeTransferOwnership_ is Unit_Shared_Test_ {
    /*//////////////////////////////////////////////////////////////
                             REVERTING TEST
    //////////////////////////////////////////////////////////////*/

    /// @notice Test to revert when trying to revoke an ownership transfer when not the owner.
    function test_RevertWhen_RevokeTransferOwnership_WhenNotOwner() public {
        vm.prank(alice);
        vm.expectRevert("Only owner");
        coreOwner.revokeTransferOwnership();
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test to revoke an ownership transfer when the caller is the owner.
    function test_RevokeTransferOwnership_WhenOwner() public commitTransferOwnership(alice) {
        // Assertions Before
        assertEq(coreOwner.pendingOwner(), alice);
        assertEq(coreOwner.ownershipTransferDeadline(), block.timestamp + coreOwner.OWNERSHIP_TRANSFER_DELAY());

        address currentOwner = coreOwner.owner();
        vm.prank(currentOwner);

        // Expected events
        vm.expectEmit({emitter: address(coreOwner)});
        emit CoreOwner.NewOwnerRevoked(currentOwner, alice);

        // Main call
        coreOwner.revokeTransferOwnership();

        // Assertions After
        assertEq(coreOwner.pendingOwner(), address(0));
        assertEq(coreOwner.ownershipTransferDeadline(), 0);
    }
}
