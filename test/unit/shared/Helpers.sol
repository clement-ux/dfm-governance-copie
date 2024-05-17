// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Base_Test_} from "../../Base.sol";

contract Helpers is Base_Test_ {
    /*//////////////////////////////////////////////////////////////
                              SYSTEM START
    //////////////////////////////////////////////////////////////*/

    function getDay() public view returns (uint256) {
        uint256 startTime = coreOwner.START_TIME();
        require(startTime != 0, "START_TIME not set");
        return (block.timestamp - startTime) / 1 days;
    }

    /*//////////////////////////////////////////////////////////////
                            BOOST CALCULATOR
    //////////////////////////////////////////////////////////////*/

    function getBoostable(uint256 totalEpochEmissions, uint256 lockPct, uint256 maxBoostPct, uint256 decayPct)
        public
        pure
        returns (uint256, uint256)
    {
        uint256 maxBoostable = (totalEpochEmissions * lockPct * maxBoostPct) / 1e11;
        uint256 fullDecay = maxBoostable + (totalEpochEmissions * lockPct * decayPct) / 1e11;
        return (maxBoostable, fullDecay);
    }
}
