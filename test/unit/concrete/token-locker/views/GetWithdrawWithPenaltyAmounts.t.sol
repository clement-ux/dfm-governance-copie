// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Unit_Shared_Test_} from "../../../shared/Shared.sol";

contract Unit_Concrete_TokenLocker_GetWithdrawWithPenaltyAmounts_ is Unit_Shared_Test_ {
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

    function test_GetWithdrawWithPenaltyAmounts_When_AmountToWithdrawIsNull() public view {
        (uint256 withdrawAmount, uint256 penaltyAmount) = tokenLocker.getWithdrawWithPenaltyAmounts(address(this), 0);

        assertEq(withdrawAmount, 0);
        assertEq(penaltyAmount, 0);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Locks 1 token for 3 epochs
    /// - Time jump 3 epochs
    /// - Update account weight
    function test_GetWithdrawWithPenaltyAmounts_When_FullUnlocked()
        public
        lock(
            Modifier_Lock({
                skipBefore: 0,
                user: address(this),
                amountToLock: 1 ether,
                duration: 3,
                skipAfter: 3 * EPOCH_LENGTH
            })
        )
    {
        tokenLocker.getAccountWeightWrite(address(this));

        (uint256 withdrawAmount, uint256 penaltyAmount) =
            tokenLocker.getWithdrawWithPenaltyAmounts(address(this), 1 ether);

        assertEq(withdrawAmount, 1 ether);
        assertEq(penaltyAmount, 0);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Locks 1 token for 3 epochs
    function test_GetWithdrawWithPenaltyAmounts_When_SinglePosition_FullLocked_FullPosition()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 1 ether, duration: 3, skipAfter: 0}))
    {
        (uint256 withdrawAmount, uint256 penaltyAmount) =
            tokenLocker.getWithdrawWithPenaltyAmounts(address(this), 1 ether);

        assertApproxEqRel(withdrawAmount, 1 ether, 1e17);
        assertGe(withdrawAmount, penaltyAmount);
        assertNotEq(penaltyAmount, 0);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Locks 2 token for 3 epochs
    function test_GetWithdrawWithPenaltyAmounts_When_SinglePosition_FullLocked_HalfPosition()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 2 ether, duration: 3, skipAfter: 0}))
    {
        (uint256 withdrawAmount, uint256 penaltyAmount) =
            tokenLocker.getWithdrawWithPenaltyAmounts(address(this), 1 ether);

        assertApproxEqRel(withdrawAmount, 1 ether, 1e17);
        assertGe(withdrawAmount, penaltyAmount);
        assertNotEq(penaltyAmount, 0);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Locks 2 token for 3 epochs
    /// - Locks 5 token for 5 epochs
    function test_GetWithdrawWithPenaltyAmounts_When_MultiplePositions_FullLocked()
        public
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 2 ether, duration: 3, skipAfter: 0}))
        lock(Modifier_Lock({skipBefore: 0, user: address(this), amountToLock: 5 ether, duration: 5, skipAfter: 0}))
    {
        (uint256 withdrawAmount, uint256 penaltyAmount) =
            tokenLocker.getWithdrawWithPenaltyAmounts(address(this), 3 ether);

        assertApproxEqRel(withdrawAmount, 3 ether, 1e17);
        assertGe(withdrawAmount, penaltyAmount);
        assertNotEq(penaltyAmount, 0);
    }

    /// @notice Test freeze, Using following conditions:
    /// - Time jump 255 epochs
    /// - Locks 1 token for 3 epochs
    function test_GetWithdrawWithPenaltyAmounts_When_EpochIs256()
        public
        lock(
            Modifier_Lock({
                skipBefore: 255 * EPOCH_LENGTH,
                user: address(this),
                amountToLock: 1 ether,
                duration: 3,
                skipAfter: 0
            })
        )
    {
        (uint256 withdrawAmount, uint256 penaltyAmount) =
            tokenLocker.getWithdrawWithPenaltyAmounts(address(this), 1 ether);

        assertApproxEqRel(withdrawAmount, 1 ether, 1e17);
        assertGe(withdrawAmount, penaltyAmount);
        assertNotEq(penaltyAmount, 0);
    }
    /*
    */
}
