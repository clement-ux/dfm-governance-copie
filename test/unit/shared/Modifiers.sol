// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Base_Test_} from "../../Base.sol";

contract Modifiers is Base_Test_ {
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
}
