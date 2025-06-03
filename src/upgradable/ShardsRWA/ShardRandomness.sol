// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
import {IERC20} from "@openzeppelin-contracts-5.0.2/token/ERC20/IERC20.sol";

abstract contract ShardRandomness {
    struct ShardMetadata {
        string multiplier; 
        uint16 x;
        uint16 y;
    }
    
    IERC20 constant WETH_CONTRACT =
        IERC20(0x48b62137EdfA95a428D35C09E44256a739F6B557); // ApeChain Mainnet
    
    uint256 public constant GRID_SIDE = 10;
    uint256 public constant FULL_GRID_QUANTITY = GRID_SIDE*GRID_SIDE;

    function totalSupply() public virtual view returns (uint);
   

    function getRand(uint256 increment) internal view returns (uint256) {
        uint256 balance = WETH_CONTRACT.totalSupply();
        uint256 rand = uint256(keccak256(abi.encodePacked(balance, totalSupply(), increment, block.number)));
        return rand;
    }

    function getRand() internal view returns (uint256) {
        return getRand(0);
    }

    function getShardMetadata() internal view returns( ShardMetadata memory shard) {
        uint256 rand = getRand();
        uint256 cellNumber = rand % FULL_GRID_QUANTITY;
        uint16 x = uint16(cellNumber % GRID_SIDE); // Take the modulus to obtain the X value
        uint16 y = uint16(cellNumber / GRID_SIDE); // Take the floor to obtain the Y value
        shard =  ShardMetadata({x: x, y: y, multiplier: ""});  
    }

    function getPackMetadata() internal pure returns( ShardMetadata[] memory shards) {
        // Allocate memory for the shards array
        shards = new ShardMetadata[](100);
        // Create each shard metadata
        for (uint16 i = 0; i < 100; i++) {
                uint16 x = uint16(i % GRID_SIDE); // Take the modulus to obtain the X value
                uint16 y = uint16(i / GRID_SIDE); // Take the floor to obtain the Y value
                shards[i]= (ShardMetadata({x: x, y: y, multiplier: "" })); 
        }
        return shards;
    }


}
