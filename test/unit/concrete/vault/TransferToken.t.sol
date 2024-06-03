// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {Vault} from "../../../../contracts/Vault.sol";
import {MockedCall} from "../../shared/MockedCall.sol";

contract Unit_Concrete_Vault_TransferTokens_ is Unit_Shared_Test_ {
    /*//////////////////////////////////////////////////////////////
                            REVERTING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_TransferTokens_Because_SelfTransfer() public asOwner {
        deal(address(govToken), address(vault), 1);

        vm.expectRevert("Self transfer denied");
        vault.transferTokens(IERC20(address(govToken)), address(vault), 1);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test transfering tokens from the vault to a user as owner
    /// Tested with GovToken.
    function test_TransferTokens_GovToken() public increaseUnallocatedSupply(1 ether) asOwner {
        // Assertions before
        assertEq(govToken.balanceOf(alice), 0);
        assertEq(govToken.balanceOf(address(vault)), 1 ether);
        assertEq(vault.unallocatedTotal(), 1 ether);

        // Expected event
        vm.expectEmit({emitter: address(vault)});
        emit Vault.UnallocatedSupplyReduced(1, 1 ether - 1);
        
        // Main call
        vault.transferTokens(IERC20(address(govToken)), alice, 1);

        // Assertions after
        assertEq(govToken.balanceOf(alice), 1);
        assertEq(govToken.balanceOf(address(vault)), 1 ether - 1);
        assertEq(vault.unallocatedTotal(), 1 ether - 1);
    }

    /// @notice Test transfering tokens from the vault to a user as owner
    /// Tested with token different from GovToken.
    function test_TransferTokens_RandomToken() public asOwner {
        deal(address(lpToken), address(vault), 1 ether);

        // Assertions before
        assertEq(lpToken.balanceOf(alice), 0);

        // Main call
        vault.transferTokens(IERC20(address(lpToken)), alice, 1 ether);

        // Assertions after
        assertEq(lpToken.balanceOf(alice), 1 ether);
    }
}
