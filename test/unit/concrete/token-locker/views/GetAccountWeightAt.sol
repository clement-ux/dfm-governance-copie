// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Unit_Shared_Test_} from "../../../shared/Shared.sol";

contract Unit_Concrete_TokenLocker_GetAccountWeightAt_ is Unit_Shared_Test_ {
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

    function test_GetAccountWeightAt_When_InFutur() public view {
        assertEq(tokenLocker.getAccountWeightAt(address(this), 1), 0);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Locks 1 token for 5 epochs
    /// - Time jump 5 epochs
    /// - Update account weight
    function test_GetAccountWeightAt_When_EpochAskedIs_LowerThan_LastUpdate()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 5, skipAfter: 0}))
    {
        skip(5 * EPOCH_LENGTH);
        tokenLocker.getAccountWeightWrite(address(this));
        assertEq(tokenLocker.getAccountWeightAt(address(this), 0), 1 * 5);
        assertEq(tokenLocker.getAccountWeightAt(address(this), 1), 1 * 4);
        assertEq(tokenLocker.getAccountWeightAt(address(this), 2), 1 * 3);
        assertEq(tokenLocker.getAccountWeightAt(address(this), 3), 1 * 2);
        assertEq(tokenLocker.getAccountWeightAt(address(this), 4), 1 * 1);
        assertEq(tokenLocker.getAccountWeightAt(address(this), 5), 0);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Locks 1 token for 5 epochs
    /// - Time jump 5 epochs
    /// - Update account weight
    /// - Time jump 5 epochs
    function test_GetAccountWeightAt_When_EpochAskedIs_GreaterThan_LastUpdate_And_AmountLockedIsNull()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 5, skipAfter: 0}))
    {
        skip(5 * EPOCH_LENGTH);
        tokenLocker.getAccountWeightWrite(address(this));
        skip(5 * EPOCH_LENGTH);
        assertEq(tokenLocker.getAccountWeightAt(address(this), 6), 0);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Locks 1 token for 5 epochs
    /// - Freeze position
    /// - Time jump 5 epochs
    function test_GetAccountWeightAt_When_EpochAskedIs_GreaterThan_LastUpdate_And_Frozen()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 5, skipAfter: 0}))
        freeze(Modifier_Freeze({skipBefore: 0, user: address(this), skipAfter: 0}))
    {
        skip(5 * EPOCH_LENGTH);
        assertEq(tokenLocker.getAccountWeightAt(address(this), 3), 1 * 52);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Locks 1 token for 5 epochs
    /// - Time jump 5 epochs
    /// - NOT Update account weight
    function test_GetAccountWeightAt_When_EpochAskedIs_GreaterThan_LastUpdate_SinglePosition()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 5, skipAfter: 0}))
    {
        skip(5 * EPOCH_LENGTH);
        assertEq(tokenLocker.getAccountWeightAt(address(this), 0), 1 * 5);
        assertEq(tokenLocker.getAccountWeightAt(address(this), 1), 1 * 4);
        assertEq(tokenLocker.getAccountWeightAt(address(this), 2), 1 * 3);
        assertEq(tokenLocker.getAccountWeightAt(address(this), 3), 1 * 2);
        assertEq(tokenLocker.getAccountWeightAt(address(this), 4), 1 * 1);
        assertEq(tokenLocker.getAccountWeightAt(address(this), 5), 0);
    }

    function test_GetAccountWeightAt_When_EpochAskedIs_GreaterThan_LastUpdate_MultiplePositions()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1, duration: 3, skipAfter: 0}))
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 2, duration: 5, skipAfter: 0}))
    {
        skip(5 * EPOCH_LENGTH);
        assertEq(tokenLocker.getAccountWeightAt(address(this), 0), 1 * 3 + 2 * 5);
        assertEq(tokenLocker.getAccountWeightAt(address(this), 1), 1 * 2 + 2 * 4);
        assertEq(tokenLocker.getAccountWeightAt(address(this), 2), 1 * 1 + 2 * 3);
        assertEq(tokenLocker.getAccountWeightAt(address(this), 3), 0 + 2 * 2);
        assertEq(tokenLocker.getAccountWeightAt(address(this), 4), 0 + 2 * 1);
        assertEq(tokenLocker.getAccountWeightAt(address(this), 5), 0);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Time jump 255 epochs
    /// - Locks 1 token for 5 epochs
    /// - Time jump 5 epochs
    function test_GetAccountWeightAt_When_EpochAskedIs_GreaterThan_LastUpdate_And_EpochIs256()
        public
        lock(
            Modifier_Lock({
                skipBefore: 255 * EPOCH_LENGTH,
                user: address(this),
                amountToLock: 1,
                duration: 5,
                skipAfter: 5 * EPOCH_LENGTH
            })
        )
    {
        assertEq(tokenLocker.getAccountWeightAt(address(this), 255), 1 * 5);
        assertEq(tokenLocker.getAccountWeightAt(address(this), 256), 1 * 4);
        assertEq(tokenLocker.getAccountWeightAt(address(this), 257), 1 * 3);
        assertEq(tokenLocker.getAccountWeightAt(address(this), 258), 1 * 2);
        assertEq(tokenLocker.getAccountWeightAt(address(this), 259), 1 * 1);
        assertEq(tokenLocker.getAccountWeightAt(address(this), 260), 0);
    }

    /// @notice Same as previous, but not really necessary, only for coverage.
    function test_GetAccountWeight_() public view {
        assertEq(tokenLocker.getAccountWeight(address(this)), 0);
    }
}
