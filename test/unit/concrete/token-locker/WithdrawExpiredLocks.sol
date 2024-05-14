// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TokenLockerBase} from "../../../../contracts/dependencies/TokenLockerBase.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardTokenLocker} from "../../../utils/WizardTokenLocker.sol";

contract Unit_Concrete_TokenLocker_WithdrawExpiredLocks_ is Unit_Shared_Test_ {
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

    function test_RevertWhen_WithdrawExpiredLocks_Because_NoUnlockedToken() public {
        vm.expectRevert("No unlocked tokens");
        tokenLocker.withdrawExpiredLocks(0);
    }

    function test_RevertWhen_WithdrawExpiredLocks_Because_ExceedMaxLock_WhenRelock()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 5, skipAfter: 5 * EPOCH_LENGTH}))
    {
        uint256 maxLockEpochs = tokenLocker.MAX_LOCK_EPOCHS();
        vm.expectRevert("Exceeds MAX_LOCK_EPOCHS");
        tokenLocker.withdrawExpiredLocks(maxLockEpochs + 1);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test freeze, Using following conditions:
    /// - Lock 1 token for 5 epochs
    /// - Skip 5 epochs
    /// - Withdraw expired locks
    function test_WithdrawExpiredLocks_SinglePosition_AtSameEpochAsUnlock()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
    {
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as exactly the same as the test
        // `Unit_Concrete_TokenLocker_Lock_::test_Lock_SecondLock_SecondEpoch_WithoutUnlockOverlapping_WithoutUnlock`

        // Start at the beginning of next epoch
        uint256 epochToSkip = 5;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        vm.expectEmit({emitter: address(govToken)});
        emit IERC20.Transfer(address(tokenLocker), address(this), 1 ether);
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksWithdrawn(address(this), 1 ether, 0);
        tokenLocker.withdrawExpiredLocks(0);

        // Assertions
        uint256 weight = 0;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 1 ether);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 1 ether);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
        /*
        */
    }

    /// @notice Test freeze, Using following conditions:
    /// - Lock 1 token for 5 epochs
    /// - Skip 6 epochs
    /// - Withdraw expired locks
    function test_WithdrawExpiredLocks_SinglePosition_AtDiffEpochAsUnlock()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
    {
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as exactly the same as the test
        // `Unit_Concrete_TokenLocker_Lock_::test_Lock_SecondLock_SecondEpoch_WithoutUnlockOverlapping_WithoutUnlock`

        // Start at the beginning of next epoch
        uint256 unlockEpoch = 5;
        uint256 epochToSkip = 6;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        vm.expectEmit({emitter: address(govToken)});
        emit IERC20.Transfer(address(tokenLocker), address(this), 1 ether);
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksWithdrawn(address(this), 1 ether, 0);
        tokenLocker.withdrawExpiredLocks(0);

        // Assertions
        uint256 weight = 0;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), unlockEpoch), 1 ether);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), currentEpoch), 0);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), unlockEpoch), weight);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), unlockEpoch), weight);
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), unlockEpoch), 1 ether);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), currentEpoch), 0);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), unlockEpoch), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), currentEpoch), false);

        /*
        */
    }

    /// @notice Test freeze, Using following conditions:
    /// - Lock 1 token for 3 epochs and 2 tokens for 5 epochs
    /// - Skip 3 epochs
    /// - Withdraw expired locks
    function test_WithdrawExpiredLocks_MultiplePositions_PartialyUnlocked()
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
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as exactly the same as the test
        // `Unit_Concrete_TokenLocker_Lock_::test_Lock_SecondLock_SecondEpoch_WithoutUnlockOverlapping_WithoutUnlock`

        // Start at the beginning of next epoch
        uint256 unlockEpoch = 3;
        uint256 epochToSkip = 3;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        vm.expectEmit({emitter: address(govToken)});
        emit IERC20.Transfer(address(tokenLocker), address(this), 1 ether);
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksWithdrawn(address(this), 1 ether, 0);
        tokenLocker.withdrawExpiredLocks(0);
        uint256 remainingTokens = 2 ether;
        uint256 remainingEpochs = 2;

        // Assertions
        uint256 weight = remainingTokens * remainingEpochs;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), remainingTokens);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), unlockEpoch), 1 ether);
        assertEq(
            vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), remainingEpochs + epochToSkip), remainingTokens
        );
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), unlockEpoch), 1 ether);
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), remainingEpochs + epochToSkip),
            remainingTokens
        );
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), remainingTokens);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), unlockEpoch), true);
        assertEq(
            vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), remainingEpochs + epochToSkip), true
        );
        /*
        */
    }

    /// @notice Test freeze, Using following conditions:
    /// - Lock 1 token for 3 epochs and 2 tokens for 5 epochs
    /// - Skip 5 epochs
    /// - Withdraw expired locks
    function test_WithdrawExpiredLocks_MultiplePositions_FullyUnlocked()
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
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as exactly the same as the test
        // `Unit_Concrete_TokenLocker_Lock_::test_Lock_SecondLock_SecondEpoch_WithoutUnlockOverlapping_WithoutUnlock`

        // Start at the beginning of next epoch
        uint256 epochToSkip = 5;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;
        uint256 totalLockedBefore = 3 ether;

        vm.expectEmit({emitter: address(govToken)});
        emit IERC20.Transfer(address(tokenLocker), address(this), totalLockedBefore);
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksWithdrawn(address(this), totalLockedBefore, 0);
        tokenLocker.withdrawExpiredLocks(0);
        uint256 remainingTokens = 0;
        uint256 remainingEpochs = 0;

        // Assertions
        uint256 weight = remainingTokens * remainingEpochs;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), remainingTokens);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 1 ether);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 2 ether);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 1 ether);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 2 ether);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), remainingTokens);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Lock 1 token for 5 epochs
    /// - Skip 5 epochs
    /// - Relock expired locks
    function test_WithdrawExpiredLocks_Relocking()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
    {
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as exactly the same as the test
        // `Unit_Concrete_TokenLocker_Lock_::test_Lock_SecondLock_SecondEpoch_WithoutUnlockOverlapping_WithoutUnlock`

        // Start at the beginning of next epoch
        uint256 epochToSkip = 5;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LockCreated(address(this), 1 ether, 10);
        tokenLocker.withdrawExpiredLocks(10);
        uint256 lockedToken = 1 ether;
        uint256 lockedEpoch = 10;

        // Assertions
        uint256 weight = lockedToken * lockedEpoch;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), lockedToken);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 1 ether);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), lockedEpoch + epochToSkip), lockedToken);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 1 ether);
        assertEq(
            vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), lockedEpoch + epochToSkip),
            lockedToken
        );
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), lockedToken);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), lockedEpoch + epochToSkip), true);
    }
}
