// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/ITokenLocker.sol";

interface ILPLocker is ITokenLocker {
    function addLiquidityAndLock(
        address account,
        uint256 govTokenAmount,
        uint256 stableCoinAmount,
        uint256 minReceived,
        uint256 lockEpochs
    ) external returns (uint256 lockAmount);
}
