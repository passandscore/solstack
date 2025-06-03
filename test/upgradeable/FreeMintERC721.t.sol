// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.25;

import "@openzeppelin-contracts-upgradeable-5.0.2/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin-contracts-upgradeable-5.0.2/proxy/utils/Initializable.sol";
import "@openzeppelin-contracts-upgradeable-5.0.2/access/OwnableUpgradeable.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {FreeMintERC721} from "../../src/upgradeable/FreeMintERC721.sol";
import {Base64} from "@openzeppelin-contracts-5.0.2/utils/Base64.sol";
import {LibString} from "@solmate-6.7.0/utils/LibString.sol";
import {Fork} from "../utils/Fork.sol";

abstract contract Base is Fork {
    FreeMintERC721 internal contractUnderTest;

    address payable deployer = payable(makeAddr("deployer"));
    address payable user1 = payable(makeAddr("user1"));
    address payable user2 = payable(makeAddr("user2"));
    address payable unauthorizedUser = payable(makeAddr("unauthorizedUser"));

    function deploy() public {
        runFork();
        vm.selectFork(mainnetFork);

        contractUnderTest = new FreeMintERC721();

        vm.startPrank(deployer);

        contractUnderTest.initialize("FreeMintERC721", "FM", "test.com");
        contractUnderTest.setMetadataProperties(
            "nft name goes here",
            "artist name goes here",
            "description goes here"
        );

        // label the contracts
        vm.label(address(contractUnderTest), "FreeMintERC721");

        // label the EOAs
        vm.label(deployer, "deployer");
        vm.label(user1, "user1");
        vm.label(user2, "user2");
        vm.label(unauthorizedUser, "unauthorizedUser");
    }

    function expectedMetadata(
        uint256 tokenId
    ) internal view returns (string memory) {
        string memory metadata = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{ "name": "',
                        contractUnderTest._nftName(),
                        " #",
                        LibString.toString(tokenId),
                        '", "tokenId": "',
                        LibString.toString(tokenId),
                        '", "image": "',
                        contractUnderTest._assetURI(),
                        '", "properties": { "artistName": "',
                        contractUnderTest._artistName(),
                        '"}, "description": "',
                        contractUnderTest._description(),
                        '"}'
                    )
                )
            )
        );

        return metadata;
    }

    function setMintingWindow(uint256 startTime, uint256 endTime) internal {
        contractUnderTest.setMintDuration(uint32(startTime), uint32(endTime));
    }
}

contract Initialize is Base {
    function setUp() public {
        super.deploy();
    }

    function test_should_set_name() external view {
        assertEq(contractUnderTest.name(), "FreeMintERC721");
    }

    function test_should_set_symbol() external view {
        assertEq(contractUnderTest.symbol(), "FM");
    }

    function test_should_set_BaseURI() external view {
        assertEq(contractUnderTest._assetURI(), "test.com");
    }

    function test_should_set_owner() external view {
        assertEq(contractUnderTest.owner(), address(deployer));
    }

    function test_when_already_initialized() external {
        vm.startPrank(deployer);
        bytes4 selector = Initializable.InvalidInitialization.selector;

        vm.expectRevert(abi.encodeWithSelector(selector));
        contractUnderTest.initialize("FreeMintERC721", "FM", "test.com");
    }
}

