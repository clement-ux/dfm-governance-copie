// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {DefaultValues as DEF} from "../../../utils/DefaultValues.sol";

import {ITokenLocker} from "../../../../contracts/interfaces/ITokenLocker.sol";
import {IncentiveVoting} from "../../../../contracts/IncentiveVoting.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardIncentiveVoting} from "../../../utils/WizardIncentiveVoting.sol";

contract Unit_Concrete_IncentiveVoting_GetReceiverWeightWrite_ is Unit_Shared_Test_ {
    using WizardIncentiveVoting for IncentiveVoting;

    /*//////////////////////////////////////////////////////////////
                            REVERTING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_GetReceiverWeightWrite_Because_IdxIsNull() public {
        vm.expectRevert("Invalid ID");
        incentiveVoting.getReceiverWeightWrite(0);
    }

    function test_RevertWhen_GetReceiverWeightWrite_Because_IdxIsGreaterThan_ReceiverCount()
        public
        addReceiver
        addReceiver
    {
        uint256 count = incentiveVoting.receiverCount();
        vm.expectRevert("Invalid ID");
        incentiveVoting.getReceiverWeightWrite(++count);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test Get receiver weight write with the following conditions:
    /// - Current epoch is equal to last update epoch
    /// - Weight is null
    function test_GetReceiverWeightWrite_When_CurrentEpoch_IsEqualTo_LastUpdate_WeightNull()
        public
        _skip(1 weeks)
        addReceiver
    {
        uint256 epoch = getWeek();
        uint256 lastUpdate = incentiveVoting.getReceiverUpdateEpochBySlotReading(1);

        // Assertions before
        assertEq(epoch, lastUpdate); // Assert we are in the desired situation

        // Main call
        uint256 weight = incentiveVoting.getReceiverWeightWrite(1);

        // Assertions after
        assertEq(weight, 0); // As no vote, no weight at all.
    }

    /// @notice Test Get receiver weight write with the following conditions:
    /// - Current epoch is equal to last update epoch
    /// - Weight is not null as user vote for it
    function test_GetReceiverWeightWrite_When_CurrentEpoch_IsEqualTo_LastUpdate_WeightNotNull()
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
        uint256 epoch = getWeek();
        uint256 lastUpdate = incentiveVoting.getReceiverUpdateEpochBySlotReading(1);
        uint256 weightBSL = incentiveVoting.getReceiverEpochWeightsBySlotReading(1, lastUpdate);

        // Assertions before
        assertEq(epoch, lastUpdate); // Assert we are in the desired situation

        // Main call
        uint256 weight = incentiveVoting.getReceiverWeightWrite(1);

        // Assertions after
        assertGt(weight, 0); // As we have a vote, we have a weight.
        assertEq(weight, DEF.LOCK_AMOUNT * DEF.LOCK_DURATION_W); // As we have a vote, we have a weight.
        assertEq(weight, weightBSL); // Assert returned value is the same as the one in the storage.
    }

    /// @notice Test Get receiver weight write with the following conditions:
    /// - Current epoch is greater than last update epoch
    /// - Weight is null
    function test_GetReceiverWeightWrite_When_CurrentEpoch_IsGreaterThan_LastUpdate_WeightNull()
        public
        _skip(1 weeks)
        addReceiver
    {
        skip(1 weeks); // Skip one more week

        uint256 epoch = getWeek();
        uint256 lastUpdate = incentiveVoting.getReceiverUpdateEpochBySlotReading(1);
        uint256 weightBSL = incentiveVoting.getReceiverEpochWeightsBySlotReading(1, lastUpdate);

        // Assertions before
        assertEq(epoch, 2);
        assertEq(lastUpdate, 1); // Assert we are in the desired situation

        // Main call
        uint256 weight = incentiveVoting.getReceiverWeightWrite(1);

        // Assertions after
        assertEq(weight, 0); // As no vote, no weight at all.
        assertEq(weight, weightBSL); // Assert returned value is the same as the one in the storage.
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), epoch); // Assert the epoch has been updated.
    }

    /// @notice Test Get receiver weight write with the following conditions:
    /// - Current epoch is greater than last update epoch
    /// - Weight is not null as user vote for it
    /// - Call the function after the weight expires
    function test_GetReceiverWeightWrite_When_CurrentEpoch_IsGreaterThan_LastUpdate_WeightNotNull_NotFrozen_UntilWeightExpiring(
    )
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
        uint256 epoch = getWeek();
        uint256 lastUpdate = incentiveVoting.getReceiverUpdateEpochBySlotReading(1);
        assertEq(epoch, 6);
        assertEq(lastUpdate, 1); // Assert we are in the desired situation
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), lastUpdate); // Assert the epoch hasn't been updated.
        assertEq(
            incentiveVoting.getReceiverEpochWeightsBySlotReading(1, lastUpdate), DEF.LOCK_AMOUNT * DEF.LOCK_DURATION_W
        ); // Assert we have a weight.
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(1), DEF.LOCK_AMOUNT); // Assert we have a decay rate.

        uint256 weight = incentiveVoting.getReceiverWeightWrite(1);

        assertEq(weight, 0); // We reached the expiration date, so we have a no weight.
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), epoch); // Assert the epoch has been updated.
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(1, epoch), 0); // Assert we have no weight.
        assertEq(
            incentiveVoting.getReceiverEpochWeightsBySlotReading(1, 5), DEF.LOCK_AMOUNT * (DEF.LOCK_DURATION_W - 4)
        );
        assertEq(
            incentiveVoting.getReceiverEpochWeightsBySlotReading(1, 4), DEF.LOCK_AMOUNT * (DEF.LOCK_DURATION_W - 3)
        );
        assertEq(
            incentiveVoting.getReceiverEpochWeightsBySlotReading(1, 3), DEF.LOCK_AMOUNT * (DEF.LOCK_DURATION_W - 2)
        );
        assertEq(
            incentiveVoting.getReceiverEpochWeightsBySlotReading(1, 2), DEF.LOCK_AMOUNT * (DEF.LOCK_DURATION_W - 1)
        );
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(1), 0); // Assert we have no decay rate.
    }

    /// @notice Test Get receiver weight write with the following conditions:
    /// - Current epoch is greater than last update epoch
    /// - Weight is not null as user vote for it
    /// - Call the function before the weight expires
    function test_GetReceiverWeightWrite_When_CurrentEpoch_IsGreaterThan_LastUpdate_WeightNotNull_NotFrozen_BeforeWeightExpiring(
    )
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
                skipAfter: (DEF.LOCK_DURATION_W - 2) * 1 weeks
            })
        )
    {
        uint256 epoch = getWeek();
        uint256 lastUpdate = incentiveVoting.getReceiverUpdateEpochBySlotReading(1);

        // Assertions before
        assertEq(epoch, 4);
        assertEq(lastUpdate, 1); // Assert we are in the desired situation
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), lastUpdate); // Assert the epoch hasn't been updated.
        assertEq(
            incentiveVoting.getReceiverEpochWeightsBySlotReading(1, lastUpdate), DEF.LOCK_AMOUNT * DEF.LOCK_DURATION_W
        ); // Assert we have a weight.
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(1), DEF.LOCK_AMOUNT); // Assert we have a decay rate.

        // Main call
        uint256 weight = incentiveVoting.getReceiverWeightWrite(1);

        // Assertions after
        assertEq(weight, DEF.LOCK_AMOUNT * 2); // We didn't reached the expiration date, so we have a weight.
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), epoch); // Assert the epoch has been updated.
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(1, epoch), DEF.LOCK_AMOUNT * 2); // Assert we have no weight.
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(1), DEF.LOCK_AMOUNT); // Assert we have no decay rate.
    }

    /// @notice Test Get receiver weight write with the following conditions:
    /// - Current epoch is greater than last update epoch
    /// - Weight is not null as user vote for it
    /// - Lock are frozen
    function test_GetReceiverWeightWrite_When_CurrentEpoch_IsGreaterThan_LastUpdate_WeightNotNull_Frozen()
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
                skipAfter: 3 * 1 weeks
            })
        )
    {
        uint256 epoch = getWeek();
        uint256 lastUpdate = incentiveVoting.getReceiverUpdateEpochBySlotReading(1);
        uint256 maxLocks = tokenLocker.MAX_LOCK_EPOCHS();

        // Assertions before
        assertEq(epoch, 4);
        assertEq(lastUpdate, 1); // Assert we are in the desired situation
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), lastUpdate); // Assert the epoch hasn't been updated.
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(1, lastUpdate), DEF.LOCK_AMOUNT * maxLocks); // Assert we have a weight.
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(1), 0); // No decay as frozen

        // Main call
        uint256 weight = incentiveVoting.getReceiverWeightWrite(1);

        // Assertions after
        assertEq(weight, DEF.LOCK_AMOUNT * maxLocks);
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), epoch); // Assert the epoch has been updated.
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(1, epoch), weight); // Same weight as frozen.
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(1, epoch - 1), weight); // Same weight as frozen.
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(1, epoch - 2), weight); // Same weight as frozen.
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(1, epoch - 3), weight); // Same weight as frozen.
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(1), 0); // No decay as frozen
    }
}
