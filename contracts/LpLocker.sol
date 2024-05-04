// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./dependencies/TokenLockerBase.sol";

interface ICurveV2 {
    function add_liquidity(uint256[2] calldata _amounts, uint256 _min_mint_amount) external returns (uint256);

    function coins(uint256 arg0) external view returns (IERC20);

    function price_oracle() external view returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts) external view returns (uint256);
}

/**
    @title LP Locker
    @notice Lock LP tokens for boost. One day epoch, max 30 days lock.
 */
contract LPLocker is TokenLockerBase {
    IERC20 private immutable govToken;
    IERC20 private immutable stableCoin;

    constructor(
        address core,
        address lpToken,
        IERC20 _govToken,
        IERC20 _stableCoin,
        bool _penaltyWithdrawalsEnabled
    ) TokenLockerBase(core, IERC20(lpToken), 1 days, _penaltyWithdrawalsEnabled) {
        govToken = _govToken;
        stableCoin = _stableCoin;
        require(ICurveV2(lpToken).coins(0) == _govToken);
        require(ICurveV2(lpToken).coins(1) == _stableCoin);
        govToken.approve(lpToken, type(uint256).max);
        stableCoin.approve(lpToken, type(uint256).max);
    }

    function addLiquidityAndLock(
        address account,
        uint256 govTokenAmount,
        uint256 stableAmount,
        uint256 minReceived,
        uint256 lockEpochs
    ) external returns (uint256 lockAmount) {
        require(govTokenAmount >= getAddLiquidityMinStableAmount(govTokenAmount), "Insufficient stableAmount");

        govToken.transferFrom(msg.sender, address(this), govTokenAmount);
        stableCoin.transferFrom(msg.sender, address(this), stableAmount);

        lockAmount = ICurveV2(address(lockToken)).add_liquidity([govTokenAmount, stableAmount], minReceived);
        _lock(account, lockAmount, lockEpochs);

        return lockAmount;
    }

    /**
        @notice Get the minimum required `stableAmount` when adding liquidity to lock
        @dev Minimum amount blocks one-sided deposits using `TokenLocker.transferToLpLocker`
             that could negatively affect the price of `govToken`
        @param govTokenAmount Amount of `govToken` to add as liquidity
        @return minStableAmount Minimum `stableAmount` to use in the deposit
     */
    function getAddLiquidityMinStableAmount(uint256 govTokenAmount) public view returns (uint256 minStableAmount) {
        return (govTokenAmount * 10 ** 18) / ICurveV2(address(lockToken)).price_oracle();
    }

    /**
        @notice Estimate the amount of LP tokens received when adding liquidity
        @return expectedLpAmount Expected amount of LP tokens received
     */
    function getAddLiquidityReceived(
        uint256 govTokenAmount,
        uint256 stableAmount
    ) external view returns (uint256 expectedLpAmount) {
        return ICurveV2(address(lockToken)).calc_token_amount([govTokenAmount, stableAmount]);
    }
}
