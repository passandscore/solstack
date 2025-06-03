// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library CustomErrors {
    /// @dev The token was not found.
    error TokenNotFound();

    /// @dev The token has already been minted by the caller.
    error TokenAlreadyMinted();

    /// @dev The ability to mint tokens is not currently enabled.
    error MintingNotEnabled();

    /// @dev Triggered when a total supply is exceeded.
    error TotalSupplyExceeded();

    /// @dev Triggered when a fund transfer fails.
    error FundTransferError();

    /// @dev Triggered when the caller has insufficient funds.
    error InsufficientFunds();

    /// @dev Triggered when passing an invalid multiplier type.
    error InvalidMultiplierType();

    /// @dev Triggered when passing an invalid shard quantity.
    error InvalidShardQuantity();

    /// @dev Triggered when the price is not set.
    error PriceNotSet();

    /// @dev Triggered when the primary sale percentage is out of range.
    error PrimarySalePercentageOutOfRange();

    /// @dev Triggered when the secondary sale percentage is out of range.
    error SecondarySalePercentageOutOfRange();

    /// @dev Triggered when the primary sale percentage is not equal to the max.
    error PrimarySalePercentageNotEqualToMax();

    /// @dev Triggered when trading is restricted.
    error TradingRestricted();

    /// @dev Triggered when the batch length is invalid.
    error InvalidBatchLength();

    /// @dev Triggered when the whitelist is not enabled.
    error NotWhitelisted();

    /// @dev Triggered when the whitelist is not enabled.
    error WhitelistNotEnabled();

    /// @dev Triggered when the token contract address is not set.
    error TokenContractAddressNotSet();

    /// @dev Triggered when the transfer fails.
    error TransferFailed();
}