// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {ERC20} from "@solmate-6.7.0/tokens/ERC20.sol";

/**
 * @title Fixed ERC20
 * @author passandscore - https://github.com/passandscore
 * @dev Fixed ERC20 with the following features:
 *
 * - Minting and burning of tokens by the owner.
 * - No minting function. Total supply is minted on deployment.
 *
 * A fixed supply is minted on deployment, and new tokens can never be created.
 */

contract FixedERC20 is ERC20 {
    /**
     * @param name Token Name
     * @param symbol Token Symbol
     * @param totalSupply Total Supply
     * @param decimals Token Decimals
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint8 decimals
    ) payable ERC20(name, symbol, decimals) {
        _mint(msg.sender, totalSupply);
    }
}
