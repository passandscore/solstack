// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

contract CrowdFunding {
    /// @dev Triggered if a campaign is not found
    error CampaignNotFound();

    /// @dev Triggered if a cmapaign has not started
    error CampaignNotStarted();

    /// @dev Triggered if a campaign has not ended
    error CampaignNotEnded();

    /// @dev Triggered if a campaign has ended
    error CampaignEnded();

    /// @dev Triggered if the campaign has already started
    error CampaignAlreadyStarted();

    /// @dev Triggered if the caller is not the creator of the campaign
    error NotCampaignCreator();

    /// @dev Triggered if the start time is less than the current time
    error InvalidStartTime();

    /// @dev Triggered if the end time is less than the start time
    error InvalidEndTime();

    /// @dev Triggered if the end time exceeds the max duration
    error EndTimeExceedsMaxDuration();

    /// @dev Triggered if the campaign did not reach the target
    error UnsuccessfulCampaign();

    /// @dev Triggered if the pledged amount is less than the amount to unpledge
    error InsufficientPledgedAmount();

    /// @dev Triggered if the funds have already been claimed
    error FundsClaimed();

    /// @dev emitted when a campaign is launched
    event Launch(
        uint256 campaignId,
        address indexed creator,
        uint256 target,
        uint32 startTime,
        uint32 endTime
    );

    /// @dev emitted when a campaign is cancelled
    event Cancel(uint256 campaignId);

    /// @dev emitted when a pledge is made
    event Pledge(
        uint256 indexed campaignId,
        address indexed caller,
        uint256 amount
    );

    /// @dev emitted when a pledge is unpledged
    event Unpledge(
        uint256 indexed campaignId,
        address indexed caller,
        uint256 amount
    );

    /// @dev emitted when a campaign is claimed
    event Claim(uint256 indexed campaignId, address indexed creator);

    /// @dev emitted when a refund is made
    event Refund(uint256 campaignId, address indexed caller, uint256 amount);

    struct Campaign {
        address creator; // creator of the campaign
        uint256 target; // target amount to be raised
        uint256 pledgedAmount; // total amount pledged
        uint32 startTime; // start time of the campaign
        uint32 endTime; // end time of the campaign
        bool claimedFunds; // whether the funds have been claimed
    }

    /// @dev The token being used for pledges
    IERC20 public immutable token;

    /// @dev The total number of campaigns
    uint256 public campaignCount;

    /// @dev The maximum duration of a campaign
    uint256 public immutable MAX_DURATION;

    /// @dev mapping campaignId to Campaign
    mapping(uint256 => Campaign) private campaigns;

    /// @dev Mapping from campaign campaignId => pledger => amount pledgedAmount
    mapping(uint256 => mapping(address => uint256)) private pledgedAmount;

    /*
        * @dev Constructor
        * @param _token The token being used for pledges
        * @param _maxDuration The maximum duration of a campaign in days
        */
    constructor(address _token, uint256 _maxDuration) {
        token = IERC20(_token);
        MAX_DURATION = _maxDuration * (1 days);
    }

    /*
     * @dev Launch a new campaign
     * @param target The target amount to be raised
     * @param startTime The start time of the campaign
     * @param endTime The end time of the campaign
     */
    function launch(uint256 target, uint32 startTime, uint32 endTime) external {
        if(block.timestamp > startTime) {
            revert InvalidStartTime();
        }

        if (endTime < startTime) {
            revert InvalidEndTime();
        }

        if (endTime > startTime + MAX_DURATION) {
            revert EndTimeExceedsMaxDuration();
        }

        campaignCount += 1;
        campaigns[campaignCount] = Campaign({
            creator: msg.sender,
            target: target,
            pledgedAmount: 0,
            startTime: startTime,
            endTime: endTime,
            claimedFunds: false
        });

        emit Launch(campaignCount, msg.sender, target, startTime, endTime);
    }


    /*
     * @dev Cancel a campaign
     * @param campaignId The id of the campaign to be cancelled
     */
    function cancel(uint256 campaignId) external {
        Campaign memory campaign = campaigns[campaignId];

        if (campaign.creator != msg.sender) {
            revert NotCampaignCreator();
        }

        _requireCampaignNotStarted(campaign.startTime);

        delete campaigns[campaignId];
        emit Cancel(campaignId);
    }

    /*
     * @dev Pledge to a campaign
     * @param campaignId The id of the campaign to pledge to
     * @param amount The amount to pledge
     */
    function pledge(uint256 campaignId, uint256 amount) external {
        Campaign storage campaign = campaigns[campaignId];

        _requireCampaignExists(campaignId);
        _requireCampaignStarted(campaign.startTime);
        _requireCampaignNotEnded(campaign.endTime);

        campaign.pledgedAmount += amount;
        pledgedAmount[campaignId][msg.sender] += amount;

        token.transferFrom(msg.sender, address(this), amount);

        emit Pledge(campaignId, msg.sender, amount);
    }

    /*
     * @dev Unpledge from a campaign
     * @param campaignId The id of the campaign to unpledge from
     * @param _amount The amount to unpledge
     */
    function unpledge(uint256 campaignId, uint256 _amount) external {
        Campaign storage campaign = campaigns[campaignId];

        _requireCampaignExists(campaignId);
        _requireCampaignNotEnded(campaign.endTime);

        if(pledgedAmount[campaignId][msg.sender] < _amount) {
            revert InsufficientPledgedAmount();
        }

        campaign.pledgedAmount -= _amount;
        pledgedAmount[campaignId][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);

        emit Unpledge(campaignId, msg.sender, _amount);
    }

    /*
     * @dev Claim the funds from a successful campaign
     * @param campaignId The id of the campaign to claim funds from
     */
    function claim(uint256 campaignId) external {
        Campaign storage campaign = campaigns[campaignId];

        _requireCampaignExists(campaignId);
        _requireCampaignCreator(campaign.creator);
        
        if(block.timestamp < campaign.endTime) {
            revert CampaignNotEnded();
        }

        if (campaign.pledgedAmount < campaign.target) {
            revert UnsuccessfulCampaign();
        }

        if (campaign.claimedFunds) {
            revert FundsClaimed();
        }

        campaign.claimedFunds = true;
        token.transfer(campaign.creator, campaign.pledgedAmount);

        emit Claim(campaignId, campaign.creator);
    }

    /*
     * @dev Refund the pledged amount
     * @param campaignId The id of the campaign to refund from
     * 
     * Can only refund after the campaign has ended
     */
    function refund(uint256 campaignId) external {
        Campaign memory campaign = campaigns[campaignId];

        _requireCampaignExists(campaignId);

        if(block.timestamp < campaign.endTime) {
            revert CampaignNotEnded();
        }

        if (campaign.claimedFunds) {
            revert FundsClaimed();
        }

        uint256 totalRefund = pledgedAmount[campaignId][msg.sender];
        pledgedAmount[campaignId][msg.sender] = 0;
        token.transfer(msg.sender, totalRefund);

        emit Refund(campaignId, msg.sender, totalRefund);
    }

    function getCampaignDetails(uint256 campaignId) external view returns (Campaign memory) {
        return campaigns[campaignId];
    }

    function getPledgedAmount(uint256 campaignId, address pledger) external view returns (uint256) {
        return pledgedAmount[campaignId][pledger];
    }


    // =============================================================
    //                         Internal Functions
    // =============================================================

    /// @dev Checks if the campaign has started
    function _requireCampaignStarted(uint256 startTime) internal view {
        if (block.timestamp < startTime) {
            revert CampaignNotStarted();
        }
    }

    function _requireCampaignNotStarted(uint256 startTime) internal view {
        if (block.timestamp >=startTime) {
            revert CampaignAlreadyStarted();
        }
    }

    /// @dev Checks if the campaign has not ended
    function _requireCampaignNotEnded(uint256 endTime) internal view {
        if (block.timestamp > endTime) {
            revert CampaignEnded();
        }
    }

    /// @dev Checks if the caller is the creator of the campaign    
    function _requireCampaignCreator(address creator) internal view {
        if (creator != msg.sender) {
            revert NotCampaignCreator();
        }
    }

    /// @dev Checks if the campaign exists
    function _requireCampaignExists(uint256 campaignId) internal view {
        if (campaigns[campaignId].startTime == 0) {
            revert CampaignNotFound();
        }
    }
}
