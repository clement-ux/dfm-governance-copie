// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {DefaultValues as DEF} from "../../../utils/DefaultValues.sol";

import {ITokenLocker} from "../../../../contracts/interfaces/ITokenLocker.sol";
import {IncentiveVoting} from "../../../../contracts/IncentiveVoting.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardIncentiveVoting} from "../../../utils/WizardIncentiveVoting.sol";

contract Unit_Concrete_IncentiveVoting_GetReceiverWeightAt_ is Unit_Shared_Test_ {
    using WizardIncentiveVoting for IncentiveVoting;

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetReceiverWeightAt_When_WrongId() public view {
        assertEq(incentiveVoting.getReceiverWeightAt(incentiveVoting.receiverCount() + 1, 1), 0);
    }

    function test_GetReceiverWeightAt_When_Epoch_IsLowerThan_LastUpdate()
        public
        lock(
            Modifier_Lock({
                skipBefore: 0,
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
                skipAfter: 5 weeks
            })
        )
    {
        incentiveVoting.getReceiverWeightWrite(1); // Update the weight

        uint256 epoch = 3;
        assertLt(epoch, incentiveVoting.getReceiverUpdateEpochBySlotReading(1));
        // Main call
        uint256 weight = incentiveVoting.getReceiverWeightAt(1, epoch);

        uint256 targetWeight = DEF.LOCK_AMOUNT * (DEF.LOCK_DURATION_W - epoch);
        assertEq(weight, targetWeight);
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(1, epoch), targetWeight);
    }

    function test_GetReceiverWeightAt_When_Epoch_IsEqualTo_LastUpdate()
        public
        lock(
            Modifier_Lock({
                skipBefore: 0,
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
                skipAfter: 3 weeks
            })
        )
    {
        incentiveVoting.getReceiverWeightWrite(1); // Update the weight

        uint256 epoch = 3;
        assertEq(epoch, incentiveVoting.getReceiverUpdateEpochBySlotReading(1));
        // Main call
        uint256 weight = incentiveVoting.getReceiverWeightAt(1, epoch);

        uint256 targetWeight = DEF.LOCK_AMOUNT * (DEF.LOCK_DURATION_W - epoch);
        assertEq(weight, targetWeight);
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(1, epoch), targetWeight);
    }

    function test_GetReceiverWeightAt_When_Epoch_IsGreaterThan_LastUpdate_NoWeight()
        public
        lock(
            Modifier_Lock({
                skipBefore: 0,
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
                skipAfter: 3 weeks
            })
        )
    {
        uint256 epoch = 4;
        assertGt(epoch, incentiveVoting.getReceiverUpdateEpochBySlotReading(1));
        // Main call
        uint256 weight = incentiveVoting.getReceiverWeightAt(1, epoch);

        assertEq(weight, 0);
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(1, epoch), 0);
    }

    function test_GetReceiverWeightAt_When_Epoch_IsGreaterThan_LastUpdate_WithWeight()
        public
        lock(
            Modifier_Lock({
                skipBefore: 0,
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
                skipAfter: 3 weeks
            })
        )
    {
        uint256 epoch = 4;
        assertGt(epoch, incentiveVoting.getReceiverUpdateEpochBySlotReading(1));
        // Main call
        uint256 weight = incentiveVoting.getReceiverWeightAt(1, epoch);
        uint256 targetWeight = DEF.LOCK_AMOUNT * (DEF.LOCK_DURATION_W - epoch);

        assertEq(weight, targetWeight);
    }

    // Useless test, just for coverage
    function test_GetReceiverWeight() public view {
        assertEq(incentiveVoting.getReceiverWeight(1), 0);
    }
}
