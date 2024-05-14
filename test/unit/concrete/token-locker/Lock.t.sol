// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";

import {TokenLocker} from "../../../../contracts/TokenLocker.sol";
import {TokenLockerBase} from "../../../../contracts/dependencies/TokenLockerBase.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardTokenLocker} from "../../../utils/WizardTokenLocker.sol";

contract Unit_Concrete_TokenLocker_Lock_ is Unit_Shared_Test_ {
    using WizardTokenLocker for Vm;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();
        govToken.approve(address(tokenLocker), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                             REVERTING TEST
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_Lock_Because_EpochIsNull() public {
        vm.expectRevert("Min 1 epoch");
        tokenLocker.lock(alice, 1, 0);
    }

    function test_RevertWhen_Lock_Because_AmountIsZero() public {
        vm.expectRevert("Amount must be nonzero");
        tokenLocker.lock(alice, 0, 1);
    }

    function test_RevertWhen_Lock_Because_EpochIsGreaterThanMaxEpoch() public {
        uint256 maxEpoch = tokenLocker.MAX_LOCK_EPOCHS();
        vm.expectRevert("Exceeds MAX_LOCK_EPOCHS");
        tokenLocker.lock(alice, 1, maxEpoch + 1);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice This test is performed under the following conditions:
    /// - on _epochWeightWrite: accountEpoch == systemEpoch.
    /// - on getTotalWeightWrite: weight == 0.
    /// - on _lock: block.timestamp is in the final half of the epoch.
    /// - on _lock:  previous == 0. (i.e. there is not lock expiring at the same epoch that user new lock expired).
    function test_Lock_InitialLock_FirstEpoch_InFinalHalfOfEpoch() public {
        // --- Assertions before --- //
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 2), 0);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), 0);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 2), 0);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 0), false);

        // --- Main call --- //
        uint256 amountToLock = 1 ether;
        deal(address(govToken), address(this), amountToLock);
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LockCreated(address(this), amountToLock, 2);
        tokenLocker.lock(address(this), amountToLock, 1);

        // --- Assertions after --- //
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountToLock);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 2), amountToLock);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), amountToLock * 2);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0), amountToLock * 2);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 2), amountToLock);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountToLock);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 2), true);
    }

    /// @notice This test is performed under the following conditions:
    /// Exactly the same as `test_Lock_InitialLock_FirstEpoch_InFinalHalfOfEpoch` test
    /// but the lock is performed for someone else.
    function testLock_InitialLock_FirstEpoch_LockForSomeoneElse() public {
        // --- Assertions before --- //
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 2), 0);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), 0);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 2), 0);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 0), false);

        // --- Main call --- //
        uint256 amountToLock = 1 ether;
        deal(address(govToken), alice, amountToLock);
        vm.startPrank(alice);
        govToken.approve(address(tokenLocker), amountToLock);
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LockCreated(address(this), amountToLock, 2);
        tokenLocker.lock(address(this), amountToLock, 1);
        vm.stopPrank();

        // --- Assertions after --- //
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountToLock);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 2), amountToLock);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), amountToLock * 2);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0), amountToLock * 2);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 2), amountToLock);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountToLock);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 2), true);
    }

    /// @notice This test is performed under the following conditions:
    /// - on _epochWeightWrite:
    ///     - accountEpoch < systemEpoch.
    ///     - accountData.frozen == 0
    ///     - accountData.locked == 0
    /// - on getTotalWeightWrite: weight == 0.
    /// - on _lock: block.timestamp is not in the final half of the epoch.
    /// - on _lock:  previous == 0. (i.e. there is not lock expiring at the same epoch that user new lock expired).
    function test_Lock_InitialLock_SecondEpoch_NotInFirstHalfOfEpoch() public {
        uint256 startTime = coreOwner.START_TIME();

        // --- Assertions before --- //
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 0);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), oldEpoch), 0);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), oldEpoch), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 0);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 0), false);

        // Start at the beginning of next epoch
        uint256 epochToSkip = 1;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        // --- Main call --- //
        uint256 amountToLock = 1 ether;
        uint256 lockDuration = 2;
        uint256 currentEpoch = oldEpoch + epochToSkip;
        deal(address(govToken), address(this), amountToLock);
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LockCreated(address(this), amountToLock, lockDuration);
        tokenLocker.lock(address(this), amountToLock, lockDuration);

        // --- Assertions after --- //
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountToLock);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), currentEpoch + lockDuration), amountToLock);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), amountToLock * lockDuration);
        // Account values
        assertEq(
            vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch),
            amountToLock * lockDuration
        );
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), currentEpoch + lockDuration),
            amountToLock
        );
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountToLock);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(
            vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), currentEpoch + lockDuration), true
        );
    }

    /// @notice This test is performed under the following conditions:
    /// - on _epochWeightWrite:
    ///     - accountEpoch < systemEpoch.
    ///     - accountData.frozen == 0
    ///     - accountData.locked != 0
    ///     - accountEpoch % 256 != 0
    ///     - bitfield & uint256(1) != 1 always (i.e. no unlock between old epoch and current epoch: WithoutUnlock)
    /// - on getTotalWeightWrite: weight != 0.
    /// - on _lock: block.timestamp is not in the final half of the epoch.
    /// - on _lock:  previous == 0. (i.e. there is not lock expiring at the same epoch that user new lock expired: WithoutUnlockOverlapping).
    /// - a 5 week lock is perfomed before the start of the test
    function test_Lock_SecondLock_SecondEpoch_WithoutUnlockOverlapping_WithoutUnlock()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
    {
        uint256 startTime = coreOwner.START_TIME();

        uint256 amountLockedBefore = 1 ether;
        uint256 previousLockDuration = 5;

        // --- Assertions before --- //
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountLockedBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), oldEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 0);
        assertEq(
            vm.getTotalEpochWeightBySlotReading(address(tokenLocker), oldEpoch),
            amountLockedBefore * previousLockDuration
        );
        // Account values
        assertEq(
            vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), oldEpoch),
            amountLockedBefore * previousLockDuration
        );
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 0);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountLockedBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), false);

        // Start at the beginning of next epoch
        uint256 epochToSkip = 3;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        // --- Main call --- //
        uint256 amountToLock = 1 ether;
        uint256 lockDuration = 5;
        uint256 currentEpoch = oldEpoch + epochToSkip;
        deal(address(govToken), address(this), amountToLock);
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LockCreated(address(this), amountToLock, lockDuration);
        tokenLocker.lock(address(this), amountToLock, lockDuration);

        // --- Assertions after --- //
        uint256 weight = amountLockedBefore * (previousLockDuration - epochToSkip) + amountToLock * lockDuration;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountLockedBefore + amountToLock);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), currentEpoch + lockDuration), amountToLock);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), currentEpoch + lockDuration),
            amountToLock
        );
        // Account lock data
        assertEq(
            vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountLockedBefore + amountToLock
        );
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), previousLockDuration), true);
        assertEq(
            vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), currentEpoch + lockDuration), true
        );
    }

    // here
    /// @notice This test is performed under the following conditions:
    /// - on _epochWeightWrite:
    ///     - accountEpoch < systemEpoch.
    ///     - accountData.frozen == 0
    ///     - accountData.locked != 0
    ///     - accountEpoch % 256 != 0
    ///     - bitfield & uint256(1) != 1 always (i.e. no unlock between old epoch and current epoch: WithoutUnlock)
    /// - on getTotalWeightWrite: weight != 0.
    /// - on _lock: block.timestamp is not in the final half of the epoch.
    /// - on _lock:  previous != 0. (i.e. there is lock expiring at the same epoch that user new lock expired: WithUnlockOverlapping).
    /// - a 5 week lock is perfomed before the start of the test
    function test_Lock_SecondLock_SecondEpoch_WithUnlockOverlapping_WithoutUnlock()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
    {
        uint256 startTime = coreOwner.START_TIME();

        uint256 amountLockedBefore = 1 ether;
        uint256 previousLockDuration = 5;

        // --- Assertions before --- //
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountLockedBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), oldEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 0);
        assertEq(
            vm.getTotalEpochWeightBySlotReading(address(tokenLocker), oldEpoch),
            amountLockedBefore * previousLockDuration
        );
        // Account values
        assertEq(
            vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), oldEpoch),
            amountLockedBefore * previousLockDuration
        );
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 0);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountLockedBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), false);

        // Start at the beginning of next epoch
        uint256 epochToSkip = 3;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        // --- Main call --- //
        uint256 amountToLock = 1 ether;
        uint256 lockDuration = 2;
        uint256 currentEpoch = oldEpoch + epochToSkip;
        deal(address(govToken), address(this), amountToLock);
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LockCreated(address(this), amountToLock, lockDuration);
        tokenLocker.lock(address(this), amountToLock, lockDuration);

        // --- Assertions after --- //
        uint256 weight = amountLockedBefore * (previousLockDuration - epochToSkip) + amountToLock * lockDuration;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountLockedBefore + amountToLock);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(
            vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), currentEpoch + lockDuration),
            amountLockedBefore + amountToLock
        );
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), currentEpoch + lockDuration),
            amountLockedBefore + amountToLock
        );
        // Account lock data
        assertEq(
            vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountLockedBefore + amountToLock
        );
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), previousLockDuration), true);
        assertEq(previousLockDuration, currentEpoch + lockDuration);
    }

    /// @notice This test is performed under the following conditions:
    /// - on _epochWeightWrite:
    ///     - accountEpoch < systemEpoch.
    ///     - accountData.frozen == 0
    ///     - accountData.locked != 0
    ///     - accountEpoch % 256 != 0
    ///     - bitfield & uint256(1) == 1 once (i.e. unlock between old epoch and current epoch: WithUnlock)
    ///         - locked == 0 (i.e. all token to unlock are already unlocked)
    /// - on getTotalWeightWrite: weight != 0.
    /// - on _lock: block.timestamp is not in the final half of the epoch.
    /// - on _lock:  previous == 0. (i.e. there is no lock expiring at the same epoch that user new lock expired: WithoutUnlockOverlapping).
    /// - a 5 week lock is perfomed before the start of the test
    function test_Lock_SecondLock_SecondEpoch_WithoutUnlockOverlapping_WithUnlock()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
    {
        uint256 startTime = coreOwner.START_TIME();

        uint256 amountLockedBefore = 1 ether;
        uint256 previousLockDuration = 5;

        // --- Assertions before --- //
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountLockedBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), oldEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 0);
        assertEq(
            vm.getTotalEpochWeightBySlotReading(address(tokenLocker), oldEpoch),
            amountLockedBefore * previousLockDuration
        );
        // Account values
        assertEq(
            vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), oldEpoch),
            amountLockedBefore * previousLockDuration
        );
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 0);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountLockedBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), false);

        // Start at the beginning of next epoch
        uint256 epochToSkip = 8;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        // --- Main call --- //
        uint256 amountToLock = 1 ether;
        uint256 lockDuration = 2;
        uint256 currentEpoch = oldEpoch + epochToSkip;
        deal(address(govToken), address(this), amountToLock);
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LockCreated(address(this), amountToLock, lockDuration);
        tokenLocker.lock(address(this), amountToLock, lockDuration);

        // --- Assertions after --- //
        uint256 weight = amountToLock * lockDuration;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountToLock);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), currentEpoch + lockDuration), amountToLock);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), currentEpoch + lockDuration),
            amountToLock
        );
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountToLock);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), amountLockedBefore);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), previousLockDuration), true);
        assertEq(
            vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), currentEpoch + lockDuration), true
        );
    }

    /// @notice This test is performed under the following conditions:
    /// - on _epochWeightWrite:
    ///     - accountEpoch < systemEpoch.
    ///     - accountData.frozen == 0
    ///     - accountData.locked != 0
    ///     - accountEpoch % 256 != 0
    ///     - bitfield & uint256(1) == 1 once (i.e. unlock between old epoch and current epoch: WithUnlock)
    ///         - locked != 0 (i.e. not all token to unlock are already unlocked)
    /// - on getTotalWeightWrite: weight != 0.
    /// - on _lock: block.timestamp is not in the final half of the epoch.
    /// - on _lock:  previous != 0. (i.e. there is lock expiring at the same epoch that user new lock expired: WithUnlockOverlapping).
    /// - a 5 week lock is perfomed before the start of the test
    /// - then after 2 epoch, a 5 week lock is performed for 7 epoch
    function test_Lock_ThirdLock_SecondEpoch_WithUnlockOverlapping_WithUnlock()
        public
        // 1st lock
        lock(
            Modifier_Lock({
                skipBefore: 0,
                user: address(this),
                amountToLock: 1 ether,
                duration: 5,
                skipAfter: EPOCH_LENGTH * 2
            })
        )
        // 2nd lock
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 7, skipAfter: 0}))
    {
        uint256 startTime = coreOwner.START_TIME();

        uint256 amountLockedBefore = 2 ether;
        // --- Assertions before --- //
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountLockedBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), oldEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 1 ether);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 9), 1 ether);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), oldEpoch), 1 ether * 3 + 1 ether * 7);
        // Account values
        assertEq(
            vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), oldEpoch),
            1 ether * 3 + 1 ether * 7
        );
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 1 ether);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 9), 1 ether);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountLockedBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), oldEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 9), true);

        // Start at the beginning of next epoch
        uint256 epochToSkip = 5;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        // --- Main call --- //
        uint256 amountToLock = 1 ether;
        uint256 lockDuration = 2;
        uint256 currentEpoch = oldEpoch + epochToSkip;
        deal(address(govToken), address(this), amountToLock);
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LockCreated(address(this), amountToLock, lockDuration);
        tokenLocker.lock(address(this), amountToLock, lockDuration);

        // --- Assertions after --- //
        uint256 weight = 1 ether * 2 + 1 ether * 2; // 1 * (7 - 5) + 1 * 2
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 2 ether); // 1 from 2nd lock, 1 from 3rd lock
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 1 ether); // 5
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 9), 2 ether); // 9, 1 from 2nd lock, 1 from 3rd lock
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), 1 ether * 5);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(
            vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch - 1), 1 ether * 3
        ); // 1 * (7 - 4)
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), currentEpoch + lockDuration),
            2 ether
        );
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 2 ether);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 1 ether);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
        assertEq(
            vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), currentEpoch + lockDuration), true
        );
    }

    /// @notice This test is performed under the following conditions:
    /// - on _epochWeightWrite:
    ///     - accountEpoch < systemEpoch.
    ///     - accountData.frozen == 0
    ///     - accountData.locked != 0
    ///     - accountEpoch % 256 != 0
    ///     - bitfield & uint256(1) == 1 once (i.e. unlock between old epoch and current epoch: WithUnlock)
    ///         - locked != 0 (i.e. not all token to unlock are already unlocked)
    /// - on getTotalWeightWrite: weight != 0.
    /// - on _lock: block.timestamp is not in the final half of the epoch.
    /// - on _lock:  previous == 0. (i.e. there is no lock expiring at the same epoch that user new lock expired: WithoutUnlockOverlapping).
    /// - a 5 week lock is perfomed before the start of the test
    /// - then after 2 epoch, a 5 week lock is performed
    function test_Lock_ThirdLock_SecondEpoch_WithoutUnlockOverlapping_WithUnlock_old()
        public
        // 1st lock
        lock(
            Modifier_Lock({
                skipBefore: 0,
                user: address(this),
                amountToLock: 1 ether,
                duration: 5,
                skipAfter: EPOCH_LENGTH * 2
            })
        )
        // 2nd lock
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
    {
        uint256 startTime = coreOwner.START_TIME();

        uint256 amountLockedBefore = 2 ether;
        // --- Assertions before --- //
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountLockedBefore);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), oldEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 1 ether);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 7), 1 ether);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), oldEpoch), 1 ether * 3 + 1 ether * 5);
        // Account values
        assertEq(
            vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), oldEpoch),
            1 ether * 3 + 1 ether * 5
        );
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 1 ether);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 7), 1 ether);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountLockedBefore);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), oldEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 7), true);

        // Start at the beginning of next epoch
        uint256 epochToSkip = 8;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        // --- Main call --- //
        uint256 amountToLock = 1 ether;
        uint256 lockDuration = 2;
        uint256 currentEpoch = oldEpoch + epochToSkip;
        deal(address(govToken), address(this), amountToLock);
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LockCreated(address(this), amountToLock, lockDuration);
        tokenLocker.lock(address(this), amountToLock, lockDuration);

        // --- Assertions after --- //
        uint256 weight = amountToLock * lockDuration;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountToLock);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 1 ether); // 5
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 7), 1 ether); // 7
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), currentEpoch + lockDuration), amountToLock); // 12
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), 1 ether * 5);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), oldEpoch), 1 ether * 3 + 1 ether * 5);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), currentEpoch + lockDuration),
            amountToLock
        );
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountToLock);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), amountLockedBefore);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 7), true);
        assertEq(
            vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), currentEpoch + lockDuration), true
        );
    }

    /// @notice This test is performed in order to test the edge case when the account epoch = 0 modulo 256.
    function test_Lock_SecondLock_AccountEpochIsModulo256()
        public
        lock(
            Modifier_Lock({
                skipBefore: EPOCH_LENGTH * 250,
                user: address(this),
                amountToLock: 1 ether,
                duration: 10,
                skipAfter: 0
            })
        )
    {
        uint256 startTime = coreOwner.START_TIME();

        uint256 amountLockedBefore = 1 ether;
        uint256 lockDurationBefore = 10;
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;

        // Start at the beginning of next epoch
        uint256 epochToSkip = 256 - oldEpoch;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        // --- Main call --- //
        uint256 amountToLock = 1 ether;
        uint256 lockDuration = 2;
        uint256 currentEpoch = oldEpoch + epochToSkip;
        deal(address(govToken), address(this), amountToLock);
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LockCreated(address(this), amountToLock, lockDuration);
        tokenLocker.lock(address(this), amountToLock, lockDuration);

        // --- Assertions after --- //
        uint256 weight = amountLockedBefore * (10 - 6) + amountToLock * lockDuration;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), amountLockedBefore + amountToLock);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(
            vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), oldEpoch + lockDurationBefore), amountLockedBefore
        );
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), currentEpoch + lockDuration), amountToLock);
        assertEq(
            vm.getTotalEpochWeightBySlotReading(address(tokenLocker), oldEpoch), amountLockedBefore * lockDurationBefore
        );
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(
            vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), oldEpoch),
            amountLockedBefore * lockDurationBefore
        );
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), currentEpoch + lockDuration),
            amountToLock
        );
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), oldEpoch + lockDurationBefore),
            amountLockedBefore
        );
        // Account lock data
        assertEq(
            vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), amountLockedBefore + amountToLock
        );
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(
            vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), currentEpoch + lockDuration), true
        );
        assertEq(
            vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), oldEpoch + lockDurationBefore), true
        );
    }

    /// @notice This test is performed under the following conditions:
    /// - User lock 1 token in the locker for 5 epochs.
    /// - User freeze the locked token.
    /// - User lock 1 token in the locker for 2 epochs.
    function test_Lock_SecondLock_WithFreeze()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
    {
        uint256 startTime = coreOwner.START_TIME();

        // --- Assertions before --- //
        uint256 maxLockEpoch = tokenLocker.MAX_LOCK_EPOCHS();
        uint256 amountLockBefore = 1 ether;
        uint256 weightBefore = amountLockBefore * maxLockEpoch;
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 0);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), weightBefore);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0), weightBefore);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 0);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 1 ether);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), true);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), false);

        // Start at the beginning of next epoch
        uint256 epochToSkip = 3;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        // --- Main call --- //
        uint256 amountToLock = 1 ether;
        uint256 lockDuration = 2; // Useless
        uint256 currentEpoch = oldEpoch + epochToSkip;
        deal(address(govToken), address(this), amountToLock);
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LockCreated(address(this), amountToLock, maxLockEpoch);
        tokenLocker.lock(address(this), amountToLock, lockDuration);

        // --- Assertions after --- //
        uint256 weight = (amountLockBefore + amountToLock) * maxLockEpoch;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), currentEpoch + lockDuration), 0);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), oldEpoch), weightBefore);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), oldEpoch), weightBefore);
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), currentEpoch + lockDuration), 0
        );
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), amountLockBefore + amountToLock);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), true);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(
            vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), currentEpoch + lockDuration), false
        );
    }
}
