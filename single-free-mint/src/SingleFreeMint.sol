// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/utils/Base64.sol";
import "openzeppelin-contracts/contracts/utils/Counters.sol";

/**
 * @title FreeMintCore
 * @dev FreeMintCore is a contract for managing free NFT minting with URI metadata generation.
 */
contract SingleFreeMint is OwnableUpgradeable, ERC721Upgradeable {
    using Counters for Counters.Counter;

    Counters.Counter private _counter;

    mapping(address => bool) private _minted;
    string public assetBaseURI;

    /**
     * @dev Throws if the token with the given ID was not minted.
     */
    error TokenNotFound();

    /**
     * @dev Throws if the token has already been minted by the caller.
     */
    error TokenAlreadyMinted();

    /**
     * @dev Initializes the contract with the specified name, symbol, and base URI.
     * @param _name The name of the NFT contract.
     * @param _symbol The symbol of the NFT contract.
     * @param _baseURI The base URI for retrieving NFT metadata.
     */
    function initialize(
        string calldata _name,
        string calldata _symbol,
        string calldata _baseURI
    ) external initializer {
        __Ownable_init();
        __ERC721_init(_name, _symbol);
        assetBaseURI = _baseURI;
    }

    /**
     * @dev Mints a new token to the caller if they haven't already minted one.
     */
    function mint() external {
        if (!_minted[_msgSender()]) {
            _minted[_msgSender()] = true;
        } else {
            revert TokenAlreadyMinted();
        }

        uint256 tokenId = _counter.current() + 1;
        _counter.increment();

        _safeMint(_msgSender(), tokenId);
    }

    /**
     * @dev Returns the total number of tokens minted.
     * @return The total number of tokens minted.
     */
    function totalSupply() external view returns (uint256) {
        return _counter.current();
    }

    /**
     * @dev Sets the base URI for retrieving NFT metadata.
     * @param baseURI The new base URI.
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        assetBaseURI = baseURI;
    }

    /**
     * @dev Returns the URI for a given token ID.
     * Throws if the token ID does not exist or is not minted.
     * @param tokenId The token ID to retrieve the URI for.
     * @return The URI for the given token ID.
     */
    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable) returns (string memory) {
        _requireMinted(tokenId);

        string memory metadata = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{ "name": "FreeMint #',
                        Strings.toString(tokenId),
                        '",',
                        '{ "tokenId": ',
                        Strings.toString(tokenId),
                        '",',
                        '"image": "https://v2-liveart.mypinata.cloud/ipfs/QmegWT8hUctpxx4RV643ZWDBo2FjtzFJ8mVhpUFAeWnSca",',
                        '"properties": { "artistName": "Unknown" },',
                        '"description": "This is a free mint",',
                        "}"
                    )
                )
            )
        );

        return metadata;
    }
}
