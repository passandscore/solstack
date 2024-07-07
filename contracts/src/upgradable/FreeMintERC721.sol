// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin-contracts-upgradeable-5.0.2/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";
import {Base64} from "@openzeppelin-contracts-5.0.2/utils/Base64.sol";
import {LibString} from "@solmate-6.7.0/utils/LibString.sol";


/**
 * @title FreeMint
 * @dev FreeMint is a contract for managing free NFT minting with URI metadata generation.
 */
contract FreeMintERC721 is OwnableUpgradeable, ERC721Upgradeable {

    uint256 public totalSupply;

    mapping(address => bool) private _minted;

    string public _nftName;
    string public _assetURI;
    string public _artistName;
    string public _description;

    uint32 public _mintStartTime;
    uint32 public _mintEndTime;
    bool public _mintingPaused;

    /// @dev The token was not found.
    error TokenNotFound();

    /// @dev The token has already been minted by the caller.
    error TokenAlreadyMinted();

    /// @dev The ability to mint tokens is not currently enabled.
    error MintingNotEnabled();

    // =============================================================
    //                         Initializer
    // =============================================================

    /**
     * @dev Initializes the contract with the specified name, symbol, and asset.
     */
    function initialize(
        string calldata name,
        string calldata symbol,
        string calldata asset
    ) external initializer {
        __Ownable_init(msg.sender);
        __ERC721_init(name, symbol);
        _assetURI = asset;
    }

    // =============================================================
    //                         Mint Control
    // =============================================================

    /**
     * @dev Pauses minting.
     */
    function pauseMint() external onlyOwner {
        _mintingPaused = true;
    }

    /**
     * @dev Resumes minting.
     */
    function resumeMint() external onlyOwner {
        _mintingPaused = false;
    }

    /**
     * @dev Sets the minting window for the NFT.
     */
    function setMintDuration(
        uint32 startTime,
        uint32 endTime
    ) external onlyOwner {
        _mintStartTime = startTime;
        _mintEndTime = endTime;
    }

    // =============================================================
    //                          Minting
    // =============================================================

    /**
     * @dev Mints a new token to the caller if they haven't already minted one.
     */
    function mint() external {
        _requireOpenMint();

        if (!_minted[_msgSender()]) {
            _minted[_msgSender()] = true;
        } else {
            revert TokenAlreadyMinted();
        }

        uint256 tokenId = totalSupply + 1;

        _safeMint(_msgSender(), tokenId);

        totalSupply += 1;
    }

    // =============================================================
    //                     Metadata Management
    // =============================================================

    /**
     * @dev Sets the asset URI for retrieving the NFT image.
     */
    function setAssetURI(string calldata assetURI) external onlyOwner {
        _assetURI = assetURI;
    }

    /**
     * @dev Sets the metadata properties.
     */
    function setMetadataProperties(
        string calldata nftName,
        string calldata artistName,
        string calldata description
    ) external onlyOwner {
        _nftName = nftName;
        _artistName = artistName;
        _description = description;
    }

    // =============================================================
    //                          View Functions
    // =============================================================

    /**
     * @dev Returns the metadata URI for a given token ID.
     * Throws if the token ID does not exist or is not minted.
     * @param tokenId The token ID to retrieve the URI for.
     * @return The URI for the given token ID metadata.
     */
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721Upgradeable) returns (string memory) {
        _requireOwned(tokenId);

        string memory metadata = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{ "name": "',
                        _nftName,
                        " #",
                        LibString.toString(tokenId),
                        '", "tokenId": "',
                        LibString.toString(tokenId),
                        '", "image": "',
                        _assetURI,
                        '", "properties": { "artistName": "',
                        _artistName,
                        '"}, "description": "',
                        _description,
                        '"}'
                    )
                )
            )
        );
        return metadata;
    }

    // =============================================================
    //                          Internal
    // =============================================================

    /**
     * @dev Reverts with `MintingNotEnabled` if minting is not currently possible.
     * @return Boolean (true) if minting is currently possible.
     */
    function _requireOpenMint() internal view returns (bool) {
        bool isActive = _mintStartTime < uint32(block.timestamp) &&
            _mintEndTime > uint32(block.timestamp);

        if (isActive && !_mintingPaused) {
            return true;
        }

        revert MintingNotEnabled();
    }
}
