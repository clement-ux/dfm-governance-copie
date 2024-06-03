// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {Vault} from "../../../../contracts/Vault.sol";

contract Unit_Concrete_Vault_RegisterReceiver_ is Unit_Shared_Test_ {
    /*//////////////////////////////////////////////////////////////
                            REVERTING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_SetReceiverMaxEmissionPct_Because_InvalidPct() public asOwner {
        uint256 max = vault.MAX_PCT();
        vm.expectRevert("Invalid maxEmissionPct");
        vault.setReceiverMaxEmissionPct(0, max + 1);
    }

    function test_RevertWhen_SetReceiverMaxEmissionPct_Because_IdNotSet() public asOwner {
        vm.expectRevert("ID not set");
        vault.setReceiverMaxEmissionPct(0, 0);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test setting the max emission pct to 0
    function test_SetReceiverMaxEmission_ToNewValue()
        public
        addReceiverFromVault(
            Modifier_RegisterAccount({receiver: makeAddr("receiver"), count: 1, maxEmissionPct: [10_000, 0]})
        )
        asOwner
    {
        uint256 id = 1;
        uint256 newPct = 125;

        // Assertions before
        (address account, uint16 maxEmissionPct) = vault.idToReceiver(1);
        assertEq(account, makeAddr("receiver"));
        assertEq(maxEmissionPct, 10_000);

        // Expected events
        vm.expectEmit({emitter: address(vault)});
        emit Vault.ReceiverMaxEmissionPctSet(id, newPct);

        // Main call
        vault.setReceiverMaxEmissionPct(1, newPct);

        // Assertions after
        (account, maxEmissionPct) = vault.idToReceiver(1);
        assertEq(account, makeAddr("receiver"));
        assertEq(maxEmissionPct, newPct);
    }

    /// @notice Test setting the max emission pct to same value as before
    function test_SetReceiverMaxEmission_ToSameValue()
        public
        addReceiverFromVault(
            Modifier_RegisterAccount({receiver: makeAddr("receiver"), count: 1, maxEmissionPct: [10_000, 0]})
        )
        asOwner
    {
        uint256 id = 1;
        uint256 newPct = 10_000;

        // Assertions before
        (address account, uint16 maxEmissionPct) = vault.idToReceiver(1);
        assertEq(account, makeAddr("receiver"));
        assertEq(maxEmissionPct, 10_000);

        // Expected events
        vm.expectEmit({emitter: address(vault)});
        emit Vault.ReceiverMaxEmissionPctSet(id, newPct);

        // Main call
        vault.setReceiverMaxEmissionPct(1, newPct);

        // Assertions after
        (account, maxEmissionPct) = vault.idToReceiver(1);
        assertEq(account, makeAddr("receiver"));
        assertEq(maxEmissionPct, newPct);
    }

    /// @notice Test setting the max emission pct to 0
    function test_SetReceiverMaxEmission_ToZero()
        public
        addReceiverFromVault(
            Modifier_RegisterAccount({receiver: makeAddr("receiver"), count: 1, maxEmissionPct: [10_000, 0]})
        )
        asOwner
    {
        uint256 id = 1;
        uint256 newPct = 0;

        // Assertions before
        (address account, uint16 maxEmissionPct) = vault.idToReceiver(1);
        assertEq(account, makeAddr("receiver"));
        assertEq(maxEmissionPct, 10_000);

        // Expected events
        vm.expectEmit({emitter: address(vault)});
        emit Vault.ReceiverMaxEmissionPctSet(id, newPct);

        // Main call
        vault.setReceiverMaxEmissionPct(1, newPct);

        // Assertions after
        (account, maxEmissionPct) = vault.idToReceiver(1);
        assertEq(account, makeAddr("receiver"));
        assertEq(maxEmissionPct, newPct);
    }
}
