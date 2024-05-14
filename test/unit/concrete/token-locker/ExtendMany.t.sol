// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {stdError} from "forge-std/StdError.sol";

import {TokenLockerBase} from "../../../../contracts/dependencies/TokenLockerBase.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardTokenLocker} from "../../../utils/WizardTokenLocker.sol";

contract Unit_Concrete_TokenLocker_ExtendMany_ is Unit_Shared_Test_ {
    using WizardTokenLocker for Vm;

    uint256 internal startTime;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

        startTime = coreOwner.START_TIME();
        govToken.approve(address(tokenLocker), UINT256_MAX);
    }

    /*//////////////////////////////////////////////////////////////
                             REVERTING TEST
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_ExtendMany_Because_Frozen()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 5, skipAfter: 0}))
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
    {
        vm.expectRevert("Lock is frozen");
        tokenLocker.extendMany(new TokenLockerBase.ExtendLockData[](0));
    }

    function test_RevertWhen_ExtendMany_Because_EpochIsZero() public {
        TokenLockerBase.ExtendLockData[] memory data = new TokenLockerBase.ExtendLockData[](1);
        data[0] = TokenLockerBase.ExtendLockData({amount: 0, currentEpochs: 0, newEpochs: 0});
        vm.expectRevert("Min 1 epoch");
        tokenLocker.extendMany(data);
    }

    function test_RevertWhen_ExtendMany_Because_DurationIsGreaterThan_MaxLockEpoch() public {
        TokenLockerBase.ExtendLockData[] memory data = new TokenLockerBase.ExtendLockData[](1);
        data[0] =
            TokenLockerBase.ExtendLockData({amount: 0, currentEpochs: 1, newEpochs: tokenLocker.MAX_LOCK_EPOCHS() + 1});
        vm.expectRevert("Exceeds MAX_LOCK_EPOCHS");
        tokenLocker.extendMany(data);
    }

    function test_RevertWhen_ExtendMany_Because_NewEpochIsLessThanCurrentEpoch() public {
        TokenLockerBase.ExtendLockData[] memory data = new TokenLockerBase.ExtendLockData[](1);
        data[0] = TokenLockerBase.ExtendLockData({amount: 0, currentEpochs: 1, newEpochs: 0});
        vm.expectRevert("newEpochs must be greater than epochs");
        tokenLocker.extendMany(data);
    }

    function test_RevertWhen_ExtendMany_Because_NewEpochIsEqualToCurrentEpoch() public {
        TokenLockerBase.ExtendLockData[] memory data = new TokenLockerBase.ExtendLockData[](1);
        data[0] = TokenLockerBase.ExtendLockData({amount: 0, currentEpochs: 1, newEpochs: 1});
        vm.expectRevert("newEpochs must be greater than epochs");
        tokenLocker.extendMany(data);
    }

    function test_RevertWhen_ExtendMany_Because_AmountIsNull() public {
        TokenLockerBase.ExtendLockData[] memory data = new TokenLockerBase.ExtendLockData[](1);
        data[0] = TokenLockerBase.ExtendLockData({amount: 0, currentEpochs: 1, newEpochs: 2});
        vm.expectRevert("Amount must be nonzero");
        tokenLocker.extendMany(data);
    }

    function test_RevertWhen_ExtendMany_Because_NoLockAtExtendedEpoch() public {
        TokenLockerBase.ExtendLockData[] memory data = new TokenLockerBase.ExtendLockData[](1);
        data[0] = TokenLockerBase.ExtendLockData({amount: 1, currentEpochs: 1, newEpochs: 2});
        vm.expectRevert(stdError.arithmeticError);
        tokenLocker.extendMany(data);

        // uint256 changedEpoch = systemEpoch + _epochs;
        // uint256 previous = unlocks[changedEpoch];
        // It will revert here because _amount is previous is null
        // unlocks[changedEpoch] = uint32(previous - _amount);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test many lock, Using following conditions:
    /// - At epoch 0, lockMany: 1 token for 3 epochs and 2 tokens for 5 epochs
    /// - Timejump no epoch
    /// - Extend 1 token unlocking at epoch 3 for 1 epoch and 2 tokens unlocking at epoch 5 for 2 epochs
    function test_ExtendMany_AllPositions_RightAfterLocking()
        public
        lockMany(
            Modifier_LockMany({
                skipBefore: 0,
                user: address(this),
                amountToLock: [1 ether, 2 ether, 0, 0, 0],
                duration: [3, 5, 0, 0, 0],
                skipAfter: 0
            })
        )
    {
        uint256 totalLockedBefore = 1 ether + 2 ether;
        uint256 weightBefore = 1 ether * 3 + 2 ether * 5;
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), totalLockedBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), oldEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 1 ether);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), weightBefore);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0), weightBefore);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 1 ether);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 2 ether);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), totalLockedBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), oldEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
        TokenLockerBase.ExtendLockData[] memory data = new TokenLockerBase.ExtendLockData[](2);
        data[0] = TokenLockerBase.ExtendLockData({amount: 1 ether, currentEpochs: 3, newEpochs: 4});
        data[1] = TokenLockerBase.ExtendLockData({amount: 2 ether, currentEpochs: 5, newEpochs: 7});

        // Start at the beginning of next epoch
        uint256 epochToSkip = 0;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        // Main call
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksExtended(address(this), data);
        tokenLocker.extendMany(data);

        // Assertions after
        uint256 weight = 1 ether * 4 + 2 ether * 7;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), totalLockedBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 4), 1 ether);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 7), 2 ether);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), currentEpoch), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 4), 1 ether);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 7), 2 ether);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), totalLockedBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0); // Should remain the same
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false); // Should remain the same
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 4), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 7), true);
    }

    /// @notice Test many lock, Using following conditions:
    /// - At epoch 0, lockMany: 1 token for 3 epochs,  2 tokens for 5 epochs, 3 tokens for 7 epochs
    /// - Timejump no epoch
    /// - Extend 1 token unlocking at epoch 3 for 1 epoch and 3 tokens unlocking at epoch 7 for 2 epochs
    function test_ExtendMany_PartPosition_RightAfterLocking()
        public
        lockMany(
            Modifier_LockMany({
                skipBefore: 0,
                user: address(this),
                amountToLock: [1 ether, 2 ether, 3 ether, 0, 0],
                duration: [3, 5, 7, 0, 0],
                skipAfter: 0
            })
        )
    {
        uint256 totalLockedBefore = 1 ether + 2 ether + 3 ether;
        uint256 weightBefore = 1 ether * 3 + 2 ether * 5 + 3 ether * 7;
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), totalLockedBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), oldEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 1 ether);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 2 ether);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 7), 3 ether);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), weightBefore);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0), weightBefore);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 1 ether);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 2 ether);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 7), 3 ether);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), totalLockedBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), oldEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 7), true);

        TokenLockerBase.ExtendLockData[] memory data = new TokenLockerBase.ExtendLockData[](2);
        data[0] = TokenLockerBase.ExtendLockData({amount: 1 ether, currentEpochs: 3, newEpochs: 4});
        data[1] = TokenLockerBase.ExtendLockData({amount: 3 ether, currentEpochs: 7, newEpochs: 9});

        // Start at the beginning of next epoch
        uint256 epochToSkip = 0;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        // Main call
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksExtended(address(this), data);
        tokenLocker.extendMany(data);

        // Assertions after
        uint256 weight = 1 ether * 4 + 2 ether * 5 + 3 ether * 9;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), totalLockedBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 4), 1 ether);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 2 ether);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 7), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 9), 3 ether);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 4), 1 ether);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 2 ether);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 7), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 9), 3 ether);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), totalLockedBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0); // Should remain the same
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false); // Should remain the same
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 4), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 7), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 9), true);
    }

    /// @notice Test many lock, Using following conditions:
    /// - At epoch 0, lockMany: 2 token for 3 epochs and 2 tokens for 5 epochs
    /// - Timejump no epoch
    /// - Extend 1 token unlocking at epoch 3 for 1 epoch and 1 tokens unlocking at epoch 5 for 2 epochs
    function test_ExtendMany_AllPositionsPartially_RightAfterLocking()
        public
        lockMany(
            Modifier_LockMany({
                skipBefore: 0,
                user: address(this),
                amountToLock: [2 ether, 2 ether, 0, 0, 0],
                duration: [3, 5, 0, 0, 0],
                skipAfter: 0
            })
        )
    {
        uint256 totalLockedBefore = 2 ether + 2 ether;
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as exactly the same as the test `test_ExtendMany_AllPositions_RightAfterLocking`

        TokenLockerBase.ExtendLockData[] memory data = new TokenLockerBase.ExtendLockData[](2);
        data[0] = TokenLockerBase.ExtendLockData({amount: 1 ether, currentEpochs: 3, newEpochs: 4});
        data[1] = TokenLockerBase.ExtendLockData({amount: 1 ether, currentEpochs: 5, newEpochs: 7});

        // Start at the beginning of next epoch
        uint256 epochToSkip = 0;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        // Main call
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksExtended(address(this), data);
        tokenLocker.extendMany(data);

        // Assertions after
        uint256 weight = 1 ether * 3 + 1 ether * 4 + 1 ether * 5 + 1 ether * 7;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), totalLockedBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 1 ether);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 4), 1 ether);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 1 ether);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 7), 1 ether);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 1 ether);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 4), 1 ether);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 1 ether);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 7), 1 ether);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), totalLockedBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0); // Should remain the same
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false); // Should remain the same
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 4), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 7), true);
    }

    /// @notice Test many lock, Using following conditions:
    /// - At epoch 0, lockMany: 1 token for 3 epochs and 2 tokens for 5 epochs
    /// - Timejump to epoch 2.
    /// - Extend 1 token unlocking at epoch 3 for 1 epoch and 1 tokens unlocking at epoch 5 for 2 epochs
    function test_ExtendMany_AllPositionsPartially_AfterTwoEpochs()
        public
        lockMany(
            Modifier_LockMany({
                skipBefore: 0,
                user: address(this),
                amountToLock: [1 ether, 2 ether, 0, 0, 0],
                duration: [3, 5, 0, 0, 0],
                skipAfter: 0
            })
        )
    {
        uint256 totalLockedBefore = 1 ether + 2 ether;
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as exactly the same as the test `test_ExtendMany_AllPositions_RightAfterLocking`

        TokenLockerBase.ExtendLockData[] memory data = new TokenLockerBase.ExtendLockData[](2);
        data[0] = TokenLockerBase.ExtendLockData({amount: 1 ether, currentEpochs: 1, newEpochs: 2});
        data[1] = TokenLockerBase.ExtendLockData({amount: 1 ether, currentEpochs: 3, newEpochs: 5});

        // Start at the beginning of next epoch
        uint256 epochToSkip = 2;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        // Main call
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksExtended(address(this), data);
        tokenLocker.extendMany(data);

        // Assertions after
        uint256 weight = 1 ether * 2 + 1 ether * 3 + 1 ether * 5;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), totalLockedBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 4), 1 ether);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 1 ether);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 7), 1 ether);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 4), 1 ether);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 1 ether);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 7), 1 ether);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), totalLockedBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0); // Should remain the same
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false); // Should remain the same
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 4), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 6), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 7), true);
    }

    /// @notice Test many lock, Using following conditions:
    /// - At epoch 0, lockMany: 1 token for 3 epochs, 2 tokens for 5 epochs, 3 tokens for 7 epochs
    /// - Timejump to epoch 4.
    /// - Extend 1 token unlocking at epoch 5 for 1 epoch and 3 tokens unlocking at epoch 7 for 2 epochs
    function test_ExtendMany_PartPositionPartially_WhenSingleUnlock()
        public
        lockMany(
            Modifier_LockMany({
                skipBefore: 0,
                user: address(this),
                amountToLock: [1 ether, 2 ether, 3 ether, 0, 0],
                duration: [3, 5, 7, 0, 0],
                skipAfter: 0
            })
        )
    {
        uint256 totalLockedBefore = 1 ether + 2 ether + 3 ether;
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as exactly the same as the test `test_ExtendMany_PartPosition_RightAfterLocking`

        TokenLockerBase.ExtendLockData[] memory data = new TokenLockerBase.ExtendLockData[](2);
        data[0] = TokenLockerBase.ExtendLockData({amount: 1 ether, currentEpochs: 1, newEpochs: 2});
        data[1] = TokenLockerBase.ExtendLockData({amount: 3 ether, currentEpochs: 3, newEpochs: 5});

        // Start at the beginning of next epoch
        uint256 epochToSkip = 4;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;
        uint256 unlockedToken = 1 ether;

        // Main call
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksExtended(address(this), data);
        tokenLocker.extendMany(data);

        // Assertions after
        uint256 weight = 1 ether * 1 + 1 ether * 2 + 3 ether * 5;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), totalLockedBefore - unlockedToken);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 1 ether);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 4), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 1 ether);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 6), 1 ether);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 7), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 8), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 9), 3 ether);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 1 ether);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 4), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 1 ether);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 6), 1 ether);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 7), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 8), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 9), 3 ether);
        // Account lock data
        assertEq(
            vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), totalLockedBefore - unlockedToken
        );
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), unlockedToken);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0); // Should remain the same
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false); // Should remain the same
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 4), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 6), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 7), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 8), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 9), true);
    }

    /// @notice Test many lock, Using following conditions:
    /// - At epoch 0, lockMany: 1 token for 3 epochs, 2 tokens for 5 epochs, 3 tokens for 7 epochs and 4 tokens for epoch 9
    /// - Timejump to epoch 6.
    /// - Extend 3 token unlocking at epoch 7 for 1 epoch and 4 tokens unlocking at epoch 9 for 2 epochs
    function test_ExtendMany_PartPositionFully_WhenMultipleUnlock()
        public
        lockMany(
            Modifier_LockMany({
                skipBefore: 0,
                user: address(this),
                amountToLock: [1 ether, 2 ether, 3 ether, 4 ether, 0],
                duration: [3, 5, 7, 9, 0],
                skipAfter: 0
            })
        )
    {
        uint256 totalLockedBefore = 1 ether + 2 ether + 3 ether + 4 ether;
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as almost the same as the test `test_ExtendMany_PartPosition_RightAfterLocking`

        TokenLockerBase.ExtendLockData[] memory data = new TokenLockerBase.ExtendLockData[](2);
        data[0] = TokenLockerBase.ExtendLockData({amount: 3 ether, currentEpochs: 1, newEpochs: 2});
        data[1] = TokenLockerBase.ExtendLockData({amount: 4 ether, currentEpochs: 3, newEpochs: 5});

        // Start at the beginning of next epoch
        uint256 epochToSkip = 6;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;
        uint256 unlockedToken = 1 ether + 2 ether;

        // Main call
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksExtended(address(this), data);
        tokenLocker.extendMany(data);

        // Assertions after
        uint256 weight = 3 ether * 2 + 4 ether * 5;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), totalLockedBefore - unlockedToken);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 1 ether);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 4), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 2 ether);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 6), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 7), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 8), 3 ether);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 9), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 10), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 11), 4 ether);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 1 ether);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 4), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 2 ether);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 6), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 7), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 8), 3 ether);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 9), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 10), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 11), 4 ether);
        // Account lock data
        assertEq(
            vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), totalLockedBefore - unlockedToken
        );
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), unlockedToken);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0); // Should remain the same
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false); // Should remain the same
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 4), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 6), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 7), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 8), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 9), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 10), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 11), true);
    }

    /// @notice Test many lock, Using following conditions:
    /// - At epoch 0, lockMany: 1 token for 3 epochs, 2 tokens for 5 epochs, 3 tokens for 7 epochs
    /// - Timejump to epoch 2.
    /// - Extend 1 token unlocking at epoch 3 for 5 epochs and 2 tokens unlocking at epoch 5 for 2 epochs
    function test_ExtendMany_PartPositionsFully_OnEpochWithUnlock_WithoutUnlock()
        public
        lockMany(
            Modifier_LockMany({
                skipBefore: 0,
                user: address(this),
                amountToLock: [1 ether, 2 ether, 3 ether, 0, 0],
                duration: [3, 5, 7, 0, 0],
                skipAfter: 0
            })
        )
    {
        uint256 totalLockedBefore = 1 ether + 2 ether + 3 ether;
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as exactly the same as the test `test_ExtendMany_PartPosition_RightAfterLocking`

        TokenLockerBase.ExtendLockData[] memory data = new TokenLockerBase.ExtendLockData[](2);
        data[0] = TokenLockerBase.ExtendLockData({amount: 1 ether, currentEpochs: 1, newEpochs: 5});
        data[1] = TokenLockerBase.ExtendLockData({amount: 2 ether, currentEpochs: 3, newEpochs: 5});

        // Start at the beginning of next epoch
        uint256 epochToSkip = 2;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;
        uint256 unlockedToken = 0;

        // Main call
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksExtended(address(this), data);
        tokenLocker.extendMany(data);

        // Assertions after
        uint256 weight = totalLockedBefore * 5;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), totalLockedBefore - unlockedToken);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 7), totalLockedBefore);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 7), totalLockedBefore);
        // Account lock data
        assertEq(
            vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), totalLockedBefore - unlockedToken
        );
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), unlockedToken);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0); // Should remain the same
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false); // Should remain the same
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 7), true);
    }

    /// @notice Test many lock, Using following conditions:
    /// - At epoch 0, lock: 1 token for 3 epochs
    /// - Timejump to epoch 2.
    /// - Extend 1 token unlocking at epoch 3 for 2 epochs, 1 token unlocking at epoch 5 for 2 epochs and 1 token unlocking at epoch 7 for 3 epochs
    function test_ExtendMany_SinglePositionExtendedMultipleTimeInARow()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 3, skipAfter: 0}))
    {
        uint256 totalLockedBefore = 1 ether;
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as almost the same as the test `Unit_Concrete_TokenLocker_Lock_::test_Lock_InitialLock_FirstEpoch_InFinalHalfOfEpoch`

        TokenLockerBase.ExtendLockData[] memory data = new TokenLockerBase.ExtendLockData[](3);
        data[0] = TokenLockerBase.ExtendLockData({amount: 1 ether, currentEpochs: 1, newEpochs: 3});
        data[1] = TokenLockerBase.ExtendLockData({amount: 1 ether, currentEpochs: 3, newEpochs: 5});
        data[2] = TokenLockerBase.ExtendLockData({amount: 1 ether, currentEpochs: 5, newEpochs: 8});

        // Start at the beginning of next epoch
        uint256 epochToSkip = 2;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;
        uint256 unlockedToken = 0;

        // Main call
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksExtended(address(this), data);
        tokenLocker.extendMany(data);

        // Assertions after
        uint256 weight = totalLockedBefore * 8;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), totalLockedBefore - unlockedToken);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 7), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 10), totalLockedBefore);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 7), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 10), totalLockedBefore);
        // Account lock data
        assertEq(
            vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), totalLockedBefore - unlockedToken
        );
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), unlockedToken);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0); // Should remain the same
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false); // Should remain the same
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 7), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 10), true);
    }
}
