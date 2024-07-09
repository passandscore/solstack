// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {CrowdFunding} from "../src/CrowdFunding.sol";
import {Fork} from "./utils/Fork.sol";
import {MockERC20} from "./utils/mocks/MockERC20.sol";
import {console} from "@forge-std-1.8.2/Console.sol";
import {WETH} from "@solmate-6.7.0/tokens/WETH.sol";

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
}

abstract contract Base is Fork {
    CrowdFunding contractUnderTest;
    IERC20 token;
    WETH weth;
    uint256 maxDuration;

    address payable campaignCreator = payable(makeAddr("campaignCreator"));
    address payable pledger1 = payable(makeAddr("pledger1"));
    address payable pledger2 = payable(makeAddr("pledger2"));
    address payable unauthorized = payable(makeAddr("unauthorized"));

    function deploy() public {
        runFork();
        vm.selectFork(mainnetFork);

        // fund the EOAs
        vm.deal(campaignCreator, 1000 ether);
        vm.deal(pledger1, 100 ether);
        vm.deal(pledger2, 100 ether);
        vm.deal(unauthorized, 100 ether);

        vm.startPrank(campaignCreator);

        weth = new WETH();
        contractUnderTest = new CrowdFunding(address(weth), 7);

        // label the contracts
        vm.label(address(contractUnderTest), "contractUnderTest");
        vm.label(address(weth), "weth");

        // label the EOAs
        vm.label(campaignCreator, "campaignCreator");
        vm.label(pledger1, "pledger1");
        vm.label(pledger2, "pledger2");
        vm.label(unauthorized, "unauthorized");

        // Fund EOAs with WETH
        weth.deposit{value: 200 ether}();
        weth.transfer(pledger1, 100 ether);
        weth.transfer(pledger2, 100 ether);

        assertEq(weth.balanceOf(campaignCreator), 0);

        vm.stopPrank();
    }

    function providePledge(
        address account,
        uint256 campaignId,
        uint256 amount
    ) public virtual {
        vm.startPrank(account);
        contractUnderTest.token().approve(address(contractUnderTest), amount);
        contractUnderTest.pledge(campaignId, amount);
        vm.stopPrank();
    }
}

contract Deployment is Base {
    function setUp() public {
        deploy();
    }

    function test_should_set_token_address() public view {
        assertEq(address(contractUnderTest.token()), address(weth));
    }

    function test_should_set_max_duration() public view {
        uint256 dayInSeconds = 86400;
        assertEq(contractUnderTest.MAX_DURATION(), 7 * dayInSeconds);
    }
}

contract Launch is Base {
    function setUp() public {
        deploy();
    }

    function test_should_revert_when_start_time_is_invalid() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp - 1);
        uint32 end = uint32(block.timestamp + 1 days);

        vm.expectRevert(CrowdFunding.InvalidStartTime.selector);
        contractUnderTest.launch(target, start, end);
    }

    function test_should_revert_when_end_time_is_invalid() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp + 1);
        uint32 end = uint32(block.timestamp - 1);

        vm.expectRevert(CrowdFunding.InvalidEndTime.selector);
        contractUnderTest.launch(target, start, end);
    }

    function test_should_revert_when_end_time_exceeds_max_duration() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp + 1);
        uint32 end = uint32(block.timestamp + 8 days);

        vm.expectRevert(CrowdFunding.EndTimeExceedsMaxDuration.selector);
        contractUnderTest.launch(target, start, end);
    }

    function test_should_increase_campaign_count() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp + 1);
        uint32 end = uint32(block.timestamp + 7 days);

        contractUnderTest.launch(target, start, end);
        assertEq(contractUnderTest.campaignCount(), 1);
    }

    function test_should_set_campaign_details() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp + 1);
        uint32 end = uint32(block.timestamp + 7 days);

        vm.startPrank(campaignCreator);
        contractUnderTest.launch(target, start, end);
        CrowdFunding.Campaign memory campaign = contractUnderTest
            .getCampaignDetails(1);

        assertEq(campaign.creator, campaignCreator);
        assertEq(campaign.target, target);
        assertEq(campaign.pledgedAmount, 0);
        assertEq(campaign.startTime, start);
        assertEq(campaign.endTime, end);
        assertEq(campaign.claimedFunds, false);
    }

    function test_should_emit_launch_event() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp + 1);
        uint32 end = uint32(block.timestamp + 7 days);

        vm.startPrank(campaignCreator);

        vm.expectEmit();
        emit CrowdFunding.Launch(1, campaignCreator, target, start, end);

        contractUnderTest.launch(target, start, end);
    }
}

