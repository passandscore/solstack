// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title LiveArt Create2 Contract Factory
 * @notice A secure contract factory using the CREATE2 opcode, with ownership and deployment tracking.
 * @dev Enables deterministic smart contract deployment and protects against redeployments.
 */
contract Create2Factory {
    /// @notice Emitted when a new contract is deployed.
    /// @param deploymentAddress The address of the deployed contract.
    event ContractDeployed(address indexed deploymentAddress);

    /// @notice Emitted when contract ownership is transferred.
    /// @param previousOwner The previous owner of the contract.
    /// @param newOwner The new owner of the contract.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev Tracks which contracts have already been deployed by this factory.
    mapping(address => bool) public _deployed;

    /// @dev Stores the current owner of the contract.
    address private _owner;

    /// @notice Sets the deployer as the initial contract owner.
    constructor(address initialOwner) {
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    /// @notice Modifier that restricts function access to the current owner.
    modifier onlyOwner() {
        require(msg.sender == _owner, "Not contract owner");
        _;
    }

    /// @notice Returns the address of the contract owner.
    /// @return The address of the current owner.
    function owner() external view returns (address) {
        return _owner;
    }

    /// @notice Transfers contract ownership to a new address.
    /// @param newOwner The address of the new owner.
    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @notice Deploys a contract deterministically using CREATE2.
     * @dev Only the owner can call this function. Prevents redeployment to the same address.
     * @param salt A unique value used in the address calculation.
     * @param initializationCode The full creation bytecode for the contract.
     * @return deploymentAddress The address at which the contract was deployed.
     */
    function safeCreate2(
        bytes32 salt,
        bytes calldata initializationCode
    ) external payable onlyOwner returns (address deploymentAddress) {
        // Load calldata into memory
        bytes memory initCode = initializationCode;

        // Calculate the deterministic deployment address using EIP-1014 formula
        address targetDeploymentAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",          // Constant per CREATE2 spec
                            address(this),    // Deployer address
                            salt,             // User-supplied salt
                            keccak256(initCode) // Hash of contract bytecode
                        )
                    )
                )
            )
        );

        // Ensure this address hasn't already been deployed to
        require(
            !_deployed[targetDeploymentAddress],
            "Already deployed"
        );

        // Deploy using inline assembly
        assembly {
            let encoded_data := add(0x20, initCode)  // Skip array length field
            let encoded_size := mload(initCode)      // Length of bytecode
            deploymentAddress := create2(
                callvalue(),        // Forward ETH if any
                encoded_data,       // Bytecode
                encoded_size,       // Length of bytecode
                salt                // Unique salt
            )
        }

        // Ensure deployment succeeded at expected address
        require(
            deploymentAddress == targetDeploymentAddress,
            "Deployment failed"
        );

        // Mark contract as deployed and emit event
        _deployed[deploymentAddress] = true;
        emit ContractDeployed(deploymentAddress);
    }

    /**
     * @notice Computes the future deployment address for a given salt and contract bytecode.
     * @param salt The salt value to be used in CREATE2.
     * @param initCode The full contract initialization code.
     * @return deploymentAddress The address where the contract would be deployed, or address(0) if already used.
     */
    function findCreate2Address(
        bytes32 salt,
        bytes calldata initCode
    ) external view returns (address deploymentAddress) {
        deploymentAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            address(this),
                            salt,
                            keccak256(initCode)
                        )
                    )
                )
            )
        );

        // Return zero address if already deployed
        if (_deployed[deploymentAddress]) {
            return address(0);
        }
    }

    /**
     * @notice Computes the future deployment address for a given salt and initCode hash.
     * @param salt The salt value to be used in CREATE2.
     * @param initCodeHash The keccak256 hash of the contract's initialization code.
     * @return deploymentAddress The address where the contract would be deployed, or address(0) if already used.
     */
    function findCreate2AddressViaHash(
        bytes32 salt,
        bytes32 initCodeHash
    ) external view returns (address deploymentAddress) {
        deploymentAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            address(this),
                            salt,
                            initCodeHash
                        )
                    )
                )
            )
        );

        // Return zero address if already deployed
        if (_deployed[deploymentAddress]) {
            return address(0);
        }
    }

    /**
     * @notice Checks if a given contract address has already been deployed by this factory.
     * @param deploymentAddress The contract address to verify.
     * @return True if the contract has been deployed, false otherwise.
     */
    function hasBeenDeployed(address deploymentAddress) external view returns (bool) {
        return _deployed[deploymentAddress];
    }
}