// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vault} from "../../../contracts/Vault.sol";

library DeploymentParams {
    /*//////////////////////////////////////////////////////////////
                             1. CORE OWNER
    //////////////////////////////////////////////////////////////*/

    /// @notice Seconds to subtract when calculating `START_TIME`. With an epoch length
    /// of one week, an offset of 3.5 days means that a new epoch begins every
    /// Sunday at 12:00:00 UTC.
    uint256 public constant START_OFFSET = 3.5 days;

    /*//////////////////////////////////////////////////////////////
                          2. GOVERNANCE TOKEN
    //////////////////////////////////////////////////////////////*/

    string public constant NAME = "Valueless Governance Token";

    string public constant SYMBOL = "VGT";

    uint256 public constant SUPPLY = 100_000_000 ether;

    /*//////////////////////////////////////////////////////////////
                             3. STABLECOIN
    //////////////////////////////////////////////////////////////*/

    string public constant STABLE_NAME = "DeFi Money USD";

    string public constant STABLE_SYMBOL = "dmUSD";

    /*//////////////////////////////////////////////////////////////
                               4. LPTOKEN
    //////////////////////////////////////////////////////////////*/

    string public constant LP_NAME = "DeFi Money LP Token";

    string public constant LP_SYMBOL = "dmLP";

    /*//////////////////////////////////////////////////////////////
                            3. TOKEN LOCKER
    //////////////////////////////////////////////////////////////*/

    uint256 public constant LOCK_TO_TOKEN_RATIO = 1 ether;

    /// @notice are penalty withdrawals of locked positions enabled initially?
    bool public constant PENALTY_WITHDRAWAL_ENABLED = true;

    /*//////////////////////////////////////////////////////////////
                          4. INCENTIVE VOTING
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                                5. VAULT
    //////////////////////////////////////////////////////////////*/

    /// @notice list of initial fixed per-epoch emissions, once this many epochs have passed
    /// the `EmissionSchedule` takes effect
    function fixedInitialAmounts() public pure returns (uint128[] memory) {
        uint128[] memory amounts = new uint128[](2);
        amounts[0] = 100_000 ether;
        amounts[1] = 100_000 ether;

        return amounts;
    }

    /// @notice list of `(address, amount)` for approvals to transfer tokens out of the vault
    /// used for allocating tokens outside of normal emissions, e.g airdrops, vests, team treasury
    /// IMPORTANT: you must allocate some balance to the deployer that can be locked in the first
    /// epoch and used to vote for the initial round of emissions
    function initialAllowances() public pure returns (Vault.InitialAllowance[] memory) {
        Vault.InitialAllowance[] memory allowances = new Vault.InitialAllowance[](0);

        return allowances;
    }

    function initialReceivers() public pure returns (Vault.InitialReceiver[] memory) {
        Vault.InitialReceiver[] memory receivers = new Vault.InitialReceiver[](0);

        return receivers;
    }

    /*//////////////////////////////////////////////////////////////
                          6. BOOST CALCULATOR
    //////////////////////////////////////////////////////////////*/

    /// @notice number of initial epochs where all claims recieve maximum boost
    /// should be >=2, because in the first epoch there are no emissions and in the second
    /// epoch users have not have a chance to lock yet
    uint256 public constant BOOST_GRACE_EPOCHS = 30;

    /// @notice max boost multiplier
    uint8 public constant MAX_BOOST_MULTIPLIER = 10;

    /// @notice percentage of the total epoch emissions that an account can claim with max
    /// boost, expressed as a percent relative to the account's percent of the total
    /// lock weight. For example, if an account has 5% of the lock weight and the
    /// max boostable percent is 150, the account can claim 7.5% (5% * 150%) of the
    /// epoch's emissions at a max boost.
    uint16 public constant MAX_BOOSTABLE_PCT = 10000; // 100%

    /// @notice percentage of the total epoch emissions that an account can claim with decaying boost
    uint16 public constant DECAY_BOOST_PCT = 10000; // 100%
}
