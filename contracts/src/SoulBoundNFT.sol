// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721} from "@solmate-6.7.0/tokens/ERC721.sol";
import {Owned} from "@solmate-6.7.0/auth/Owned.sol";


/**
 * @title Soulbound NFT
 * @author passandscore - https://github.com/passandscore
 * @dev ERC721 Soulbound NFT with the following features:
 *
 *  - Minting capability.
 *  - Max mint per wallet.
 *  - No transfer capability.
 */

contract SoulboundNFT is ERC721, Owned {
    string public baseURI;
    uint256 public immutable MAX_SUPPLY;
    uint256 public totalSupply;
    uint8 public maxMintPerWallet;

    /**
     * @param _name NFT Name
     * @param _symbol NFT Symbol
     * @param _uri Token URI used for metadata
     * @param _maxSupply Maximum # of NFTs
     * @param _maxMintPerWallet Maximum # of NFTs that can be minted per wallet
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _maxSupply,
        uint8 _maxMintPerWallet
    ) payable ERC721(_name, _symbol) Owned(msg.sender) {
        baseURI = _uri;
        MAX_SUPPLY = _maxSupply;
        maxMintPerWallet = _maxMintPerWallet;
    }

    /// @dev triggered when the maximum supply is reached
    error MaxSupplyReached();

    /// @dev triggered when the mint amount exceeds the maximum mint per wallet
    error ExceedsMaxMintPerWallet();

    /// @dev triggered when a transfer is attempted
    error SoulBoundToken_TransferNotAllowed();

    /**
     * @dev Mints a new NFT.
     * @param amount The amount of NFTs to mint.
     *
     * Requirements:
     * - The total supply must not exceed the maximum supply.
     * - The amount of NFTs to mint must not exceed the maximum mint per wallet.
     */
    function mint(uint256 amount) public {
        address to = msg.sender;
        
        if (totalSupply + 1 >= MAX_SUPPLY) {
            revert MaxSupplyReached();
        }

        if (
            maxMintPerWallet != 0 && amount + _balanceOf[to] > maxMintPerWallet
        ) {
            revert ExceedsMaxMintPerWallet();
        }

        for (uint256 i = 1; i <= amount; i++) {
            _safeMint(to, totalSupply + i);
        }

        totalSupply += amount;
    }

    /**
     * @dev Updates the baseURI that will be used to retrieve NFT metadata.
     * @param baseURI_ The baseURI to be used.
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @dev Returns the URI for a given token ID.
     * @param id uint256 ID of the token to query.
     * @return string URI of the token.
     */
    function tokenURI(
        uint256 id
    ) public view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Updates the maximum number of NFTs that can be minted per wallet.
     * @param _maxMintPerWallet The maximum number of NFTs that can be minted per wallet.
     * @notice Set to 0 to disable this feature.
     */
    function setMaxMintPerWallet(uint8 _maxMintPerWallet) external onlyOwner {
        maxMintPerWallet = _maxMintPerWallet;
    }

    // =============================================================
    //                         Transfer Overrides
    // =============================================================
    
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        revert SoulBoundToken_TransferNotAllowed();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        revert SoulBoundToken_TransferNotAllowed();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public override {
        revert SoulBoundToken_TransferNotAllowed();
    }
}
