// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Staking Cooldown Silo
 * @notice The Staking Cooldown Silo allows stores stakingTokens during the stake cooldown process.
 * 
 * This contract is to be used in conjunction with a staking contract.
 */
contract StakingCoolDownSilo {
    using SafeERC20 for IERC20;
    error OnlyStakingContract();

    address immutable STAKING_CONTRACT;
    IERC20 immutable stakingToken;


    /**
     * @dev Initializes the Staking Cooldown Silo with the specified StakingContract and stakingToken.
     * @param _stakingContract address of the StakingContract.
     * @param _stakingToken address of the stakingToken.
     */
    constructor(address _stakingContract, address _stakingToken) {
        STAKING_CONTRACT = _stakingContract;
        stakingToken = IERC20(_stakingToken);
    }

    /**
     * @notice Throws if the caller is not the StakingContract.
     */
    modifier onlyStakingContract() {
        if (msg.sender != STAKING_CONTRACT) revert OnlyStakingContract();
        _;
    }

    /**
     * @notice Withdraws the specified amount of stakingToken to the specified address.
     * @param to The address to withdraw to.
     * @param amount The amount of stakingToken to withdraw.
     * @dev Only the StakingContract can call this function.
     * 
     * Requirements:
     * - `to` cannot be the zero address.
     * - `amount` must be greater than 0.
     * - The caller must be the StakingContract.
     */
    function withdraw(address to, uint256 amount) external onlyStakingContract {
        stakingToken.safeTransfer(to, amount);
    }
}
