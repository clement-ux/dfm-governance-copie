// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {DefaultValues as DEF} from "../../../utils/DefaultValues.sol";

import {ITokenLocker} from "../../../../contracts/interfaces/ITokenLocker.sol";
import {IncentiveVoting} from "../../../../contracts/IncentiveVoting.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardIncentiveVoting} from "../../../utils/WizardIncentiveVoting.sol";

contract Unit_Concrete_IncentiveVoting_GetAccountRegisteredLocks_ is Unit_Shared_Test_ {
    using WizardIncentiveVoting for IncentiveVoting;

    /*//////////////////////////////////////////////////////////////
                            VALIDATING TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Test Get account registered locks under following conditions:
    /// - No locks registered
    function test_GetAccountRegisteredLocks_When_NoLocks() public view {
        (uint256 frozenWeight, IncentiveVoting.LockData[] memory locks) =
            incentiveVoting.getAccountRegisteredLocks(address(this));

        assertEq(frozenWeight, 0);
        assertEq(locks.length, 0);
    }

    /// @notice Test Get account registered locks under following conditions:
    /// - Lock 1 ether of token for 5 weeks on TokenLocker
    /// - Freeze the account
    /// - Register account weight
    /// - Skip 3 weeks
    function test_GetAccountRegisteredLocks_When_Frozen()
        public
        lock(
            Modifier_Lock({
                skipBefore: 0,
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
                skipAfter: 3 weeks
            })
        )
    {
        (uint256 frozenWeight, IncentiveVoting.LockData[] memory locks) =
            incentiveVoting.getAccountRegisteredLocks(address(this));

        assertEq(frozenWeight, DEF.LOCK_AMOUNT * 52);
        assertEq(locks.length, 0);
    }

    /// @notice Test Get account registered locks under following conditions:
    /// - Lock 1 ether of token for 5 weeks and 2 ether for 10 weeks on TokenLocker
    /// - Register account weight
    /// - Skip 3 weeks
    function test_GetAccountRegisteredLocks_When_NotFrozen_NoUnlocks()
        public
        lockMany(
            Modifier_LockMany({
                skipBefore: 0,
                user: address(this),
                amountToLock: [uint64(DEF.LOCK_AMOUNT), 2 * uint64(DEF.LOCK_AMOUNT), 0, 0, 0],
                duration: [uint8(DEF.LOCK_DURATION_W), 2 * uint8(DEF.LOCK_DURATION_W), 0, 0, 0],
                skipAfter: 0
            })
        )
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
                skipAfter: 3 weeks
            })
        )
    {
        (uint256 frozenWeight, IncentiveVoting.LockData[] memory locks) =
            incentiveVoting.getAccountRegisteredLocks(address(this));

        assertEq(frozenWeight, 0);
        assertEq(locks.length, 2);
        assertEq(locks[0].amount, DEF.LOCK_AMOUNT * 2);
        assertEq(locks[0].epochsToUnlock, DEF.LOCK_DURATION_W * 2 - 3);
        assertEq(locks[1].amount, DEF.LOCK_AMOUNT);
        assertEq(locks[1].epochsToUnlock, DEF.LOCK_DURATION_W - 3);
    }

    /// @notice Test Get account registered locks under following conditions:
    /// - Lock 1 ether of token for 5 weeks and 2 ether for 10 weeks on TokenLocker
    /// - Register account weight
    /// - Skip 6 weeks
    function test_GetAccountRegisteredLocks_When_NotFrozen_WithUnlocks()
        public
        lockMany(
            Modifier_LockMany({
                skipBefore: 0,
                user: address(this),
                amountToLock: [uint64(DEF.LOCK_AMOUNT), 2 * uint64(DEF.LOCK_AMOUNT), 0, 0, 0],
                duration: [uint8(DEF.LOCK_DURATION_W), 2 * uint8(DEF.LOCK_DURATION_W), 0, 0, 0],
                skipAfter: 0
            })
        )
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
                skipAfter: 6 weeks
            })
        )
    {
        (uint256 frozenWeight, IncentiveVoting.LockData[] memory locks) =
            incentiveVoting.getAccountRegisteredLocks(address(this));

        assertEq(frozenWeight, 0);
        assertEq(locks.length, 1);
        assertEq(locks[0].amount, DEF.LOCK_AMOUNT * 2);
        assertEq(locks[0].epochsToUnlock, DEF.LOCK_DURATION_W * 2 - 6);
    }
}
