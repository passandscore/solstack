// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721EnumerableUpgradeable} from
    "@openzeppelin-contracts-upgradeable-5.0.2/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ERC721Upgradeable} from "@openzeppelin-contracts-upgradeable-5.0.2/token/ERC721/ERC721Upgradeable.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC2981} from "./interfaces/IERC2981.sol";
import {BPS} from "./libraries/BPS.sol";
import {MetadataLib} from "./libraries/MetadataLib.sol";
import {CustomErrors} from "./CustomErrors.sol";
import {ShardRandomness} from "./ShardRandomness.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";


/**
 * @title ShardsRWA
 * @dev Handles fractional ownership of NFTs.
 * @custom:oz-upgrades-unsafe-allow external-library-linking
 */
contract ShardsRWA is OwnableUpgradeable, ERC721EnumerableUpgradeable, ShardRandomness {
    //==================================================================
    //                          Constants
    //==================================================================

    bytes32 constant IERC721METADATA_INTERFACE = hex"5b5e139f";
    bytes32 constant IERC721_INTERFACE = hex"80ac58cd";
    bytes32 constant IERC2981_INTERFACE = hex"2a55205a";
    bytes32 constant IERC165_INTERFACE = hex"01ffc9a7";
    bytes32 constant IERC4906_INTERFACE = hex"49064906";

    uint256 private constant MAX_BPS = 10_000;

    // =============================================================
    //                          Storage
    // =============================================================

    /**
     * @dev Core Storage
     */
    // Mappings (32 bytes each, separate slots)
    mapping(uint16 => string) shardMultiplier;
    mapping(uint16 => uint256) shardPricePerPack;
    mapping(uint16 => uint256) wlShardPricePerPack;
    mapping(uint256 => ShardRandomness.ShardMetadata) shardMetadata;

    // 32 byte values
    bytes32 public merkleRoot;
    uint256 public maxSupply;
    uint256 public totalHoursOpen;

    // Strings (32 bytes each, separate slots)
    string public nftName;
    string public artistName;
    string public description;
    string public baseURI;

    // Pack these together in one slot (32 bytes total)
    uint48 public primarySalePercentage; // 6 bytes
    uint48 public secondarySalePercentage; // 6 bytes
    address payable public royaltyReceiver; // 20 bytes

    // Pack remaining values together (1 slot)
    uint32 public mintStartTime; // 4 bytes
    uint32 public mintEndTime; // 4 bytes
    uint32 public mintedSupply; // 4 bytes
    bool public mintingPaused; // 1 byte
    bool public tradingRestricted; // 1 byte
    bool public whitelistEnabled; // 1 byte

    // Pack remaining values together (1 slot)
    IERC20 public tokenContractAddress; // 20 bytes

    // =============================================================
    //                         Initializer
    // =============================================================

    /**
     * @dev Initializes the contract with the specified name, symbol, and asset.
     */
    function initialize(
        string calldata _name,
        string calldata _symbol,
        string calldata _baseURI,
        uint256 _maxSupply,
        uint48 _primarySalePercentage,
        uint48 _secondarySalePercentage,
        address payable _royaltyReceiver,
        address _tokenContractAddress
    ) external initializer {
        __Ownable_init(msg.sender);
        __ERC721_init(_name, _symbol);
        __ERC721Enumerable_init();

        baseURI = _baseURI;
        maxSupply = _maxSupply;

        // Royalties receiver
        royaltyReceiver = _royaltyReceiver;
        primarySalePercentage = _primarySalePercentage;
        secondarySalePercentage = _secondarySalePercentage;

        // Restrict trading by default
        tradingRestricted = true;

        tokenContractAddress = IERC20(_tokenContractAddress);
    }

    // =============================================================
    //                         Mint Control
    // =============================================================

    /**
     * @dev Pauses minting.
     */
    function toggleMintingPaused() external onlyOwner {
        mintingPaused = !mintingPaused;
    }

    /**
     * @dev Sets the minting window for the NFT.
     */
    function setMintDuration(uint32 _startTime, uint32 _endTime) external onlyOwner {
        mintStartTime = _startTime;
        mintEndTime = _endTime;
    }

    /**
     * @dev Restricts trading of the NFT.
     */
    function toggleTradingRestricted() external onlyOwner {
        tradingRestricted = !tradingRestricted;
    }

    // =============================================================
    //                          Minting
    // =============================================================

    /**
     * @dev Allows the owner to mint single shards to the caller.
     * @param _quantity The number of shards to mint.
     * @param _recipient The address to receive the shards.
     */
    function adminMintSingleShard(uint16 _quantity, address _recipient) public onlyOwner {
        _requireValidShardQuantity(_quantity);
        _requireAvailableSupply(_quantity);
        _mintSingleShards(_quantity, _recipient);
    }

    /**
     * @dev Allows the owner to mint a full grid to the caller.
     * @param _recipient The address to receive the full grid.
     * @param _quantity The number of full grids to mint.
     */
    function adminMintMaxPack(address _recipient, uint16 _quantity) external onlyOwner {
        _requireAvailableSupply(_quantity * FULL_GRID_QUANTITY);

        for (uint256 i = 0; i < _quantity; i++) {
            _mintMaxPack(_recipient);
        }
    }

    /**
     * @dev Allows the owner to mint multiple shards to multiple recipients.
     * @param _quantities The number of shards to mint for each recipient.
     * @param _recipients The addresses to receive the shards.
     */
    function batchMintSingleShards(uint16[] calldata _quantities, address[] calldata _recipients) external onlyOwner {
        uint16 quantity = uint16(_quantities.length);

        require(quantity == _recipients.length, CustomErrors.InvalidBatchLength());
        require(quantity > 0 && _recipients.length > 0, CustomErrors.InvalidBatchLength());

        for (uint256 i = 0; i < quantity; i++) {
            adminMintSingleShard(_quantities[i], _recipients[i]);
        }
    }

    /**
     * @dev Mints a full grid to the caller.
     * @param _recipient The address to receive the full grid.
     * @param _quantity The number of full grids to mint.
     * @param _mintWithToken Whether to mint with a token.
     */
    function mintMaxPack(address _recipient, uint16 _quantity, bool _mintWithToken) public payable {
        _requireShardPriceSet(uint16(FULL_GRID_QUANTITY));
        uint256 price = getShardPricePerPack(uint16(FULL_GRID_QUANTITY));

        _requireOpenMint();
        _requireAvailableSupply(_quantity * FULL_GRID_QUANTITY);
        _verifyValue(price, _quantity, _mintWithToken, true);

        for (uint256 i = 0; i < _quantity; i++) {
            _mintMaxPack(_recipient);
        }

        _sendRoyaltiesAfterMint();
    }

    /**
     * @dev Mints a single shard to the caller.
     * @param _recipient The address to receive the shard.
     * @param _quantity The number of shards to mint.
     * @param _mintWithToken Whether to mint with a token.
     */
    function mintSingleShards(address _recipient, uint16 _quantity, bool _mintWithToken) public payable {
        _requireOpenMint();
        _requireValidShardQuantity(_quantity);
        _requireAvailableSupply(_quantity);
        _requireShardPriceSet(_quantity);

        uint256 price = getShardPricePerPack(_quantity);
        _verifyValue(price, _quantity, _mintWithToken, false);

        _mintSingleShards(_quantity, _recipient);
        _sendRoyaltiesAfterMint();
    }

    /**
     * @dev Mints to a whitelisted user.
     * @param _merkleProof The Merkle proof for the user.
     * @param _wlAddress The address of the user.
     * @param _quantity The number of shards to mint.
     * @param _isMaxPack Whether the user is minting a full grid.
     * @param _mintWithToken Whether to mint with a token.
     */
    function whitelistMint(bytes32[] memory _merkleProof, address _wlAddress, uint16 _quantity, bool _isMaxPack, bool _mintWithToken)
        public
        payable
    {
        if (!_isWhitelistMintEnabled()) {
            revert CustomErrors.WhitelistNotEnabled();
        }

        // Hash the user's address to match with the Merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(_wlAddress));

        // Verify the Merkle proof using OpenZeppelin's MerkleProof contract
        if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf)) {
            revert CustomErrors.NotWhitelisted();
        }

        if (_isMaxPack) {
            mintMaxPack(_wlAddress, _quantity, _mintWithToken);
        } else {
            mintSingleShards(_wlAddress, _quantity, _mintWithToken);
        }
    }

    // =============================================================
    //                     Metadata Management
    // =============================================================

    /**
     * @dev Returns the URI for a given token ID asset.
     * @param _tokenId The token ID to retrieve the URI for.
     * example "BASE_URI/x_y.png"
     */
    function imageURI(uint256 _tokenId) public view returns (string memory uri) {
        ShardMetadata memory shard = shardMetadata[_tokenId];

        return MetadataLib.imageURI(baseURI, shard.x, shard.y);
    }

    /**
     * @dev Updates the base URI for the asset metadata URL
     * @param _url The new base URI.
     *
     * @notice Requires an ending forward slash.
     */
    function setBaseURI(string memory _url) external onlyOwner {
        baseURI = _url;
    }

    /**
     * @dev Updates the NFT name.
     * @param _name The new name of the NFT.
     */
    function setNftName(string memory _name) external onlyOwner {
        nftName = _name;
    }

    /**
     * @dev Updates the artist name.
     * @param _name The new name of the artist.
     */
    function setArtistName(string memory _name) external onlyOwner {
        artistName = _name;
    }

    /**
     * @dev Updates the description.
     * @param _description The new description.
     */
    function setDescription(string memory _description) external onlyOwner {
        description = _description;
    }

    /**
     * @dev Sets the Merkle root for the whitelist.
     * @param _merkleRoot The new Merkle root.
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // =============================================================
    //                     Withdrawal
    // =============================================================

    /**
     * @dev Returns the contract's balance.
     */
    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Withdraws the specified amount to the recipient.
     * @param _recipient The address to receive the funds.
     * @param _amount The amount to withdraw.
     */
    function withdrawAmount(address payable _recipient, uint256 _amount) external onlyOwner {
        (bool succeed,) = _recipient.call{value: _amount}("");
        if (!succeed) {
            revert CustomErrors.FundTransferError();
        }
    }

    /**
     * @dev Withdraws the entire balance to the recipient.
     * @param _recipient The address to receive the funds.
     */
    function withdrawAll(address payable _recipient) external onlyOwner {
        (bool succeed,) = _recipient.call{value: balance()}("");
        if (!succeed) {
            revert CustomErrors.FundTransferError();
        }
    }

    // =============================================================
    //                          View Functions
    // =============================================================

    /**
     * @dev Returns the metadata URI for a given token ID.
     * Throws if the token ID does not exist or is not minted.
     * @param _tokenId The token ID to retrieve the URI for.
     * @return The URI for the given token ID metadata.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        _requireOwned(_tokenId);
        return MetadataLib.tokenURI(
            _tokenId,
            baseURI,
            nftName,
            artistName,
            description,
            shardMetadata[_tokenId].multiplier,
            shardMetadata[_tokenId].x,
            shardMetadata[_tokenId].y
        );
    }

    /**
     * @dev Returns all token Ids owned by owner.
     * @param _owner The address of the owner.
     */
    function getTokensByOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokens = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokens[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokens;
    }

    /**
     * @dev Returns the shard metadata for the specified token ID.
     * @param _tokenId The token ID to retrieve the metadata for.
     */
    function getShardDataByTokenId(uint256 _tokenId) external view returns (ShardMetadata memory) {
        return shardMetadata[_tokenId];
    }

    /**
     * @dev Returns the price for the specified shard quantity.
     * @param _shardQuantity The type of multiplier to retrieve. Can be 1, 5, 10, 25, 50, or 100
     */
    function getShardPricePerPack(uint16 _shardQuantity) internal view returns (uint256) {
        if (_isWhitelistMintEnabled()) {
            return wlShardPricePerPack[_shardQuantity];
        }
        return shardPricePerPack[_shardQuantity];
    }

    /**
     * @dev Returns the price for the specified shard quantity.
     * @param _shardQuantity The type of multiplier to retrieve. Can be 1, 5, 10, 25, 50, or 100
     * @param _whitelistPrices Whether the price is for whitelist minting.
     * @return The price for the specified shard quantity for the given mint type.
     */
    function getShardPricePerPack(uint16 _shardQuantity, bool _whitelistPrices) public view returns (uint256) {
        if (_whitelistPrices) {
            return wlShardPricePerPack[_shardQuantity];
        }
        return shardPricePerPack[_shardQuantity];
    }

    /**
     * @dev Returns the multiplier for the specified shard quantity.
     * @param _shardQuantity The type of multiplier to retrieve. Can be 1, 5, 10, 25, 50, or 100.
     */
    function getMultipler(uint16 _shardQuantity) external view returns (string memory) {
        return shardMultiplier[_shardQuantity];
    }

    /**
     * @dev Returns the minting window.
     */
    function getMintingDuration() external view returns (uint32, uint32) {
        return (mintStartTime, mintEndTime);
    }

    /**
     * @dev Returns the whitelist details.
     */
    function getWhitelistDetails() external view returns (bool, uint256) {
        return (whitelistEnabled, totalHoursOpen * 1 hours);
    }

    // =============================================================
    //                          Setters
    // =============================================================

    /**
     * @dev Sets the maximum supply of the NFT collection.
     * @param _maxSupply The maximum supply of the NFT collection.
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply >= mintedSupply, CustomErrors.TotalSupplyExceeded());
        maxSupply = _maxSupply;
    }

    /**
     * @dev Sets the whitelist mint configuration.
     * @param _enableWhitelistMint Whether the whitelist mint is enabled.
     * @param _totalHoursOpen The total number of hours the whitelist mint is open.
     */
    function setWhitelistMintConfig(bool _enableWhitelistMint, uint256 _totalHoursOpen) external onlyOwner {
        whitelistEnabled = _enableWhitelistMint;
        totalHoursOpen = _totalHoursOpen;
    }

    /**
     * @dev Updates multiple shard multipliers in a single transaction
     * @param _shardQuantities Array of shard quantities (1, 5, 10, 25, 50, or 100)
     * @param _newMultipliers Array of corresponding multiplier values
     * @notice Arrays must be the same length
     */
    function batchSetMultipliers(uint16[] calldata _shardQuantities, string[] calldata _newMultipliers)
        external
        onlyOwner
    {
        require(_shardQuantities.length == _newMultipliers.length, "Array lengths must match");

        for (uint256 i = 0; i < _shardQuantities.length; i++) {
            _requireValidShardQuantity(_shardQuantities[i]);
            shardMultiplier[_shardQuantities[i]] = _newMultipliers[i];
        }
    }

    /**
     * @dev Updates multiple shard prices in a single transaction
     * @param _shardQuantities Array of shard quantities (1, 5, 10, 25, 50, or 100)
     * @param _prices Array of corresponding prices in wei
     * @param _isWhitelistPrices Whether these prices are for whitelist minting
     * @notice Arrays must be the same length
     */
    function batchSetShardPrices(
        uint16[] calldata _shardQuantities,
        uint256[] calldata _prices,
        bool _isWhitelistPrices
    ) external onlyOwner {
        require(_shardQuantities.length == _prices.length, "Array lengths must match");

        for (uint256 i = 0; i < _shardQuantities.length; i++) {
            _requireValidShardQuantity(_shardQuantities[i]);
            if (_isWhitelistPrices) {
                wlShardPricePerPack[_shardQuantities[i]] = _prices[i];
            } else {
                shardPricePerPack[_shardQuantities[i]] = _prices[i];
            }
        }
    }

    /**
     * @dev Sets the token contract address.
     * @param _tokenContractAddress The address of the token contract.
     */
    function setTokenContractAddress(address _tokenContractAddress) external onlyOwner {
        tokenContractAddress = IERC20(_tokenContractAddress);
    }

    // =============================================================
    //                          Internal
    // =============================================================

    /**
     * @dev Reverts with `MintingNotEnabled` if minting is not currently possible.
     * @return Boolean (true) if minting is currently possible.
     */
    function _requireOpenMint() internal view returns (bool) {
        // Check if we're in whitelist window
        bool isWhitelistActive = _isWhitelistMintEnabled();

        // Check if we're in regular mint window
        bool isRegularMintActive = block.timestamp >= mintStartTime && block.timestamp <= mintEndTime;

        if ((isWhitelistActive || isRegularMintActive) && !mintingPaused) {
            return true;
        }

        revert CustomErrors.MintingNotEnabled();
    }

    /**
     * @dev Reverts with `TotalSupplyExceeded` if the total supply would be exceeded.
     */
    function _requireAvailableSupply(uint256 _qty) internal view {
        require(mintedSupply + _qty <= maxSupply, CustomErrors.TotalSupplyExceeded());
    }

    function _requireValidShardQuantity(uint256 _quantity) internal pure {
        require(
            _quantity == 1 || _quantity == 5 || _quantity == 10 || _quantity == 25 || _quantity == 50
                || _quantity == 100,
            CustomErrors.InvalidShardQuantity()
        );
    }

    /**
     * @dev Reverts when the shard price is not set.
     * @param _shardPackSize The size of the shard pack.
     */
    function _requireShardPriceSet(uint16 _shardPackSize) internal view {
        uint256 price = getShardPricePerPack(_shardPackSize);
        require(price > 0, CustomErrors.PriceNotSet());
    }

    /**
     * @dev Mints a new token to the caller if they haven't already minted one.
     */
    function _mintMaxPack(address _recipient) internal {
        ShardMetadata[] memory _shards = getPackMetadata();

        uint16 quantity = uint16(_shards.length);

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = ++mintedSupply;

            _mint(_recipient, tokenId);

            shardMetadata[tokenId] = _shards[i];
            shardMetadata[tokenId].multiplier = calculateShardMultiplier(FULL_GRID_QUANTITY);
        }
    }

    /**
     * @dev Mints a new token to the caller if they haven't already minted one.
     */
    function _mintSingleShards(uint256 _quantity, address _recipient) internal {
        for (uint256 i = 0; i < _quantity; i++) {
            uint256 tokenId = ++mintedSupply;

            _mint(_recipient, tokenId);

            shardMetadata[tokenId] = getShardMetadata();
            shardMetadata[tokenId].multiplier = calculateShardMultiplier(_quantity);
        }
    }
    /**
     * @dev Returns a scaled multiplier based on the quantity of shards.
     * @param _quantity The number of shards to mint.
     * @notice The multiplier is scaled by 1000.
     */

    function calculateShardMultiplier(uint256 _quantity) internal view returns (string memory) {
        string memory multiplier = shardMultiplier[uint16(_quantity)];

        if (bytes(multiplier).length == 0) {
            revert("InvalidMultiplierType");
        }

        return multiplier;
    }

    function _isWhitelistMintEnabled() internal view returns (bool) {
        return whitelistEnabled && block.timestamp >= mintStartTime - (totalHoursOpen * 1 hours)
            && block.timestamp < mintStartTime;
    }

    function _verifyValue(uint256 _price, uint256 _quantity, bool _mintWithToken, bool _isMaxMint) internal {
        uint256 totalPrice;

         if (_isMaxMint) {
                totalPrice = _price * FULL_GRID_QUANTITY;
            } else {
                totalPrice = _price * _quantity;
            }

         if (_mintWithToken) {
            require(address(tokenContractAddress) != address(0), CustomErrors.TokenContractAddressNotSet());
            require(IERC20(tokenContractAddress).transferFrom(
                _msgSender(),
                royaltyReceiver,
                totalPrice
            ), CustomErrors.TransferFailed());
        } else {
            if (_isMaxMint) {
                require(msg.value == (_price * FULL_GRID_QUANTITY) * _quantity, CustomErrors.InsufficientFunds());
            } else {
                require(msg.value == totalPrice, CustomErrors.InsufficientFunds());
            }
        }
    }

    //==================================================================
    //                          Royalties
    //==================================================================

    /**
     * @dev Registers the royalty receiver and percentages.
     * @param _wallet The address of the royalty receiver.
     * @param _primarySalePercentage The primary sale percentage.
     * @param _secondarySalePercentage The secondary sale percentage.
     */
    function registerRoyaltyReceiver(
        address payable _wallet,
        uint48 _primarySalePercentage,
        uint48 _secondarySalePercentage
    ) external onlyOwner {
        if (_primarySalePercentage != MAX_BPS) {
            revert CustomErrors.PrimarySalePercentageNotEqualToMax();
        }

        if (_secondarySalePercentage > MAX_BPS) {
            revert CustomErrors.SecondarySalePercentageOutOfRange();
        }

        royaltyReceiver = _wallet;
        primarySalePercentage = _primarySalePercentage;
        secondarySalePercentage = _secondarySalePercentage;
    }

    /// @dev see: EIP-2981
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyReceiver, BPS._calculatePercentage(salePrice, secondarySalePercentage));
    }

    /**
     * @dev Sends royalties to the receivers after minting.
     */
    function _sendRoyaltiesAfterMint() internal {
        uint256 royalties = BPS._calculatePercentage(msg.value, primarySalePercentage);
        (bool sent,) = royaltyReceiver.call{value: royalties}("");

        if (!sent) {
            revert CustomErrors.FundTransferError();
        }
    }

    // =============================================================
    //                          Overrides
    // =============================================================

    /**
     * @dev Returns the total number of tokens minted.
     */
    function totalSupply() public view override(ShardRandomness, ERC721EnumerableUpgradeable) returns (uint256) {
        return mintedSupply;
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override(ERC721Upgradeable, IERC721) {
        if (tradingRestricted) {
            revert CustomErrors.TradingRestricted();
        }

        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override(ERC721Upgradeable, IERC721) {
        if (tradingRestricted) {
            revert CustomErrors.TradingRestricted();
        }

        _approve(to, tokenId, _msgSender());
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable, IERC721) {
        if (tradingRestricted) {
            revert CustomErrors.TradingRestricted();
        }

        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721Upgradeable, IERC721)
    {
        if (tradingRestricted) {
            revert CustomErrors.TradingRestricted();
        }

        super.safeTransferFrom(from, to, tokenId, data);
    }
}
