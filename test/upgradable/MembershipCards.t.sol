// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "@openzeppelin-contracts-upgradeable-5.0.2/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";
import "@openzeppelin-contracts-5.0.2/utils/cryptography/MerkleProof.sol";
import "@openzeppelin-contracts-5.0.2/interfaces/draft-IERC6093.sol";
import "@openzeppelin-contracts-5.0.2/utils/Strings.sol";
import {Merkle} from "murky/src/Merkle.sol";
import {RevertingRecipient} from "../mocks/RevertingRecipient.sol";

import {MembershipCards} from "../../src/upgradable/MembershipCards.sol";
import {Fork} from "../utils/Fork.sol";

abstract contract Base is Fork {
    address payable deployer = payable(makeAddr("deployer"));
    address payable user1 = payable(makeAddr("user1"));
    address payable user2 = payable(makeAddr("user2"));
    address payable wlUser1 = payable(makeAddr("wlUser1"));
    address payable wlUser2 = payable(makeAddr("wlUser2"));
    address payable unauthorizedUser = payable(makeAddr("unauthorizedUser"));

    MembershipCards internal contractUnderTest;

    address[] whitelistedUsers = [wlUser1, wlUser2];
    bytes32 whitelistMerkleRoot =
        0xde81cbd8ef31da8553f3ea08ff81bf2650bd86e3812104df4d805117cefb9a9c;

    function deploy() public {
        runFork();
        vm.selectFork(mainnetFork);

        contractUnderTest = new MembershipCards();

        vm.startPrank(deployer);

        contractUnderTest.initialize(
            "MembershipCards",
            "MC",
            "www.example.com/",
            100,
            1 ether,
            100
        );

        // label the contracts
        vm.label(address(contractUnderTest), "membershipCards");

        vm.label(deployer, "deployer");
        vm.label(user1, "user1");
        vm.label(user2, "user2");
        vm.label(wlUser1, "wlUser1");
        vm.label(wlUser2, "wlUser2");
        vm.label(unauthorizedUser, "unauthorizedUser");

        // deal funds to EOAs
        vm.deal(deployer, 100 ether);
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(wlUser1, 100 ether);
        vm.deal(wlUser2, 100 ether);
        vm.deal(unauthorizedUser, 100 ether);
    }

    function generateMerkleProof(
        uint256 node
    ) public returns (bytes32[] memory WLProof) {
        Merkle merkle = new Merkle();

        bytes32[] memory data = new bytes32[](whitelistedUsers.length);
        for (uint256 i = 0; i < whitelistedUsers.length; i++) {
            data[i] = keccak256(abi.encodePacked(whitelistedUsers[i]));
        }

        bytes32 root = merkle.getRoot(data);
        contractUnderTest.setWhitelistMerkleRoot(root);

        return merkle.getProof(data, node);
    }
}

contract Initialize is Base {
    function setUp() public {
        super.deploy();
    }

    function test_should_set_owner() external view {
        assertEq(contractUnderTest.owner(), address(deployer));
    }

    function test_should_set_name() external view {
        assertEq(contractUnderTest.name(), "MembershipCards");
    }

    function test_should_set_symbol() external view {
        assertEq(contractUnderTest.symbol(), "MC");
    }

    function test_should_set_max_supply() external view {
        assertEq(contractUnderTest.maxSupply(), 100);
    }

    function test_should_set_mint_price() external view {
        assertEq(contractUnderTest.mintPrice(), 1 ether);
    }

    function test_should_revert_when_already_initialized() external {
        vm.startPrank(deployer);

        vm.expectRevert(Initializable.InvalidInitialization.selector);
        contractUnderTest.initialize(
            "MembershipCards",
            "MC",
            "www.example.com/",
            100,
            1 ether,
            100
        );
    }
}

