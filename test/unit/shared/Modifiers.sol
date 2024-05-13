// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Base_Test_} from "../../Base.sol";

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

    modifier freeze(Modifier_Freeze memory _freeze) {
        _modifierFreeze(_freeze);
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // --- Locker ---

    function _modifierLock(Modifier_Lock memory _lock) internal {
        skip(_lock.skipBefore);
        deal(address(govToken), _lock.user, _lock.amountToLock * 1 ether);
        vm.prank(_lock.user);
        tokenLocker.lock(_lock.user, _lock.amountToLock, _lock.duration);
        skip(_lock.skipAfter);
    }

    function _modifierFreeze(Modifier_Freeze memory _freeze) internal {
        skip(_freeze.skipBefore);
        vm.prank(_freeze.user);
        tokenLocker.freeze();
        skip(_freeze.skipAfter);
    }
}
