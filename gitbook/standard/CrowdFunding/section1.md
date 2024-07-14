# Functions

- **Launch**: Initiate a new crowdfunding campaign with a specified target amount, start time, and end time.
  - **Returns**: Emits a `Launch` event upon successful campaign creation.

- **Cancel**: Cancel a campaign before it starts.
  - **Security**: Requires the caller to be the campaign creator.
  - **Returns**: Emits a `Cancel` event upon successful cancellation.

- **Pledge**: Contribute tokens to a campaign during its active period.
  - **Security**: Verifies campaign existence, validity of start and end times.
  - **Returns**: Emits a `Pledge` event upon successful pledge.

- **Unpledge**: Withdraw pledged tokens from a campaign before it ends.
  - **Security**: Ensures the campaign is active and the caller has sufficient pledged amount.
  - **Returns**: Emits an `Unpledge` event upon successful unpledge.

- **Claim**: Claim the pledged tokens from a successful campaign after its end.
  - **Security**: Validates campaign success (reached target), end time passed, and prevents multiple claims.
  - **Returns**: Emits a `Claim` event upon successful fund claim.

- **Refund**: Refund pledged tokens from an unsuccessful campaign after its end.
  - **Security**: Ensures the campaign ended without reaching the target and prevents multiple refunds.
  - **Returns**: Emits a `Refund` event upon successful refund.

- **getCampaignDetails**: Retrieve details of a specific campaign.
  - **Returns**: Returns the complete details of the campaign.

- **getPledgedAmount**: Retrieve the pledged amount by a specific pledger for a campaign.
  - **Returns**: Returns the amount pledged by the specified address.

### Errors

Various errors are defined to handle exceptions during campaign operations, ensuring secure and reliable execution of functions.

### Internal Functions

Internal functions handle validation checks like campaign start and end times, existence, and ownership, ensuring proper execution flow and access control.

## Implementation Details

- **ERC-20 Token Integration**: Utilizes the ERC-20 interface for managing token transfers and balances.
- **Campaign Management**: Tracks campaign details including creator, target amount, pledged amount, start time, end time, and fund claim status.
- **Event Emitters**: Emits events for key operations like campaign launch, cancellation, pledge, unpledge, claim, and refund, providing transparency and auditability.