contract ContractManagement is Base {
    function setUp() public {
        super.deploy();
    }

    function test_should_set_max_mint_per_address() external {
        uint256 startingMaxMintPerAddress = contractUnderTest
            .maxMintPerAddress();
        assertEq(startingMaxMintPerAddress, 0);

        vm.startPrank(deployer);
        contractUnderTest.setMaxMintPerAddress(10);
        assertEq(contractUnderTest.maxMintPerAddress(), 10);
    }

    function test_should_revert_when_set_max_mint_per_address_not_owner()
        external
    {
        bytes4 selector = OwnableUpgradeable
            .OwnableUnauthorizedAccount
            .selector;
        vm.expectRevert(abi.encodeWithSelector(selector, wlUser2));

        vm.startPrank(wlUser2);
        contractUnderTest.setMaxMintPerAddress(10);
    }

    function test_should_set_mint_start_timestamp() external {
        uint256 startingMintStartTimestamp = contractUnderTest
            .mintStartTimestamp();
        assertEq(startingMintStartTimestamp, 0);

        vm.startPrank(deployer);
        uint256 mintStartTimestamp = 1722681924;
        contractUnderTest.setMintStartTimestamp(mintStartTimestamp);
        assertEq(contractUnderTest.mintStartTimestamp(), mintStartTimestamp);
    }

    function test_should_revert_when_set_mint_start_timestamp_not_owner()
        external
    {
        bytes4 selector = OwnableUpgradeable
            .OwnableUnauthorizedAccount
            .selector;
        vm.expectRevert(abi.encodeWithSelector(selector, unauthorizedUser));

        vm.startPrank(unauthorizedUser);
        contractUnderTest.setMintStartTimestamp(1722681924);
    }

    function test_should_toggle_mint_opened() external {
        bool startingMintOpened = contractUnderTest.mintOpened();
        assertEq(startingMintOpened, false);

        vm.startPrank(deployer);
        contractUnderTest.toggleMintOpened();
        assertEq(contractUnderTest.mintOpened(), true);
    }

    function test_should_revert_when_toggle_mint_opened_not_owner() external {
        bytes4 selector = OwnableUpgradeable
            .OwnableUnauthorizedAccount
            .selector;
        vm.expectRevert(abi.encodeWithSelector(selector, unauthorizedUser));

        vm.startPrank(unauthorizedUser);
        contractUnderTest.toggleMintOpened();
    }

    function test_should_toggle_trading_restricted() external {
        bool startingTradingRestricted = contractUnderTest.tradingRestricted();
        assertEq(startingTradingRestricted, false);

        vm.startPrank(deployer);
        contractUnderTest.toggletradingRestricted();
        assertEq(contractUnderTest.tradingRestricted(), true);
    }

    function test_should_revert_when_toggle_trading_restricted_not_owner()
        external
    {
        bytes4 selector = OwnableUpgradeable
            .OwnableUnauthorizedAccount
            .selector;
        vm.expectRevert(abi.encodeWithSelector(selector, unauthorizedUser));

        vm.startPrank(unauthorizedUser);
        contractUnderTest.toggletradingRestricted();
    }

    function test_should_set_whitelist_merkle_root() external {
        bytes32 startingWhitelistMerkleRoot = contractUnderTest
            .whitelistMerkleRoot();
        assertEq(startingWhitelistMerkleRoot, bytes32(0));

        vm.startPrank(deployer);
        bytes32 whitelistMerkleRoot = keccak256("whitelistMerkleRoot");
        contractUnderTest.setWhitelistMerkleRoot(whitelistMerkleRoot);
        assertEq(contractUnderTest.whitelistMerkleRoot(), whitelistMerkleRoot);
    }

    function test_should_revert_when_set_whitelist_merkle_root_not_owner()
        external
    {
        bytes4 selector = OwnableUpgradeable
            .OwnableUnauthorizedAccount
            .selector;
        vm.expectRevert(abi.encodeWithSelector(selector, unauthorizedUser));

        vm.startPrank(unauthorizedUser);
        contractUnderTest.setWhitelistMerkleRoot(
            keccak256("whitelistMerkleRoot")
        );
    }

    function test_should_set_max_supply() external {
        uint256 startingMaxSupply = contractUnderTest.maxSupply();
        assertEq(startingMaxSupply, 100);

        vm.startPrank(deployer);
        contractUnderTest.setMaxSupply(200);
        assertEq(contractUnderTest.maxSupply(), 200);
    }

    function test_should_revert_when_set_max_supply_not_owner() external {
        bytes4 selector = OwnableUpgradeable
            .OwnableUnauthorizedAccount
            .selector;
        vm.expectRevert(abi.encodeWithSelector(selector, unauthorizedUser));

        vm.startPrank(unauthorizedUser);
        contractUnderTest.setMaxSupply(200);
    }

    function test_should_set_mint_price() external {
        uint256 startingMintPrice = contractUnderTest.mintPrice();
        assertEq(startingMintPrice, 1 ether);

        vm.startPrank(deployer);
        contractUnderTest.setMintPrice(2 ether);
        assertEq(contractUnderTest.mintPrice(), 2 ether);
    }

    function test_should_revert_when_set_mint_price_not_owner() external {
        bytes4 selector = OwnableUpgradeable
            .OwnableUnauthorizedAccount
            .selector;
        vm.expectRevert(abi.encodeWithSelector(selector, unauthorizedUser));

        vm.startPrank(unauthorizedUser);
        contractUnderTest.setMintPrice(2 ether);
    }

    function test_should_set_pre_sale_start_timestamp() external {
        uint256 startingPreSaleStartTimestamp = contractUnderTest
            .preSaleStartTimestamp();
        assertEq(startingPreSaleStartTimestamp, 0);

        vm.startPrank(deployer);
        uint256 preSaleStartTimestamp = 1722681924;
        contractUnderTest.setPreSaleStartTimestamp(preSaleStartTimestamp);
        assertEq(
            contractUnderTest.preSaleStartTimestamp(),
            preSaleStartTimestamp
        );
    }

    function test_should_revert_when_set_pre_sale_start_timestamp_not_owner()
        external
    {
        bytes4 selector = OwnableUpgradeable
            .OwnableUnauthorizedAccount
            .selector;
        vm.expectRevert(abi.encodeWithSelector(selector, unauthorizedUser));

        vm.startPrank(unauthorizedUser);
        contractUnderTest.setPreSaleStartTimestamp(1722681924);
    }

    function test_should_set_presale_max_mint_per_wallet() external {
        uint256 startingPresaleMaxMintPerWallet = contractUnderTest
            .presaleMaxMintPerWallet();
        assertEq(startingPresaleMaxMintPerWallet, 0);

        vm.startPrank(deployer);
        contractUnderTest.setPresaleMaxMintPerWallet(10);
        assertEq(contractUnderTest.presaleMaxMintPerWallet(), 10);
    }

    function test_should_revert_when_set_presale_max_mint_per_wallet_not_owner()
        external
    {
        bytes4 selector = OwnableUpgradeable
            .OwnableUnauthorizedAccount
            .selector;
        vm.expectRevert(abi.encodeWithSelector(selector, unauthorizedUser));

        vm.startPrank(unauthorizedUser);
        contractUnderTest.setPresaleMaxMintPerWallet(10);
    }

    function test_should_set_airdrop_max_batch_size() external {
        uint256 startingAirdropMaxBatchSize = contractUnderTest
            .airdropMaxBatchSize();
        assertEq(startingAirdropMaxBatchSize, 100);

        vm.startPrank(deployer);
        contractUnderTest.setAirdropMaxBatchSize(10);
        assertEq(contractUnderTest.airdropMaxBatchSize(), 10);
    }

    function test_should_revert_when_set_airdrop_max_batch_size_not_owner()
        external
    {
        bytes4 selector = OwnableUpgradeable
            .OwnableUnauthorizedAccount
            .selector;
        vm.expectRevert(abi.encodeWithSelector(selector, unauthorizedUser));

        vm.startPrank(unauthorizedUser);
        contractUnderTest.setAirdropMaxBatchSize(10);
    }

    function test_should_default_to_false_when_preSaleStartTimestamp_is_zero()
        external view
    {
        assertEq(contractUnderTest.isPreSaleOpen(), false);
    }

}

