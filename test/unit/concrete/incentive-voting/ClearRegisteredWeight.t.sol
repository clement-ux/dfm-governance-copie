// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {DefaultValues as DEF} from "../../../utils/DefaultValues.sol";

import {ITokenLocker} from "../../../../contracts/interfaces/ITokenLocker.sol";
import {IncentiveVoting} from "../../../../contracts/IncentiveVoting.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardIncentiveVoting} from "../../../utils/WizardIncentiveVoting.sol";

contract Unit_Concrete_IncentiveVoting_ClearRegisteredWeight_ is Unit_Shared_Test_ {
    using WizardIncentiveVoting for IncentiveVoting;

    /*//////////////////////////////////////////////////////////////
                            REVERTING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_ClearRegisteredWeight_DelegateNotApproved() public {
        vm.prank(alice);
        vm.expectRevert("Delegate not approved");
        incentiveVoting.clearRegisteredWeight(address(this));
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test Clear vote under following conditions:
    /// - No lock, no votes
    /// - Nothing happens, but true is returned
    function test_ClearRegisteredWeight_As_TokenLocker_NoPositions() public {
        vm.prank(address(tokenLocker));
        assertTrue(incentiveVoting.clearRegisteredWeight(address(this)));
    }

    /// @notice Test Clear vote under following conditions:
    /// - No lock, no votes
    /// - Nothing happens, but true is returned
    function test_ClearRegisteredWeight_As_Delegate_NoPositions() public {
        incentiveVoting.setDelegateApproval(alice, true);
        vm.prank(alice);
        assertTrue(incentiveVoting.clearRegisteredWeight(address(this)));
    }

    /// @notice Test Clear vote under following conditions:
    /// - Lock 1 ether of token for 5 weeks on TokenLocker
    /// - Register new receiver
    /// - Freeze account
    /// - Register account weight and vote 100% for receiver 1
    function test_ClearRegisteredWeight_When_Frozen_ActiveVotes()
        public
        lock(
            Modifier_Lock({
                skipBefore: 1 weeks,
                user: address(this),
                amountToLock: DEF.LOCK_AMOUNT,
                duration: DEF.LOCK_DURATION_W,
                skipAfter: 0
            })
        )
        addReceiver
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
        registerAccountWeightAndVote(
            Modifier_RegisterAccountWeightAndVote({
                skipBefore: 0,
                account: address(this),
                minEpochs: 0,
                votes: [
                    [uint256(1), uint256(DEF.MAX_VOTE)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)]
                ],
                skipAfter: 0
            })
        )
    {
        // Assertions before
        // No need as almoost the same as `test_RegisterAccountWeightAndVote_When_NoPreviousVotes_SingleVote_Frozen_MaxPoints`.

        // Expected events
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.ClearedVotes(address(this), 1);
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.AccountWeightRegistered(address(this), 1, 0, new ITokenLocker.LockData[](0));

        // Main Call
        assertTrue(incentiveVoting.clearRegisteredWeight(address(this)));

        // Assertions after
        // Account data
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataFrozenWeightBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 0);
        assertEq(
            incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(1), uint16(DEF.MAX_VOTE)]
        ); // Active vote are not deleted
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), 0);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), 0);
        // Receiver data
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(1), 0);
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), 1);
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(1, 1), 0);
        assertEq(incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, 1), 0);
        // Total data
        assertEq(incentiveVoting.getTotalDecayRateBySlotReading(), 0);
        assertEq(incentiveVoting.getTotalUpdateEpochBySlotReading(), 1);
        assertEq(incentiveVoting.getTotalEpochWeightsBySlotReading(1), 0);
        assertEq(incentiveVoting.getTotalEpochUnlocksBySlotReading(1), 0);
    }

    /// @notice Test Clear vote under following conditions:
    /// - Lock 1 ether of token for 5 weeks on TokenLocker
    /// - Register new receiver
    /// - Freeze account
    /// - Register account weight without voting
    function test_ClearRegisteredWeight_When_Frozen_NoActiveVotes()
        public
        lock(
            Modifier_Lock({
                skipBefore: 1 weeks,
                user: address(this),
                amountToLock: DEF.LOCK_AMOUNT,
                duration: DEF.LOCK_DURATION_W,
                skipAfter: 0
            })
        )
        addReceiver
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
        registerAccountWeightAndVote(
            Modifier_RegisterAccountWeightAndVote({
                skipBefore: 0,
                account: address(this),
                minEpochs: 0,
                votes: [
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)]
                ],
                skipAfter: 0
            })
        )
    {
        // Assertions before
        // No need as almoost the same as `test_RegisterAccountWeightAndVote_When_NoPreviousVotes_SingleVote_Frozen_MaxPoints`.

        // Expected events
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.AccountWeightRegistered(address(this), 1, 0, new ITokenLocker.LockData[](0));

        // Main Call
        assertTrue(incentiveVoting.clearRegisteredWeight(address(this)));

        // Assertions after
        // Assertions after
        // Account data
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataFrozenWeightBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(0), uint16(0)]); // Active vote are not deleted
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), 0);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), 0);
        // Receiver data
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(1), 0);
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), 1);
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(1, 1), 0);
        assertEq(incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, 1), 0);
        // Total data
        assertEq(incentiveVoting.getTotalDecayRateBySlotReading(), 0);
        assertEq(incentiveVoting.getTotalUpdateEpochBySlotReading(), 0);
        assertEq(incentiveVoting.getTotalEpochWeightsBySlotReading(1), 0);
        assertEq(incentiveVoting.getTotalEpochUnlocksBySlotReading(1), 0);
    }

    /// @notice Test Clear vote under following conditions:
    /// - Lock 1 ether of token for 5 weeks on TokenLocker
    /// - Register new receiver
    /// - Register account weight without voting
    function test_ClearRegisteredWeight_When_NotFrozen_NoActiveVotes()
        public
        lock(
            Modifier_Lock({
                skipBefore: 1 weeks,
                user: address(this),
                amountToLock: DEF.LOCK_AMOUNT,
                duration: DEF.LOCK_DURATION_W,
                skipAfter: 0
            })
        )
        addReceiver
        registerAccountWeightAndVote(
            Modifier_RegisterAccountWeightAndVote({
                skipBefore: 0,
                account: address(this),
                minEpochs: 0,
                votes: [
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)]
                ],
                skipAfter: 0
            })
        )
    {
        // Assertions before
        // No need as almoost the same as `test_RegisterAccountWeightAndVote_When_NoPreviousVotes_SingleVote_Frozen_MaxPoints`.

        // Expected events
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.AccountWeightRegistered(address(this), 1, 0, new ITokenLocker.LockData[](0));

        // Main Call
        assertTrue(incentiveVoting.clearRegisteredWeight(address(this)));

        // Assertions after
        // Account data
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataFrozenWeightBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(0), uint16(0)]); // Active vote are not deleted
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), DEF.LOCK_AMOUNT); // Not deleted
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), DEF.LOCK_DURATION_W); // Not deleted
        // Receiver data
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(1), 0);
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), 1);
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(1, 1), 0);
        assertEq(incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, 1), 0);
        // Total data
        assertEq(incentiveVoting.getTotalDecayRateBySlotReading(), 0);
        assertEq(incentiveVoting.getTotalUpdateEpochBySlotReading(), 0);
        assertEq(incentiveVoting.getTotalEpochWeightsBySlotReading(1), 0);
        assertEq(incentiveVoting.getTotalEpochUnlocksBySlotReading(1), 0);
    }
}
