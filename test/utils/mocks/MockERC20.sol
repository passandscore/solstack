// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC20} from "@solmate-6.7.0/tokens/ERC20.sol";

contract MockERC20 is ERC20 {

     constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint8 decimals
    ) payable ERC20(name, symbol, decimals) {
        _mint(msg.sender, totalSupply);
    }
}