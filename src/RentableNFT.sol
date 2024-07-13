// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {BasicERC721} from "./BasicERC721.sol";
import "./interfaces/IERC4907.sol";
import {console} from "@forge-std-1.8.2/Console.sol";

contract RentableNFT is BasicERC721, IERC4907 {
    /// @dev Emitted when the caller is not the owner or approved for the NFT
    error NotApprovedOrOwner();

    /// @dev Emitted when the rental exceeds the max days
    error ExceedsMaxRentalDays();

    /// @dev Emitted when the NFT is already rented
    error AlreadyRented();

    /// @dev Emitted when the NFT is not found
    error TokenNotFound();

    /// @dev Emitted when the user is invalid
    error InvalidUser();

    /// @dev Emitted when the expiration is invalid
    error InvalidExpiration();

    /// @dev Emitted when the users value is less than the rental price
    error InsufficientFunds();

    /// @dev Emitted when attempting to rent a permissioned rental
    error PermissionedRental(uint256 tokenId);

    uint256 public rentalPricePerDay;
    uint256 public maxDaysPerRental;

    struct RenterInfo {
        uint256 price; // cost of the NFT rental
        address user; // address of NFT renter
        uint64 expires; // timestamp of when the NFT rental expires
    }

    mapping(uint256 => RenterInfo) internal renters;
    mapping(uint256 => bool) internal permissionedRental;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _price,
        uint256 _maxSupply,
        uint256 _rentalPricePerDay,
        uint256 _maxDaysPerRental
    ) BasicERC721(_name, _symbol, _uri, _price, _maxSupply) {
        rentalPricePerDay = _rentalPricePerDay;
        maxDaysPerRental = _maxDaysPerRental;
    }

    /*
     * @dev Set the user and expires of a NFT for permissioned rentals
     * @param tokenId The NFT to set the user and expires for
     * @param user The new renter of the NFT
     * @param expires Timestamp indicating when the user can use the NFT until
     *
     * Can only be called by the owner or approved address
     */
    function setUser(uint256 tokenId, address user, uint64 expires) public {
        _requireRentalAvailable(tokenId);
        _requireValidRental(user, expires);
        _validatePermissions(tokenId);
        _calculateRentalEstimate(expires);

        RenterInfo memory rentalInfo = renters[tokenId];

        rentalInfo.user = user;
        rentalInfo.expires = expires;

        renters[tokenId] = rentalInfo;

        emit UpdateUser(tokenId, user, expires);
    }

    /**
     * @dev Allows a user to rent an NFT for a specified period.
     *
     * The function calculates the rental price based on the duration of the rental period.
     * The rental process is subject to several validations:
     * - The NFT must not be currently rented under a permissioned rental agreement.
     * - The user initiating the rental must meet specific validity criteria.
     * - The rental expiration timestamp must be valid (i.e., in the future).
     * - The payment provided by the user must meet or exceed the calculated rental price.
     *
     * @param tokenId The unique identifier of the NFT to be rented.
     * @param expires The UNIX timestamp indicating the end of the rental period.
     *
     * @notice If any of the above conditions are not met, the rental transaction will be reverted.
     */
    function rent(uint256 tokenId, uint64 expires) public payable {
        address user = msg.sender;

        _requireRentalAvailable(tokenId);
        _requireValidRental(user, expires);

        if (permissionedRental[tokenId]) {
            revert PermissionedRental(tokenId);
        }

        (, uint256 totalRentalPrice) = _calculateRentalEstimate(expires);

        if (msg.value < totalRentalPrice) {
            revert InsufficientFunds();
        }

        RenterInfo memory rentalInfo = renters[tokenId];
        rentalInfo.user = user;
        rentalInfo.expires = expires;
        rentalInfo.price = totalRentalPrice;

        renters[tokenId] = rentalInfo;

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

    /*
     * @dev Get the rental price of an NFT
     * @param tokenId The NFT to get the rental price for
     * @return The rental price for this NFT
     */
    function setRentalPricePerDay(uint256 _rentalPricePerDay) public onlyOwner {
        rentalPricePerDay = _rentalPricePerDay;
    }

    /*
     * @dev Set the permissioned rental status of an NFT
     * @param tokenId The NFT to set the permissioned rental status for
     * @param permissioned The permissioned rental status for this NFT
     */
    function setPermissionedRental(
        uint256 tokenId,
        bool permissioned
    ) public {
        _validatePermissions(tokenId);
        permissionedRental[tokenId] = permissioned;
    }


    /*
     * @dev Get the permissioned rental status of an NFT
     * @param tokenId The NFT to get the permissioned rental status for
     * @return The permissioned rental status for this NFT
     */
    function getPermissionedRental(uint256 tokenId) public view returns (bool) {
        return permissionedRental[tokenId];
    }


    /*
     * @dev Get the rental info of an NFT
     * @param tokenId The NFT to get the rental info for
     * @return The rental info for this NFT
     */
    function getRentalInfo(
        uint256 tokenId
    ) public view returns (uint256 price, address user, uint64 expires) {
        RenterInfo memory rentalInfo = renters[tokenId];
        return (rentalInfo.price, rentalInfo.user, rentalInfo.expires);
    }

    function getRentalEstimate(
        uint64 expires
    ) public view returns (uint256, uint256) {
        (
            uint256 totalDaysRented,
            uint256 totalRentalPrice
        ) = _calculateRentalEstimate(expires);

        return (totalDaysRented, totalRentalPrice);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC4907).interfaceId ||
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*
     * @dev Destroys `tokenId`. See {ERC721-_burn}
     * @param tokenId The token ID to burn
     * 
     * This override will additionally clear the user information for the token.
     * 
     * Requires that the rental is available
     */
    function _burn(uint256 tokenId) internal virtual override {
        _requireRentalAvailable(tokenId);

        super._burn(tokenId);
        delete renters[tokenId];
        emit UpdateUser(tokenId, address(0), 0);
    }

    function _requireRentalAvailable(uint256 tokenId) internal view {
        if (userExpires(tokenId) > block.timestamp) {
            revert AlreadyRented();
        }
    }

    /*
     * @dev Require that the rental is valid
     * @param user The user address to validate
     * @param expires The expiration timestamp to validate
     *
     * Invalid Tokens are handled by the ERC721 contract
     */
    function _requireValidRental(address user, uint64 expires) internal view {
        if (user == address(0)) {
            revert InvalidUser();
        }

        if (expires <= block.timestamp) {
            revert InvalidExpiration();
        }
    }

    function _validatePermissions(uint256 tokenId) internal view {
        address owner = ownerOf(tokenId);
        address spender = msg.sender;
        bool isOwner = spender == owner;
        bool isApproved = getApproved[tokenId] == spender;
        bool isApprovedForAll = isApprovedForAll[owner][spender];

        if (!isOwner && !isApproved && !isApprovedForAll) {
            revert NotApprovedOrOwner();
        }
    }

    function _calculateRentalEstimate(
        uint64 expires
    )
        internal
        view
        returns (uint256 totalDaysRented, uint256 totalRentalPrice)
    {
        uint256 daysRented = (expires - block.timestamp) / 86400;
        console.log("Days rented - before: %s", daysRented);

        if (daysRented > maxDaysPerRental) {
            revert ExceedsMaxRentalDays();
        }

        // Ensure that the rental period is at least 1 day
        daysRented == 0 ? daysRented = 1 : daysRented;

        console.log("Days rented - after: %s", daysRented);
        console.log("Rental price per day - after: %s", rentalPricePerDay);

        return (daysRented, daysRented * rentalPricePerDay);
    }
}