contract Cancel is Base {
    function setUp() public {
        deploy();
    }

    function test_should_revert_when_campaign_started() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp);
        uint32 end = uint32(block.timestamp + 7 days);

        contractUnderTest.launch(target, start, end);

        vm.expectRevert(CrowdFunding.CampaignAlreadyStarted.selector);
        contractUnderTest.cancel(1);
    }

    function test_should_revert_when_caller_is_not_campaign_creator() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp + 1);
        uint32 end = uint32(block.timestamp + 7 days);

        contractUnderTest.launch(target, start, end);

        vm.expectRevert(CrowdFunding.NotCampaignCreator.selector);
        vm.startPrank(pledger1);
        contractUnderTest.cancel(1);
    }

    function test_should_delete_campaign() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp + 1 days);
        uint32 end = uint32(block.timestamp + 7 days);

        vm.startPrank(campaignCreator);
        contractUnderTest.launch(target, start, end);

        CrowdFunding.Campaign memory campaignBefore = contractUnderTest
            .getCampaignDetails(1);

        assertEq(campaignBefore.creator, campaignCreator);
        assertEq(campaignBefore.target, target);
        assertEq(campaignBefore.pledgedAmount, 0);
        assertEq(campaignBefore.startTime, start);
        assertEq(campaignBefore.endTime, end);
        assertEq(campaignBefore.claimedFunds, false);

        contractUnderTest.cancel(1);

        CrowdFunding.Campaign memory campaignAfter = contractUnderTest
            .getCampaignDetails(1);

        assertEq(campaignAfter.creator, address(0));
        assertEq(campaignAfter.target, 0);
        assertEq(campaignAfter.pledgedAmount, 0);
        assertEq(campaignAfter.startTime, 0);
        assertEq(campaignAfter.endTime, 0);
        assertEq(campaignAfter.claimedFunds, false);
    }

    function test_should_emit_cancel_event() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp + 1 days);
        uint32 end = uint32(block.timestamp + 7 days);

        vm.startPrank(campaignCreator);
        contractUnderTest.launch(target, start, end);

        vm.expectEmit();
        emit CrowdFunding.Cancel(1);

        contractUnderTest.cancel(1);
    }
}

contract Pledge is Base {
    function setUp() public {
        deploy();
    }

    function test_should_revert_when_campaign_is_not_found() public {
        vm.expectRevert(CrowdFunding.CampaignNotFound.selector);
        contractUnderTest.pledge(1, 100 ether);
    }

    function test_should_revert_when_campaign_not_started() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp + 1 days);
        uint32 end = uint32(block.timestamp + 7 days);

        contractUnderTest.launch(target, start, end);

        vm.expectRevert(CrowdFunding.CampaignNotStarted.selector);
        contractUnderTest.pledge(1, 100 ether);
    }

    function test_should_revert_when_campaign_ended() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp + 1);
        uint32 end = uint32(block.timestamp + 1 days);

        contractUnderTest.launch(target, start, end);

        vm.warp(block.timestamp + 2 days);

        vm.expectRevert(CrowdFunding.CampaignEnded.selector);
        contractUnderTest.pledge(1, 100 ether);
    }

    function test_should_update_campaign_pledged_amount() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp);
        uint32 end = uint32(block.timestamp + 7 days);

        vm.startPrank(campaignCreator);
        contractUnderTest.launch(target, start, end);
        vm.stopPrank();

        vm.startPrank(pledger1);
        contractUnderTest.token().approve(address(contractUnderTest), 10 ether);
        contractUnderTest.pledge(1, 10 ether);

        CrowdFunding.Campaign memory campaign = contractUnderTest
            .getCampaignDetails(1);

        assertEq(campaign.pledgedAmount, 10 ether);
    }

    function test_should_emit_pledge_event() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp);
        uint32 end = uint32(block.timestamp + 7 days);

        vm.startPrank(campaignCreator);
        contractUnderTest.launch(target, start, end);
        vm.stopPrank();

        vm.startPrank(pledger1);
        contractUnderTest.token().approve(address(contractUnderTest), 10 ether);

        vm.expectEmit();
        emit CrowdFunding.Pledge(1, pledger1, 10 ether);

        contractUnderTest.pledge(1, 10 ether);
    }
}

