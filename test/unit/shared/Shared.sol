// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// DAO contracts
import {Vault} from "../../../contracts/Vault.sol";
import {LPLocker} from "../../../contracts/LpLocker.sol";
import {GovToken} from "../../../contracts/GovToken.sol";
import {CoreOwner} from "../../../contracts/CoreOwner.sol";
import {TokenLocker} from "../../../contracts/TokenLocker.sol";
import {BoostCalculator} from "../../../contracts/BoostCalculator.sol";
import {IncentiveVoting} from "../../../contracts/IncentiveVoting.sol";

import {ILPLocker} from "../../../contracts/interfaces/ILPLocker.sol";
import {ITokenLocker} from "../../../contracts/interfaces/ITokenLocker.sol";
import {IERC20Mintable} from "../../../contracts/interfaces/IERC20Mintable.sol";
import {IBoostCalculator} from "../../../contracts/interfaces/IBoostCalculator.sol";
import {IIncentiveVoting} from "../../../contracts/interfaces/IIncentiveVoting.sol";

import {MockLpToken} from "../../utils/mocks/MockLpToken.sol";
import {MockStableCoin} from "../../utils/mocks/MockStableCoin.sol";

// Test imports
import {Modifiers} from "./Modifiers.sol";
import {Base_Test_} from "../../Base.sol";
import {Environment as ENV} from "../../utils/Environment.sol";
import {DeploymentParams as DP} from "./DeploymentParameters.sol";

