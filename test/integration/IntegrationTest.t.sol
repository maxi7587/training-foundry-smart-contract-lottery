// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleIntegrationTests is Test {
    Raffle raffle;
    HelperConfig helperConfig;

    function setUp() public {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
    }

    function testDeployRaffleWorks() public {
        assert(raffle.getPlayers().length == 0);
    }

    // TODO: test other DeployRaffle banches and add coverage to Interactions
}