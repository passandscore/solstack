// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {ERC721} from "@solmate-6.7.0/tokens/ERC721.sol";
import {Owned} from "@solmate-6.7.0/auth/Owned.sol";
import {LibString} from "@solmate-6.7.0/utils/LibString.sol";

/**
 * @title Basic ERC721
 * @author passandscore - https://github.com/passandscore
 * @dev Basic ERC721 with the following features:
 *
 *  - Built-in NFT drop with ability to ajust the price.
 *  - Admin function for the owner to mint free NFTs.
 *  - Fixed maximum supply.
 */

contract BasicERC721 is ERC721, Owned {
    string public baseURI;
    uint256 public immutable MAX_SUPPLY;
    uint256 public mintPrice;
    uint256 public totalSupply;
    bool public isMintOpen = true;

    /**
     @dev Constructor for the BasicERC721 contract.
        @param _name The name of the NFT.
        @param _symbol The symbol of the NFT.
        @param _uri The baseURI for the NFT metadata.
        @param price The price of each NFT during the initial sale.
        @param maxSupply The maximum supply of the NFT.
        */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 price,
        uint256 maxSupply
    ) payable ERC721(_name, _symbol) Owned(msg.sender) {
        baseURI = _uri;
        mintPrice = price;
        MAX_SUPPLY = maxSupply;
    }

    ///@dev Triggered when the sale is not active.
    error SaleNotActive();

    ///@dev Triggered when the total supply exceeds the maximum supply.
    error ExceedsMaxSupply();

    ///@dev Triggered when the value sent is less than the mint price.
    error InsufficientValue();

    /**
     * @dev Mints a specific number of NFTs for the caller.
     * @param amount The number of NFTs to mint.
     */
    function mint(uint256 amount) external payable {
        if (!isMintOpen) {
            revert SaleNotActive();
        }

        if (totalSupply + amount > MAX_SUPPLY) {
            revert ExceedsMaxSupply();
        }

        if (mintPrice * amount > msg.value) {
            revert InsufficientValue();
        }

        for (uint256 i = 1; i <= amount; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }

        totalSupply += amount;
    }

    /**
     * @dev Allows the owner to mint a specific number of NFTs for free.
     * @param amount The number of NFTs to mint.
     */
    function adminMint(uint256 amount) external onlyOwner {
        if (totalSupply + amount > MAX_SUPPLY) {
            revert ExceedsMaxSupply();
        }

        for (uint256 i = 1; i <= amount; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }

        totalSupply += amount;

    }

    /// @dev Withdraws the contract's balance to the owner's address.
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev Updates the baseURI that will be used to retrieve NFT metadata.
     * @param baseURI_ The baseURI to be used.
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /// @dev Pauses the NFT sale.
    function pauseMint() external onlyOwner {
        isMintOpen = false;
    }

    /// @dev Resumes the NFT sale.
    function resumeMint() external onlyOwner {
        isMintOpen = true;
    }

    /**
     * @dev Sets the price of each NFT during the initial sale.
     * @param price The price of each NFT during the initial sale | precision:18
     */
    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    // =============================================================
    //                         Required Overrides
    // =============================================================

    /**
     * @dev Returns the URI for a specific token ID.
     * @param id The token ID.
     * @return The URI for the token ID containing the metadata.
     */
    function tokenURI(
        uint256 id
    ) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, LibString.toString(id)));
    }

    /**
     * @dev Indicates whether the contract supports the ERC721 interface.
     * @param interfaceId The interface ID.
     * @return True if the contract supports the interface, false otherwise.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
