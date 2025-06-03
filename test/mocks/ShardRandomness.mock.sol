// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.2 <0.9.0;
import {ShardRandomness} from "./ShardRandomness.sol";

contract ShardRandomnessMock is ShardRandomness {
    uint256 _totalSupply = 0;

    mapping(uint256 => ShardRandomness.ShardMetadata) public metadataByTokenID;

    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }

    function setTotalSupply(uint256 newSupply) public {
        _totalSupply = newSupply;
    }

    function squareRoot(uint y) public pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function fakeMint(uint count) public {
        for (uint256 index = 0; index < count; index++) {
            uint256 tokenID = totalSupply();
            ShardRandomness.ShardMetadata memory shard = getShardMetadata();
            metadataByTokenID[tokenID] = shard;
            setTotalSupply(tokenID + 1);
        }
    }

    function _getShardMetadata()
        public
        view
        returns (ShardRandomness.ShardMetadata memory)
    {
        return super.getShardMetadata();
    }

    function _getPackMetadata()
        public
        view
        returns (ShardRandomness.ShardMetadata[] memory)
    {
        return super.getPackMetadata();
    }
}