contract Unpledge is Base {
    function setUp() public {
        deploy();
    }

    function test_should_revert_when_campaign_is_not_found() public {
        vm.expectRevert(CrowdFunding.CampaignNotFound.selector);
        contractUnderTest.unpledge(1, 100 ether);
    }

    function test_should_revert_when_campaign_has_ended() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp + 1 days);
        uint32 end = uint32(block.timestamp + 2 days);

        contractUnderTest.launch(target, start, end);

        vm.warp(block.timestamp + 3 days);

        vm.expectRevert(CrowdFunding.CampaignEnded.selector);
        contractUnderTest.unpledge(1, 100 ether);
    }

    function test_should_revert_when_unpledging_more_than_pledged_amount()
        public
    {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp + 1 days);
        uint32 end = uint32(block.timestamp + 7 days);

        contractUnderTest.launch(target, start, end);
        vm.warp(block.timestamp + 3 days);

        vm.expectRevert(CrowdFunding.InsufficientPledgedAmount.selector);
        contractUnderTest.unpledge(1, 1 ether);
    }

    function test_should_updated_campaign_pledged_amount() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp + 1 days);
        uint32 end = uint32(block.timestamp + 7 days);

        contractUnderTest.launch(target, start, end);
        vm.warp(block.timestamp + 3 days);

        providePledge(pledger1, 1, 10 ether);

        CrowdFunding.Campaign memory campaignBefore = contractUnderTest
            .getCampaignDetails(1);

        assertEq(campaignBefore.pledgedAmount, 10 ether);

        vm.startPrank(pledger1);
        contractUnderTest.unpledge(1, 5 ether);

        CrowdFunding.Campaign memory campaignAfter = contractUnderTest
            .getCampaignDetails(1);

        assertEq(campaignAfter.pledgedAmount, 5 ether);
    }

    function test_should_update_balance_of_pledger() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp + 1 days);
        uint32 end = uint32(block.timestamp + 7 days);

        contractUnderTest.launch(target, start, end);
        vm.warp(block.timestamp + 3 days);

        providePledge(pledger1, 1, 10 ether);

        assertEq(contractUnderTest.token().balanceOf(pledger1), 90 ether);
        assertEq(contractUnderTest.getPledgedAmount(1, pledger1), 10 ether);

        vm.startPrank(pledger1);
        contractUnderTest.unpledge(1, 5 ether);

        assertEq(contractUnderTest.token().balanceOf(pledger1), 95 ether);
        assertEq(contractUnderTest.getPledgedAmount(1, pledger1), 5 ether);
    }

    function test_should_update_the_contract_balance() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp + 1 days);
        uint32 end = uint32(block.timestamp + 7 days);

        contractUnderTest.launch(target, start, end);
        vm.warp(block.timestamp + 3 days);

        providePledge(pledger1, 1, 10 ether);

        assertEq(
            contractUnderTest.token().balanceOf(address(contractUnderTest)),
            10 ether
        );

        vm.startPrank(pledger1);
        contractUnderTest.unpledge(1, 5 ether);

        assertEq(
            contractUnderTest.token().balanceOf(address(contractUnderTest)),
            5 ether
        );
    }

    function test_should_emit_unpledge_event() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp + 1 days);
        uint32 end = uint32(block.timestamp + 7 days);

        contractUnderTest.launch(target, start, end);
        vm.warp(block.timestamp + 3 days);

        providePledge(pledger1, 1, 10 ether);

        vm.startPrank(pledger1);
        vm.expectEmit();
        emit CrowdFunding.Unpledge(1, pledger1, 5 ether);

        contractUnderTest.unpledge(1, 5 ether);
    }
}

