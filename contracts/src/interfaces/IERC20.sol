// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
     *
     * Note that `value` may be zero.
     *
     * @param from The account the tokens are transferred from.
     * @param to The account the tokens are transferred to.
     * @param value The amount of tokens transferred.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     *
     * @param owner The account that owns the tokens.
     * @param spender The account allowed to spend the tokens.
     * @param value The new allowance of tokens.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @notice Returns the total number of tokens in existence.
     * @dev Returns the total supply of tokens.
     * @return The total supply of tokens.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Returns the balance of tokens for a specified account.
     * @dev Returns the amount of tokens owned by `account`.
     * @param account The address to query the balance of.
     * @return The balance of tokens.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice Transfers tokens to a specified account.
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     * @param recipient The address receiving the tokens.
     * @param amount The number of tokens to transfer.
     * @return True if the transfer was successful.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}.
     * @dev Returns the remaining allowance for a spender.
     * @param owner The account that owns the tokens.
     * @param spender The account allowed to spend the tokens.
     * @return The remaining allowance.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @notice Sets the allowance over the caller's tokens for a specified `spender`.
     * @dev Approves `spender` to spend up to `amount` from the caller's account.
     * @param spender The address allowed to spend the tokens.
     * @param amount The number of tokens to approve for spending.
     * @return True if the approval was successful.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice Transfers tokens from one account to another using the allowance mechanism.
     * @dev Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism.
     * @param sender The account sending the tokens.
     * @param recipient The account receiving the tokens.
     * @param amount The number of tokens to transfer.
     * @return True if the transfer was successful.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}
