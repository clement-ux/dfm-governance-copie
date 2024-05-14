// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {stdError} from "forge-std/StdError.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {TokenLocker} from "../../../../contracts/TokenLocker.sol";
import {TokenLockerBase} from "../../../../contracts/dependencies/TokenLockerBase.sol";
import {IIncentiveVoting} from "../../../../contracts/interfaces/IIncentiveVoting.sol";
import {Unit_Shared_Test_} from "../../shared/Shared.sol";
import {WizardTokenLocker} from "../../../utils/WizardTokenLocker.sol";

contract Unit_Concrete_TokenLocker_Constructor_ is Unit_Shared_Test_ {
    using WizardTokenLocker for Vm;

    uint256 internal startTime;

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/

    function test_TokenLocker_Constructor() public {
        tokenLocker = new TokenLocker(
            address(coreOwner),
            IERC20(govToken),
            IIncentiveVoting(address(incentiveVoting)),
            IERC20(stableCoin),
            address(lpLocker),
            true
        );

        assertEq(address(tokenLocker.incentiveVoter()), address(incentiveVoting));
        assertEq(address(tokenLocker.stableCoin()), address(stableCoin));
        assertEq(address(tokenLocker.lpLocker()), address(lpLocker));
        assertEq(stableCoin.allowance(address(tokenLocker), address(lpLocker)), MAX);
        assertEq(govToken.allowance(address(tokenLocker), address(lpLocker)), MAX);
        assertEq(address(tokenLocker.lockToken()), address(govToken));
        assertEq(tokenLocker.isPenaltyWithdrawalEnabled(), true);
        assertEq(tokenLocker.EPOCH_LENGTH(), 7 days);
        assertEq(tokenLocker.MAX_LOCK_EPOCHS(), 52);
    }
}
