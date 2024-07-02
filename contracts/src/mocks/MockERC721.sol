// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../token/ERC721.sol";

contract MockERC721 is ERC721 {
    string public baseURI;

    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newURI) external {
        baseURI = newURI;
    }

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

}