contract Claim is Base {
    function setUp() public {
        deploy();
    }

    function test_should_revert_when_campaign_is_not_found() public {
        vm.expectRevert(CrowdFunding.CampaignNotFound.selector);
        contractUnderTest.claim(1);
    }

    function test_should_revert_when_caller_is_not_campaign_creator() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp + 1 days);
        uint32 end = uint32(block.timestamp + 7 days);

        contractUnderTest.launch(target, start, end);

        vm.expectRevert(CrowdFunding.NotCampaignCreator.selector);
        vm.startPrank(pledger1);
        contractUnderTest.claim(1);
    }

    function test_should_revert_when_campaign_has_not_ended() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp + 1 days);
        uint32 end = uint32(block.timestamp + 7 days);

        contractUnderTest.launch(target, start, end);

        vm.expectRevert(CrowdFunding.CampaignNotEnded.selector);
        contractUnderTest.claim(1);
    }

    function test_should_revert_when_campaign_target_not_reached() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp + 1 days);
        uint32 end = uint32(block.timestamp + 7 days);

        contractUnderTest.launch(target, start, end);
        vm.warp(block.timestamp + 3 days);

        providePledge(pledger1, 1, 10 ether);

        vm.warp(block.timestamp + 4 days);

        vm.expectRevert(CrowdFunding.UnsuccessfulCampaign.selector);
        contractUnderTest.claim(1);
    }

    function test_should_revert_when_funds_already_claimed() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp + 1 days);
        uint32 end = uint32(block.timestamp + 7 days);

        contractUnderTest.launch(target, start, end);
        vm.warp(block.timestamp + 3 days);

        providePledge(pledger1, 1, 100 ether);

        vm.warp(block.timestamp + 8 days);

        contractUnderTest.claim(1);

        vm.expectRevert(CrowdFunding.FundsClaimed.selector);
        contractUnderTest.claim(1);
    }

    function test_should_update_funds_claimes_to_true() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp + 1 days);
        uint32 end = uint32(block.timestamp + 7 days);

        contractUnderTest.launch(target, start, end);
        vm.warp(block.timestamp + 3 days);

        providePledge(pledger1, 1, 100 ether);

        assertEq(contractUnderTest.getCampaignDetails(1).claimedFunds, false);

        vm.warp(block.timestamp + 8 days);

        contractUnderTest.claim(1);

        assertEq(contractUnderTest.getCampaignDetails(1).claimedFunds, true);
    }

    function test_should_successfully_transfer_funds() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp + 1 days);
        uint32 end = uint32(block.timestamp + 7 days);

        vm.startPrank(campaignCreator);
        contractUnderTest.launch(target, start, end);
        vm.stopPrank();

        vm.warp(block.timestamp + 3 days);

        providePledge(pledger1, 1, 100 ether);

        assertEq(contractUnderTest.token().balanceOf(campaignCreator), 0);
        assertEq(
            contractUnderTest.token().balanceOf(address(contractUnderTest)),
            100 ether
        );

        vm.warp(block.timestamp + 8 days);

        vm.startPrank(campaignCreator);
        contractUnderTest.claim(1);

        assertEq(
            contractUnderTest.token().balanceOf(campaignCreator),
            100 ether
        );
        assertEq(
            contractUnderTest.token().balanceOf(address(contractUnderTest)),
            0
        );
    }

    function test_should_emit_claim_event() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp + 1 days);
        uint32 end = uint32(block.timestamp + 7 days);

        vm.startPrank(campaignCreator);
        contractUnderTest.launch(target, start, end);
        vm.stopPrank();

        vm.warp(block.timestamp + 3 days);

        providePledge(pledger1, 1, 100 ether);

        vm.warp(block.timestamp + 8 days);

        vm.startPrank(campaignCreator);
        vm.expectEmit();
        emit CrowdFunding.Claim(1, campaignCreator);

        contractUnderTest.claim(1);
    }
}

