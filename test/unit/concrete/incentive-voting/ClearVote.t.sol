// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {DefaultValues as DEF} from "../../../utils/DefaultValues.sol";

import {ITokenLocker} from "../../../../contracts/interfaces/ITokenLocker.sol";
import {IncentiveVoting} from "../../../../contracts/IncentiveVoting.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardIncentiveVoting} from "../../../utils/WizardIncentiveVoting.sol";

contract Unit_Concrete_IncentiveVoting_ClearVote_ is Unit_Shared_Test_ {
    using WizardIncentiveVoting for IncentiveVoting;

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test Clear vote under following conditions:
    /// - No lock, no votes
    /// - Nothing happens, but event is emitted
    function test_ClearVote_When_Vote_Not_Exists() public {
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.ClearedVotes(address(this), 0);
        incentiveVoting.clearVote(address(this));

        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), 0);
    }

    /// @notice Test Clear vote under following conditions:
    /// - Lock 1 ether of token for 5 weeks on TokenLocker
    /// - Register new receiver
    /// - Register account weight and vote 100% for receiver 1
    /// - Clear vote
    function test_ClearVote_When_Vote_Exists()
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
        // No need, already done here: `test_RegisterAccountWeightAndVote_When_PreviousVotes_TransferedToNewReceiver_Frozen_MaxPoints_Directly`

        // Clear vote
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.ClearedVotes(address(this), 1);
        incentiveVoting.clearVote(address(this));

        // Assertions after
        // Account data
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataFrozenWeightBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 0);
        assertEq(
            incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(1), uint16(DEF.MAX_VOTE)]
        ); // Active vote is not deleted
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), DEF.LOCK_AMOUNT);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), DEF.LOCK_DURATION_W);
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
}
