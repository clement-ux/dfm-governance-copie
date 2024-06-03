// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {Vault} from "../../../../contracts/Vault.sol";
import {MockedCall} from "../../shared/MockedCall.sol";

contract Unit_Concrete_Vault_IncreaseUnallocatedSupply_ is Unit_Shared_Test_ {
    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test increase unallocated supply when unallocated supply is 0.
    function test_IncreaseUnallocatedSupply_WhenEmpty() public {
        deal(address(govToken), address(this), 1 ether);
        govToken.approve(address(vault), 1 ether);

        // Assertions before
        assertEq(govToken.balanceOf(address(vault)), 0);

        // Expected event
        vm.expectEmit({emitter: address(vault)});
        emit Vault.UnallocatedSupplyIncreased(1 ether, 1 ether);

        // Main call
        vault.increaseUnallocatedSupply(1 ether);

        // Assertions after
        assertEq(govToken.balanceOf(address(vault)), 1 ether);
    }

    /// @notice Test increase unallocated supply when unallocated supply is not 0.
    function test_IncreaseUnallocatedSupply_WhenNotEmpty() public increaseUnallocatedSupply(1 ether) {
        deal(address(govToken), address(this), 1 ether);
        govToken.approve(address(vault), 1 ether);

        // Assertions before
        assertEq(govToken.balanceOf(address(vault)), 1 ether);

        // Expected event
        vm.expectEmit({emitter: address(vault)});
        emit Vault.UnallocatedSupplyIncreased(1 ether, 2 ether);

        // Main call
        vault.increaseUnallocatedSupply(1 ether);

        // Assertions after
        assertEq(govToken.balanceOf(address(vault)), 2 ether);
    }
}
