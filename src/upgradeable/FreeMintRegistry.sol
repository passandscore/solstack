// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin-contracts-upgradeable-5.0.2/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin-contracts-5.0.2/interfaces/IERC2981.sol";


/**
 * @title FreeMintRegistry
 * @dev A contract for managing free NFT minting across multiple collections with URI metadata generation.
 */
contract FreeMintRegistry is OwnableUpgradeable, ERC1155Upgradeable, IERC2981 {
    /// @dev Triggered when trying to update a non-existent freemint.
    error FreemintDoesNotExist();

    /// @dev Triggered when providing an invalid input.
    error InvalidInput();

    /// @dev Triggered when minting is not enabled.
    error MintingNotEnabled();

    /// @dev Triggered when the user has already minted.
    error TokenAlreadyMinted();

    /// @dev Triggered when the user has insufficient funds.
    error InsufficientFunds();

    /// @dev Emitted when a new freemint is registered.
    event RegistedFreemint(uint256 indexed id, string name, string uri);

    /// @dev Emitted when the metadata is updated.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev Emitted when royalty info is updated.
    event RoyaltyInfoUpdated(uint256 indexed tokenId, address receiver, uint96 royaltyFraction);

    struct Freemint {
        uint256 id;
        string nftName;
        string assetURI;
        string artistName;
        string description;
        string partnerName;
        uint256 mintedSupply;
        uint256 pointsPerMint;
        uint32 mintStartTime;
        uint32 mintEndTime;
        bool mintingPaused;
    }

    // Mapping from address -> freemint ID -> minted.
    mapping(address => mapping(uint256 => bool)) minted;

    // Mapping from freemint ID -> Freemint.
    mapping(uint256 => Freemint) freeMints;

    // Total number of freemints.
    uint256 public idCounter;
    uint256 public totalTokensMinted;

    // Contract Metadata
    string public name;
    string public symbol;

    // Mapping from freemint ID -> mint price
    mapping(uint256 => uint256) mintPrice;

    // Add royalty info structure
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction; // Using uint96 to optimize storage
    }

    // Mapping from token ID to royalty info
    mapping(uint256 => RoyaltyInfo) private _royalties;

    // =============================================================
    //                          INITIALIZATION
    // =============================================================

    function initialize(
        string calldata _name,
        string calldata _symbol
    ) external initializer {
        __Ownable_init(msg.sender);
        __ERC1155_init("");
        name = _name;
        symbol = _symbol;
    }

    // =============================================================
    //                         FREEMINT LOGIC
    // =============================================================

    /**
     * @dev A method for the owner to register a new freemint.
     * @param nftName The name of the NFT.
     * @param assetURI The URI of the NFT.
     * @param artistName The name of the artist.
     * @param description The description of the NFT.
     * @param partnerName The name of the partner.
     * @param pointsPerMint The number of points per mint.
     * @param mintStartTime The start time of the mint.
     * @param mintEndTime The end time of the mint.
     */
    function registerFreemint(
        string memory nftName,
        string memory assetURI,
        string memory artistName,
        string memory description,
        string memory partnerName,
        uint256 pointsPerMint,
        uint32 mintStartTime,
        uint32 mintEndTime
    ) external onlyOwner {
        uint256 freemintId = ++idCounter;

        Freemint storage freemint = freeMints[freemintId];
        freemint.id = freemintId;
        freemint.nftName = nftName;
        freemint.assetURI = assetURI;
        freemint.artistName = artistName;
        freemint.description = description;
        freemint.mintStartTime = mintStartTime;
        freemint.mintEndTime = mintEndTime;
        freemint.mintedSupply = 0;
        freemint.mintingPaused = false;
        freemint.partnerName = partnerName;
        freemint.pointsPerMint = pointsPerMint;

        emit RegistedFreemint(freemintId, nftName, assetURI);
    }

    // =============================================================
    //                         Metadata Management
    // =============================================================


    /**
     * @dev Sets the asset URI for retrieving the NFT image.
     * @param _id The ID of the freemint.
     * @param assetURI The URI of the NFT.
     */
    function setAssetURI(
        uint256 _id,
        string calldata assetURI
    ) external onlyOwner {
        freeMints[_id].assetURI = assetURI;
        emit MetadataUpdate(_id);
    }
    /**
     * @dev A method for the owner to update the metadata of a freemint.
     * @param _id The ID of the freemint.
     * @param nftName The name of the NFT.
     * @param artistName The name of the artist.
     * @param description The description of the NFT.
     */
    function updateMetadata(
        uint256 _id,
        string memory nftName,
        string memory artistName,
        string memory description
    ) external onlyOwner {
        freeMints[_id].nftName = nftName;
        freeMints[_id].artistName = artistName;
        freeMints[_id].description = description;
        emit MetadataUpdate(_id);
    }

    /**
     * @dev A method for the owner to update the partner data of a freemint.
     * @param _id The ID of the freemint.
     * @param partnerName The name of the partner.
     * @param pointsPerMint The number of points per mint.
     */
    function updatePartnerData(
        uint256 _id,
        string memory partnerName,
        uint256 pointsPerMint
    ) external onlyOwner {
        freeMints[_id].partnerName = partnerName;
        freeMints[_id].pointsPerMint = pointsPerMint;
    }

    // =============================================================
    //                         MINT CONTROL
    // =============================================================

    /**
     * @dev Pauses the minting of a freemint.
     * @param _id The ID of the freemint.
     */
    function pauseMint(uint256 _id) external onlyOwner {
        freeMints[_id].mintingPaused = true;
    }

    /**
     * @dev Resumes the minting of a freemint.
     * @param _id The ID of the freemint.
     */
    function resumeMint(uint256 _id) external onlyOwner {
        freeMints[_id].mintingPaused = false;
    }

    /**
     * @dev A method for the owner to update an existing raffle.
     * @param _id The ID of the freemint.
     * @param mintStartTime The start time of the mint.
     * @param mintEndTime The end time of the mint.
     */
    function updateMintDuration(
        uint256 _id,
        uint32 mintStartTime,
        uint32 mintEndTime
    ) external onlyOwner {
        if (freeMints[_id].id == 0) {
            revert FreemintDoesNotExist();
        }

        freeMints[_id].mintStartTime = mintStartTime;
        freeMints[_id].mintEndTime = mintEndTime;
    }

    /**
     * @dev A method for the owner to update the mint price of a freemint.
     * @param _id The ID of the freemint.
     * @param price The price of the mint.
     */
    function updateMintPrice(uint256 _id, uint256 price) external onlyOwner {
        Freemint memory freemint = freeMints[_id];
        if (freemint.id == 0) {
            revert FreemintDoesNotExist();
        }
        mintPrice[_id] = price;
    }

    // =============================================================
    //                          Minting
    // =============================================================

    /**
     * @dev A method for the user to mint a token.
     * @param _id The ID of the freemint.
     */
    function mint(
        address to,
        uint256 _id,
        uint256 quantity,
        bytes memory data
    ) external payable {
        if (minted[to][_id]) {
            revert TokenAlreadyMinted();
        }

        if (quantity == 0 || quantity > 1) {
            revert InvalidInput();
        }

        Freemint storage freemint = freeMints[_id];

        _requireOpenMint(
            freemint.mintStartTime,
            freemint.mintEndTime,
            freemint.mintingPaused
        );

        ++totalTokensMinted;
        ++freemint.mintedSupply;
        minted[to][_id] = true;

        if (msg.value < mintPrice[_id]) {
            revert InsufficientFunds();
        }

        _mint(to, freemint.id, quantity, data);
    }

    /**
     * @dev A method for the owner to batch mint tokens.
     * @param _id The ID of the freemint.
     * @param recipients The addresses to mint the tokens to.
     */
    function batchAdminMint(
        uint256 _id,
        address[] calldata recipients,
        uint256[] calldata quantities
    ) external onlyOwner {
        if (recipients.length != quantities.length) {
            revert InvalidInput();
        }

        Freemint storage freemint = freeMints[_id];
        uint256 batchTotalMinted = 0;

        for (uint256 i = 0; i < recipients.length; i++) {
            address to = recipients[i];
            uint256 quantity = quantities[i];

            _mint(to, freemint.id, quantity, "");

            if (!minted[to][_id]) {
                minted[to][_id] = true;
            }

            batchTotalMinted += quantity;
        }

        totalTokensMinted += batchTotalMinted;
        freemint.mintedSupply += batchTotalMinted;
    }

    // =============================================================
    //                          VIEW FUNCTIONS
    // =============================================================

    /**
     * @dev Returns the total quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function hasMinted(address user, uint256 _id) external view returns (bool) {
        return minted[user][_id];
    }

    /**
     * @dev Returns the total quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function totalSupply(uint256 _id) public view returns (uint256) {
        return freeMints[_id].mintedSupply;
    }

    function isPaused(uint256 _id) public view returns (bool) {
        return freeMints[_id].mintingPaused;
    }

    /**
     * @dev A method for the owner to get the details of a freemint.
     * @param _id The ID of the freemint.
     */
    function getFreemintDetails(
        uint256 _id
    ) external view returns (Freemint memory) {
        return freeMints[_id];
    }

    /**
     * @dev A method for the owner to get the mint price of a freemint.
     * @param _id The ID of the freemint.
     */
    function getMintPrice(uint256 _id) external view returns (uint256) {
        return mintPrice[_id];
    }

    // =============================================================
    //                          Internal
    // =============================================================

    /**
     * @dev Reverts with `MintingNotEnabled` if minting is not currently possible.
     */
    function _requireOpenMint(
        uint32 mintStartTime,
        uint32 mintEndTime,
        bool mintingPaused
    ) internal view {
        bool isActive = mintStartTime <= uint32(block.timestamp) &&
            mintEndTime >= uint32(block.timestamp);

        if (!isActive || mintingPaused) {
            revert MintingNotEnabled();
        }
    }

    // =============================================================
    //                         ERC1155 OVERRIDES
    // =============================================================

    /**
     * @dev A method to get the URI of a raffle.
     * @param id The ID of the raffle.
     */
    function uri(
        uint256 id
    ) public view virtual override returns (string memory) {
        Freemint memory freemint = freeMints[id];

        string memory metadata = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{ "name": "',
                        freemint.nftName,
                        '", "id": "',
                        Strings.toString(id),
                        '", "image": "',
                        freemint.assetURI,
                        '", "properties": { "artistName": "',
                        freemint.artistName,
                        '"}, "description": "',
                        freemint.description,
                        '", "partnerName": "',
                        freemint.partnerName,
                        '", "pointsPerMint": "',
                        Strings.toString(freemint.pointsPerMint),
                        '"}'
                    )
                )
            )
        );
        return metadata;
    }

    // =============================================================
    //                          Royalty
    // =============================================================

    /**
     * @dev Sets the royalty information for a specific token ID.
     * @param tokenId The token ID to set royalty info for
     * @param receiver Address to receive royalty payments
     * @param feeNumerator The royalty fee numerator (e.g., 500 for 5%)
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        if (feeNumerator > 10000) {
            revert InvalidInput();
        }
        if (receiver == address(0)) {
            revert InvalidInput();
        }

        _royalties[tokenId] = RoyaltyInfo(receiver, feeNumerator);
        emit RoyaltyInfoUpdated(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev Implementation of the IERC2981 interface.
     * @param tokenId The token ID to calculate royalties for
     * @param salePrice The sale price of the token
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalty = _royalties[tokenId];
        receiver = royalty.receiver;
        royaltyAmount = (salePrice * royalty.royaltyFraction) / 10000;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function withdraw(address _to) external onlyOwner {
        payable(_to).transfer(address(this).balance);
    }
}
