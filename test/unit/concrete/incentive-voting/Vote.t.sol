// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {DefaultValues as DEF} from "../../../utils/DefaultValues.sol";

import {ITokenLocker} from "../../../../contracts/interfaces/ITokenLocker.sol";
import {IncentiveVoting} from "../../../../contracts/IncentiveVoting.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardIncentiveVoting} from "../../../utils/WizardIncentiveVoting.sol";

contract Unit_Concrete_IncentiveVoting_Vote_ is Unit_Shared_Test_ {
    using WizardIncentiveVoting for IncentiveVoting;

    /*//////////////////////////////////////////////////////////////
                            REVERTING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test that the function reverts when the user has no registered weight (frozen or locked)
    function test_RevertWhen_Vote_Because_NoFrozenWeight_And_NoLock() public {
        vm.expectRevert("No registered weight");
        incentiveVoting.vote(address(this), new IncentiveVoting.Vote[](0), false);
    }

    /// @notice Test that the function reverts when lock is expired
    function test_RevertWhen_Vote_Because_RegisteredWeightExpired()
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
                skipAfter: (DEF.LOCK_DURATION_W) * 1 weeks
            })
        )
    {
        vm.expectRevert("Registered weight has expired");
        incentiveVoting.vote(address(this), new IncentiveVoting.Vote[](1), false);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test Vote under following conditions:
    /// - Lock 1 ether of token for 5 weeks on TokenLocker
    /// - Register new receiver
    /// - Register account weight without voting
    /// - Vote with 1 vote, 100% into first receiver
    function test_Vote_NoClear_NoOverlap_FirstVote()
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
        uint256 epoch = 1;

        // Assertions before
        assertEq(getWeek(), epoch);
        // Account data
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), epoch);
        assertEq(incentiveVoting.getLockDataFrozenWeightBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(0), uint16(0)]);
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), DEF.LOCK_AMOUNT);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), DEF.LOCK_DURATION_W);
        // Receiver data
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(1), 0); // No votes
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), epoch); // No votes
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(1, epoch), 0); // No votes
        assertEq(incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, epoch), 0); // No votes
        // Total data
        assertEq(incentiveVoting.getTotalDecayRateBySlotReading(), 0); // No votes
        assertEq(incentiveVoting.getTotalUpdateEpochBySlotReading(), 0); // No votes
        assertEq(incentiveVoting.getTotalEpochWeightsBySlotReading(epoch), 0); // No votes
        assertEq(incentiveVoting.getTotalEpochUnlocksBySlotReading(epoch), 0); // No votes

        IncentiveVoting.Vote[] memory votes = new IncentiveVoting.Vote[](1);
        votes[0] = IncentiveVoting.Vote({id: 1, points: DEF.MAX_VOTE});

        // Expected events
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.NewVotes(address(this), 1, votes, votes[0].points);

        // Main call
        incentiveVoting.vote(address(this), votes, false);

        // Assertions after
        assertEq(getWeek(), epoch);
        // Account data
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), epoch);
        assertEq(incentiveVoting.getLockDataFrozenWeightBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), votes[0].points);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 1);
        assertEq(
            incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(1), uint16(votes[0].points)]
        );
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), DEF.LOCK_AMOUNT);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), DEF.LOCK_DURATION_W);
        // Receiver data
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(1), DEF.LOCK_AMOUNT * votes[0].points / DEF.MAX_VOTE);
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), epoch);
        assertEq(
            incentiveVoting.getReceiverEpochWeightsBySlotReading(1, epoch),
            DEF.LOCK_AMOUNT * votes[0].points / DEF.MAX_VOTE * DEF.LOCK_DURATION_W
        );
        assertEq(incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, epoch), 0);
        assertEq(
            incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, epoch + DEF.LOCK_DURATION_W),
            DEF.LOCK_AMOUNT * votes[0].points / DEF.MAX_VOTE
        );
        // Total data
        assertEq(incentiveVoting.getTotalDecayRateBySlotReading(), DEF.LOCK_AMOUNT * votes[0].points / DEF.MAX_VOTE);
        assertEq(incentiveVoting.getTotalUpdateEpochBySlotReading(), epoch);
        assertEq(
            incentiveVoting.getTotalEpochWeightsBySlotReading(epoch),
            DEF.LOCK_AMOUNT * votes[0].points / DEF.MAX_VOTE * DEF.LOCK_DURATION_W
        );
        assertEq(incentiveVoting.getTotalEpochUnlocksBySlotReading(epoch), 0);
    }

    /// @notice Test Vote under following conditions:
    /// - Lock 1 ether of token for 5 weeks on TokenLocker
    /// - Register 2 new receivers
    /// - Register account weight and vote 10% for receiver 1
    /// - Vote 20% for receiver 2
    function test_Vote_NoClear_NoOverlap_SecondVote()
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
        addReceiver
        registerAccountWeightAndVote(
            Modifier_RegisterAccountWeightAndVote({
                skipBefore: 0,
                account: address(this),
                minEpochs: 0,
                votes: [
                    [uint256(1), uint256(DEF.MAX_VOTE / 10)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)]
                ],
                skipAfter: 0
            })
        )
    {
        uint256 epoch = 1;

        // Assertions before
        assertEq(getWeek(), epoch);
        // Account data
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), epoch);
        assertEq(incentiveVoting.getLockDataFrozenWeightBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), DEF.MAX_VOTE / 10);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 1);
        assertEq(
            incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1),
            [uint16(1), uint16(DEF.MAX_VOTE / 10)]
        );
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), DEF.LOCK_AMOUNT);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), DEF.LOCK_DURATION_W);
        // Receiver data
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(1), DEF.LOCK_AMOUNT / 10);
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), epoch);
        assertEq(
            incentiveVoting.getReceiverEpochWeightsBySlotReading(1, epoch), DEF.LOCK_AMOUNT / 10 * DEF.LOCK_DURATION_W
        );
        assertEq(incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, epoch), 0);
        assertEq(
            incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, epoch + DEF.LOCK_DURATION_W), DEF.LOCK_AMOUNT / 10
        );
        // Total data
        assertEq(incentiveVoting.getTotalDecayRateBySlotReading(), DEF.LOCK_AMOUNT / 10);
        assertEq(incentiveVoting.getTotalUpdateEpochBySlotReading(), epoch);
        assertEq(incentiveVoting.getTotalEpochWeightsBySlotReading(epoch), DEF.LOCK_AMOUNT / 10 * DEF.LOCK_DURATION_W);
        assertEq(incentiveVoting.getTotalEpochUnlocksBySlotReading(epoch), 0);

        IncentiveVoting.Vote[] memory votes = new IncentiveVoting.Vote[](1);
        votes[0] = IncentiveVoting.Vote({id: 2, points: DEF.MAX_VOTE * 2 / 10});
        uint256 previousPoints = DEF.MAX_VOTE / 10;
        uint256 totalPoints = votes[0].points + previousPoints;

        // Expected events
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.NewVotes(address(this), 1, votes, totalPoints);

        // Main call
        incentiveVoting.vote(address(this), votes, false);

        // Assertions after
        // Account data
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), epoch);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), totalPoints);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 2);
        assertEq(
            incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(1), uint16(previousPoints)]
        );
        assertEq(
            incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 2), [uint16(2), uint16(votes[0].points)]
        );
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), DEF.LOCK_AMOUNT);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), DEF.LOCK_DURATION_W);
        // Receiver data
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(1), DEF.LOCK_AMOUNT * previousPoints / DEF.MAX_VOTE);
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), epoch);
        assertEq(
            incentiveVoting.getReceiverEpochWeightsBySlotReading(1, epoch),
            DEF.LOCK_AMOUNT * previousPoints / DEF.MAX_VOTE * DEF.LOCK_DURATION_W
        );
        assertEq(incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, epoch), 0);
        assertEq(
            incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, epoch + DEF.LOCK_DURATION_W),
            DEF.LOCK_AMOUNT * previousPoints / DEF.MAX_VOTE
        );
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(2), DEF.LOCK_AMOUNT * votes[0].points / DEF.MAX_VOTE);
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(2), epoch);
        assertEq(
            incentiveVoting.getReceiverEpochWeightsBySlotReading(2, epoch),
            DEF.LOCK_AMOUNT * votes[0].points / DEF.MAX_VOTE * DEF.LOCK_DURATION_W
        );
        assertEq(incentiveVoting.getReceiverEpocUnlocksBySlotReading(2, epoch), 0);
        assertEq(
            incentiveVoting.getReceiverEpocUnlocksBySlotReading(2, epoch + DEF.LOCK_DURATION_W),
            DEF.LOCK_AMOUNT * votes[0].points / DEF.MAX_VOTE
        );
        // Total data
        assertEq(
            incentiveVoting.getTotalDecayRateBySlotReading(),
            DEF.LOCK_AMOUNT * previousPoints / DEF.MAX_VOTE + DEF.LOCK_AMOUNT * votes[0].points / DEF.MAX_VOTE
        );
        assertEq(incentiveVoting.getTotalUpdateEpochBySlotReading(), epoch);
        assertEq(
            incentiveVoting.getTotalEpochWeightsBySlotReading(epoch),
            DEF.LOCK_AMOUNT * previousPoints / DEF.MAX_VOTE * DEF.LOCK_DURATION_W
                + DEF.LOCK_AMOUNT * votes[0].points / DEF.MAX_VOTE * DEF.LOCK_DURATION_W
        );
        assertEq(incentiveVoting.getTotalEpochUnlocksBySlotReading(epoch), 0);
    }

    /// @notice Test Vote under following conditions:
    /// - Lock 1 ether of token for 5 weeks on TokenLocker
    /// - Register new receiver
    /// - Register account weight and vote 10% for receiver 1
    /// - Vote with 20% for receiver 1. Total should be 30%.
    /// - However, it is seen as two different votes.
    function test_Vote_NoClear_WithOverlap()
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
                    [uint256(1), uint256(DEF.MAX_VOTE / 10)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)]
                ],
                skipAfter: 0
            })
        )
    {
        uint256 epoch = 1;
        // Assertions before
        // No need to add more assertions, they are already tested in `test_Vote_NoClear_NoOverlap_SecondVote`.

        IncentiveVoting.Vote[] memory votes = new IncentiveVoting.Vote[](1);
        votes[0] = IncentiveVoting.Vote({id: 1, points: DEF.MAX_VOTE * 2 / 10});
        uint256 previousPoints = DEF.MAX_VOTE / 10;
        uint256 totalPoints = votes[0].points + previousPoints;

        // Expected events
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.NewVotes(address(this), 1, votes, totalPoints);

        // Main call
        incentiveVoting.vote(address(this), votes, false);

        // Assertions after
        assertEq(getWeek(), epoch);
        // Account data
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), epoch);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), totalPoints);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 2);
        assertEq(
            incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(1), uint16(previousPoints)]
        );
        assertEq(
            incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 2), [uint16(1), uint16(votes[0].points)]
        );
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), DEF.LOCK_AMOUNT);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), DEF.LOCK_DURATION_W);
        // Receiver data
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(1), DEF.LOCK_AMOUNT * totalPoints / DEF.MAX_VOTE);
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), epoch);
        assertEq(
            incentiveVoting.getReceiverEpochWeightsBySlotReading(1, epoch),
            DEF.LOCK_AMOUNT * totalPoints / DEF.MAX_VOTE * DEF.LOCK_DURATION_W
        );
        assertEq(incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, epoch), 0);
        assertEq(
            incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, epoch + DEF.LOCK_DURATION_W),
            DEF.LOCK_AMOUNT * totalPoints / DEF.MAX_VOTE
        );
        // Total data
        assertEq(incentiveVoting.getTotalDecayRateBySlotReading(), DEF.LOCK_AMOUNT * totalPoints / DEF.MAX_VOTE);
        assertEq(incentiveVoting.getTotalUpdateEpochBySlotReading(), epoch);
        assertEq(
            incentiveVoting.getTotalEpochWeightsBySlotReading(epoch),
            DEF.LOCK_AMOUNT * totalPoints / DEF.MAX_VOTE * DEF.LOCK_DURATION_W
        );
        assertEq(incentiveVoting.getTotalEpochUnlocksBySlotReading(epoch), 0);
    }

    /// @notice Test Vote under following conditions:
    /// - Lock 1 ether of token for 5 weeks on TokenLocker
    /// - Register new receiver
    /// - Register account weight and vote 10% for receiver 1
    /// - Clear previous vote and vote with 20% for receiver 1. Total should be 20%.
    function test_Vote_Clear()
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
                    [uint256(1), uint256(DEF.MAX_VOTE / 10)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)]
                ],
                skipAfter: 0
            })
        )
    {
        uint256 epoch = 1;
        // Assertions before
        // No need to add more assertions, they are already tested in `test_Vote_NoClear_NoOverlap_SecondVote`.

        IncentiveVoting.Vote[] memory votes = new IncentiveVoting.Vote[](1);
        votes[0] = IncentiveVoting.Vote({id: 1, points: DEF.MAX_VOTE * 2 / 10});

        // Expected events
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.NewVotes(address(this), 1, votes, votes[0].points);

        // Main call
        incentiveVoting.vote(address(this), votes, true);

        // Assertions after
        // Account data
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), epoch);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), votes[0].points);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 1);
        assertEq(
            incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(1), uint16(votes[0].points)]
        );
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), DEF.LOCK_AMOUNT);
        assertEq(incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), DEF.LOCK_DURATION_W);
        // Receiver data
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(1), DEF.LOCK_AMOUNT * votes[0].points / DEF.MAX_VOTE);
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), epoch);
        assertEq(
            incentiveVoting.getReceiverEpochWeightsBySlotReading(1, epoch),
            DEF.LOCK_AMOUNT * votes[0].points / DEF.MAX_VOTE * DEF.LOCK_DURATION_W
        );
        assertEq(incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, epoch), 0);
        assertEq(
            incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, epoch + DEF.LOCK_DURATION_W),
            DEF.LOCK_AMOUNT * votes[0].points / DEF.MAX_VOTE
        );
        // Total data
        assertEq(incentiveVoting.getTotalDecayRateBySlotReading(), DEF.LOCK_AMOUNT * votes[0].points / DEF.MAX_VOTE);
        assertEq(incentiveVoting.getTotalUpdateEpochBySlotReading(), epoch);
        assertEq(
            incentiveVoting.getTotalEpochWeightsBySlotReading(epoch),
            DEF.LOCK_AMOUNT * votes[0].points / DEF.MAX_VOTE * DEF.LOCK_DURATION_W
        );
        assertEq(incentiveVoting.getTotalEpochUnlocksBySlotReading(epoch), 0);
        
    }
}