abstract contract Unit_Shared_Test_ is Modifiers {
    MockLpToken public lpToken;
    MockStableCoin public stableCoin;

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct DeploymentInfos {
        Predicted vault;
        Predicted lpToken;
        Predicted lpLocker;
        Predicted govToken;
        Predicted coreOwner;
        Predicted stableCoin;
        Predicted tokenLocker;
        Predicted boostCalculator;
        Predicted incentiveVoting;
        Predicted emissionSchedule;
    }

    struct Predicted {
        address predicted;
        bytes1 nonce;
    }

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/

    DeploymentInfos public DI;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

        // 1. Set up realistic environment test
        _setUpRealisticEnvironment();

        // 2. Generate user addresses
        _generateAddresses();

        // 3. Deploy contracts
        _deployContracts();

        // 4. Check predicted and deployed address match
        _checkPredictedAndDeployedAddress();
    }

    /*//////////////////////////////////////////////////////////////
                             CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _setUpRealisticEnvironment() internal {
        vm.warp(ENV.TIMESTAMP); // Setup realistic environment Timestamp
        vm.roll(ENV.BLOCKNUMBER); // Setup realistic environment Blocknumber
    }

    function _generateAddresses() internal {
        alice = makeAddr("alice");
        manager = makeAddr("manager");
        deployer = makeAddr("deployer");
        multisig = makeAddr("multisig");
        guardian = makeAddr("guardian");
        feeReceiver = makeAddr("feeReceiver");
    }

    function _deployContracts() internal {
        // 1. Set nonces
        _setNonces();

        // 2. Predict addresses
        _predictAddresses();

        vm.startPrank(deployer);

        // 3. Deploy contracts
        // 3.1 Core Owner
        vm.setNonce(deployer, uint8(DI.coreOwner.nonce));
        coreOwner = new CoreOwner(multisig, feeReceiver, DP.START_OFFSET);

        // 3.2 GovToken
        vm.setNonce(deployer, uint8(DI.govToken.nonce));
        govToken = new GovToken(DP.NAME, DP.SYMBOL, DI.vault.predicted, DI.tokenLocker.predicted, DP.SUPPLY);

        // 3.3 Stablecoin
        vm.setNonce(deployer, uint8(DI.stableCoin.nonce));
        stableCoin = new MockStableCoin(DP.STABLE_NAME, DP.STABLE_SYMBOL);


        // 3.4 LP Token
        vm.setNonce(deployer, uint8(DI.lpToken.nonce));
        lpToken =
            new MockLpToken(DP.LP_NAME, DP.LP_SYMBOL, IERC20(DI.govToken.predicted), IERC20(DI.stableCoin.predicted));

        // 3.5 LpLocker
        vm.setNonce(deployer, uint8(DI.lpLocker.nonce));
        lpLocker = new LPLocker(
            DI.coreOwner.predicted,
            address(lpToken),
            IERC20(DI.govToken.predicted),
            IERC20(DI.stableCoin.predicted),
            DP.PENALTY_WITHDRAWAL_ENABLED
        );

        // 3.6 Token Locker
        vm.setNonce(deployer, uint8(DI.tokenLocker.nonce));
        tokenLocker = new TokenLocker(
            DI.coreOwner.predicted,
            IERC20(DI.govToken.predicted),
            IIncentiveVoting(DI.incentiveVoting.predicted),
            IERC20(DI.stableCoin.predicted),
            DI.lpLocker.predicted,
            DP.PENALTY_WITHDRAWAL_ENABLED
        );

        // 3.7 Incentive Voting
        vm.setNonce(deployer, uint8(DI.incentiveVoting.nonce));
        incentiveVoting =
            new IncentiveVoting(DI.coreOwner.predicted, ITokenLocker(DI.tokenLocker.predicted), DI.vault.predicted);

        // 3.8 Vault
        vm.setNonce(deployer, uint8(DI.vault.nonce));
        vault = new Vault(
            DI.coreOwner.predicted,
            IERC20Mintable(DI.govToken.predicted),
            IIncentiveVoting(DI.incentiveVoting.predicted),
            IBoostCalculator(DI.boostCalculator.predicted)
        );

        // 3.9 Boost Calculator
        vm.setNonce(deployer, uint8(DI.boostCalculator.nonce));
        boostCalculator = new BoostCalculator(
            DI.coreOwner.predicted,
            ILPLocker(DI.lpLocker.predicted),
            DP.BOOST_GRACE_EPOCHS,
            DP.MAX_BOOST_MULTIPLIER,
            DP.MAX_BOOSTABLE_PCT,
            DP.DECAY_BOOST_PCT
        );

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    function _setNonces() internal {
        DI.coreOwner.nonce = bytes1(0x01); // 1. Core Owner
        DI.govToken.nonce = bytes1(0x02); // 2. GovToken
        DI.stableCoin.nonce = bytes1(0x03); // 3. StableCoin
        DI.lpToken.nonce = bytes1(0x04); // 4. LP Token
        DI.lpLocker.nonce = bytes1(0x05); // 5. LP Locker
        DI.tokenLocker.nonce = bytes1(0x06); // 6. Token Locker
        DI.incentiveVoting.nonce = bytes1(0x07); // 7. Incentive Voting
        DI.vault.nonce = bytes1(0x08); // 8. Vault
        DI.boostCalculator.nonce = bytes1(0x09); // 9. Boost Calculator
    }

    function _predictAddresses() internal {
        DI.coreOwner.predicted = computeAddress(deployer, DI.coreOwner.nonce); // 1. Core Owner
        DI.govToken.predicted = computeAddress(deployer, DI.govToken.nonce); // 2. GovToken
        DI.stableCoin.predicted = computeAddress(deployer, DI.stableCoin.nonce); // 3. StableCoin
        DI.lpToken.predicted = computeAddress(deployer, DI.lpToken.nonce); // 4. LP Token
        DI.lpLocker.predicted = computeAddress(deployer, DI.lpLocker.nonce); // 5. LP Locker
        DI.tokenLocker.predicted = computeAddress(deployer, DI.tokenLocker.nonce); // 6. Token Locker
        DI.incentiveVoting.predicted = computeAddress(deployer, DI.incentiveVoting.nonce); // 7. Incentive Voting
        DI.vault.predicted = computeAddress(deployer, DI.vault.nonce); // 8. Vault
        DI.boostCalculator.predicted = computeAddress(deployer, DI.boostCalculator.nonce); // 9. Boost Calculator
    }

    function computeAddress(address _deployer, bytes1 _nonce) public pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), _deployer, _nonce)))));
    }

    function _checkPredictedAndDeployedAddress() internal view {
        require(address(coreOwner) == DI.coreOwner.predicted, "CoreOwner address mismatch");
        require(address(govToken) == DI.govToken.predicted, "GovToken address mismatch");
        require(address(stableCoin) == DI.stableCoin.predicted, "StableCoin address mismatch");
        require(address(lpToken) == DI.lpToken.predicted, "LP Token address mismatch");
        require(address(lpLocker) == DI.lpLocker.predicted, "LP Locker address mismatch");
        require(address(tokenLocker) == DI.tokenLocker.predicted, "Token Locker address mismatch");
        require(address(incentiveVoting) == DI.incentiveVoting.predicted, "Incentive Voting address mismatch");
        require(address(vault) == DI.vault.predicted, "Vault address mismatch");
        require(address(boostCalculator) == DI.boostCalculator.predicted, "Boost Calculator address mismatch");
    }
}
