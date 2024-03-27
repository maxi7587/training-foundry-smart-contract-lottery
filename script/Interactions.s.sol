// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }

    function createSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (,,address vrfCoordinator,,,,) = helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns (uint64) {
        console.log("creating subscription on chain ID: ", block.chainid);
        vm.startBroadcast();
        uint64 subscriptionId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("subscription ID is: ", subscriptionId);
        console.log("Please update the subscription ID in HelperConfig.sol");
        return subscriptionId;
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function run() external {
        fundSubscriptionUsingConfig();
    }

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (,,address vrfCoordinator,,uint64 subscriptionId,,address link) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinator, subscriptionId, link);
    }

    function fundSubscription(address vrfCoordinator, uint64 subscriptionId, address link) public {
        console.log("funding subscription: ", subscriptionId);
        console.log("using coordinator: ", vrfCoordinator);
        console.log("on chain ID: ", block.chainid);

        if (block.chainid == 31337) { // Anvil
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(link).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );
            vm.stopBroadcast();
        }
    }
}

contract AddConsumer is Script {
    function run() external {
        address raffleContractAddress = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(raffleContractAddress);

    }

    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        (,,address vrfCoordinator,,uint64 subscriptionId,,) = helperConfig.activeNetworkConfig();
        addConsumer(raffle, vrfCoordinator, subscriptionId);
    }

    function addConsumer(address raffle, address vrfCoordinator, uint64 subscriptionId) public {
        console.log("adding consumer: ", raffle);
        console.log("using coordinator: ", vrfCoordinator);
        console.log("on chain ID: ", block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subscriptionId, raffle);
        vm.stopBroadcast();
    }
}