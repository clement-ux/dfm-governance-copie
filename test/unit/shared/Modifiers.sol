// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Helpers} from "./Helpers.sol";
import {IncentiveVoting} from "../../../contracts/IncentiveVoting.sol";
import {TokenLockerBase} from "../../../contracts/dependencies/TokenLockerBase.sol";

import {MockLpToken} from "../../utils/mocks/MockLpToken.sol";
import {MockStableCoin} from "../../utils/mocks/MockStableCoin.sol";

contract Modifiers is Helpers {
    MockLpToken public lpToken;
    MockStableCoin public stableCoin;

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    // --- Token Locker ---

    struct Modifier_Lock {
        uint256 skipBefore;
        address user;
        uint256 amountToLock;
        uint256 duration;
        uint256 skipAfter;
    }

    struct Modifier_LockMany {
        uint256 skipBefore;
        address user;
        uint64[5] amountToLock;
        uint8[5] duration;
        uint256 skipAfter;
    }

    struct Modifier_Freeze {
        uint256 skipBefore;
        address user;
        uint256 skipAfter;
    }

    // --- Boost Calculator ---
    struct Modifier_SetBoostParams {
        uint256 skipBefore;
        uint8 maxBoostMul;
        uint16 maxBoostPct;
        uint16 decayPct;
        uint256 skipAfter;
    }

    struct Modifier_GetBoostedAmountWrite {
        uint256 skipBefore;
        address account;
        uint256 amount;
        uint256 previousAmount;
        uint256 totalEpochEmissions;
        uint256 skipAfter;
    }

    // --- Incentive Voting ---
    struct Modifier_RegisterAccountWeightAndVote {
        uint256 skipBefore;
        address account;
        uint256 minEpochs;
        uint256[2][5] votes;
        uint256 skipAfter;
    }

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    // --- General ---

    modifier _skip(uint256 time) {
        skip(time);
        _;
    }

    // --- Core Owner ---

    modifier asOwner() {
        vm.startPrank(coreOwner.owner());
        _;
        vm.stopPrank();
    }

    modifier commitTransferOwnership(address newOwner) {
        vm.prank(coreOwner.owner());
        coreOwner.commitTransferOwnership(newOwner);
        _;
    }

    // --- Token Locker ---

    modifier asTokenLocker() {
        vm.startPrank(address(tokenLocker));
        _;
        vm.stopPrank();
    }

    modifier lock(Modifier_Lock memory _lock) {
        _modifierLock(_lock, IERC20(address(govToken)));
        _;
    }

    modifier lockMany(Modifier_LockMany memory _lockMany) {
        _modifierLockMany(_lockMany);
        _;
    }

    modifier freeze(Modifier_Freeze memory _freeze) {
        _modifierFreeze(_freeze);
        _;
    }

    modifier enableWithdrawWithPenalty() {
        _modifierEnableWithdrawWithPenalty();
        _;
    }

    modifier disableWithdrawWithPenalty() {
        _modifierDisableWithdrawWithPenalty();
        _;
    }

    // --- LP Locker ---
    modifier lockLP(Modifier_Lock memory _lock) {
        _modifierLock(_lock, IERC20(address(lpToken)));
        _;
    }

    // --- Boost Calculator ---

    modifier setBoostParams(Modifier_SetBoostParams memory _sbp) {
        _modifierSetBoostParams(_sbp);
        _;
    }

    modifier getBoostedAmountWrite(Modifier_GetBoostedAmountWrite memory _gbaw) {
        _modifierGetBoostedAmountWrite(_gbaw);
        _;
    }

    // --- Incentive Voting ---

    modifier addReceiver() {
        _modifierAddReceiver();
        _;
    }

    modifier registerAccountWeightAndVote(Modifier_RegisterAccountWeightAndVote memory _rawav) {
        _modifierRegisterWeightAccountAndVote(_rawav);
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // --- Token Locker ---

    function _modifierLock(Modifier_Lock memory _lock, IERC20 _token) internal {
        // Timejump before
        skip(_lock.skipBefore);

        // Deal tokens to user
        deal(address(_token), _lock.user, _lock.amountToLock);

        // As user
        vm.startPrank(_lock.user);
        // Approve and Lock tokens
        if (address(_token) == address(govToken)) {
            govToken.approve(address(tokenLocker), MAX);
            tokenLocker.lock(_lock.user, _lock.amountToLock, _lock.duration);
        } else if (address(_token) == address(lpToken)) {
            lpToken.approve(address(lpLocker), MAX);
            lpLocker.lock(_lock.user, _lock.amountToLock, _lock.duration);
        }
        vm.stopPrank();

        // Timejump after
        skip(_lock.skipAfter);
    }

    function _modifierLockMany(Modifier_LockMany memory _lockMany) internal {
        skip(_lockMany.skipBefore);

        // Find correct lenght for the array
        uint256 len;
        for (uint256 i; i < _lockMany.amountToLock.length; i++) {
            if (_lockMany.amountToLock[i] == 0) {
                len = i;
                break;
            }
        }

        TokenLockerBase.LockData[] memory data = new TokenLockerBase.LockData[](len);
        uint256 totalAmount;
        for (uint256 i = 0; i < len; i++) {
            uint256 amount = _lockMany.amountToLock[i];

            totalAmount += amount;
            data[i] = TokenLockerBase.LockData({amount: amount, epochsToUnlock: _lockMany.duration[i]});
        }

        deal(address(govToken), _lockMany.user, totalAmount);
        vm.startPrank(_lockMany.user);
        govToken.approve(address(tokenLocker), MAX);
        tokenLocker.lockMany(_lockMany.user, data);
        vm.stopPrank();
        skip(_lockMany.skipAfter);
    }

    function _modifierFreeze(Modifier_Freeze memory _freeze) internal {
        skip(_freeze.skipBefore);
        vm.prank(_freeze.user);
        tokenLocker.freeze();
        skip(_freeze.skipAfter);
    }

    function _modifierEnableWithdrawWithPenalty() internal {
        vm.prank(coreOwner.owner());
        tokenLocker.setPenaltyWithdrawalEnabled(true);
    }

    function _modifierDisableWithdrawWithPenalty() internal {
        vm.prank(coreOwner.owner());
        tokenLocker.setPenaltyWithdrawalEnabled(false);
    }

    // --- Boost Calculator ---

    function _modifierSetBoostParams(Modifier_SetBoostParams memory _sbp) internal {
        skip(_sbp.skipBefore);
        vm.startPrank(coreOwner.owner());
        boostCalculator.setBoostParams(_sbp.maxBoostMul, _sbp.maxBoostPct, _sbp.decayPct);
        vm.stopPrank();
        skip(_sbp.skipAfter);
    }

    function _modifierGetBoostedAmountWrite(Modifier_GetBoostedAmountWrite memory _gbaw) internal {
        skip(_gbaw.skipBefore);
        boostCalculator.getBoostedAmountWrite(
            _gbaw.account, _gbaw.amount, _gbaw.previousAmount, _gbaw.totalEpochEmissions
        );
        skip(_gbaw.skipAfter);
    }

    // --- Incentive Voting ---
    function _modifierAddReceiver() internal {
        vm.prank(incentiveVoting.vault());
        incentiveVoting.registerNewReceiver();
    }

    function _modifierRegisterWeightAccountAndVote(Modifier_RegisterAccountWeightAndVote memory _rawav) internal {
        skip(_rawav.skipBefore);

        // Get non null length
        uint256 len;
        for (uint256 i; i < _rawav.votes.length; i++) {
            if (_rawav.votes[i][0] == 0) {
                len = i;
                break;
            }
        }

        // Build votes array
        IncentiveVoting.Vote[] memory votes = new IncentiveVoting.Vote[](len);
        for (uint256 i = 0; i < len; i++) {
            votes[i] = IncentiveVoting.Vote({id: _rawav.votes[i][0], points: _rawav.votes[i][1]});
        }

        vm.prank(_rawav.account);
        if (len != 0) {
            incentiveVoting.registerAccountWeightAndVote(_rawav.account, _rawav.minEpochs, votes);
        } else {
            incentiveVoting.registerAccountWeight(_rawav.account, _rawav.minEpochs);
        }
        skip(_rawav.skipAfter);
    }
}
