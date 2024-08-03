// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin-contracts-upgradeable-5.0.2/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";
import "@openzeppelin-contracts-5.0.2/utils/cryptography/MerkleProof.sol";
import "@openzeppelin-contracts-5.0.2/utils/Strings.sol";

/**
 * @title MembershipCards
 * @dev A contract that allows users to mint membership cards during the pre-sale and public mint.
 */
contract MembershipCards is ERC721Upgradeable, OwnableUpgradeable {
    // =============================================================
    //                           Errors
    // =============================================================

    /// @dev triggered when the caller does not have the required balance to mint the requested quantity.
    error InsufficientEtherValue();

    /// @dev triggered when the requested quantity exceeds the maximum allowed per wallet.
    error InsufficientSupply();

    /// @dev triggered when the requested quantity exceeds the maximum allowed per wallet.
    error MaxMintPerAddressReached();

    /// @dev triggered when the requested quantity exceeds the maximum allowed per wallet.
    error MintNotOpened();

    /// @dev triggered when the caller is not whitelisted for the pre-sale.
    error NotWhitelisted();

    /// @dev triggered when the caller has already minted the maximum allowed per wallet.
    error WithdrawlError();

    /// @dev triggered when trading is restricted.
    error TradingRestricted();

    /// @dev triggered when the token ids and recipients arrays have different lengths.
    error IncorrectTokenIdsLength();

    /// @dev triggered when the recipients array is mismatched.
    error TooManyRecipients();

    /// @dev triggered when the recipients array is empty.
    error NoRecipients();

    // =============================================================
    //                     State variables
    // =============================================================
    uint256 public mintPrice;
    uint256 public presaleMaxMintPerWallet;
    uint256 public airdropMaxBatchSize;
    uint256 public preSaleStartTimestamp;
    uint256 public mintStartTimestamp;
    uint256 public maxMintPerAddress;
    bytes32 public whitelistMerkleRoot;
    uint256 public maxSupply;
    uint256 public totalMinted;
    string public baseURI;
    bool public mintOpened;
    bool public tradingRestricted;

    /**
     * @notice Initialize the contract with the required parameters.
     *
     * @param _name name of the membership card
     * @param _symbol symbol of the membership card
     * @param _baseURI base URI for the metadata
     * @param _maxSupply maximum supply of the membership card
     * @param _mintPrice price to mint a membership card
     * @param _airdropMaxBatchSize maximum batch size for airdrops
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _maxSupply,
        uint256 _mintPrice,
        uint256 _airdropMaxBatchSize
    ) external initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init(msg.sender);
        maxSupply = _maxSupply;
        mintPrice = _mintPrice;
        baseURI = _baseURI;
        airdropMaxBatchSize = _airdropMaxBatchSize;
    }

    // =============================================================
    //                     Contract management
    // =============================================================

    /**
     * @notice Set the maximum mint per address.
     *
     * @param _maxMintPerAddress maximum mint per address
     */
    function setMaxMintPerAddress(
        uint256 _maxMintPerAddress
    ) external onlyOwner {
        maxMintPerAddress = _maxMintPerAddress;
    }

    /**
     * @notice Set the mint start timestamp.
     *
     * @param _mintStartTimestamp mint start timestamp
     */
    function setMintStartTimestamp(
        uint256 _mintStartTimestamp
    ) external onlyOwner {
        mintStartTimestamp = _mintStartTimestamp;
    }

    /**
     * @notice Toggle the mint opened state.
     */
    function toggleMintOpened() external onlyOwner {
        mintOpened = !mintOpened;
    }

    /**
     * @notice Toggle the trading restricted state.
     */
    function toggletradingRestricted() external onlyOwner {
        tradingRestricted = !tradingRestricted;
    }

    /**
     * @notice Set the whitelist merkle root.
     *
     * @param _merkleRoot whitelist merkle root
     */
    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    /**
     * @notice Set the maximum supply.
     *
     * @param _maxSupply maximum supply
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /**
     * @notice Set the mint price.
     *
     * @param _mintPrice mint price for the membership card
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
     * @notice Set the pre-sale start timestamp.
     *
     * @param _preSaleStartTimestamp timestamp for the pre-sale to start
     */
    function setPreSaleStartTimestamp(
        uint256 _preSaleStartTimestamp
    ) external onlyOwner {
        preSaleStartTimestamp = _preSaleStartTimestamp;
    }

    /**
     * @notice Set the pre-sale max mint per wallet.
     *
     * @param _amount amount of the nfts that can be minted per wallet
     */
    function setPresaleMaxMintPerWallet(uint256 _amount) external onlyOwner {
        presaleMaxMintPerWallet = _amount;
    }

    /**
     * @notice Set the base URI.
     *
     * @param _baseURI base URI for the membership card metadata
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @notice Set the airdrop max batch size.
     *
     * @param _airdropMaxBatchSize maximum batch size for airdrops
     */
    function setAirdropMaxBatchSize(
        uint256 _airdropMaxBatchSize
    ) external onlyOwner {
        airdropMaxBatchSize = _airdropMaxBatchSize;
    }

    // =============================================================
    //                     Modifiers
    // =============================================================

    /**
     * @notice Check if the pre-sale is open.
     *
     * @return true if the pre-sale is open, false otherwise
     */
    function isPreSaleOpen() public view returns (bool) {
        return
            preSaleStartTimestamp > 0
                ? block.timestamp >= preSaleStartTimestamp
                : false;
    }

    /**
     * @notice Check when the pre-sale is active.
     */

    modifier whenPreSaleActive() {
        if (!isPreSaleOpen()) {
            revert MintNotOpened();
        }
        _;
    }

    /**
     * @notice Check when the mint is active.
     *
     * @dev The mint is active if the mint start timestamp is set and the mint is opened.
     */
    modifier whenMintActive() {
        if (
            mintStartTimestamp == 0 ||
            block.timestamp < mintStartTimestamp ||
            !mintOpened
        ) {
            revert MintNotOpened();
        }
        _;
    }

    // =============================================================
    //                     Minting
    // =============================================================

    /**
     * @notice Mint membership cards during the pre-sale.
     *
     * @param quantity amount of membership cards to mint
     * @param merkleProof merkle proof for the whitelist
     *
     * requirements:
     * - the caller must be whitelisted
     * - the caller must have enough balance to mint the requested quantity
     * - the requested quantity must not exceed the maximum supply
     * - the requested quantity must not exceed the maximum mint per wallet
     */
    function mintPreSale(
        uint256 quantity,
        bytes32[] calldata merkleProof
    ) external payable whenPreSaleActive {
        // check is WL has already been claimed for this user
        if ((balanceOf(msg.sender) + quantity) > presaleMaxMintPerWallet) {
            revert MaxMintPerAddressReached();
        }

        if (totalMinted + quantity > maxSupply) {
            revert InsufficientSupply();
        }

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if (!MerkleProof.verify(merkleProof, whitelistMerkleRoot, leaf)) {
            revert NotWhitelisted();
        }

        uint256 batchPrice = mintPrice * quantity;

        if (batchPrice > msg.value) {
            revert InsufficientEtherValue();
        }

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = totalMinted + 1;
            _mint(msg.sender, tokenId);
            totalMinted++;
        }
    }

    /**
     * @notice Mint membership cards during the public mint.
     *
     * @param quantity amount of membership cards to mint
     *
     * requirements:
     * - the caller must have enough balance to mint the requested quantity
     * - the requested quantity must not exceed the maximum supply
     * - the requested quantity must not exceed the maximum mint per wallet
     */
    function publicMint(uint256 quantity) external payable whenMintActive {
        if (totalMinted + quantity > maxSupply) {
            revert InsufficientSupply();
        }

        if ((balanceOf(msg.sender) + quantity) > maxMintPerAddress) {
            revert MaxMintPerAddressReached();
        }

        uint256 batchPrice = mintPrice * quantity;

        if (batchPrice > msg.value) {
            revert InsufficientEtherValue();
        }

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = totalMinted + 1;
            _mint(msg.sender, tokenId);
            totalMinted++;
        }
    }

    /**
     * @notice Mint membership cards during the public mint.
     *
     * @param recipient address to mint the membership cards to
     * @param quantity amount of membership cards to mint
     *
     * requirements:
     * - the caller must be the owner
     * - the requested quantity must not exceed the maximum supply
     */
    function adminMint(address recipient, uint256 quantity) external onlyOwner {
        if (totalMinted + quantity > maxSupply) {
            revert InsufficientSupply();
        }

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = totalMinted + 1;
            _mint(recipient, tokenId);
            totalMinted++;
        }
    }

    // =============================================================
    //                     ERC721 Overrides
    // =============================================================
    /**
     * @notice Override the token URI function to return the metadata URI.
     *
     * @param tokenId id of the token
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    // =============================================================
    //                     Withdrawls
    // =============================================================

    /**
     * @notice Get the contract balance.
     */
    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Withdraw an amount from the contract balance.
     *
     * @param recipient address to withdraw the balance to
     * @param amount amount to withdraw
     *
     * requirements:
     * - the caller must be the owner
     */
    function withdrawAmount(
        address payable recipient,
        uint256 amount
    ) external onlyOwner {
        (bool succeed, ) = recipient.call{value: amount}("");
        if (!succeed) {
            revert WithdrawlError();
        }
    }

    /**
     * @notice Withdraw the entire contract balance.
     *
     * @param recipient address to withdraw the balance to
     *
     * requirements:
     * - the caller must be the owner
     */
    function withdrawAll(address payable recipient) external onlyOwner {
        (bool succeed, ) = recipient.call{value: balance()}("");
        if (!succeed) {
            revert WithdrawlError();
        }
    }

    // =============================================================
    //                     Airdrops
    // =============================================================

    /**
     * @notice Batch transfer membership cards to a list of recipients.
     * 
     * @param recipients list of recipients
     * @param tokenIds list of token ids
     * 
     requirements:
     * - the recipients array must not be empty
     * - the recipients array must not exceed the maximum batch size
     * - the token ids array must have the same length as the recipients array
     */
    function batchTransfer(
        address[] calldata recipients,
        uint256[] calldata tokenIds
    ) external {
        if (recipients.length == 0) {
            revert NoRecipients();
        }

        if (recipients.length > airdropMaxBatchSize) {
            revert TooManyRecipients();
        }

        if (tokenIds.length != recipients.length) {
            revert IncorrectTokenIdsLength();
        }

        for (uint256 i = 0; i < recipients.length; i++) {
            safeTransferFrom(msg.sender, recipients[i], tokenIds[i]);
        }
    }
}
