// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {DefaultValues as DEF} from "../../../utils/DefaultValues.sol";

import {ITokenLocker} from "../../../../contracts/interfaces/ITokenLocker.sol";
import {IncentiveVoting} from "../../../../contracts/IncentiveVoting.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardIncentiveVoting} from "../../../utils/WizardIncentiveVoting.sol";

contract Unit_Concrete_IncentiveVoting_Unfreeze_ is Unit_Shared_Test_ {
    using WizardIncentiveVoting for IncentiveVoting;

    /*//////////////////////////////////////////////////////////////
                            REVERTING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_Unfreeze_Because_NotTokenLocker() public {
        vm.expectRevert("Only TokenLocker");
        incentiveVoting.unfreeze(address(this), false);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test Unfreeze vote under following conditions:
    /// - Not Frozen
    /// - Nothing happens, but true is returned
    function test_Unfreeze_When_NotFrozen() public asTokenLocker {
        assertTrue(incentiveVoting.unfreeze(address(this), false));
    }

    /// @notice Test Unfreeze vote under following conditions:
    /// - Lock 1 ether of token for 5 weeks on TokenLocker
    /// - Freeze account
    /// - Register account weight and without voting
    /// - Vote are not kept
    function test_Unfreeze_When_NoVote()
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
                skipAfter: 1 weeks
            })
        )
        asTokenLocker
    {
        // Assertions before
        // No need to add assertions before, as almost same as `test_RegisterAccountWeightAndVote_When_NoPreviousVotes_SingleVote_Frozen_MaxPoints`.

        // Expected event
        ITokenLocker.LockData[] memory lock = new ITokenLocker.LockData[](1);
        lock[0] = ITokenLocker.LockData({amount: DEF.LOCK_AMOUNT, epochsToUnlock: tokenLocker.MAX_LOCK_EPOCHS()});
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.AccountWeightRegistered(address(this), 2, 0, lock);

        // Main call
        assertTrue(incentiveVoting.unfreeze(address(this), false));

        // Assertions after
        // Account data
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), 2);
        assertEq(incentiveVoting.getLockDataFrozenWeightBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(0), uint16(0)]); // Active vote are not deleted
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), DEF.LOCK_AMOUNT);
        assertEq(
            incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), tokenLocker.MAX_LOCK_EPOCHS()
        );
        // Receiver data
        // No receiver
        // Total data
        assertEq(incentiveVoting.getTotalDecayRateBySlotReading(), 0);
        assertEq(incentiveVoting.getTotalUpdateEpochBySlotReading(), 0);
        assertEq(incentiveVoting.getTotalEpochWeightsBySlotReading(1), 0);
        assertEq(incentiveVoting.getTotalEpochUnlocksBySlotReading(1), 0);
    }

    /// @notice Test Unfreeze vote under following conditions:
    /// - Lock 1 ether of token for 5 weeks on TokenLocker
    /// - Freeze account
    /// - Register account weight and vote 100% of max points
    /// - Vote are not kept
    function test_Unfreeze_When_Vote_NotKeeped()
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
                skipAfter: 1 weeks
            })
        )
        asTokenLocker
    {
        // Assertions before
        // No need to add assertions before, as almost same as `test_RegisterAccountWeightAndVote_When_PreviousVotes_TransferedToNewReceiver_Frozen_MaxPoints_Directly`.

        ITokenLocker.LockData[] memory lock = new ITokenLocker.LockData[](1);
        lock[0] = ITokenLocker.LockData({amount: DEF.LOCK_AMOUNT, epochsToUnlock: tokenLocker.MAX_LOCK_EPOCHS()});

        // Expected event
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.ClearedVotes(address(this), 2);
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.AccountWeightRegistered(address(this), 2, 0, lock);

        // Main call
        assertTrue(incentiveVoting.unfreeze(address(this), false));

        // Assertions after
        // Account data
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), 2);
        assertEq(incentiveVoting.getLockDataFrozenWeightBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 0);
        assertEq(
            incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(1), uint16(DEF.MAX_VOTE)]
        ); // Active vote are not deleted
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), DEF.LOCK_AMOUNT); // Not deleted
        assertEq(
            incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), tokenLocker.MAX_LOCK_EPOCHS()
        ); // Not deleted
        // Receiver data
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(1), 0);
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), 2);
        assertEq(incentiveVoting.getReceiverEpochWeightsBySlotReading(1, 2), 0);
        assertEq(incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, 2), 0);
        // Total data
        assertEq(incentiveVoting.getTotalDecayRateBySlotReading(), 0);
        assertEq(incentiveVoting.getTotalUpdateEpochBySlotReading(), 2);
        assertEq(incentiveVoting.getTotalEpochWeightsBySlotReading(2), 0);
        assertEq(incentiveVoting.getTotalEpochUnlocksBySlotReading(2), 0);
    }

    /// @notice Test Unfreeze vote under following conditions:
    /// - Lock 1 ether of token for 5 weeks on TokenLocker
    /// - Freeze account
    /// - Register account weight and vote 100% of max points
    /// - Vote are kept
    function test_Unfreeze_When_Vote_Keeped()
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
                skipAfter: 1 weeks
            })
        )
        asTokenLocker
    {
        // Assertions before
        // No need to add assertions before, as almost same as `test_Unfreeze_When_Vote_NotKeeped`.

        ITokenLocker.LockData[] memory lock = new ITokenLocker.LockData[](1);
        lock[0] = ITokenLocker.LockData({amount: DEF.LOCK_AMOUNT, epochsToUnlock: tokenLocker.MAX_LOCK_EPOCHS()});

        // Expected event
        vm.expectEmit({emitter: address(incentiveVoting)});
        emit IncentiveVoting.AccountWeightRegistered(address(this), 2, 0, lock);

        // Main call
        assertTrue(incentiveVoting.unfreeze(address(this), true));

        // Assertions after
        // Account data
        assertEq(incentiveVoting.getLockDataEpochBySlotReading(address(this)), 2);
        assertEq(incentiveVoting.getLockDataFrozenWeightBySlotReading(address(this)), 0);
        assertEq(incentiveVoting.getLockDataPointsBySlotReading(address(this)), DEF.MAX_VOTE);
        assertEq(incentiveVoting.getLockDataLockLengthBySlotReading(address(this)), 1);
        assertEq(incentiveVoting.getLockDataVoteLengthBySlotReading(address(this)), 1);
        assertEq(
            incentiveVoting.getLockDataActiveVotesBySlotReading(address(this), 1), [uint16(1), uint16(DEF.MAX_VOTE)]
        ); // Active vote are not deleted
        assertEq(incentiveVoting.getLockDataLockedAmountsBySlotReading(address(this), 0), DEF.LOCK_AMOUNT); // Not deleted
        assertEq(
            incentiveVoting.getLockDataEpochsToUnlockBySlotReading(address(this), 0), tokenLocker.MAX_LOCK_EPOCHS()
        ); // Not deleted
        // Receiver data
        assertEq(incentiveVoting.getReceiverDecayRateBySlotReading(1), DEF.LOCK_AMOUNT);
        assertEq(incentiveVoting.getReceiverUpdateEpochBySlotReading(1), 2);
        assertEq(
            incentiveVoting.getReceiverEpochWeightsBySlotReading(1, 2), DEF.LOCK_AMOUNT * tokenLocker.MAX_LOCK_EPOCHS()
        );
        assertEq(
            incentiveVoting.getReceiverEpocUnlocksBySlotReading(1, 2 + tokenLocker.MAX_LOCK_EPOCHS()), DEF.LOCK_AMOUNT
        );
        // Total data
        assertEq(incentiveVoting.getTotalDecayRateBySlotReading(), DEF.LOCK_AMOUNT);
        assertEq(incentiveVoting.getTotalUpdateEpochBySlotReading(), 2);
        assertEq(incentiveVoting.getTotalEpochWeightsBySlotReading(2), DEF.LOCK_AMOUNT * tokenLocker.MAX_LOCK_EPOCHS());
        assertEq(incentiveVoting.getTotalEpochUnlocksBySlotReading(2 + tokenLocker.MAX_LOCK_EPOCHS()), DEF.LOCK_AMOUNT);
    }
}
