// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./dependencies/TokenLockerBase.sol";
import "./interfaces/IIncentiveVoting.sol";

/**
    @title Token Locker
    @notice Tokens can be locked in this contract to receive "lock weight",
            which is used within `AdminVoting` and `IncentiveVoting` to vote on
            core protocol operations.
 */
contract TokenLocker is TokenLockerBase {
    IIncentiveVoting public immutable incentiveVoter;

    constructor(
        address core,
        IERC20 _token,
        IIncentiveVoting _voter,
        bool _penaltyWithdrawalsEnabled
    ) TokenLockerBase(core, _token, 7 days, 52, _penaltyWithdrawalsEnabled) {
        incentiveVoter = _voter;
    }

    /**
        @notice Unfreeze all locks for the caller
        @dev When an account's locks are unfrozen, the epochs-to-unlock decay normally.
             This is the default locking behaviour for each account. Unfreezing locks
             also updates the frozen status within `IncentiveVoter` - otherwise it could be
             possible for accounts to have a larger registered vote weight than their actual
             lock weight.
        @param keepIncentivesVote If true, existing incentive votes are preserved when updating
                                  the frozen status within `IncentiveVoter`. Voting with unfrozen
                                  weight uses significantly more gas than voting with frozen weight.
                                  If the caller has many active locks and/or many votes, it will be
                                  much cheaper to set this value to false.

     */
    function unfreeze(bool keepIncentivesVote) external {
        incentiveVoter.unfreeze(msg.sender, keepIncentivesVote);
        _unfreeze(msg.sender);
    }

    /**
        @notice Pay a penalty to withdraw locked tokens
        @dev Withdrawals are processed starting with the lock that will expire soonest.
             The penalty starts at 100% and decays linearly based on the number of epochs
             remaining until the tokens unlock. The exact calculation used is:

             [total amount] * [epochs to unlock] / MAX_LOCK_EPOCHS = [penalty amount]

        @param amountToWithdraw Amount to withdraw. This
                                is the same number of tokens that will be received; the
                                penalty amount is taken on top of this. Reverts if the
                                caller's locked balances are insufficient to cover both
                                the withdrawal and penalty amounts. Setting this value as
                                `type(uint256).max` withdrawals the entire available locked
                                balance, excluding any lock at `MAX_LOCK_EPOCHS` as the
                                penalty on this lock would be 100%.
        @return uint256 Amount of tokens withdrawn, penalty amount paid
     */
    function withdrawWithPenalty(uint256 amountToWithdraw) external returns (uint256, uint256) {
        (uint256 withdrawn, uint256 penalty) = _withdrawWithPenalty(amountToWithdraw);
        if (penalty > 0) incentiveVoter.clearRegisteredWeight(msg.sender);
        return (withdrawn, penalty);
    }
}
