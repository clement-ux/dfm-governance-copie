// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {SlotFinder} from "./SlotFinder.sol";

import {BoostCalculator} from "../../contracts/BoostCalculator.sol";

library WizardBoostCalculator {
    /*//////////////////////////////////////////////////////////////
                            SLOT REFERENCES
    //////////////////////////////////////////////////////////////*/
    /// totalEpochWeights --------| -> 0 -> 32767 (2 values per slots)
    /// accountEpochLockPct ------| -> 32768

    uint256 public constant TOTAL_EPOCH_WEIGHTS_ARRAY_SLOT_REF = 0;
    uint256 public constant ACCOUNT_EPOCH_LOCK_PCT_MAPPING_SLOT_REF = 32768;

    /*//////////////////////////////////////////////////////////////
                              TOTAL VALUES
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the total epoch weight by slot reading from the storage
    function getTotalEpochWeightBySlotReading(Vm vm, address _contract, uint256 _epoch) public view returns (uint128) {
        uint256 valuePerSlot = 2; // How many uint128 fit in a slot? 256 / 128 = 2.
        uint256 level = _epoch / valuePerSlot;
        bytes32 slot = bytes32(TOTAL_EPOCH_WEIGHTS_ARRAY_SLOT_REF + level);
        uint256 offSet = _epoch % valuePerSlot + 1;
        bytes32 data = vm.load(address(_contract), slot);
        return uint128(uint256((data << (256 - offSet * 128) >> (256 - 128))));
    }

    /*//////////////////////////////////////////////////////////////
                             ACCOUNT VALUES
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the account epoch weights by slot reading from the storage
    function getAccountEpochWeightsBySlotReading(Vm vm, address _contract, address _account, uint256 _epoch)
        public
        view
        returns (uint32)
    {
        bytes32 slot = SlotFinder.getMappingElementSlotIndex(_account, ACCOUNT_EPOCH_LOCK_PCT_MAPPING_SLOT_REF);
        uint256 valuePerSlot = 8; // How many uint32 fit in a slot? 256 / 32 = 8.
        uint256 level = _epoch / valuePerSlot;
        slot = bytes32(uint256(slot) + level);
        uint256 offSet = _epoch % valuePerSlot + 1;
        bytes32 data = vm.load(address(_contract), slot);
        return uint32(uint256((data << (256 - offSet * 32) >> (256 - 32))));
    }
}
