// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {DefaultValues as DEF} from "../../../utils/DefaultValues.sol";

import {ITokenLocker} from "../../../../contracts/interfaces/ITokenLocker.sol";
import {IncentiveVoting} from "../../../../contracts/IncentiveVoting.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardIncentiveVoting} from "../../../utils/WizardIncentiveVoting.sol";

contract Unit_Concrete_IncentiveVoting_GetReceiverVotePct_ is Unit_Shared_Test_ {
    using WizardIncentiveVoting for IncentiveVoting;

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test `getReceiverVotePct` when no votes
    function test_GetReceiverVotePct_WhenNoVotes() public _skip(2 weeks) addReceiver {
        assertEq(incentiveVoting.getReceiverVotePct(1, 2), 0);
    }

    /// @notice Test `getReceiverVotePct` with the following conditions:
    /// - Frozen account
    /// - 1 vote with 100% of the votes for receiver 1 at epoch 1
    function test_GetReceiverVotePct_When_FullVotes()
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
                skipAfter: 2 weeks
            })
        )
    {
        uint256 amount = DEF.LOCK_AMOUNT * DEF.MAX_VOTE / DEF.MAX_VOTE;
        uint256 weight = amount * tokenLocker.MAX_LOCK_EPOCHS();

        // Main call
        uint256 vote = incentiveVoting.getReceiverVotePct(1, 2);

        assertEq(vote, 1e18);
        assertEq(incentiveVoting.getTotalEpochWeightsBySlotReading(2), weight);
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(1, 2), weight);
    }

    /// @notice Test `getReceiverVotePct` with the following conditions:
    /// - Frozen account
    /// - 2 votes with 70% and 30% of the votes for receiver 1 and 2 at epoch 1
    function test_GetReceiverVotePct_When_SplitVotes()
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
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
        registerAccountWeightAndVote(
            Modifier_RegisterAccountWeightAndVote({
                skipBefore: 0,
                account: address(this),
                minEpochs: 0,
                votes: [
                    [uint256(1), uint256(DEF.MAX_VOTE * 7 / 10)],
                    [uint256(2), uint256(DEF.MAX_VOTE * 3 / 10)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)],
                    [uint256(0), uint256(0)]
                ],
                skipAfter: 2 weeks
            })
        )
    {
        uint256 amount1 = DEF.LOCK_AMOUNT * (DEF.MAX_VOTE * 7 / 10) / DEF.MAX_VOTE;
        uint256 amount2 = DEF.LOCK_AMOUNT * (DEF.MAX_VOTE * 3 / 10) / DEF.MAX_VOTE;
        uint256 weight1 = amount1 * tokenLocker.MAX_LOCK_EPOCHS();
        uint256 weight2 = amount2 * tokenLocker.MAX_LOCK_EPOCHS();

        // Main call
        uint256 vote1 = incentiveVoting.getReceiverVotePct(1, 2);
        uint256 vote2 = incentiveVoting.getReceiverVotePct(2, 2);

        assertEq(vote1, 7e17);
        assertEq(vote2, 3e17);
        assertEq(incentiveVoting.getTotalEpochWeightsBySlotReading(2), weight1 + weight2);
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(1, 2), weight1);
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(2, 2), weight2);
    }
}
