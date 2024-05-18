// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";

import {ITokenLocker} from "../../../../contracts/interfaces/ITokenLocker.sol";
import {IncentiveVoting} from "../../../../contracts/IncentiveVoting.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardIncentiveVoting} from "../../../utils/WizardIncentiveVoting.sol";

contract Unit_Concrete_IncentiveVoting_RegisterNewReceiver_ is Unit_Shared_Test_ {
    using WizardIncentiveVoting for Vm;

    /*//////////////////////////////////////////////////////////////
                            REVERTING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_IncentiveVoting_RegisterNewReceiver_Because_NotVault() public {
        vm.expectRevert("Only Vault");
        incentiveVoting.registerNewReceiver();
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test Register New Receiver
    /// - Skip one period to be sure that the starting epoch is correctly set
    /// - Register a new receiver
    function test_IncentiveVoting_RegisterNewReceiver() public {
        skip(1 weeks);

        uint256 epoch = getWeek();
        // Assertion before
        assertEq(incentiveVoting.receiverCount(), 0);
        assertEq(vm.getReceiverUpdateEpochBySlotReading(address(incentiveVoting), 1), 0);

        // Main call
        vm.prank(incentiveVoting.vault());
        uint256 id = incentiveVoting.registerNewReceiver();

        // Assertion after
        assertEq(id, 1);
        assertEq(incentiveVoting.receiverCount(), 1);
        assertEq(vm.getReceiverUpdateEpochBySlotReading(address(incentiveVoting), 1), epoch);
    }
}
