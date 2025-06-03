// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ShardRandomnessMock} from "test/mocks/ShardRandomness.mock.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";


contract ShardRandomnessTest is Test {
    ShardRandomnessMock public contractUnderTest;
    IERC20 constant WETH_CONTRACT =
        IERC20(0x48b62137EdfA95a428D35C09E44256a739F6B557);

     uint256 public constant GRID_SIDE = 10;
    uint256 public constant FULL_GRID_QUANTITY = GRID_SIDE*GRID_SIDE;
    

    function setUp() public {
        contractUnderTest = new ShardRandomnessMock();
    }

    function test_getShardMetadata() public {
        uint256 wethSupply = 1000;
        uint256 totalSupply = 69;
        uint256 blockNumber = 420;

        vm.mockCall(
            address(WETH_CONTRACT),
            abi.encodeWithSelector(IERC20.totalSupply.selector),
            abi.encode(wethSupply)
        );
        contractUnderTest.setTotalSupply(totalSupply);

        vm.roll(blockNumber);

        ShardRandomnessMock.ShardMetadata memory shard = contractUnderTest
            ._getShardMetadata();

        assertTrue(shard.x >= 0 && shard.x < GRID_SIDE);
        assertTrue(shard.y >= 0 && shard.y < GRID_SIDE);

        uint256 rand = uint256(
            keccak256(
                abi.encodePacked(wethSupply, totalSupply, uint(0), blockNumber)
            )
        );
        uint256 cellNumber = rand % contractUnderTest.FULL_GRID_QUANTITY();
        uint16 expectedX = uint16(cellNumber % GRID_SIDE);
        uint16 expectedY = uint16(cellNumber / GRID_SIDE);
        assertEq(shard.x, expectedX);
        assertEq(shard.y, expectedY);
    }

    function test_getPackMetadata() public view {
        ShardRandomnessMock.ShardMetadata[] memory shards = contractUnderTest
            ._getPackMetadata();
        assertEq(shards.length, 100);
        assertEq(shards[0].x, 0);
        assertEq(shards[0].y, 0);
        assertEq(shards[99].x, 9);
        assertEq(shards[99].y, 9);
    }

    function test_squareRoot() public view {
        assertEq(contractUnderTest.squareRoot(0), 0);
        assertEq(contractUnderTest.squareRoot(1), 1);
        assertEq(contractUnderTest.squareRoot(4), 2);
        assertEq(contractUnderTest.squareRoot(10), 3);
        assertEq(contractUnderTest.squareRoot(16), 4);
        assertEq(contractUnderTest.squareRoot(25), 5);
        assertEq(contractUnderTest.squareRoot(81), 9);
        assertEq(contractUnderTest.squareRoot(10000), 100);
    }


    // function test_grid_distribution() public {
    //     contractUnderTest.fakeMint(50);
    //     ShardRandomnessMock.ShardMetadata memory shards = ShardRandomnessMock.ShardMetadata(50);
    //     for (uint256 index = 0; index < 50; index++) {
    //         (uint256 x, uint256 y) = contractUnderTest.metadataByTokenID(index);
    //         shards[index] = ShardRandomnessMock.ShardMetadata({x:x, y:y});
    //         console.log(x);
    //         console.log(y);
    //         console.log(" ");
    //     }
    // }

function test_randomShardDistribution() public {
    vm.mockCall(
        address(WETH_CONTRACT),
        abi.encodeWithSelector(IERC20.totalSupply.selector),
        abi.encode(1000)
    );
    contractUnderTest.setTotalSupply(69);

    uint256 gridSide = GRID_SIDE;
    uint256[] memory xOccurrences = new uint256[](gridSide);
    uint256[] memory yOccurrences = new uint256[](gridSide);

    // Simulate multiple calls to getShardMetadata
    for (uint256 i = 0; i < 1000; i++) {
        vm.roll(420 + i); // Varying block numbers to ensure randomness
        ShardRandomnessMock.ShardMetadata memory shard = contractUnderTest._getShardMetadata();
        
        xOccurrences[shard.x]++;
        yOccurrences[shard.y]++;

        assertTrue(shard.x >= 0 && shard.x < gridSide);
        assertTrue(shard.y >= 0 && shard.y < gridSide);
    }

    // Check that all x and y values have been populated
    for (uint16 i = 0; i < gridSide; i++) {
        assertGt(xOccurrences[i], 0, "Some x values were never generated");
        assertGt(yOccurrences[i], 0, "Some y values were never generated");
    }
}
}
