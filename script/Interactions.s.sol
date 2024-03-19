//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() internal returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , , , , address vrfCoordinatorV2, ) = helperConfig
            .activeNetworkConfig();

        return createSubscription(vrfCoordinatorV2);
    }

    function createSubscription(
        address vrfCoordinatorV2
    ) public returns (uint64) {
        console.log("Creating subscription on chain Id:", block.chainid);
        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinatorV2)
            .createSubscription();
        vm.stopBroadcast();
        console.log("Subscription created with id:", subId);
        console.log("Please update subscription id in HelperConfig.s.sol");
        return subId;
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint64 subId,
            ,
            ,
            ,
            ,
            address vrfCoordinatorV2,
            address link
        ) = helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinatorV2, link, subId);
    }

    function fundSubscription(
        address vrfCoordinatorV2,
        address link,
        uint64 subId
    ) public {
        console.log("Funding subscription:", subId);
        console.log("Using vrfCoordinatorV2:", vrfCoordinatorV2);
        console.log("On chain Id:", block.chainid);

        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(vrfCoordinatorV2).fundSubscription(
                subId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(link).transferAndCall(
                vrfCoordinatorV2,
                FUND_AMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(
        address raffle,
        address vrfCoordinatorV2,
        uint64 subId
    ) public {
        console.log("Adding consumer to raffle:", raffle);
        console.log("Using vrfCoordinatorV2:", vrfCoordinatorV2);
        console.log("On chain Id:", block.chainid);

        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCoordinatorV2).addConsumer(subId, raffle);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        (uint64 subId, , , , , address vrfCoordinatorV2, ) = helperConfig
            .activeNetworkConfig();
        addConsumer(raffle, vrfCoordinatorV2, subId);
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(raffle);
    }
}
