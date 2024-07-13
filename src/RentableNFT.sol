// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {BasicERC721} from "./BasicERC721.sol";
import "./interfaces/IERC4907.sol";

contract RentableNFT is BasicERC721, IERC4907 {

    /// @dev Emitted when the caller is not the owner or approved for the NFT
    error NotApprovedOrOwner();

    struct RenterInfo {
        address user; // address of NFT renter
        uint64 expires; // timestamp of when the NFT rental expires
    }

    mapping(uint256 => RenterInfo) internal renters;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _price,
        uint256 _maxSupply
    ) BasicERC721(_name, _symbol, _uri, _price, _maxSupply) {}


    /*
     * @dev Set the user and expires of a NFT
     * @param tokenId The NFT to set the user and expires for
     * @param user The new renter of the NFT
     * @param expires Timestamp indicating when the user can use the NFT until
     */
    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) public virtual {
        address owner = ownerOf(tokenId);
        address spender = msg.sender;

        if (
            spender != owner ||
            getApproved[tokenId] != spender ||
            isApprovedForAll[owner][spender]
        ) {
            revert NotApprovedOrOwner();
        }

        RenterInfo memory info = renters[tokenId];
        info.user = user;
        info.expires = expires;

        renters[tokenId] = info;

        emit UpdateUser(tokenId, user, expires);
    }

    /*
     * @dev Get the user address of an NFT
     * @param tokenId The NFT to get the user address for
     * @return The user address for this NFT
     */
    function userOf(uint256 tokenId) public view virtual returns (address) {
        if (uint256(renters[tokenId].expires) >= block.timestamp) {
            return renters[tokenId].user;
        }

        return address(0);
    }

    /*
     * @dev Get the user expires of an NFT
     * @param tokenId The NFT to get the user expires for
     * @return The user expires for this NFT
     */
    function userExpires(
        uint256 tokenId
    ) public view virtual returns (uint256) {
        return renters[tokenId].expires;
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC4907).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /*
     * @dev Destroys `tokenId`. See {ERC721-_burn}
     * @param tokenId The token ID to burn
     * This override will additionally clear the user information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        delete renters[tokenId];
        emit UpdateUser(tokenId, address(0), 0);
    }
}
