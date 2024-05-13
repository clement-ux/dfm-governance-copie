// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {stdError} from "forge-std/StdError.sol";

import {TokenLocker} from "../../../../../contracts/TokenLocker.sol";
import {Unit_Shared_Test_} from "../../../shared/Shared.sol";
import {WizardTokenLocker} from "../../../../utils/WizardTokenLocker.sol";

contract Unit_Concrete_TokenLocker_GetAccountActiveLocks_ is Unit_Shared_Test_ {
    uint256 internal startTime;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

        startTime = coreOwner.START_TIME();
        govToken.approve(address(tokenLocker), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test freeze, Using following conditions:
    /// - Locks 1 token for 5 epochs
    /// - Freeze position
    function test_GetAccountActiveLocks_When_Frozen()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 5, skipAfter: 0}))
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
    {
        (TokenLocker.LockData[] memory locks, uint256 frozenAmount) =
            tokenLocker.getAccountActiveLocks(address(this), 0);

        assertEq(locks.length, 0);
        assertEq(frozenAmount, 1);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Locks 1 token for 3 epochs
    function test_GetAccountActiveLocks_When_NotFrozen_SinglePosition_MinEpochTooLarge()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 3, skipAfter: 0}))
    {
        (TokenLocker.LockData[] memory locks, uint256 frozenAmount) =
            tokenLocker.getAccountActiveLocks(address(this), 4);

        assertEq(locks.length, 0);
        assertEq(frozenAmount, 0);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Locks 1 token for 3 epochs
    function test_GetAccountActiveLocks_When_NotFrozen_SinglePosition_MinEpochIsNull()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 3, skipAfter: 0}))
    {
        (TokenLocker.LockData[] memory locks, uint256 frozenAmount) =
            tokenLocker.getAccountActiveLocks(address(this), 0);

        assertEq(locks.length, 1);
        assertEq(locks[0].amount, 1);
        assertEq(locks[0].epochsToUnlock, 3);
        assertEq(frozenAmount, 0);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Locks 1 token for 3 epochs
    /// - Locks 2 tokens for 5 epochs
    function test_GetAccountActiveLocks_When_NotFrozen_MultiplePositions()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 3, skipAfter: 0}))
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 2, duration: 5, skipAfter: 0}))
    {
        (TokenLocker.LockData[] memory locks, uint256 frozenAmount) =
            tokenLocker.getAccountActiveLocks(address(this), 0);

        assertEq(locks.length, 2);
        assertEq(locks[0].amount, 2);
        assertEq(locks[0].epochsToUnlock, 5);
        assertEq(locks[1].amount, 1);
        assertEq(locks[1].epochsToUnlock, 3);
        assertEq(frozenAmount, 0);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Locks 1 token for 3 epochs
    /// - Time jump 1 epoch
    function test_GetAccountActiveLocks_When_NotFrozen_SinglePosition_After1Epoch()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 3, skipAfter: EPOCH_LENGTH}))
    {
        (TokenLocker.LockData[] memory locks, uint256 frozenAmount) =
            tokenLocker.getAccountActiveLocks(address(this), 0);

        assertEq(locks.length, 1);
        assertEq(locks[0].amount, 1);
        assertEq(locks[0].epochsToUnlock, 2);
        assertEq(frozenAmount, 0);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Locks 1 token for 3 epochs
    /// - Time jump 3 epochs
    function test_GetAccountActiveLocks_When_NotFrozen_SinglePosition_After3Epochs()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 3, skipAfter: 3 * EPOCH_LENGTH}))
    {
        (TokenLocker.LockData[] memory locks, uint256 frozenAmount) =
            tokenLocker.getAccountActiveLocks(address(this), 0);

        assertEq(locks.length, 0);
        assertEq(frozenAmount, 0);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Time jump 254 epochs
    /// - Locks 1 token for 3 epochs
    function test_GetAccountActiveLocks_When_NotFrozen_SinglePosition_AtEpoch256()
        public
        lock(
            Modifier_Lock({skipBefore: 254 * EPOCH_LENGTH, user: address(this), amountToLock: 1, duration: 3, skipAfter: 0})
        )
    {
        (TokenLocker.LockData[] memory locks, uint256 frozenAmount) =
            tokenLocker.getAccountActiveLocks(address(this), 0);

        assertEq(locks.length, 1);
        assertEq(locks[0].amount, 1);
        assertEq(locks[0].epochsToUnlock, 3);
        assertEq(frozenAmount, 0);
    }
}