contract PreMint is Base {
    function setUp() public {
        super.deploy();
    }

    function test_should_mint_successfully() external {
        vm.startPrank(deployer);
        contractUnderTest.toggleMintOpened();
        contractUnderTest.setPreSaleStartTimestamp(block.timestamp - 1);
        contractUnderTest.setPresaleMaxMintPerWallet(1);

        uint256 node = 0;
        bytes32[] memory WLProof = generateMerkleProof(node);
        vm.stopPrank();

        vm.startPrank(wlUser1);
        contractUnderTest.mintPreSale{value: 1 ether}(1, WLProof);

        assertEq(contractUnderTest.balanceOf(wlUser1), 1);
    }

    function test_should_revert_when_pre_sale_not_open() external {
        vm.startPrank(deployer);
        uint256 node = 0;
        bytes32[] memory WLProof = generateMerkleProof(node);
        contractUnderTest.setPreSaleStartTimestamp(0);
        vm.stopPrank();

        vm.expectRevert(MembershipCards.MintNotOpened.selector);
        vm.startPrank(unauthorizedUser);

        contractUnderTest.mintPreSale(1, WLProof);
    }

    function test_should_revert_when_max_mint_per_wallet_reached() external {
        vm.startPrank(deployer);
        contractUnderTest.toggleMintOpened();
        contractUnderTest.setPreSaleStartTimestamp(block.timestamp - 1);
        contractUnderTest.setPresaleMaxMintPerWallet(1);

        uint256 node = 0;
        bytes32[] memory WLProof = generateMerkleProof(node);
        vm.stopPrank();

        vm.startPrank(wlUser1);
        contractUnderTest.mintPreSale{value: 1 ether}(1, WLProof);

        vm.expectRevert(MembershipCards.MaxMintPerAddressReached.selector);
        contractUnderTest.mintPreSale{value: 1 ether}(1, WLProof);
    }

    function test_should_revert_when_insufficient_supply() external {
        vm.startPrank(deployer);
        contractUnderTest.toggleMintOpened();
        contractUnderTest.setPreSaleStartTimestamp(block.timestamp - 1);
        contractUnderTest.setPresaleMaxMintPerWallet(2);
        contractUnderTest.setMaxSupply(1);

        uint256 node = 0;
        bytes32[] memory WLProof = generateMerkleProof(node);
        vm.stopPrank();

        vm.startPrank(wlUser1);
        contractUnderTest.mintPreSale{value: 1 ether}(1, WLProof);

        vm.expectRevert(MembershipCards.InsufficientSupply.selector);
        contractUnderTest.mintPreSale{value: 1 ether}(1, WLProof);
    }

    function test_should_revert_when_user_is_not_whitelisted() external {
        vm.startPrank(deployer);
        contractUnderTest.toggleMintOpened();
        contractUnderTest.setPreSaleStartTimestamp(block.timestamp - 1);
        contractUnderTest.setPresaleMaxMintPerWallet(1);

        uint256 node = 0;
        bytes32[] memory WLProof = generateMerkleProof(node);
        vm.stopPrank();

        vm.expectRevert(MembershipCards.NotWhitelisted.selector);
        vm.startPrank(unauthorizedUser);
        contractUnderTest.mintPreSale{value: 1 ether}(1, WLProof);
    }

    function test_should_revert_when_user_has_insufficient_ether_value()
        external
    {
        vm.startPrank(deployer);
        contractUnderTest.toggleMintOpened();
        contractUnderTest.setPreSaleStartTimestamp(block.timestamp - 1);
        contractUnderTest.setPresaleMaxMintPerWallet(2);

        uint256 node = 0;
        bytes32[] memory WLProof = generateMerkleProof(node);
        vm.stopPrank();

        vm.deal(wlUser1, 1 ether);

        vm.startPrank(wlUser1);
        vm.expectRevert(MembershipCards.InsufficientEtherValue.selector);
        contractUnderTest.mintPreSale{value: 1 ether}(2, WLProof);
    }

    function set_should_set_base_uri() external {
        string memory baseURI = "www.example.com/";
        assertEq(contractUnderTest.baseURI(), baseURI);

        vm.startPrank(deployer);
        contractUnderTest.setBaseURI("www.newexample.com/");
        assertEq(contractUnderTest.baseURI(), "www.newexample.com/");
    }

    function test_should_revert_when_set_base_uri_not_owner() external {
        bytes4 selector = OwnableUpgradeable
            .OwnableUnauthorizedAccount
            .selector;
        vm.expectRevert(abi.encodeWithSelector(selector, unauthorizedUser));

        vm.startPrank(unauthorizedUser);
        contractUnderTest.setBaseURI("www.newexample.com/");
    }
}