contract Refund is Base {
    function setUp() public {
        deploy();
    }

    function test_should_revert_when_campaign_is_not_found() public {
        vm.expectRevert(CrowdFunding.CampaignNotFound.selector);
        contractUnderTest.refund(1);
    }

    function test_should_revert_when_campaign_has_ended() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp);
        uint32 end = uint32(block.timestamp + 2 days);

        contractUnderTest.launch(target, start, end);

        vm.warp(block.timestamp + 1 days);

        providePledge(pledger1, 1, 100 ether);

        vm.startPrank(pledger1);
        vm.expectRevert(CrowdFunding.CampaignNotEnded.selector);
        contractUnderTest.refund(1);
    }

    function test_should_revert_when_funds_already_claimed() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp);
        uint32 end = uint32(block.timestamp + 2 days);

        vm.startPrank(campaignCreator);
        contractUnderTest.launch(target, start, end);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);

        providePledge(pledger1, 1, 100 ether);

        vm.warp(block.timestamp + 2 days);

        vm.startPrank(campaignCreator);
        contractUnderTest.claim(1);
        vm.stopPrank();

        vm.startPrank(pledger1);
        vm.expectRevert(CrowdFunding.FundsClaimed.selector);
        contractUnderTest.refund(1);
    }

    function test_should_update_pledged_amount_to_zero() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp);
        uint32 end = uint32(block.timestamp + 2 days);

        contractUnderTest.launch(target, start, end);

        providePledge(pledger1, 1, 100 ether);

        assertEq(contractUnderTest.getPledgedAmount(1, pledger1), 100 ether);

        vm.warp(block.timestamp + 3 days);

        vm.startPrank(pledger1);
        contractUnderTest.refund(1);

        assertEq(contractUnderTest.getPledgedAmount(1, pledger1), 0);
    }

    function test_should_sucessfully_transfer_refund() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp);
        uint32 end = uint32(block.timestamp + 2 days);

        contractUnderTest.launch(target, start, end);

        providePledge(pledger1, 1, 99 ether);

        // pledger1: starting balance (100 eth) - pledgedAmount (99 eth)
        assertEq(contractUnderTest.token().balanceOf(pledger1), 1 ether);
        assertEq(
            contractUnderTest.token().balanceOf(address(contractUnderTest)),
            99 ether
        );

        vm.warp(block.timestamp + 3 days);

        vm.startPrank(pledger1);
        contractUnderTest.refund(1);

        assertEq(contractUnderTest.token().balanceOf(pledger1), 100 ether);
        assertEq(
            contractUnderTest.token().balanceOf(address(contractUnderTest)),
            0
        );
    }

    function test_should_emit_refund_event() public {
        uint256 target = 100 ether;
        uint32 start = uint32(block.timestamp);
        uint32 end = uint32(block.timestamp + 2 days);

        contractUnderTest.launch(target, start, end);

        providePledge(pledger1, 1, 99 ether);

        vm.warp(block.timestamp + 3 days);

        vm.startPrank(pledger1);
        vm.expectEmit();
        emit CrowdFunding.Refund(1, pledger1, 99 ether);

        contractUnderTest.refund(1);
    }
}
