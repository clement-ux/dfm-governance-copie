// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// External imports
import {Test} from "forge-std/Test.sol";
import {Constants} from "./utils/Constants.sol";

// DAO contracts
import {Vault} from "../contracts/Vault.sol";
import {LPLocker} from "../contracts/LpLocker.sol";
import {GovToken} from "../contracts/GovToken.sol";
import {CoreOwner} from "../contracts/CoreOwner.sol";
import {TokenLocker} from "../contracts/TokenLocker.sol";
import {BoostCalculator} from "../contracts/BoostCalculator.sol";
import {IncentiveVoting} from "../contracts/IncentiveVoting.sol";

abstract contract Base_Test_ is Test, Constants {
    Vault public vault;
    LPLocker public lpLocker;
    GovToken public govToken;
    CoreOwner public coreOwner;
    TokenLocker public tokenLocker;
    BoostCalculator public boostCalculator;
    IncentiveVoting public incentiveVoting;

    address public alice;
    address public carole;
    address public manager;
    address public deployer;
    address public multisig;
    address public guardian;
    address public feeReceiver;

    function setUp() public virtual {}
}
