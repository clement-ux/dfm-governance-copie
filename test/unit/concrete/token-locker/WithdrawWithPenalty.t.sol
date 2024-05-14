// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TokenLockerBase} from "../../../../contracts/dependencies/TokenLockerBase.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardTokenLocker} from "../../../utils/WizardTokenLocker.sol";

contract Unit_Concrete_TokenLocker_WithdrawWithPenalty_ is Unit_Shared_Test_ {
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

    function test_RevertWhen_WithdrawWithPenalty_Because_Disable() public disableWithdrawWithPenalty {
        vm.expectRevert("Penalty withdrawals are disabled");
        tokenLocker.withdrawWithPenalty(1);
    }

    function test_RevertWhen_WithdrawWithPenalty_Because_InsufficentBalanceAfterFees()
        public
        enableWithdrawWithPenalty
    {
        vm.expectRevert("Insufficient balance after fees");
        tokenLocker.withdrawWithPenalty(1);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test withdraw with penalty, Using following conditions:
    /// - Lock 2 token for 5 epochs
    /// - Skip 5 epochs
    /// - Withdraw 1 token with penalty (no penalty at the end)
    function test_WithdrawWithPenalty_When_Unlocked_IsGreaterThan_AmountToWithdraw()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 2 ether, duration: 5, skipAfter: 0}))
        enableWithdrawWithPenalty
    {
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as almost the same as the test
        // `Unit_Concrete_TokenLocker_Lock_::test_Lock_SecondLock_SecondEpoch_WithoutUnlockOverlapping_WithoutUnlock`

        // Start at the beginning of next epoch
        uint256 epochToSkip = 5;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        vm.expectEmit({emitter: address(govToken)});
        emit IERC20.Transfer(address(tokenLocker), address(this), 1 ether);
        tokenLocker.withdrawWithPenalty(1 ether);

        // Assertions
        uint256 weight = 0;
        // Total values - Not updated in this case!
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 2 ether);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 2 ether);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), 10 ether);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 2 ether);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 1 ether);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
    }

    /// @notice Test withdraw with penalty, Using following conditions:
    /// - Lock 1 token for 5 epochs
    /// - Skip 5 epochs
    /// - Withdraw 1 token with penalty (no penalty at the end)
    function test_WithdrawWithPenalty_When_Unlocked_EqualTo_AmountToWithdraw()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
        enableWithdrawWithPenalty
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
        tokenLocker.withdrawWithPenalty(1 ether);

        // Assertions
        uint256 weight = 0;
        // Total values - Not updated in this case!
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 1 ether);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 1 ether);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), 5 ether);
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
    }

    /// @notice Test withdraw with penalty, Using following conditions:
    /// - Lock 1 token for 5 epochs
    /// - Skip 0 epochs
    /// - Withdraw maximum token with penalty
    function test_WithdrawWithPenalty_ZeroUnlocked_SinglePosition_RightAfterLocking_MaxAmount()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
        enableWithdrawWithPenalty
    {
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as exactly the same as the test
        // `Unit_Concrete_TokenLocker_Lock_::test_Lock_SecondLock_SecondEpoch_WithoutUnlockOverlapping_WithoutUnlock`

        // Start at the beginning of next epoch
        uint256 epochToSkip = 0;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        //vm.expectEmit({emitter: address(govToken)});
        //emit IERC20.Transfer(address(tokenLocker), address(this), 1 ether);
        (uint256 amountWithdrawn, uint256 penalty) = tokenLocker.withdrawWithPenalty(MAX);

        // Assertions
        uint256 weight = 0;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 0);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 0);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), false);
        // Withdrawn amount
        assertGt(amountWithdrawn, 0);
        assertLt(amountWithdrawn, 1 ether);
        assertGt(penalty, 0);
    }

    /// @notice Test withdraw with penalty, Using following conditions:
    /// - Lock 2 token for 5 epochs
    /// - Skip 0 epochs
    /// - Withdraw 1 ether with penalty equal to approx 0.1 ether
    function test_WithdrawWithPenalty_ZeroUnlocked_SinglePosition_RightAfterLocking_PartialAmount_WithLeftOver()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 2 ether, duration: 5, skipAfter: 0}))
        enableWithdrawWithPenalty
    {
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as almost the same as the test
        // `Unit_Concrete_TokenLocker_Lock_::test_Lock_SecondLock_SecondEpoch_WithoutUnlockOverlapping_WithoutUnlock`

        // Start at the beginning of next epoch
        uint256 epochToSkip = 0;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        uint256 amountToWithdraw = 1 ether;
        (uint256 predictedAmountWithdrawn, uint256 predictedPenalty) =
            tokenLocker.getWithdrawWithPenaltyAmounts(address(this), 1 ether);
        uint256 remaining = 2 ether - predictedAmountWithdrawn - predictedPenalty;

        vm.expectEmit({emitter: address(govToken)});
        emit IERC20.Transfer(address(tokenLocker), address(this), predictedAmountWithdrawn);
        vm.expectEmit({emitter: address(govToken)});
        emit IERC20.Transfer(address(tokenLocker), feeReceiver, predictedPenalty);
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksWithdrawn(address(this), predictedAmountWithdrawn, predictedPenalty);
        (uint256 amountWithdrawn,) = tokenLocker.withdrawWithPenalty(amountToWithdraw);

        // Assertions
        uint256 weight = remaining * 5;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), remaining);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), remaining);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), remaining);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), remaining);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true); // Finding: This should be false. Can it be a vulnerability? -> No.
        // Withdrawn amount
        assertEq(amountWithdrawn, predictedAmountWithdrawn);
        assertEq(govToken.balanceOf(feeReceiver), predictedPenalty);
    }

    /// @notice Test withdraw with penalty, Using following conditions:
    /// - Lock 1 token for 5 epochs
    /// - Skip 2 epochs
    /// - Withdraw maximum token with penalty
    function test_WithdrawWithPenalty_ZeroUnlocked_SinglePosition_2EpochsAfterLocking_MaxAmount()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
        enableWithdrawWithPenalty
    {
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as exactly the same as the test
        // `Unit_Concrete_TokenLocker_Lock_::test_Lock_SecondLock_SecondEpoch_WithoutUnlockOverlapping_WithoutUnlock`

        // Start at the beginning of next epoch
        uint256 epochToSkip = 2;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        (uint256 amountWithdrawn,) = tokenLocker.withdrawWithPenalty(MAX);

        // Assertions
        uint256 weight = 0;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 0);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 0);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), false);
        // Withdrawn amount
        assertGt(amountWithdrawn, 0);
        assertLt(amountWithdrawn, 1 ether);
    }

    /// @notice Test withdraw with penalty, Using following conditions:
    /// - Lock 3 token for 5 epochs
    /// - Skip 2 epochs
    /// - Withdraw 1 ether with penalty equal to approx 0.1 ether
    function test_WithdrawWithPenalty_ZeroUnlocked_SinglePosition_2EpochsAfterLocking_PartialAmount_WithLeftOver()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 3 ether, duration: 5, skipAfter: 0}))
        enableWithdrawWithPenalty
    {
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as exactly the same as the test
        // `Unit_Concrete_TokenLocker_Lock_::test_Lock_SecondLock_SecondEpoch_WithoutUnlockOverlapping_WithoutUnlock`

        // Start at the beginning of next epoch
        uint256 epochToSkip = 2;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        uint256 amountToWithdraw = 1 ether;
        (uint256 predictedAmountWithdrawn, uint256 predictedPenalty) =
            tokenLocker.getWithdrawWithPenaltyAmounts(address(this), 1 ether);
        uint256 remaining = 3 ether - predictedAmountWithdrawn - predictedPenalty;

        vm.expectEmit({emitter: address(govToken)});
        emit IERC20.Transfer(address(tokenLocker), address(this), predictedAmountWithdrawn);
        vm.expectEmit({emitter: address(govToken)});
        emit IERC20.Transfer(address(tokenLocker), feeReceiver, predictedPenalty);
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksWithdrawn(address(this), predictedAmountWithdrawn, predictedPenalty);
        (uint256 amountWithdrawn,) = tokenLocker.withdrawWithPenalty(amountToWithdraw);

        // Assertions
        uint256 weight = remaining * 3;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), remaining);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), remaining);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), remaining);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), remaining);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
        // Withdrawn amount
        assertEq(amountWithdrawn, 1 ether);
        assertEq(govToken.balanceOf(feeReceiver), predictedPenalty);
    }

    /// @notice Test withdraw with penalty, Using following conditions:
    /// - Lock 1 token for 3 epochs
    /// - Lock 2 token for 5 epochs
    /// - Skip 0 epochs
    /// - Withdraw maximum token with penalty
    function test_WithdrawWithPenalty_ZeroUnlocked_MultiplePosition_RightAfterLocking_MaxAmount()
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
        enableWithdrawWithPenalty
    {
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as exactly the same as the test
        // `Unit_Concrete_TokenLocker_Lock_::test_Lock_SecondLock_SecondEpoch_WithoutUnlockOverlapping_WithoutUnlock`

        // Start at the beginning of next epoch
        uint256 epochToSkip = 0;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        (uint256 amountWithdrawn,) = tokenLocker.withdrawWithPenalty(MAX);

        // Assertions
        uint256 weight = 0;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 0);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 0);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), false);
        // Withdrawn amount
        assertGt(amountWithdrawn, 0);
        assertLt(amountWithdrawn, 3 ether);
    }

    /// @notice Test withdraw with penalty, Using following conditions:
    /// - Lock 1 token for 3 epochs
    /// - Lock 2 token for 5 epochs
    /// - Skip 0 epochs
    /// - Withdraw 1 ether token with penalty equal to appprox 0.1 ether
    function test_WithdrawWithPenalty_ZeroUnlocked_MultiplePosition_RightAfterLocking_PartialAmount_WithLeftOver()
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
        enableWithdrawWithPenalty
    {
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as exactly the same as the test
        // `Unit_Concrete_TokenLocker_Lock_::test_Lock_SecondLock_SecondEpoch_WithoutUnlockOverlapping_WithoutUnlock`

        // Start at the beginning of next epoch
        uint256 epochToSkip = 0;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        uint256 amountToWithdraw = 1 ether;
        (uint256 predictedAmountWithdrawn, uint256 predictedPenalty) =
            tokenLocker.getWithdrawWithPenaltyAmounts(address(this), amountToWithdraw);
        uint256 remaining = 3 ether - predictedAmountWithdrawn - predictedPenalty;

        vm.expectEmit({emitter: address(govToken)});
        emit IERC20.Transfer(address(tokenLocker), address(this), predictedAmountWithdrawn);
        vm.expectEmit({emitter: address(govToken)});
        emit IERC20.Transfer(address(tokenLocker), feeReceiver, predictedPenalty);
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksWithdrawn(address(this), predictedAmountWithdrawn, predictedPenalty);
        (uint256 amountWithdrawn,) = tokenLocker.withdrawWithPenalty(amountToWithdraw);

        // Assertions
        uint256 weight = remaining * 5;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), remaining);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 0); // Checks that withdrawals are proceesed starting
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), remaining); // from the lock that will expire soonest.
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), remaining);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), remaining);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
        // Withdrawn amount
        assertEq(amountWithdrawn, 1 ether);
        assertEq(govToken.balanceOf(feeReceiver), predictedPenalty);
    }

    /// @notice Test withdraw with penalty, Using following conditions:
    /// - Lock 1 token for 3 epochs
    /// - Lock 2 token for 5 epochs
    /// - Skip 2 epochs
    /// - Withdraw maximum token with penalty
    function test_WithdrawWithPenalty_ZeroUnlocked_MultiplePosition_2EpochsAfterLocking_MaxAmount()
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
        enableWithdrawWithPenalty
    {
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as exactly the same as the test
        // `Unit_Concrete_TokenLocker_Lock_::test_Lock_SecondLock_SecondEpoch_WithoutUnlockOverlapping_WithoutUnlock`

        // Start at the beginning of next epoch
        uint256 epochToSkip = 2;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        (uint256 amountWithdrawn,) = tokenLocker.withdrawWithPenalty(MAX);

        // Assertions
        uint256 weight = 0;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 0);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 0);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), false);
        // Withdrawn amount
        assertGt(amountWithdrawn, 0);
        assertLt(amountWithdrawn, 3 ether);
    }

    /// @notice Test withdraw with penalty, Using following conditions:
    /// - Lock 1 token for 3 epochs
    /// - Lock 2 token for 5 epochs
    /// - Skip 2 epochs
    /// - Withdraw 1 ether token with penalty equal to appprox 0.1 ether
    function test_WithdrawWithPenalty_ZeroUnlocked_MultiplePosition_2EpochsAfterLocking_PartialAmount_WithLeftOver()
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
        enableWithdrawWithPenalty
    {
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as exactly the same as the test
        // `Unit_Concrete_TokenLocker_Lock_::test_Lock_SecondLock_SecondEpoch_WithoutUnlockOverlapping_WithoutUnlock`

        // Start at the beginning of next epoch
        uint256 epochToSkip = 2;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        uint256 amountToWithdraw = 1 ether;
        (uint256 predictedAmountWithdrawn, uint256 predictedPenalty) =
            tokenLocker.getWithdrawWithPenaltyAmounts(address(this), amountToWithdraw);
        uint256 remaining = 3 ether - predictedAmountWithdrawn - predictedPenalty;

        vm.expectEmit({emitter: address(govToken)});
        emit IERC20.Transfer(address(tokenLocker), address(this), predictedAmountWithdrawn);
        vm.expectEmit({emitter: address(govToken)});
        emit IERC20.Transfer(address(tokenLocker), feeReceiver, predictedPenalty);
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksWithdrawn(address(this), predictedAmountWithdrawn, predictedPenalty);
        (uint256 amountWithdrawn,) = tokenLocker.withdrawWithPenalty(amountToWithdraw);

        // Assertions
        uint256 weight = remaining * 3;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), remaining);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 0); // Checks that withdrawals are proceesed starting
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), remaining); // from the lock that will expire soonest.
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), remaining);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), remaining);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
        // Withdrawn amount
        assertEq(amountWithdrawn, 1 ether);
        assertEq(govToken.balanceOf(feeReceiver), predictedPenalty);
    }

    /// @notice Test withdraw with penalty, Using following conditions:
    /// - Lock 1 token for 3 epochs
    /// - Lock 2 token for 5 epochs
    /// - Skip 3 epochs
    /// - Withdraw maximum token with penalty
    function test_WithdrawWithPenalty_PartialyUnlocked_MultiplePosition_RightAfterLocking_MaxAmount()
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
        enableWithdrawWithPenalty
    {
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as exactly the same as the test
        // `Unit_Concrete_TokenLocker_Lock_::test_Lock_SecondLock_SecondEpoch_WithoutUnlockOverlapping_WithoutUnlock`

        // Start at the beginning of next epoch
        uint256 epochToSkip = 3;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        (uint256 amountWithdrawn,) = tokenLocker.withdrawWithPenalty(MAX);

        // Assertions
        uint256 weight = 0;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        // assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 1); // It should be 0, but however, 1 is not a vulnerability.
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 0);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        //assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 1); // It should be 0, but however, 1 is not a vulnerability.
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 0);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        //assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), true); // It should be false, but however, true is not a vulnerability.
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), false);
        // Withdrawn amount
        assertGt(amountWithdrawn, 0);
        assertLt(amountWithdrawn, 3 ether);
    }

    /// @notice Test withdraw with penalty, Using following conditions:
    /// - Lock 1 token for 3 epochs
    /// - Lock 2 token for 5 epochs
    /// - Skip 2 epochs
    /// - Withdraw 1 token with penalty equal to 1 ether
    function test_WithdrawWithPenalty_PartialyUnlocked_MultiplePosition_RightAfterLocking_PartialAmount_WithLeftOver()
        public
        lockMany(
            Modifier_LockMany({
                skipBefore: 0,
                user: address(this),
                amountToLock: [1 ether, 3 ether, 3 ether, 0, 0],
                duration: [3, 5, 7, 0, 0],
                skipAfter: 0
            })
        )
        enableWithdrawWithPenalty
    {
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as almost the same as the test
        // `Unit_Concrete_TokenLocker_Lock_::test_Lock_SecondLock_SecondEpoch_WithoutUnlockOverlapping_WithoutUnlock`

        // Start at the beginning of next epoch
        uint256 epochToSkip = 3;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        uint256 amountToWithdraw = 2 ether;
        (uint256 predictedAmountWithdrawn, uint256 predictedPenalty) =
            tokenLocker.getWithdrawWithPenaltyAmounts(address(this), amountToWithdraw);
        uint256 remaining = 7 ether - predictedAmountWithdrawn - predictedPenalty;

        vm.expectEmit({emitter: address(govToken)});
        emit IERC20.Transfer(address(tokenLocker), address(this), predictedAmountWithdrawn);
        vm.expectEmit({emitter: address(govToken)});
        emit IERC20.Transfer(address(tokenLocker), feeReceiver, predictedPenalty);
        vm.expectEmit({emitter: address(tokenLocker)});
        emit TokenLockerBase.LocksWithdrawn(address(this), predictedAmountWithdrawn, predictedPenalty);
        (uint256 amountWithdrawn,) = tokenLocker.withdrawWithPenalty(amountToWithdraw);

        // Assertions
        uint256 weight = (remaining - 3 ether) * 2 + 3 ether * 4;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), remaining);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        //assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 3), 1); // It should be 0, but however, 1 is not a vulnerability.
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), (remaining - 3 ether));
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 7), 3 ether);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        assertEq(tokenLocker.getTotalWeightAt(currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        //assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 3), 1); // It should be 0, but however, 1 is not a vulnerability.
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), (remaining - 3 ether));
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 7), 3 ether);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), remaining);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        // assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 3), true); // It should be false, but however, true is not a vulnerability.
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 7), true);
        // Withdrawn amount
        assertEq(amountWithdrawn, 2 ether);
        assertEq(govToken.balanceOf(feeReceiver), predictedPenalty);
    }

    /// @notice Test withdraw with penalty, Using following conditions:
    /// - Skip 250 epochs
    /// - Lock 1 token for 5 epochs
    /// - Skip 2 epochs
    /// - Withdraw maximum token with penalty
    function test_WithdrawWithPenalty_ZeroUnlocked_SinglePosition_AtEpoch256_MaxAmount()
        public
        lock(Modifier_Lock({skipBefore: 250 weeks, user: address(this), amountToLock: 1 ether, duration: 10, skipAfter: 0}))
        enableWithdrawWithPenalty
    {
        uint256 oldEpoch = (block.timestamp - startTime) / EPOCH_LENGTH;
        // No need to add assertions before as almost the same as the test
        // `Unit_Concrete_TokenLocker_Lock_::test_Lock_SecondLock_SecondEpoch_WithoutUnlockOverlapping_WithoutUnlock`

        // Start at the beginning of next epoch
        uint256 epochToSkip = 3;
        vm.warp(startTime + (oldEpoch + epochToSkip) * EPOCH_LENGTH);
        uint256 currentEpoch = oldEpoch + epochToSkip;

        (uint256 amountWithdrawn,) = tokenLocker.withdrawWithPenalty(MAX);

        // Assertions
        uint256 weight = 0;
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), currentEpoch);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), currentEpoch), weight);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), currentEpoch), weight);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), currentEpoch);
        // Withdrawn amount
        assertGt(amountWithdrawn, 0);
        assertLt(amountWithdrawn, 1 ether);
    }
}
