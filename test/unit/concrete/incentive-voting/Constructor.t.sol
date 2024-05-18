// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ITokenLocker} from "../../../../contracts/interfaces/ITokenLocker.sol";

import {IncentiveVoting} from "../../../../contracts/IncentiveVoting.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";

contract Unit_Concrete_IncentiveVoting_Constructor_ is Unit_Shared_Test_ {
    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test constructor with valid parameters
    function test_IncentiveVoting_Constructor() public asOwner {
        incentiveVoting = new IncentiveVoting(address(coreOwner), ITokenLocker(address(tokenLocker)), address(vault));

        assertEq(address(incentiveVoting.tokenLocker()), address(tokenLocker));
        assertEq(address(incentiveVoting.vault()), address(vault));
    }
}