contract PublicMint is Base {
    function setUp() public {
        super.deploy();
    }

    function test_should_mint_successfully() external {
        vm.startPrank(deployer);
        contractUnderTest.toggleMintOpened();
        contractUnderTest.setMintStartTimestamp(block.timestamp - 1);
        contractUnderTest.setMaxMintPerAddress(1);
        vm.stopPrank();

        vm.startPrank(user1);
        contractUnderTest.publicMint{value: 1 ether}(1);

        assertEq(contractUnderTest.balanceOf(user1), 1);
    }

    function test_should_revert_when_sale_not_open() external {
        vm.startPrank(deployer);
        vm.expectRevert(MembershipCards.MintNotOpened.selector);
        contractUnderTest.publicMint{value: 1 ether}(1);
    }

    function test_should_revert_when_insufficient_supply() external {
        vm.startPrank(deployer);
        contractUnderTest.toggleMintOpened();
        contractUnderTest.setMintStartTimestamp(block.timestamp - 1);
        contractUnderTest.setMaxMintPerAddress(2);
        contractUnderTest.setMaxSupply(1);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert(MembershipCards.InsufficientSupply.selector);
        contractUnderTest.publicMint{value: 1 ether}(2);
    }

    function test_should_revert_when_max_mint_per_wallet_reached() external {
        vm.startPrank(deployer);
        contractUnderTest.toggleMintOpened();
        contractUnderTest.setMintStartTimestamp(block.timestamp - 1);
        contractUnderTest.setMaxMintPerAddress(1);
        vm.stopPrank();

        vm.startPrank(user1);
        contractUnderTest.publicMint{value: 1 ether}(1);

        vm.expectRevert(MembershipCards.MaxMintPerAddressReached.selector);
        contractUnderTest.publicMint{value: 1 ether}(1);
    }

    function test_should_revert_when_user_has_insufficient_ether_value()
        external
    {
        vm.startPrank(deployer);
        contractUnderTest.toggleMintOpened();
        contractUnderTest.setMintStartTimestamp(block.timestamp - 1);
        contractUnderTest.setMaxMintPerAddress(2);
        vm.stopPrank();

        vm.deal(user1, 1 ether);

        vm.startPrank(user1);
        vm.expectRevert(MembershipCards.InsufficientEtherValue.selector);
        contractUnderTest.publicMint{value: 1 ether}(2);
    }
}

