// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin-contracts-upgradeable-5.0.2/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";
import "@openzeppelin-contracts-5.0.2/utils/cryptography/MerkleProof.sol";
import "@openzeppelin-contracts-5.0.2/utils/Strings.sol";

contract MembershipCards is
    ERC721Upgradeable,
    OwnableUpgradeable
{
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Errors
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    error InsufficientEtherValue();
    error InsufficientSupply();
    error MaxMintPerAddressReached();
    error MintNotOpened();
    error NotWhitelisted();
    error WithdrawlError();
    error TradingRestricted();
    error IncorrectTokenIdsLength();
    error TooManyRecipients();
    error NoRecipients();

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Events
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * State
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    uint256 public immutable MINT_PRICE;
    uint256 public  presaleMaxMintPerWallet;
    uint256 public  airdropMaxBatchSize;
    uint256 public preSaleStartTimestamp;
    uint256 public mintStartTimestamp;
    uint256 public maxMintPerAddress;
    bytes32 public whitelistMerkleRoot;
    uint256 public maxSupply;
    string public baseURI;
    bool public mintOpened;
    bool public tradingRestricted;

    function initialize(string memory _name, string memory _symbol, uint256 _maxSupply) internal initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init(msg.sender);
        maxSupply = _maxSupply;
    }


    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Contract management
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function setMaxMintPerAddress(
        uint256 _maxMintPerAddress
    ) external onlyOwner {
        maxMintPerAddress = _maxMintPerAddress;
    }

    function setMintStartTimestamp(
        uint256 _mintStartTimestamp
    ) external onlyOwner {
        mintStartTimestamp = _mintStartTimestamp;
    }

    function toggleMintOpened() external onlyOwner {
        mintOpened = !mintOpened;
    }

    function toggletradingRestricted() external onlyOwner {
        tradingRestricted = !tradingRestricted;
    }


    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }


    function setPreSaleStartTimestamp(
        uint256 _preSaleStartTimestamp
    ) external onlyOwner {
        preSaleStartTimestamp = _preSaleStartTimestamp;
    }


    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * MODIFIERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function isPreSaleOpen() public view returns (bool) {
        return
            preSaleStartTimestamp > 0
                ? block.timestamp >= preSaleStartTimestamp
                : false;
    }

    modifier whenPreSaleActive() {
        if (!isPreSaleOpen()) {
            revert MintNotOpened();
        }
        _;
    }

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

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Minting
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function mintPreSale(
        uint256 quantity,
        bytes32[] calldata merkleProof
    ) external payable whenPreSaleActive {
        // check is WL has already been claimed for this user
        if ((balanceOf(msg.sender) + quantity) > presaleMaxMintPerWallet) {
            revert MaxMintPerAddressReached();
        }

        if (balanceOf(msg.sender) + quantity > maxSupply) {
            revert InsufficientSupply();
        }

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if (!MerkleProof.verify(merkleProof, whitelistMerkleRoot, leaf)) {
            revert NotWhitelisted();
        }

        uint256 batchPrice = MINT_PRICE * quantity;

        if (batchPrice > msg.value) {
            revert InsufficientEtherValue();
        }


        _mint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable whenMintActive {
        if (balanceOf(msg.sender) + quantity > maxSupply) {
            revert InsufficientSupply();
        }

        if ((balanceOf(msg.sender) + quantity) > maxMintPerAddress) {
            revert MaxMintPerAddressReached();
        }

        uint256 batchPrice = MINT_PRICE * quantity;

        if (batchPrice > msg.value) {
            revert InsufficientEtherValue();
        }


        _mint(msg.sender, quantity);
    }

    function adminMint(address recipient, uint256 quantity) external onlyOwner {
        if (balanceOf(msg.sender)  + quantity > maxSupply) {
            revert InsufficientSupply();
        }

        _mint(recipient, quantity);
    }

   function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }


    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     * Withdrawls
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawAmount(
        address payable recipient,
        uint256 amount
    ) external onlyOwner {
        (bool succeed, ) = recipient.call{value: amount}("");
        if (!succeed) {
            revert WithdrawlError();
        }
    }

    function withdrawAll(address payable recipient) external onlyOwner {
        (bool succeed, ) = recipient.call{value: balance()}("");
        if (!succeed) {
            revert WithdrawlError();
        }
    }

    function airdrop(
        address[] calldata recipients,
        uint256[] calldata tokenIds
    ) external onlyOwner {
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
            safeTransferFrom(owner(), recipients[i], tokenIds[i]);
        }
    }

    /**
     * isCardHolder function
     * @param tokenId the card Token ID
     * Note: If tokenId is 0, then user is not an Card holder
     */
    function isCardHolder(uint256 tokenId) public view returns (bool) {
        if (tokenId != 0) {
            address cardOwner = ownerOf(tokenId);
            return cardOwner != tx.origin;
        }
        return false;
    }
}
