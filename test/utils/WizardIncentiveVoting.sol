// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {SlotFinder} from "./SlotFinder.sol";

library WizardIncentiveVoting {
    /*//////////////////////////////////////////////////////////////
                            SLOT REFERENCES
    //////////////////////////////////////////////////////////////*/
    /// isApprovedDelegate (DelegateOps) ----------|-> 0
    ///
    /// accountLockData ---------------------------|-> 1
    ///
    /// receiverDecayRate -------------------------|-> 2 -> 32769 (2 values per slots, 32767 slots per arrays, 1 array in total)
    ///                                                           (need 32767 slots in total)
    ///
    /// receiverUpdatedEpoch ----------------------|-> 32770 -> 36865 (16 values per slots, 4095 slots per arrays, 1 array in total)
    ///                                                               (need 4095 slots in total)
    ///
    /// receiverEpochWeights ----------------------|-> 36866 -> 2147487745 (2 values per slots, 32767 slots per arrays, 65535 arrays in total)
    ///                                                                    (need (32767 + 1) * 65535 - 1 = 2147450880 slots in total)
    ///
    /// receiverEpochUnlocks ----------------------|-> 2147487746 -> 4294938625 (2 values per slots, 32767 slots per arrays, 65535 arrays in total)
    ///                                                                    (need (32767 + 1) * 65535 - 1 = 2147450880 slots in total)
    ///
    /// receiverCount -----------------------------|
    /// totalDecayRate ----------------------------|
    /// totalUpdatedEpoch -------------------------|-> 4294938626
    ///
    /// totalEpochWeights -------------------------| -> 4294938627 -> 4294971394 (2 values per slots, 32767 slots per arrays)
    ///                                                                          (need 32767 slots in total)
    ///
    /// totalEpochUnlocks -------------------------| -> 4294971395 -> 4295004162 (2 values per slots, 32767 slots per arrays)
    ///                                                                          (need 32767 slots in total)

    /// struct Account data
    /// epoch -------------------------------------|
    /// frozenWeight ------------------------------|
    /// points ------------------------------------|
    /// lockLength --------------------------------|
    /// voteLenght --------------------------------|-> 0
    ///
    /// activeVotes -------------------------------| -> 1 -> 20000 (2 values per slots, 1 slot per array, 10000 arrays in total)
    ///                                                            (need (1 + 1) * 10000 - 1 = 19999 slots in total)
    /// lockedAmounts -----------------------------| -> 20001 -> 25001 (2 values per slots, 5000 slots per array, 1 arrays in total)
    ///                                                                (need 5000 slots in total)
    /// epochsToUnlock ----------------------------| -> 25002 ->  25033 (32 values per slots, 31 slots per array, 1 arrays in total)
    ///                                                                 (need 31 slots in total)
    /// -----------------------------------------------------------------------------------------------------------------------------------

    uint256 public constant IS_APPROVED_DELEGATE_SLOT_REF = 0;
    uint256 public constant ACCOUNT_LOCK_DATA_SLOT_REF = 1;

    // Receiver Data
    uint256 public constant RECEIVER_DECAY_RATE_ARRAY_SLOT_REF = 2;
    uint256 public constant RECEIVER_UPDATED_EPOCH_ARRAY_SLOT_REF = 32770;
    uint256 public constant RECEIVER_EPOCH_WEIGHTS_ARRAY_SLOT_REF = 36866;
    uint256 public constant RECEIVER_EPOCH_UNLOCKS_ARRAY_SLOT_REF = 2147487746;
    uint256 public constant RECEIVER_COUNT_SLOT_REF = 4294938626;

    // Total Data
    uint256 public constant TOTAL_DECAY_RATE_SLOT_REF = 4294938626;
    uint256 public constant TOTAL_UPDATED_EPOCH_SLOT_REF = 4294938626;
    uint256 public constant TOTAL_EPOCH_WEIGHTS_ARRAY_SLOT_REF = 4294938627;
    uint256 public constant TOTAL_EPOCH_UNLOCKS_ARRAY_SLOT_REF = 4294971395;

    // Lock Data
    uint256 public constant LOCK_DATA_EPOCH = 0;
    uint256 public constant LOCK_DATA_FROZEN_WEIGHT = 0;
    uint256 public constant LOCK_DATA_POINTS = 0;
    uint256 public constant LOCK_DATA_LOCK_LENGTH = 0;
    uint256 public constant LOCK_DATA_VOTE_LENGTH = 0;
    uint256 public constant LOCK_DATA_ACTIVE_VOTES = 1;
    uint256 public constant LOCK_DATA_LOCKED_AMOUNTS = 20001;
    uint256 public constant LOCK_DATA_EPOCHS_TO_UNLOCK = 25002;

    /*//////////////////////////////////////////////////////////////
                            RECEIVER VALUES
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the decay rate of a receiver
    /// @param _contract The contract address
    /// @param _id The receiver id
    function getReceiverDecayRateBySlotReading(Vm vm, address _contract, uint256 _id) public view returns (uint120) {
        uint256 valuePerSlot = 2; // How many uint120 fit in a slot? 256 / 120 = 2.
        uint256 level = _id / valuePerSlot;
        bytes32 slot = bytes32(RECEIVER_DECAY_RATE_ARRAY_SLOT_REF + level);
        uint256 offSet = _id % valuePerSlot + 1;
        bytes32 data = vm.load(address(_contract), slot);
        return uint120(uint256((data << (256 - offSet * 120) >> (256 - 120))));
    }

    /// @notice Get the updated epoch of a receiver
    /// @param _contract The contract address
    /// @param _id The receiver id
    function getReceiverUpdateEpochBySlotReading(Vm vm, address _contract, uint256 _id) public view returns (uint16) {
        uint256 valuePerSlot = 16; // How many uint16 fit in a slot? 256 / 16 = 16.
        uint256 level = _id / valuePerSlot;
        bytes32 slot = bytes32(RECEIVER_UPDATED_EPOCH_ARRAY_SLOT_REF + level);
        uint256 offSet = _id % valuePerSlot + 1;
        bytes32 data = vm.load(address(_contract), slot);
        return uint16(uint256((data << (256 - offSet * 16) >> (256 - 16))));
    }

    /// @notice Get the count of receivers registered in the contract
    function getReceiverCount(Vm vm, address _contract) public view returns (uint256) {
        return uint256(vm.load(address(_contract), bytes32(RECEIVER_COUNT_SLOT_REF)));
    }

    /*//////////////////////////////////////////////////////////////
                               LOCK DATA
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the epoch of a lock data
    /// @param _contract The contract address
    /// @param _account The account address
    function getLockDataEpochBySlotReading(Vm vm, address _contract, address _account) public view returns (uint16) {
        return uint16(
            uint256(
                vm.load(
                    address(_contract),
                    bytes32(
                        uint256(SlotFinder.getMappingElementSlotIndex(_account, ACCOUNT_LOCK_DATA_SLOT_REF))
                            + LOCK_DATA_EPOCH
                    )
                ) << (256 - 16) >> (256 - 16)
            )
        );
    }

    /// @notice Get the frozen weight of a lock data
    /// @param _contract The contract address
    /// @param _account The account address
    function getLockDataFrozenWeightBySlotReading(Vm vm, address _contract, address _account)
        public
        view
        returns (uint128)
    {
        return uint128(
            uint256(
                vm.load(
                    address(_contract),
                    bytes32(
                        uint256(SlotFinder.getMappingElementSlotIndex(_account, ACCOUNT_LOCK_DATA_SLOT_REF))
                            + LOCK_DATA_FROZEN_WEIGHT
                    )
                ) << (256 - (128 + 16)) >> (256 - 128)
            )
        );
    }

    /// @notice Get the points of a lock data
    /// @param _contract The contract address
    /// @param _account The account address
    function getLockDataPointsBySlotReading(Vm vm, address _contract, address _account) public view returns (uint16) {
        return uint16(
            uint256(
                vm.load(
                    address(_contract),
                    bytes32(
                        uint256(SlotFinder.getMappingElementSlotIndex(_account, ACCOUNT_LOCK_DATA_SLOT_REF))
                            + LOCK_DATA_EPOCH
                    )
                ) << (256 - (16 + 128 + 16)) >> (256 - 16)
            )
        );
    }

    /// @notice Get the lock length of a lock data
    /// @param _contract The contract address
    /// @param _account The account address
    function getLockDataLockLengthBySlotReading(Vm vm, address _contract, address _account)
        public
        view
        returns (uint8)
    {
        return uint8(
            uint256(
                vm.load(
                    address(_contract),
                    bytes32(
                        uint256(SlotFinder.getMappingElementSlotIndex(_account, ACCOUNT_LOCK_DATA_SLOT_REF))
                            + LOCK_DATA_EPOCH
                    )
                ) << (256 - (16 + 128 + 16 + 8)) >> (256 - 8)
            )
        );
    }

    /// @notice Get the vote length of a lock data
    /// @param _contract The contract address
    /// @param _account The account address
    function getLockDataVoteLengthBySlotReading(Vm vm, address _contract, address _account)
        public
        view
        returns (uint8)
    {
        return uint8(
            uint256(
                vm.load(
                    address(_contract),
                    bytes32(
                        uint256(SlotFinder.getMappingElementSlotIndex(_account, ACCOUNT_LOCK_DATA_SLOT_REF))
                            + LOCK_DATA_EPOCH
                    )
                ) << (256 - (16 + 128 + 16 + 8)) >> (256 - 8)
            )
        );
    }

    /// @notice Get the active votes of a lock data
    /// @param _contract The contract address
    /// @param _account The account address
    /// @param _id The receiver id
    /// @return votes -> [receiverId, points]
    function getLockDataActiveVotesBySlotReading(Vm vm, address _contract, address _account, uint256 _id)
        public
        view
        returns (uint16[2] memory votes)
    {
        bytes32 firstSlot = bytes32(
            uint256(SlotFinder.getMappingElementSlotIndex(_account, ACCOUNT_LOCK_DATA_SLOT_REF))
                + LOCK_DATA_ACTIVE_VOTES
        );

        uint256 level = _id - 1;
        bytes32 slot = bytes32(uint256(firstSlot) + level);
        bytes32 data = vm.load(address(_contract), slot);
        uint16 receiverId;
        uint16 points;

        receiverId = uint16(uint256(data << (256 - (16 + 16)) >> (256 - 16)));
        points = uint16(uint256(data << (256 - 16) >> (256 - 16)));
        return [receiverId, points];
    }

    /// @notice Get the locked amounts of a lock data
    /// @param _contract The contract address
    /// @param _account The account address
    /// @param _epoch The epoch
    function getLockDataLockedAmountsBySlotReading(Vm vm, address _contract, address _account, uint256 _epoch)
        public
        view
        returns (uint120)
    {
        bytes32 firstSlot = bytes32(
            uint256(SlotFinder.getMappingElementSlotIndex(_account, ACCOUNT_LOCK_DATA_SLOT_REF))
                + LOCK_DATA_LOCKED_AMOUNTS
        );

        uint256 valuePerSlot = 2; // How many uint120 fit in a slot? 256 / 120 = 2.
        uint256 level = _epoch / valuePerSlot;
        bytes32 slot = bytes32(uint256(firstSlot) + level);
        bytes32 data = vm.load(address(_contract), slot);
        uint256 offSet = _epoch % valuePerSlot + 1;
        return uint120(uint256(data << (256 - offSet * 120) >> (256 - 120)));
    }

    /// @notice Get the epochs to unlock of a lock data
    /// @param _contract The contract address
    /// @param _account The account address
    /// @param _epoch The epoch
    function getLockDataEpochsToUnlockBySlotReading(Vm vm, address _contract, address _account, uint256 _epoch)
        public
        view
        returns (uint8)
    {
        bytes32 firstSlot = bytes32(
            uint256(SlotFinder.getMappingElementSlotIndex(_account, ACCOUNT_LOCK_DATA_SLOT_REF))
                + LOCK_DATA_EPOCHS_TO_UNLOCK
        );

        uint256 valuePerSlot = 32; // How many uint8 fit in a slot? 256 / 8 = 32.
        uint256 level = _epoch / valuePerSlot;
        bytes32 slot = bytes32(uint256(firstSlot) + level);
        bytes32 data = vm.load(address(_contract), slot);
        uint256 offSet = _epoch % valuePerSlot + 1;
        return uint8(uint256(data << (256 - offSet * 8) >> (256 - 8)));
    }
}