contract AdminMint is Base {
    function setUp() public {
        super.deploy();
    }

    function test_should_mint_successfully() external {
        vm.startPrank(deployer);
        contractUnderTest.toggleMintOpened();
        contractUnderTest.setMintStartTimestamp(block.timestamp - 1);

        contractUnderTest.adminMint(user1, 10);
        assertEq(contractUnderTest.balanceOf(user1), 10);
    }

    function test_should_revert_when_caller_is_not_owner() external {
        vm.startPrank(deployer);
        contractUnderTest.toggleMintOpened();
        contractUnderTest.setMintStartTimestamp(block.timestamp - 1);

        bytes4 selector = OwnableUpgradeable
            .OwnableUnauthorizedAccount
            .selector;
        vm.expectRevert(abi.encodeWithSelector(selector, user1));

        vm.startPrank(user1);
        contractUnderTest.adminMint(user1, 10);
    }

    function test_should_revert_when_insufficient_supply() external {
        vm.startPrank(deployer);
        contractUnderTest.toggleMintOpened();
        contractUnderTest.setMintStartTimestamp(block.timestamp - 1);
        contractUnderTest.setMaxSupply(1);
        vm.stopPrank();

        vm.expectRevert(MembershipCards.InsufficientSupply.selector);
        vm.startPrank(deployer);
        contractUnderTest.adminMint(user1, 10);
    }
}

