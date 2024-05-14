// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Base_Test_} from "../../Base.sol";
import {TokenLockerBase} from "../../../contracts/dependencies/TokenLockerBase.sol";

contract Modifiers is Base_Test_ {
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    // --- Locker ---

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

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

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

    // --- Locker ---

    modifier lock(Modifier_Lock memory _lock) {
        _modifierLock(_lock);
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

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // --- Locker ---

    function _modifierLock(Modifier_Lock memory _lock) internal {
        skip(_lock.skipBefore);
        deal(address(govToken), _lock.user, _lock.amountToLock * 1 ether);
        vm.startPrank(_lock.user);
        govToken.approve(address(tokenLocker), MAX);
        tokenLocker.lock(_lock.user, _lock.amountToLock, _lock.duration);
        vm.stopPrank();
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

        deal(address(govToken), _lockMany.user, totalAmount * 1 ether);
        vm.prank(_lockMany.user);
        tokenLocker.lockMany(_lockMany.user, data);
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
}
