// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {SystemStart} from "../../../contracts/dependencies/SystemStart.sol";

contract MockSystemStart is SystemStart {
    constructor(address _core) SystemStart(_core) {}

    function getStartTime() public view returns (uint256) {
        return START_TIME;
    }

    function getWeek_() public view returns (uint256) {
        return getWeek();
    }

    function getDay_() public view returns (uint256) {
        return getDay();
    }
}
