// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {ERC1155} from "@solmate-6.7.0/tokens/ERC1155.sol";
import {Owned} from "@solmate-6.7.0/auth/Owned.sol";

/**
 * @title Simple ERC1155
 * @author passandscore - https://github.com/passandscore
 * @dev Simple ERC1155 with the following features:
 *
 * - A URI for all token types.
 * - Minting and burning of tokens by the owner.
 * - Minting and burning of tokens in batches by the owner.
 */

contract BasicERC1155 is ERC1155, Owned {
    string private _uri;

    constructor(string memory uri_) payable Owned(msg.sender) {
        _uri = uri_;
    }

    /**
     * @dev A method for the owner to set the URI for all token types.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the ERC].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(
        uint256 /* id */
    ) public view virtual override returns (string memory) {
        return _uri;
    }


    /**
     * @dev A method for the owner to mint new ERC1155 tokens.
     * @param account The account for new tokens to be sent to.
     * @param id The id of the token type.
     * @param amount The number of tokens to be minted.
     * @param data additional data that will be used within the receivers' onERC1155Received method
     */
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyOwner {
        _mint(account, id, amount, data);
    }

    /**
     * @dev A method for the owner to burn an existing ERC1155 token.
     * @param from The account for existing tokens to be burnt from.
     * @param id The id of the token type.
     * @param amount The number of tokens to be burnt.
     */

    function burn(address from, uint256 id, uint256 amount) external onlyOwner {
        _burn(from, id, amount);
    }



       /**
     * @dev A method for the owner to mint new ERC1155 tokens in batches.
     * @param to The account for new tokens to be sent to.
     * @param ids The ids of the token types.
     * @param amounts The number of tokens to be minted.
     * @param data additional data that will be used within the receivers' onERC1155Received method
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyOwner {
        _batchMint(to, ids, amounts, data);
    }

    /**
     * @dev A method for the owner to burn an existing ERC1155 tokens in batches.
     * @param from The account for existing tokens to be burnt from.
     * @param ids The ids of the token types.
     * @param amounts The number of tokens to be burnt.
     */
    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyOwner {
        _batchBurn(from, ids, amounts);
    }

 
}