contract Mint is Base {
    function setUp() public {
        super.deploy();
    }

    function test_should_revert_when_mint_paused_and_no_duration_set()
        external
    {
        vm.startPrank(deployer);
        contractUnderTest.pauseMint();
        vm.expectRevert(FreeMintERC721.MintingNotEnabled.selector);
        contractUnderTest.mint();
    }

    function test_should_revert_when_duration_set_but_minting_paused()
        external
    {
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        contractUnderTest.pauseMint();

        vm.expectRevert(FreeMintERC721.MintingNotEnabled.selector);
        contractUnderTest.mint();
    }

    function test_should_return_zero_minted_when_none_minted() external view {
        assertEq(contractUnderTest.totalSupply(), 0);
    }

    function test_should_return_proper_minted_count_when_mint_unpaused()
        external
    {
        vm.startPrank(deployer);
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        contractUnderTest.mint();
        vm.stopPrank();

        vm.startPrank(user1);
        contractUnderTest.mint();
        vm.stopPrank();

        vm.startPrank(user2);
        contractUnderTest.mint();

        assertEq(contractUnderTest.totalSupply(), 3);
    }

    function test_should_revert_when_already_minted() external {
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        contractUnderTest.mint();
        vm.expectRevert(FreeMintERC721.TokenAlreadyMinted.selector);
        contractUnderTest.mint();
    }

    function test_should_mint_when_unpaused_and_then_revert_when_paused()
        external
    {
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        contractUnderTest.mint();

        contractUnderTest.pauseMint();
        vm.expectRevert(FreeMintERC721.MintingNotEnabled.selector);

        vm.startPrank(user1);
        contractUnderTest.mint();
    }

    function test_should_prevent_minting_when_minting_duration_has_ended()
        external
    {
        vm.startPrank(deployer);

        uint256 startTime = block.timestamp - 1 days;
        uint256 endTime = block.timestamp + 1 days;

        setMintingWindow(startTime, endTime);

        contractUnderTest.mint();
        vm.stopPrank();

        vm.startPrank(user1);
        contractUnderTest.mint();
        vm.stopPrank();

        vm.startPrank(user2);
        contractUnderTest.mint();

        vm.warp(endTime + 1);

        vm.expectRevert(FreeMintERC721.MintingNotEnabled.selector);
        contractUnderTest.mint();
    }
}

contract Pause is Base {
    function setUp() public {
        super.deploy();
    }

    function test_should_revert_when_setting_mint_paused_as_unauthorized_user()
        external
    {
        vm.startPrank(unauthorizedUser);
        bytes4 selector = OwnableUpgradeable
            .OwnableUnauthorizedAccount
            .selector;
        vm.expectRevert(abi.encodeWithSelector(selector, unauthorizedUser));
        contractUnderTest.pauseMint();
    }

    function test_should_revert_when_resuming_mint_as_unauthorized_user()
        external
    {
        uint256 startTime = block.timestamp - 1 days;
        uint256 endTime = block.timestamp + 1 days;
        setMintingWindow(startTime, endTime);

        vm.startPrank(user1);
        contractUnderTest.mint();

        vm.startPrank(deployer);
        contractUnderTest.pauseMint();

        bytes4 selector = OwnableUpgradeable
            .OwnableUnauthorizedAccount
            .selector;
        vm.expectRevert(abi.encodeWithSelector(selector, unauthorizedUser));

        vm.startPrank(unauthorizedUser);
        contractUnderTest.resumeMint();
    }

    function test_should_pause_mint() external {
        uint256 startTime = block.timestamp - 1 days;
        uint256 endTime = block.timestamp + 1 days;
        setMintingWindow(startTime, endTime);

        contractUnderTest.mint();

        vm.startPrank(user1);
        contractUnderTest.mint();

        vm.startPrank(user2);
        contractUnderTest.mint();

        vm.warp(endTime + 1);

        vm.expectRevert(FreeMintERC721.MintingNotEnabled.selector);
        contractUnderTest.mint();
    }

    function test_should_resume_mint() external {
        uint256 startTime = block.timestamp - 1 days;
        uint256 endTime = block.timestamp + 1 days;

        setMintingWindow(startTime, endTime);

        contractUnderTest.mint();

        vm.startPrank(deployer);
        contractUnderTest.pauseMint();

        vm.expectRevert(FreeMintERC721.MintingNotEnabled.selector);
        vm.startPrank(user1);
        contractUnderTest.mint();

        vm.startPrank(deployer);
        contractUnderTest.resumeMint();

        vm.startPrank(user2);
        contractUnderTest.mint();

        assertEq(contractUnderTest.totalSupply(), 2);
    }
}

