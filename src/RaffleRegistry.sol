// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {ERC1155} from "@solmate-6.7.0/tokens/ERC1155.sol";
import {Owned} from "@solmate-6.7.0/auth/Owned.sol";
import {LibString} from "@solmate-6.7.0/utils/LibString.sol";

/**
 * @title RaffleRegistry
 * @author passandscore - https://github.com/passandscore
 * @dev RaffleRegistry is used to:
 *
 * - create and manage raffles that have been created on third party platforms.
 * - register raffles and provide the asset URI for the raffle winners.
 *
 */

contract RaffleRegistry is ERC1155, Owned {
    /// @dev Triggered when trying to update a non-existent raffle.
    error RaffleDoesNotExist();

    /// @dev Triggered when providing an invalid input.
    error InvalidInput();

    /// @dev Emitted when a new raffle is registered.
    event RegisterRaffle(uint256 indexed id, string name, string uri);

    /// @dev Emitted when a raffle is updated.
    event UpdateRaffle(uint256 indexed id, string name, string uri);

    struct Raffle {
        string name;
        string uri;
        uint256 id;
    }

    // Mapping from raffle ID -> Raffle.
    mapping(uint256 => Raffle) public raffles;


    // Total number of raffles.
    uint256 public raffleCount;

    constructor() payable Owned(msg.sender) {}

    // =============================================================
    //                         RAFFLE LOGIC
    // =============================================================

    /**
     * @dev A method for the owner to register a new raffle.
     * @param _name The name of the raffle.
     * @param _uri The URI of the raffle.
     */
    function registerRaffle(
        string memory _name,
        string memory _uri
    ) external onlyOwner {
        uint256 raffleId = ++raffleCount;
        string memory raffleURI = string(
            abi.encodePacked(_uri, LibString.toString(raffleId), ".json")
        );

        raffles[raffleId] = Raffle({name: _name, uri: _uri, id: raffleId});

        emit RegisterRaffle(raffleId, _name, raffleURI);
    }

    /**
     * @dev A method for the owner to update an existing raffle.
     * @param _id The ID of the raffle.
     * @param _name The name of the raffle.
     * @param _uri The URI of the raffle.
     */
    function updateRaffle(
        uint256 _id,
        string memory _name,
        string memory _uri
    ) external onlyOwner {
        if (raffles[_id].id == 0) {
            revert RaffleDoesNotExist();
        }

        if (bytes(_name).length == 0 || bytes(_uri).length == 0) {
            revert InvalidInput();
        }

        raffles[_id] = Raffle({name: _name, uri: _uri, id: _id});

        emit UpdateRaffle(_id, _name, _uri);
    }

    /**
     * @dev A method to get the details of a raffle.
     * @param _id The ID of the raffle.
     */
    function getRaffleDetails(
        uint256 _id
    ) external view returns (Raffle memory) {
        return raffles[_id];
    }

    /**
     * @dev A method for the owner to mint new ERC1155 tokens in batches.
     * @param to The account for new tokens to be sent to.
     * @param ids The ids of the token types.
     * @param amounts The number of tokens to be minted.
     * @param data additional data that will be used within the receivers' onERC1155Received method
     */
    function setRaffleWinners(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyOwner {
        _batchMint(to, ids, amounts, data);
    }

    /**
     * @dev A method for the owner to burn an existing ERC1155 tokens in batches.
     * @param from The account for existing tokens to be burnt from.
     * @param ids The ids of the token types.
     * @param amounts The number of tokens to be burnt.
     */
    function removeRaffleWinners(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyOwner {
        _batchBurn(from, ids, amounts);
    }


    // =============================================================
    //                         ERC1155 OVERRIDES
    // =============================================================

    /**
     * @dev A method to get the URI of a raffle.
     * @param id The ID of the raffle.
     */
    function uri(
        uint256 id
    ) public view virtual override returns (string memory) {
        return raffles[id].uri;
    }
}
