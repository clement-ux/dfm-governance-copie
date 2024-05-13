// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {CoreOwnable} from "../../../contracts/dependencies/CoreOwnable.sol";

contract MockCoreOwnable is CoreOwnable {
    constructor(address _core) CoreOwnable(_core) {}

    function tModifier_OnlyOwner() public view onlyOwner returns (bool) {
        return true;
    }
}