contract SetAssetURI is Base {
    function setUp() public {
        super.deploy();
    }

    function test_should_revert_when_setting_base_uri_as_unauthorized_user()
        external
    {
        vm.startPrank(unauthorizedUser);
        bytes4 selector = OwnableUpgradeable
            .OwnableUnauthorizedAccount
            .selector;
        vm.expectRevert(abi.encodeWithSelector(selector, unauthorizedUser));
        contractUnderTest.setAssetURI("test.com");
    }

    function test_should_set_base_uri() external {
        string memory newAssetURI = "newURI.com";
        assertNotEq(contractUnderTest._assetURI(), newAssetURI);

        vm.startPrank(deployer);
        contractUnderTest.setAssetURI(newAssetURI);
        assertEq(contractUnderTest._assetURI(), newAssetURI);
    }
}

contract SetMetadataProperties is Base {
    function setUp() public {
        super.deploy();
    }

    function test_should_revert_when_setting_metadata_as_unauthorized_user()
        external
    {
        vm.startPrank(unauthorizedUser);
        bytes4 selector = OwnableUpgradeable
            .OwnableUnauthorizedAccount
            .selector;
        vm.expectRevert(abi.encodeWithSelector(selector, unauthorizedUser));

        contractUnderTest.setMetadataProperties(
            "newNftName",
            "newArtistName",
            "newDescription"
        );
    }

    function test_should_set_new_metadata_properties() external {
        string memory currentNftName = contractUnderTest._nftName();
        string memory currentArtistName = contractUnderTest._artistName();
        string memory currentDescription = contractUnderTest._description();
        string memory newNftName = "newNftName";
        string memory newArtistName = "newArtistName";
        string memory newDescription = "newDescription";

        vm.startPrank(deployer);
        contractUnderTest.setMetadataProperties(
            newNftName,
            newArtistName,
            newDescription
        );

        assertNotEq(currentNftName, newNftName);
        assertNotEq(currentArtistName, newArtistName);
        assertNotEq(currentDescription, newDescription);

        assertEq(contractUnderTest._nftName(), newNftName);
        assertEq(contractUnderTest._artistName(), newArtistName);
        assertEq(contractUnderTest._description(), newDescription);
    }
}

contract SetMintDuration is Base {
    function setUp() public {
        super.deploy();
    }

    function test_should_revert_when_setting_mint_duration_as_unauthorized_user()
        external
    {
        vm.startPrank(unauthorizedUser);
        bytes4 selector = OwnableUpgradeable
            .OwnableUnauthorizedAccount
            .selector;
        vm.expectRevert(abi.encodeWithSelector(selector, unauthorizedUser));

        contractUnderTest.setMintDuration(
            uint32(block.timestamp),
            uint32(block.timestamp + 100)
        );
    }

    function test_should_set_mint_duration() external {
        uint32 startTime = uint32(block.timestamp);
        uint32 endTime = uint32(block.timestamp + 100);

        vm.startPrank(deployer);
        contractUnderTest.setMintDuration(startTime, endTime);

        assertEq(contractUnderTest._mintStartTime(), startTime);
    }
}

contract SetTokenURI is Base {
    function setUp() public {
        super.deploy();
    }

    function test_should_revert_when_returning_token_uri_for_unminted_token()
        external
    {
        uint256 tokenId = 1;
        vm.startPrank(user1);
        bytes4 selector = IERC721Errors.ERC721NonexistentToken.selector;
        vm.expectRevert(abi.encodeWithSelector(selector, tokenId));

        contractUnderTest.tokenURI(1);
    }

    function test_should_return_correct_tokenURI_for_minted_token() external {
        setMintingWindow(block.timestamp - 1, block.timestamp + 1 days);

        vm.startPrank(user1);
        string memory expectedMetadataFirstToken = expectedMetadata(1);
        contractUnderTest.mint();
        string memory metadataFirstToken = contractUnderTest.tokenURI(1);

        vm.startPrank(user2);
        string memory expectedMetadataSecondToken = expectedMetadata(2);
        contractUnderTest.mint();
        string memory metadataSecondToken = contractUnderTest.tokenURI(2);

        assertEq(
            keccak256(abi.encodePacked((expectedMetadataFirstToken))),
            keccak256(abi.encodePacked(metadataFirstToken))
        );

        assertEq(
            keccak256(abi.encodePacked(expectedMetadataSecondToken)),
            keccak256(abi.encodePacked(metadataSecondToken))
        );
    }
}
