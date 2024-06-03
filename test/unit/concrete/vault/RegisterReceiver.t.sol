// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {Vault} from "../../../../contracts/Vault.sol";
import {MockedCall} from "../../shared/MockedCall.sol";

contract Unit_Concrete_Vault_SetReceiverMaxEmissionPct_ is Unit_Shared_Test_ {
    /*//////////////////////////////////////////////////////////////
                            REVERTING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_RegisterReceiver_Because_LengthMissmatch() public asOwner {
        vm.expectRevert("Invalid maxEmissionPct.length");
        vault.registerReceiver(address(0), 1, new uint256[](2));
    }

    function test_RevertWhen_RegisterReceiver_Because_InvalidMaxPct() public asOwner {
        uint256[] memory maxEmissionPct = new uint256[](1);
        maxEmissionPct[0] = vault.MAX_PCT() + 1;
        vm.expectRevert("Invalid maxEmissionPct");
        vault.registerReceiver(address(0), 1, maxEmissionPct);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test registering a single receiver with a max pct of 50%
    function test_RegisterReceiver_SingleReceiver_NotMaxPct() public asOwner {
        uint256 nextId = incentiveVoting.receiverCount() + 1;

        uint256[] memory maxEmissionPcts = new uint256[](1);
        maxEmissionPcts[0] = vault.MAX_PCT() / 2;
        address receiver = makeAddr("receiver");
        MockedCall.notifyRegisteredId(receiver);

        vm.expectEmit({emitter: address(vault)});
        emit Vault.NewReceiverRegistered(receiver, nextId);
        // Main call
        vault.registerReceiver(receiver, 1, maxEmissionPcts);

        (address account, uint16 maxEmissionPct) = vault.idToReceiver(nextId);
        // Assertions after
        assertEq(vault.receiverUpdatedEpoch(nextId), getWeek());
        assertEq(account, receiver);
        assertEq(maxEmissionPct, vault.MAX_PCT() / 2);
    }

    /// @notice Test registering a single receiver with a max pct of 0
    /// -> it should turn the 0 into the MAX_PCT
    function test_RegisterReceiver_SingleReceiver_WithMaxPct() public asOwner {
        uint256 nextId = incentiveVoting.receiverCount() + 1;

        uint256[] memory maxEmissionPcts = new uint256[](1);
        maxEmissionPcts[0] = 0;
        address receiver = makeAddr("receiver");
        MockedCall.notifyRegisteredId(receiver);

        vm.expectEmit({emitter: address(vault)});
        emit Vault.NewReceiverRegistered(receiver, nextId);
        // Main call
        vault.registerReceiver(receiver, 1, maxEmissionPcts);

        (address account, uint16 maxEmissionPct) = vault.idToReceiver(nextId);
        // Assertions after
        assertEq(vault.receiverUpdatedEpoch(nextId), getWeek());
        assertEq(account, receiver);
        assertEq(maxEmissionPct, vault.MAX_PCT());
    }

    /// @notice Test registering multiple receivers with different max pcts
    function test_RegisterReceiver_MultipleReceiver() public asOwner {
        uint256 nextId = incentiveVoting.receiverCount() + 1;

        uint256[] memory maxEmissionPcts = new uint256[](2);
        maxEmissionPcts[0] = vault.MAX_PCT() / 2;
        maxEmissionPcts[1] = vault.MAX_PCT() / 3;
        address receiver = makeAddr("receiver");
        MockedCall.notifyRegisteredId(receiver);

        vm.expectEmit({emitter: address(vault)});
        emit Vault.NewReceiverRegistered(receiver, nextId);
        vm.expectEmit({emitter: address(vault)});
        emit Vault.NewReceiverRegistered(receiver, nextId + 1);
        // Main call
        vault.registerReceiver(receiver, 2, maxEmissionPcts);

        (address account1, uint16 maxEmissionPct1) = vault.idToReceiver(nextId);
        (address account2, uint16 maxEmissionPct2) = vault.idToReceiver(nextId + 1);
        // Assertions after
        assertEq(vault.receiverUpdatedEpoch(nextId), getWeek());
        assertEq(vault.receiverUpdatedEpoch(nextId + 1), getWeek());
        assertEq(account1, receiver);
        assertEq(account2, receiver);
        assertEq(maxEmissionPct1, vault.MAX_PCT() / 2);
        assertEq(maxEmissionPct2, vault.MAX_PCT() / 3);
    }
}
