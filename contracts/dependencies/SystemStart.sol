// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "../interfaces/ICoreOwner.sol";

/**
    @title System Start Time
    @author Prisma Finance
    @dev Provides a unified `START_TIME` and `getEpoch`
 */
abstract contract SystemStart {
    uint256 immutable START_TIME;

    constructor(address core) {
        START_TIME = ICoreOwner(core).START_TIME();
    }

    function getWeek() internal view returns (uint256 epoch) {
        return (block.timestamp - START_TIME) / 1 weeks;
    }

    function getDay() internal view returns (uint256 day) {
        return (block.timestamp - START_TIME) / 1 days;
    }
}