contract TokenURI is Base {
    function setUp() public {
        super.deploy();
    }

    function test_should_return_tokenURI_after_mint() external {
        vm.startPrank(deployer);
        contractUnderTest.toggleMintOpened();
        contractUnderTest.setMintStartTimestamp(block.timestamp - 1);
        contractUnderTest.setMaxMintPerAddress(1);
        vm.stopPrank();

        vm.startPrank(user1);
        contractUnderTest.publicMint{value: 1 ether}(1);

        assertEq(contractUnderTest.tokenURI(1), "www.example.com/1");
    }

    function test_should_return_token_uri_with_new_base_uri_after_mint()
        external
    {
        vm.startPrank(deployer);
        contractUnderTest.toggleMintOpened();
        contractUnderTest.setMintStartTimestamp(block.timestamp - 1);
        contractUnderTest.setMaxMintPerAddress(1);
        vm.stopPrank();

        vm.startPrank(user1);
        contractUnderTest.publicMint{value: 1 ether}(1);
        vm.stopPrank();

        vm.startPrank(deployer);
        contractUnderTest.setBaseURI("www.newexample.com/");

        assertEq(contractUnderTest.tokenURI(1), "www.newexample.com/1");
    }
}

contract Withdrawls is Base {
    function setUp() public {
        super.deploy();
    }

    function test_should_return_balance_after_mint() external {
        vm.startPrank(deployer);
        contractUnderTest.toggleMintOpened();
        contractUnderTest.setMintStartTimestamp(block.timestamp - 1);
        contractUnderTest.setMaxMintPerAddress(1);
        vm.stopPrank();

        vm.startPrank(user1);
        contractUnderTest.publicMint{value: 1 ether}(1);

        assertEq(contractUnderTest.balance(), 1 ether);
    }

    function should_return_balance_after_multiple_mints() external {
        vm.startPrank(deployer);
        contractUnderTest.toggleMintOpened();
        contractUnderTest.setMintStartTimestamp(block.timestamp - 1);
        contractUnderTest.setMaxMintPerAddress(1);
        vm.stopPrank();

        vm.startPrank(user1);
        contractUnderTest.publicMint{value: 1 ether}(1);
        contractUnderTest.publicMint{value: 1 ether}(1);

        assertEq(contractUnderTest.balance(), 2 ether);
    }

    function test_owner_should_withdraw_portion_of_balance() external {
        vm.startPrank(deployer);
        contractUnderTest.toggleMintOpened();
        contractUnderTest.setMintStartTimestamp(block.timestamp - 1);
        contractUnderTest.setMaxMintPerAddress(2);
        vm.stopPrank();

        vm.startPrank(user1);
        contractUnderTest.publicMint{value: 2 ether}(2);

        vm.startPrank(deployer);
        contractUnderTest.withdrawAmount(deployer, 1 ether);

        assertEq(contractUnderTest.balance(), 1 ether);
    }

    function test_should_revert_when_unauthorized_attempts_to_withdraw_amount()
        external
    {
        vm.startPrank(deployer);
        contractUnderTest.toggleMintOpened();
        contractUnderTest.setMintStartTimestamp(block.timestamp - 1);
        contractUnderTest.setMaxMintPerAddress(2);
        vm.stopPrank();

        vm.startPrank(user1);
        contractUnderTest.publicMint{value: 2 ether}(2);

        bytes4 selector = OwnableUpgradeable
            .OwnableUnauthorizedAccount
            .selector;
        vm.expectRevert(abi.encodeWithSelector(selector, user1));

        contractUnderTest.withdrawAmount(user1, 1 ether);
    }

    function test_should_revert_when_recipient_call_fails_withdrawing_amount()
        external
    {
        vm.startPrank(deployer);
        contractUnderTest.toggleMintOpened();
        contractUnderTest.setMintStartTimestamp(block.timestamp - 1);
        contractUnderTest.setMaxMintPerAddress(2);
        vm.stopPrank();

        vm.startPrank(user1);
        contractUnderTest.publicMint{value: 2 ether}(2);

        RevertingRecipient recipient = new RevertingRecipient();
        address payable recipientAddress = payable(address(recipient));

        vm.startPrank(deployer);
        vm.expectRevert(MembershipCards.WithdrawlError.selector);

        contractUnderTest.withdrawAmount(recipientAddress, 1 ether);
    }

    function test_should_be_able_to_withdraw_all_funds() external {
        vm.startPrank(deployer);
        contractUnderTest.toggleMintOpened();
        contractUnderTest.setMintStartTimestamp(block.timestamp - 1);
        contractUnderTest.setMaxMintPerAddress(2);
        vm.stopPrank();

        vm.startPrank(user1);
        contractUnderTest.publicMint{value: 2 ether}(2);

        vm.startPrank(deployer);
        contractUnderTest.withdrawAll(deployer);

        assertEq(contractUnderTest.balance(), 0);
    }

    function test_should_revert_when_unauthorized_attempts_to_withdraw_all_funds()
        external
    {
        vm.startPrank(deployer);
        contractUnderTest.toggleMintOpened();
        contractUnderTest.setMintStartTimestamp(block.timestamp - 1);
        contractUnderTest.setMaxMintPerAddress(2);
        vm.stopPrank();

        vm.startPrank(user1);
        contractUnderTest.publicMint{value: 2 ether}(2);

        RevertingRecipient recipient = new RevertingRecipient();
        address payable recipientAddress = payable(address(recipient));

        vm.expectRevert(MembershipCards.WithdrawlError.selector);

        contractUnderTest.withdrawAll(recipientAddress);
    }
}

