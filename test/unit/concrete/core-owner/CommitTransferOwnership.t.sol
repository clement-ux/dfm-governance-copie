// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {CoreOwner} from "../../../../contracts/CoreOwner.sol";

contract Unit_Concrete_CoreOwner_CommitTransferOwnership_ is Unit_Shared_Test_ {
    /*//////////////////////////////////////////////////////////////
                             REVERTING TEST
    //////////////////////////////////////////////////////////////*/

    /// @notice Test to revert when trying to commit an ownership transfer when not the owner.
    function test_RevertWhen_CommitTransferOwnership_WhenNotOwner() public {
        vm.prank(alice);
        vm.expectRevert("Only owner");
        coreOwner.commitTransferOwnership(address(0x1));
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test to commit an ownership transfer when the caller is the owner.
    function test_CommitTransferOwnership_WhenOwner() public asOwner {
        address newOwner = makeAddr("newOwner");

        // Assertions Before
        assertEq(coreOwner.pendingOwner(), address(0));
        assertEq(coreOwner.ownershipTransferDeadline(), 0);

        address currentOwner = coreOwner.owner();
        uint256 transferDelay = coreOwner.OWNERSHIP_TRANSFER_DELAY();
        vm.expectEmit({emitter: address(coreOwner)});
        emit CoreOwner.NewOwnerCommitted(currentOwner, newOwner, block.timestamp + transferDelay);

        // Main call
        coreOwner.commitTransferOwnership(newOwner);

        // Assertions After
        assertEq(coreOwner.pendingOwner(), newOwner);
        assertEq(coreOwner.ownershipTransferDeadline(), block.timestamp + transferDelay);
    }
}
