// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {FreeMintRegistry} from "src/upgradeable/FreeMintRegistry.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "forge-std/Test.sol";

abstract contract ContractUnderTest is Test {
    FreeMintRegistry internal singletonFreeMint;
    uint256 public mainnetFork;

    address payable deployer = payable(makeAddr("deployer"));
    address payable user1 = payable(makeAddr("user1"));
    address payable user2 = payable(makeAddr("user2"));
    address payable user3 = payable(makeAddr("user3"));
    address payable unauthorizedUser = payable(makeAddr("unauthorizedUser"));
    address payable royaltyReceiver = payable(makeAddr("royaltyReceiver"));

    function setUp() public virtual {
        // Mainnet fork
        string memory mainnet_rpc_url_key = "RPC_URL";
        string memory mainnet_rpc_url = vm.envString(mainnet_rpc_url_key);
        mainnetFork = vm.createFork(mainnet_rpc_url);

        vm.startPrank({msgSender: deployer});

        singletonFreeMint = new FreeMintRegistry();

        singletonFreeMint.initialize(
            "Test Name",
            "Test Symbol"
        );

        vm.label({
            account: address(singletonFreeMint),
            newLabel: "FreeMintRegistry"
        });

        vm.stopPrank();
    }

    function setMintingWindow(uint256 startTime, uint256 endTime, uint256 id) internal {
        singletonFreeMint.updateMintDuration(id, uint32(startTime), uint32(endTime));
    }
}
