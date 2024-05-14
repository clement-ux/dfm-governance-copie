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

    function add_liquidity(uint256[2] calldata _amounts, uint256 _min_mint_amount) external returns (uint256) {
        coins[0].transferFrom(msg.sender, address(this), _amounts[0]);
        coins[1].transferFrom(msg.sender, address(this), _amounts[1]);
        return _min_mint_amount;
    }

    function price_oracle() external pure returns (uint256) {
        return 1e18;
    }
}
