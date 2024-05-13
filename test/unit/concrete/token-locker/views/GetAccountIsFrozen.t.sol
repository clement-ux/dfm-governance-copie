// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Unit_Shared_Test_} from "../../../shared/Shared.sol";

contract Unit_Concrete_TokenLocker_GetAccountIsFrozen_ is Unit_Shared_Test_ {
    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetAccountIsFrozen_WhenTrue()
        public
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
    {
        assertTrue(tokenLocker.getAccountIsFrozen(address(this)));
    }

    function test_GetAccountIsFrozen_WhenFalse() public view {
        assertFalse(tokenLocker.getAccountIsFrozen(address(this)));
    }
}
