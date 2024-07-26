// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {FixedERC20} from "./FixedERC20.sol";
import {Owned} from "@solmate-6.7.0/auth/Owned.sol";

/**
 * @title AntiBotERC20
 * @author passandscore - https://github.com/passandscore
 * @dev AntiBotERC20 is used to make it difficult for bots to execute their typical buy-sell strategies within a single block, as any attempt to transfer tokens bought in the same block will be flagged and blocked.
 *
 * The contract owner can enable or disable the bot check.
 */

contract AntiBotERC20 is FixedERC20, Owned {
    /// @dev Emitted when the bot check status is changed.
    event BotCheckStatusChanged(bool status);

    mapping(address => uint256) private _buyBlock;
    bool public enableBotCheck = true;

    /**
     * @param name Token Name
     * @param symbol Token Symbol
     * @param totalSupply Total Supply
     * @param decimals Token Decimals
     *
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint8 decimals
    ) FixedERC20(name, symbol, totalSupply, decimals) Owned(msg.sender) {}

    /**
     * @dev Modifier to check if the same address is buying tokens in the same block.
     * @param from The address of the buyer.
     * @param to The address of the recipient.
     *
     * Requirements:
     * - The bot check must be enabled.
     */
    modifier isBot(address from, address to) {
        if (enableBotCheck)
            require(_buyBlock[from] != block.number, "Bot blocked!");
        _;
    }

    /**
     * @dev A method to enable or disable the bot check.
     * @param _status The status of the bot check.
     *
     * Requirements:
     * - The caller must be the owner.
     */
    function setCheckBot(bool _status) public onlyOwner {
        enableBotCheck = _status;

        emit BotCheckStatusChanged(_status);
    }

    /**
     * @dev A method to check if the same address is buying tokens in the same block.
     * @param from The address of the buyer.
     * @param to The address of the recipient.
     */
    function _requireBotCheck(
        address from,
        address to
    ) internal isBot(from, to) {
        _buyBlock[to] = block.number;
    }

    // =============================================================
    //                         Required Overrides
    // =============================================================

    /**
     * @dev Transfer tokens from one address to another.
     * @param to The address to transfer to.
     * @param amount The amount to be transferred.
     * @return A boolean that indicates if the operation was successful.
     *
     * Changes:
     * - Added bot check.
     */
    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        _requireBotCheck(msg.sender, to);
        return super.transfer(to, amount);
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param amount The amount to be transferred.
     * @return A boolean that indicates if the operation was successful.
     *
     * Changes:
     * - Added bot check.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        _requireBotCheck(from, to);
        return super.transferFrom(from, to, amount);
    }
}
