// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {SlotFinder} from "./SlotFinder.sol";

library WizardCoreOwner {
    /*//////////////////////////////////////////////////////////////
                            SLOT REFERENCES
    //////////////////////////////////////////////////////////////*/
    /// owner ----------------------|-> 0
    ///
    /// pendingOwner ---------------|-> 1
    ///
    /// ownershipTransferDeadline --|-> 2
    ///
    /// addressRegistry ------------|-> 3

    uint256 public constant CORE_OWNER_OWNER_SLOT = 0;
    uint256 public constant CORE_OWNER_PENDING_OWNER_SLOT = 1;
    uint256 public constant CORE_OWNER_OWNERSHIP_TRANSFER_DEADLINE_SLOT = 2;
    uint256 public constant CORE_OWNER_ADDRESS_REGISTRY_SLOT = 3;

    function getAddressRegirstyBSL(Vm vm, address _contract, bytes32 _identifier) public view returns (address) {
        bytes32 slot = SlotFinder.getMappingElementSlotIndex(_identifier, CORE_OWNER_ADDRESS_REGISTRY_SLOT);
        bytes32 data = vm.load(_contract, slot);
        return address(uint160(uint256(data)));
    }
}
