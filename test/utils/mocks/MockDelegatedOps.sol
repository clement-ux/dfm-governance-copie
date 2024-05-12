// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {DelegatedOps} from "../../../contracts/dependencies/DelegatedOps.sol";

contract MockDelegatedOps is DelegatedOps {
    function testModifier_CallerOrDelegated(address _account) public view callerOrDelegated(_account) returns (bool) {
        return true;
    }
}
