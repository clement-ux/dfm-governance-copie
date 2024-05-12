// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {CoreOwner} from "../../../../contracts/CoreOwner.sol";

import {Unit_Shared_Test_} from "../../shared/Shared.sol";

contract Unit_Concrete_CoreOwner_AcceptTransferOwnership_ is Unit_Shared_Test_ {
    /*//////////////////////////////////////////////////////////////
                             REVERTING TEST
    //////////////////////////////////////////////////////////////*/

    /// @notice Test to revert when trying to accept an ownership transfer when not the new owner.
    function test_RevertWhen_AcceptTransferOwnership_Because_Owner() public asOwner {
        vm.expectRevert("Only new owner");
        coreOwner.acceptTransferOwnership();
    }

    /// @notice Test to revert when trying to accept an ownership transfer when deadline not passed.
    function test_RevertWhen_AcceptTransferOwnership_Because_DeadlineNotPassed()
        public
        commitTransferOwnership(alice)
    {
        vm.prank(alice);
        vm.expectRevert("Deadline not passed");
        coreOwner.acceptTransferOwnership();
    }

    /// @notice Test to revert when trying to accept an ownership transfer when deadline just not passed.
    function test_RevertWhen_AcceptTransferOwnership_Because_DeadlineJustNotPassed()
        public
        commitTransferOwnership(alice)
    {
        skip(coreOwner.OWNERSHIP_TRANSFER_DELAY() - 1);

        vm.prank(alice);
        vm.expectRevert("Deadline not passed");
        coreOwner.acceptTransferOwnership();
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test to accept an ownership transfer when the deadline has just passed.
    function test_AcceptTransferOwnership_When_DeadlineExactlyPassed() public commitTransferOwnership(alice) {
        skip(coreOwner.OWNERSHIP_TRANSFER_DELAY());

        // Assertions Before
        address previousOwner = coreOwner.owner();
        assertNotEq(previousOwner, alice);
        assertEq(coreOwner.pendingOwner(), alice);
        assertLe(coreOwner.ownershipTransferDeadline(), block.timestamp);

        vm.prank(alice);

        // Expected events
        vm.expectEmit({emitter: address(coreOwner)});
        emit CoreOwner.NewOwnerAccepted(previousOwner, alice);

        // Main call
        coreOwner.acceptTransferOwnership();

        // Assertions After
        assertEq(coreOwner.owner(), alice);
        assertEq(coreOwner.pendingOwner(), address(0));
        assertEq(coreOwner.ownershipTransferDeadline(), 0);
    }

    /// @notice Test to accept an ownership transfer when the deadline has passed.
    function test_AcceptTransferOwnership_When_DeadlineWayPassed() public commitTransferOwnership(alice) {
        skip(coreOwner.OWNERSHIP_TRANSFER_DELAY() * 2);

        // Assertions Before
        address previousOwner = coreOwner.owner();
        assertNotEq(previousOwner, alice);
        assertEq(coreOwner.pendingOwner(), alice);
        assertLt(coreOwner.ownershipTransferDeadline(), block.timestamp);

        vm.prank(alice);

        // Expected events
        vm.expectEmit({emitter: address(coreOwner)});
        emit CoreOwner.NewOwnerAccepted(previousOwner, alice);

        // Main call
        coreOwner.acceptTransferOwnership();

        // Assertions After
        assertEq(coreOwner.owner(), alice);
        assertEq(coreOwner.pendingOwner(), address(0));
        assertEq(coreOwner.ownershipTransferDeadline(), 0);
    }
    /*
    */
}
