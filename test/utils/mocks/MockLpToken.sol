// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockLpToken is ERC20 {
    IERC20[2] public coins;

    constructor(string memory name, string memory symbol, IERC20 govToken, IERC20 stableCoin) ERC20(name, symbol) {
        coins[0] = govToken;
        coins[1] = stableCoin;
    }

    function mint(address to, uint256 value) public virtual {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public virtual {
        _burn(from, value);
    }
}
