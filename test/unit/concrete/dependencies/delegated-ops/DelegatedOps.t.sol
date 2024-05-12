// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {MockDelegatedOps, DelegatedOps} from "../../../../utils/mocks/MockDelegatedOps.sol";
import {Unit_Shared_Test_} from "../../../shared/Shared.sol";

contract Unit_Concrete_DelegatedOps_ is Unit_Shared_Test_ {
    MockDelegatedOps delegatedOps;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

        delegatedOps = new MockDelegatedOps();
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SetDelegateApproval_Approve() public {
        // Assertion before
        assertEq(delegatedOps.isApprovedDelegate(address(this), alice), false);

        // Expected event
        vm.expectEmit({emitter: address(delegatedOps)});
        emit DelegatedOps.DelegateApprovalSet(address(this), alice, true);

        // Action
        delegatedOps.setDelegateApproval(alice, true);

        // Assertion after
        assertEq(delegatedOps.isApprovedDelegate(address(this), alice), true);
    }

    function test_SetDelegateApproval_Revoke() public {
        test_SetDelegateApproval_Approve();

        // Assertion before
        assertEq(delegatedOps.isApprovedDelegate(address(this), alice), true);

        // Expected event
        vm.expectEmit({emitter: address(delegatedOps)});
        emit DelegatedOps.DelegateApprovalSet(address(this), alice, false);

        // Action
        delegatedOps.setDelegateApproval(alice, false);

        // Assertion after
        assertEq(delegatedOps.isApprovedDelegate(address(this), alice), false);
    }

    function testModifier_CallerOrDelegated_WhenDelegated() public {
        // Delegate ops to alice
        delegatedOps.setDelegateApproval(alice, true);

        vm.prank(alice);
        assertTrue(delegatedOps.testModifier_CallerOrDelegated(address(this)));
    }

    function testModifier_CallerOrDelegated_WhenCallerIsMsgSender() public view {
        // Delegate ops to alice
        assertTrue(delegatedOps.testModifier_CallerOrDelegated(address(this)));
    }

    /*//////////////////////////////////////////////////////////////
                             REVERTING TEST
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_CallerOrDelegated_WhenNotDelegated() public {
        vm.expectRevert("Delegate not approved");
        vm.prank(alice);
        delegatedOps.testModifier_CallerOrDelegated(address(this));
    }
}
