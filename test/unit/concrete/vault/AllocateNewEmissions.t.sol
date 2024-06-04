// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {Vault} from "../../../../contracts/Vault.sol";
import {MockedCall} from "../../shared/MockedCall.sol";

contract Unit_Concrete_Vault_AllocateNewEmissions_ is Unit_Shared_Test_ {
    /*//////////////////////////////////////////////////////////////
                            REVERTING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_AllocateNewEmissions_Because_ReceiverNotRegistered() public {
        vm.expectRevert("Receiver not registered");
        vault.allocateNewEmissions(1);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test allocate new emissions when id is 0.
    /// -> Instant return as id 0 is not valid.
    function test_AllocateNewEmissions_When_Id0() public {
        assertEq(vault.allocateNewEmissions(0), 0);
    }

    /// @notice Test allocate new emissions under following conditions:
    /// - Receiver epoch is up to date with total epoch. -> return 0 as receiver already received all emissions.
    function test_AllocateNewEmissions_When_EpochIsEqualToTotalEpoch()
        public
        addReceiverFromVault(
            Modifier_RegisterAccount({receiver: makeAddr("receiver"), count: 1, maxEmissionPct: [10_000, 0]})
        )
    {
        // Assert epoch is up to date with total epoch
        assertEq(vault.receiverUpdatedEpoch(1), vault.totalUpdateEpoch());

        vm.prank(makeAddr("receiver"));
        assertEq(vault.allocateNewEmissions(1), 0);
    }

    /// @notice Test allocate new emissions under following conditions:
    /// - Timejump 1 epoch to avoid false 0.
    /// - Add receiver with max emission percentage.
    /// - Timejump 1 epoch to discyncronize receiver epoch with total epoch.
    /// - Notify new emissions of 1 ether.
    /// - Receiver has 100% of vote percentage.
    /// - Expected event: IncreasedReceiverAllocation.
    /// - Expected return: 1 ether.
    /// - No unallocated supply.
    function test_AllocateNewEmissions_When_1EpochBehind_MaxPct_NoUnallocated()
        public
        _skip(EPOCH_LENGTH)
        addReceiverFromVault(
            Modifier_RegisterAccount({receiver: makeAddr("receiver"), count: 1, maxEmissionPct: [10_000, 0]})
        )
        notifyNewEmissions(Modifier_AllocateNewEmissions({skipBefore: EPOCH_LENGTH, amount: 1 ether, skipAfter: 0}))
    {
        // Assertions before
        assertEq(vault.receiverUpdatedEpoch(1), 1);
        assertEq(vault.totalUpdateEpoch(), 2);
        assertEq(vault.epochEmissions(2), 1 ether);
        assertEq(vault.unallocatedTotal(), 0);

        MockedCall.getReceiverVotePct(address(incentiveVoting), 1, 2, 1e18);

        // Expected event
        vm.expectEmit({emitter: address(vault)});
        emit Vault.IncreasedReceiverAllocation(makeAddr("receiver"), 1 ether);

        // Main call
        vm.prank(makeAddr("receiver"));
        uint256 allocated = vault.allocateNewEmissions(1);

        // Assertions after
        assertEq(allocated, 1 ether);
        assertEq(vault.receiverUpdatedEpoch(1), 2);
        assertEq(vault.receiverAllocated(makeAddr("receiver")), 1 ether);
    }

    /// @notice Test allocate new emissions under following conditions:
    /// - Timejump 1 epochs to avoid false 0.
    /// - Add receiver with max emission percentage.
    /// - Timejump 1 epoch to discyncronize receiver epoch with total epoch.
    /// - Notify new emissions of 1 ether.
    /// - Timejump 1 epoch to discyncronize receiver epoch with total epoch.
    /// - Notify new emissions of 2 ether.
    /// - Receiver has 100% of vote percentage for both epochs.
    /// - Expected event: IncreasedReceiverAllocation.
    /// - Expected return: 3 ether.
    /// - No unallocated supply.
    function test_AllocateNewEmissions_When_2EpochBehind_MaxPct_NoUnallocated()
        public
        _skip(EPOCH_LENGTH)
        addReceiverFromVault(
            Modifier_RegisterAccount({receiver: makeAddr("receiver"), count: 1, maxEmissionPct: [10_000, 0]})
        )
        notifyNewEmissions(Modifier_AllocateNewEmissions({skipBefore: EPOCH_LENGTH, amount: 1 ether, skipAfter: 0}))
        notifyNewEmissions(Modifier_AllocateNewEmissions({skipBefore: EPOCH_LENGTH, amount: 2 ether, skipAfter: 0}))
    {
        // Assertions before
        assertEq(vault.receiverUpdatedEpoch(1), 1);
        assertEq(vault.totalUpdateEpoch(), 3);
        assertEq(vault.epochEmissions(2), 1 ether);
        assertEq(vault.epochEmissions(3), 2 ether);
        assertEq(vault.unallocatedTotal(), 0);

        MockedCall.getReceiverVotePct(address(incentiveVoting), 1, 2, 1e18);
        MockedCall.getReceiverVotePct(address(incentiveVoting), 1, 3, 1e18);

        // Expected event
        vm.expectEmit({emitter: address(vault)});
        emit Vault.IncreasedReceiverAllocation(makeAddr("receiver"), 3 ether);

        // Main call
        vm.prank(makeAddr("receiver"));
        uint256 allocated = vault.allocateNewEmissions(1);

        // Assertions after
        assertEq(allocated, 3 ether);
        assertEq(vault.receiverUpdatedEpoch(1), 3);
        assertEq(vault.receiverAllocated(makeAddr("receiver")), 3 ether);
    }

    /// @notice Test allocate new emissions under following conditions:
    /// - Timejump 1 epoch to avoid false 0.
    /// - Add receiver with max emission percentage.
    /// - Timejump 1 epoch to discyncronize receiver epoch with total epoch.
    /// - Notify new emissions of 1 ether.
    /// - Receiver has 50% of vote percentage.
    /// - Expected event: IncreasedReceiverAllocation.
    /// - Expected return: 1 ether / 2.
    /// - No unallocated supply.
    function test_AllocateNewEmissions_When_1EpochBehind_NotMaxPct_NoUnallocated()
        public
        _skip(EPOCH_LENGTH)
        addReceiverFromVault(
            Modifier_RegisterAccount({receiver: makeAddr("receiver"), count: 1, maxEmissionPct: [10_000, 0]})
        )
        notifyNewEmissions(Modifier_AllocateNewEmissions({skipBefore: EPOCH_LENGTH, amount: 1 ether, skipAfter: 0}))
    {
        // Assertions before
        assertEq(vault.receiverUpdatedEpoch(1), 1);
        assertEq(vault.totalUpdateEpoch(), 2);
        assertEq(vault.epochEmissions(2), 1 ether);
        assertEq(vault.unallocatedTotal(), 0);

        MockedCall.getReceiverVotePct(address(incentiveVoting), 1, 2, 1e18 / 2);

        // Expected event
        vm.expectEmit({emitter: address(vault)});
        emit Vault.IncreasedReceiverAllocation(makeAddr("receiver"), 1 ether / 2);

        // Main call
        vm.prank(makeAddr("receiver"));
        uint256 allocated = vault.allocateNewEmissions(1);

        // Assertions after
        assertEq(allocated, 1 ether / 2);
        assertEq(vault.receiverUpdatedEpoch(1), 2);
        assertEq(vault.receiverAllocated(makeAddr("receiver")), 1 ether / 2);
    }

    /// @notice Test allocate new emissions under following conditions:
    /// - Timejump 1 epoch to avoid false 0.
    /// - Add receiver with 50% of max emission percentage.
    /// - Timejump 1 epoch to discyncronize receiver epoch with total epoch.
    /// - Notify new emissions of 1 ether.
    /// - Receiver has 100% of vote percentage.
    /// - Expected event: IncreasedReceiverAllocation.
    /// - Expected event: UnallocatedSupplyIncreased.
    /// - Expected return: 1 ether / 2.
    function test_AllocateNewEmissions_When_1EpochBehind_CappedGreaterThanAllowed()
        public
        _skip(EPOCH_LENGTH)
        addReceiverFromVault(
            Modifier_RegisterAccount({receiver: makeAddr("receiver"), count: 1, maxEmissionPct: [5_000, 0]})
        )
        notifyNewEmissions(Modifier_AllocateNewEmissions({skipBefore: EPOCH_LENGTH, amount: 1 ether, skipAfter: 0}))
    {
        // Assertions before
        assertEq(vault.receiverUpdatedEpoch(1), 1);
        assertEq(vault.totalUpdateEpoch(), 2);
        assertEq(vault.epochEmissions(2), 1 ether);
        assertEq(vault.unallocatedTotal(), 0);

        MockedCall.getReceiverVotePct(address(incentiveVoting), 1, 2, 1e18);

        // Expected event
        vm.expectEmit({emitter: address(vault)});
        emit Vault.IncreasedReceiverAllocation(makeAddr("receiver"), 1 ether / 2);
        vm.expectEmit({emitter: address(vault)});
        emit Vault.UnallocatedSupplyIncreased(1 ether / 2, 1 ether / 2);

        // Main call
        vm.prank(makeAddr("receiver"));
        uint256 allocated = vault.allocateNewEmissions(1);

        // Assertions after
        assertEq(allocated, 1 ether / 2);
        assertEq(vault.receiverUpdatedEpoch(1), 2);
        assertEq(vault.receiverAllocated(makeAddr("receiver")), 1 ether / 2);
        assertEq(vault.unallocatedTotal(), 1 ether / 2);
    }

    /// @notice Test allocate new emissions under following conditions:
    /// - Timejump 1 epoch to avoid false 0.
    /// - Add receiver with 50% of max emission percentage.
    /// - Timejump 1 epoch to discyncronize receiver epoch with total epoch.
    /// - Notify new emissions of 1 ether.
    /// - Receiver has 20% of vote percentage.
    /// - Expected event: IncreasedReceiverAllocation.
    /// - Expected return: 1 ether / 5.
    /// - No unallocated supply.
    function test_AllocateNewEmissions_When_1EpochBehind_CappedLowerThanAllowed()
        public
        _skip(EPOCH_LENGTH)
        addReceiverFromVault(
            Modifier_RegisterAccount({receiver: makeAddr("receiver"), count: 1, maxEmissionPct: [5_000, 0]})
        )
        notifyNewEmissions(Modifier_AllocateNewEmissions({skipBefore: EPOCH_LENGTH, amount: 1 ether, skipAfter: 0}))
    {
        // Assertions before
        assertEq(vault.receiverUpdatedEpoch(1), 1);
        assertEq(vault.totalUpdateEpoch(), 2);
        assertEq(vault.epochEmissions(2), 1 ether);
        assertEq(vault.unallocatedTotal(), 0);

        MockedCall.getReceiverVotePct(address(incentiveVoting), 1, 2, 1e18 / 5); // 20%

        // Expected event
        vm.expectEmit({emitter: address(vault)});
        emit Vault.IncreasedReceiverAllocation(makeAddr("receiver"), 1 ether / 5);

        // Main call
        vm.prank(makeAddr("receiver"));
        uint256 allocated = vault.allocateNewEmissions(1);

        // Assertions after
        assertEq(allocated, 1 ether / 5);
        assertEq(vault.receiverUpdatedEpoch(1), 2);
        assertEq(vault.receiverAllocated(makeAddr("receiver")), 1 ether / 5);
        assertEq(vault.unallocatedTotal(), 0);
    }

    /// @notice Test allocate new emissions under following conditions:
    /// - Timejump 1 epoch to avoid false 0.
    /// - Add receiver with max emission percentage.
    /// - Timejump 1 epoch to discyncronize receiver epoch with total epoch.
    /// - Notify new emissions of 1 ether.
    /// - Receiver has 0% of vote percentage.
    /// - No event emitted.
    /// - Expected return: 0.
    function test_AllocateNewEmissions_When_1EpochBehind_MaxPct_NoVote()
        public
        _skip(EPOCH_LENGTH)
        addReceiverFromVault(
            Modifier_RegisterAccount({receiver: makeAddr("receiver"), count: 1, maxEmissionPct: [10_000, 0]})
        )
        notifyNewEmissions(Modifier_AllocateNewEmissions({skipBefore: EPOCH_LENGTH, amount: 1 ether, skipAfter: 0}))
    {
        // Assertions before
        assertEq(vault.receiverUpdatedEpoch(1), 1);
        assertEq(vault.totalUpdateEpoch(), 2);
        assertEq(vault.epochEmissions(2), 1 ether);
        assertEq(vault.unallocatedTotal(), 0);

        MockedCall.getReceiverVotePct(address(incentiveVoting), 1, 2, 0);

        // Expected event
        // vm.expectEmit({emitter: address(vault)});
        // emit Vault.IncreasedReceiverAllocation(makeAddr("receiver"), 1 ether); // Not emitted in this case

        // Main call
        vm.prank(makeAddr("receiver"));
        uint256 allocated = vault.allocateNewEmissions(1);

        // Assertions after
        assertEq(allocated, 0);
        assertEq(vault.receiverUpdatedEpoch(1), 2);
        assertEq(vault.receiverAllocated(makeAddr("receiver")), 0);
        assertEq(vault.unallocatedTotal(), 0);
    }
}
