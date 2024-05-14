// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Unit_Shared_Test_} from "../../../shared/Shared.sol";

contract Unit_Concrete_TokenLocker_GetAccountBalances_ is Unit_Shared_Test_ {
    uint256 internal startTime;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

        startTime = coreOwner.START_TIME();
        govToken.approve(address(tokenLocker), MAX);
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test freeze, Using following conditions:
    /// - Locks 1 token for 5 epochs
    /// - Freeze position
    function test_GetAccountBalances_When_Frozen_NoUnlocked()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 5, skipAfter: 0}))
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
    {
        (uint256 frozen, uint256 unlocked) = tokenLocker.getAccountBalances(address(this));

        assertEq(frozen, 1);
        assertEq(unlocked, 0);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Locks 1 token for 3 epochs
    /// - Locks 2 tokens for 5 epochs
    /// - Freeze position
    function test_GetAccountBalances_When_Frozen_WithUnlocked()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 3, skipAfter: 4 * EPOCH_LENGTH}))
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 2, duration: 5, skipAfter: 0}))
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
    {
        (uint256 frozen, uint256 unlocked) = tokenLocker.getAccountBalances(address(this));

        assertEq(frozen, 2);
        assertEq(unlocked, 1);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Locks 1 token for 3 epochs
    /// - No timejumps
    function test_GetAccountBalances_When_NoFrozen_SinglePosition_When_UpToDate()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 3, skipAfter: 0}))
    {
        (uint256 locked, uint256 unlocked) = tokenLocker.getAccountBalances(address(this));

        assertEq(locked, 1);
        assertEq(unlocked, 0);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Locks 1 token for 5 epochs
    /// - Timejump 3 epochs
    function test_GetAccountBalances_When_NoFrozen_SinglePosition_When_MiddleInDate()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 5, skipAfter: 3 * EPOCH_LENGTH}))
    {
        (uint256 locked, uint256 unlocked) = tokenLocker.getAccountBalances(address(this));

        assertEq(locked, 1);
        assertEq(unlocked, 0);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Locks 1 token for 5 epochs
    /// - Timejump 5 epochs
    function test_GetAccountBalances_When_NoFrozen_SinglePosition_When_OutOfDate()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 5, skipAfter: 5 * EPOCH_LENGTH}))
    {
        (uint256 locked, uint256 unlocked) = tokenLocker.getAccountBalances(address(this));

        assertEq(locked, 0);
        assertEq(unlocked, 1);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Locks 1 token for 3 epochs
    /// - Locks 2 tokens for 5 epochs
    /// - Timejump 5 epochs
    function test_GetAccountBalances_When_NoFrozen_MultiplePositions_When_AllOutOfDate()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 3, skipAfter: 0}))
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 2, duration: 5, skipAfter: 5 * EPOCH_LENGTH}))
    {
        (uint256 locked, uint256 unlocked) = tokenLocker.getAccountBalances(address(this));

        assertEq(locked, 0);
        assertEq(unlocked, 3);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Locks 1 token for 3 epochs
    /// - Locks 2 tokens for 5 epochs
    /// - Timejump 3 epochs
    function test_GetAccountBalances_When_NoFrozen_MultiplePositions_When_PartialyOutOfDate()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 3, skipAfter: 0}))
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 2, duration: 5, skipAfter: 3 * EPOCH_LENGTH}))
    {
        (uint256 locked, uint256 unlocked) = tokenLocker.getAccountBalances(address(this));

        assertEq(locked, 2);
        assertEq(unlocked, 1);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Timejump 255 epochs
    /// - Locks 1 token for 3 epochs
    /// - Timejump 3 epochs
    function test_GetAccountBalances_When_NoFrozen_SinglePosition_AtEpoch256()
        public
        lock(
            Modifier_Lock({
                skipBefore: 255 * EPOCH_LENGTH,
                user: address(this),
                amountToLock: 1,
                duration: 3,
                skipAfter: 3 * EPOCH_LENGTH
            })
        )
    {
        (uint256 locked, uint256 unlocked) = tokenLocker.getAccountBalances(address(this));

        assertEq(locked, 0);
        assertEq(unlocked, 1);
    }
}