contract BatchTransfer is Base {
    function setUp() public {
        super.deploy();
    }

    function test_should_successfully_perform_airdrop() external {
        vm.startPrank(deployer);
        contractUnderTest.toggleMintOpened();
        contractUnderTest.setMintStartTimestamp(block.timestamp - 1);
        contractUnderTest.setMaxMintPerAddress(2);
        vm.stopPrank();

        vm.startPrank(user1);
        contractUnderTest.publicMint{value: 2 ether}(2);

        address[] memory recipients = new address[](1);
        recipients[0] = user2;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        contractUnderTest.batchTransfer(recipients, tokenIds);
        vm.stopPrank();

        assertEq(contractUnderTest.balanceOf(user2), 1);
    }

    function test_should_revert_when_no_recipients() external {
        vm.expectRevert(MembershipCards.NoRecipients.selector);
        contractUnderTest.batchTransfer(new address[](0), new uint256[](0));
    }

    function test_should_revert_WHen_recipients_and_tokenIds_length_mismatch()
        external
    {
        vm.expectRevert(MembershipCards.IncorrectTokenIdsLength.selector);
        contractUnderTest.batchTransfer(new address[](1), new uint256[](2));
    }

    function test_shouuld_revert_when_recipients_length_exceeds_airdrop_max_batch_size()
        external
    {
        vm.expectRevert(MembershipCards.TooManyRecipients.selector);
        contractUnderTest.batchTransfer(new address[](101), new uint256[](101));
    }

    function test_should_revert_when_contract_is_not_approved() external {
        vm.startPrank(deployer);
        contractUnderTest.toggleMintOpened();
        contractUnderTest.setMintStartTimestamp(block.timestamp - 1);
        contractUnderTest.setMaxMintPerAddress(2);
        vm.stopPrank();

        vm.startPrank(user1);
        contractUnderTest.publicMint{value: 2 ether}(2);
        vm.stopPrank();

        vm.startPrank(user2);

        address[] memory recipients = new address[](1);
        recipients[0] = user2;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        bytes4 selector = IERC721Errors.ERC721InsufficientApproval.selector;
        vm.expectRevert(abi.encodeWithSelector(selector, address(user2), 1));

        contractUnderTest.batchTransfer(recipients, tokenIds);
    }
}
