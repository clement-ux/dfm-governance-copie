// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {stdError} from "forge-std/StdError.sol";

import {TokenLocker} from "../../../../contracts/TokenLocker.sol";
import {TokenLockerBase} from "../../../../contracts/dependencies/TokenLockerBase.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardTokenLocker} from "../../../utils/WizardTokenLocker.sol";

contract Unit_Concrete_TokenLocker_TransferToLpLocker_ is Unit_Shared_Test_ {
    using WizardTokenLocker for Vm;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

        govToken.approve(address(tokenLocker), MAX);
    }
    /*//////////////////////////////////////////////////////////////
                             REVERTING TEST
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_TransferToLpLocker_Because_LockListIsEmpty() public {
        vm.expectRevert("Min 1 epoch");
        tokenLocker.transferToLpLocker(new TokenLockerBase.LockData[](0), 0, 0);
    }

    function test_RevertWhen_TransferToLpLocker_Because_LockListContainsAnAmountNull() public {
        vm.expectRevert("Amount must be nonzero");
        tokenLocker.transferToLpLocker(new TokenLockerBase.LockData[](1), 0, 0);
    }

    function test_RevertWhen_TransferToLpLocker_Because_LockListContainsAnEpochNulll() public {
        TokenLockerBase.LockData[] memory lockData = new TokenLockerBase.LockData[](1);
        lockData[0] = TokenLockerBase.LockData(1, 0);
        vm.expectRevert("Min 1 epoch");
        tokenLocker.transferToLpLocker(lockData, 0, 0);
    }

    function test_RevertWhen_TransferToLpLocker_Because_LockListContainsAnEpochGreaterThanMaxEpoch() public {
        TokenLockerBase.LockData[] memory lockData = new TokenLockerBase.LockData[](1);
        lockData[0] = TokenLockerBase.LockData(1, 53);
        vm.expectRevert("Exceeds MAX_LOCK_EPOCHS");
        tokenLocker.transferToLpLocker(lockData, 0, 0);
    }

    function test_RevertWhen_TransferToLpLocker_When_Frozen_Because_IncorrectLength()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 30, skipAfter: 0}))
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
    {
        vm.expectRevert("Lock length should be 1");
        tokenLocker.transferToLpLocker(new TokenLockerBase.LockData[](2), 0, 0);
    }

    function test_RevertWhen_TransferToLpLocker_When_Frozen_Because_IncorrectEpoch()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 30, skipAfter: 0}))
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
    {
        vm.expectRevert("Epoch must be MAX_LOCK_EPOCHS");
        TokenLockerBase.LockData[] memory lockData = new TokenLockerBase.LockData[](1);
        lockData[0] = TokenLockerBase.LockData(1 ether, 5);
        tokenLocker.transferToLpLocker(lockData, 0, 0);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test transferToLpLocker under following conditions:
    /// - Lock 1 ether for 5 epochs
    /// - Skip 0 epochs
    /// - Transfer 1 ether to LpLocker
    function test_TransferToLpLocker_When_SingleLock_FullPosition()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
    {
        TokenLockerBase.LockData[] memory lockData = new TokenLockerBase.LockData[](1);
        lockData[0] = TokenLockerBase.LockData(1 ether, 5);
        tokenLocker.transferToLpLocker(lockData, 0, 1 ether);

        // --- Assertions after --- //
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 0), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 0);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 0);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 0), false);
        // LpLocker values
        (uint256 locked, uint256 unlocked) = lpLocker.getAccountBalances(address(this));
        assertEq(locked, 1 ether);
        assertEq(unlocked, 0);
    }

    /// @notice Test transferToLpLocker under following conditions:
    /// - Lock 1 ether for 5 epochs
    /// - Skip 0 epochs
    /// - Transfer 0.5 ether to LpLocker
    function test_TransferToLpLocker_When_SingleLock_HalfPosition()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
    {
        TokenLockerBase.LockData[] memory lockData = new TokenLockerBase.LockData[](1);
        lockData[0] = TokenLockerBase.LockData(0.5 ether, 5);
        tokenLocker.transferToLpLocker(lockData, 0, 0.5 ether);

        // --- Assertions after --- //
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0.5 ether);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), 0.5 ether * 5);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 0), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 0.5 ether);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0), 0.5 ether * 5);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 0.5 ether);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0.5 ether);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), true);
        (uint256 locked, uint256 unlocked) = lpLocker.getAccountBalances(address(this));
        // LpLocker values
        assertEq(locked, 0.5 ether);
        assertEq(unlocked, 0);
    }

    /// @notice Test transferToLpLocker under following conditions:
    /// - Lock 1 ether for 5 epochs and 2 ether for 10 epochs
    /// - Skip 0 epochs
    /// - Transfer 3 ether to LpLocker
    function test_TransferToLpLocker_When_MultipleLocks_FullPosition()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 2 ether, duration: 10, skipAfter: 0}))
    {
        TokenLockerBase.LockData[] memory lockData = new TokenLockerBase.LockData[](2);
        lockData[0] = TokenLockerBase.LockData(1 ether, 5);
        lockData[1] = TokenLockerBase.LockData(2 ether, 10);
        tokenLocker.transferToLpLocker(lockData, 0, 3 ether);

        // --- Assertions after --- //
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 0), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 10), 0);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 10), 0);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 10), false);
        // LpLocker values
        (uint256 locked, uint256 unlocked) = lpLocker.getAccountBalances(address(this));
        assertEq(locked, 3 ether);
        assertEq(unlocked, 0);
    }

    /// @notice Test transferToLpLocker under following conditions:
    /// - Lock 1 ether for 5 epochs and 2 ether for 10 epochs
    /// - Skip 0 epochs
    /// - Transfer 1.5 ether to LpLocker
    function test_TransferToLpLocker_When_MultipleLocks_HalfPosition()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 2 ether, duration: 10, skipAfter: 0}))
    {
        TokenLockerBase.LockData[] memory lockData = new TokenLockerBase.LockData[](2);
        lockData[0] = TokenLockerBase.LockData(1 ether, 5);
        lockData[1] = TokenLockerBase.LockData(0.5 ether, 10);
        tokenLocker.transferToLpLocker(lockData, 0, 1.5 ether);

        // --- Assertions after --- //
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 1.5 ether);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), 1.5 ether * 10);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 0), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 10), 1.5 ether);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0), 1.5 ether * 10);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 10), 1.5 ether);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 1.5 ether);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 5), false);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 10), true);
        // LpLocker values
        (uint256 locked, uint256 unlocked) = lpLocker.getAccountBalances(address(this));
        assertEq(locked, 1.5 ether);
        assertEq(unlocked, 0);
    }

    /// @notice Test transferToLpLocker under following conditions:
    /// - Lock 1 ether for 5 epochs
    /// - Skip 4 epochs
    /// - Transfer 1 ether to LpLocker
    function test_TransferToLpLocker_When_SingleLock_When_GlobalStateAreNotUptoDate()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
        lock(Modifier_Lock({skipBefore: 0, user: alice, amountToLock: 1 ether, duration: 5, skipAfter: 4 weeks}))
    {
        TokenLockerBase.LockData[] memory lockData = new TokenLockerBase.LockData[](1);
        lockData[0] = TokenLockerBase.LockData(1 ether, 1);
        tokenLocker.transferToLpLocker(lockData, 0, 1 ether);

        // --- Assertions after --- //
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 1 ether);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), 4);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), 2 ether * 5);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 1), 2 ether * 4);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 2), 2 ether * 3);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 3), 2 ether * 2);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 4), 1 ether * 1);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 0), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), 5), 1 ether);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0), 1 ether * 5);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), 5), 0);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), false);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), 4);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), 0), false);
        // LpLocker values
        (uint256 locked, uint256 unlocked) = lpLocker.getAccountBalances(address(this));
        assertEq(locked, 1 ether);
        assertEq(unlocked, 0);
    }

    /// @notice Test transferToLpLocker under following conditions:
    /// - Lock 1 ether for 5 epochs
    /// - Freeze the account
    /// - Transfer 1 ether to LpLocker
    function test_TransferToLpLocker_When_Frozen_FullPosition()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
    {
        uint256 maxEpochs = tokenLocker.MAX_LOCK_EPOCHS();

        TokenLockerBase.LockData[] memory lockData = new TokenLockerBase.LockData[](1);
        lockData[0] = TokenLockerBase.LockData(1 ether, maxEpochs);
        tokenLocker.transferToLpLocker(lockData, 0, 1 ether);

        // --- Assertions after --- //
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), 0);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), maxEpochs), 0);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0), 0);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), maxEpochs), 0);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), true);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), maxEpochs), false);
        // LpLocker values
        (uint256 locked, uint256 unlocked) = lpLocker.getAccountBalances(address(this));
        assertEq(locked, 1 ether);
        assertEq(unlocked, 0);
    }

    /// @notice Test transferToLpLocker under following conditions:
    /// - Lock 1 ether for 5 epochs
    /// - Freeze the account
    /// - Transfer 0.5 ether to LpLocker
    function test_TransferToLpLocker_When_Frozen_HalfPosition()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 5, skipAfter: 0}))
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
    {
        uint256 maxEpochs = tokenLocker.MAX_LOCK_EPOCHS();

        TokenLockerBase.LockData[] memory lockData = new TokenLockerBase.LockData[](1);
        lockData[0] = TokenLockerBase.LockData(0.5 ether, maxEpochs);
        tokenLocker.transferToLpLocker(lockData, 0, 0.5 ether);

        // --- Assertions after --- //
        // Total values
        assertEq(vm.getTotalDecayRateBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalUpdateEpochBySlotReading(address(tokenLocker)), 0);
        assertEq(vm.getTotalEpochWeightBySlotReading(address(tokenLocker), 0), 0.5 ether * maxEpochs);
        assertEq(vm.getTotalEpochUnlockBySlotReading(address(tokenLocker), maxEpochs), 0);
        // Account values
        assertEq(vm.getAccountEpochWeightsBySlotReading(address(tokenLocker), address(this), 0), 0.5 ether * maxEpochs);
        assertEq(vm.getAccountEpochUnlocksBySlotReading(address(tokenLocker), address(this), maxEpochs), 0);
        // Account lock data
        assertEq(vm.getLockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUnlockedAmountBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getFrozenAmountBySlotReading(address(tokenLocker), address(this)), 0.5 ether);
        assertEq(vm.getIsFrozenBySlotReading(address(tokenLocker), address(this)), true);
        assertEq(vm.getEpochBySlotReading(address(tokenLocker), address(this)), 0);
        assertEq(vm.getUpdateEpochsBySlotReading(address(tokenLocker), address(this), maxEpochs), false);
        // LpLocker values
        (uint256 locked, uint256 unlocked) = lpLocker.getAccountBalances(address(this));
        assertEq(locked, 0.5 ether);
        assertEq(unlocked, 0);
    }
}
