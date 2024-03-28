// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

contract RaffleTest is Test {
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    address public PLAYER = makeAddr("player");

    Raffle raffle;
    HelperConfig helperConfig;
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;

    // Events
    event EnterRaffle (address indexed player);

    function setUp() public {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            link
        ) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /////////////////
    // enterRaffle //
    /////////////////
    function testRaffleRevertsWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);

        // Act - Assert
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        address player = raffle.getPlayers()[0];
        assert(player == PLAYER);
    }

    function testEventEmitOnEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnterRaffle(PLAYER);

        raffle.enterRaffle{value: entranceFee}();
    }

    function testCantEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        // cheat codes for setting time
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    //////////////////
    // Check Upkeep //
    //////////////////

    function testCheckUpkeepReturnsFalseIfTheContractHasNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assertFalse(upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfTheRaffleIsNotOpen() public raffleEnterAndTimePassed {
        // Arrange
        raffle.performUpkeep("");

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assertFalse(upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfNotEnoughTimeHasPassed() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval - 1);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assertFalse(upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueIfAllRequirementsAreMet() public raffleEnterAndTimePassed {
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        // Assert
        assertTrue(upkeepNeeded);
    }

    ////////////////////
    // Perform Upkeep //
    ////////////////////

    function testPerformUpkeepCanRunIfCheckUpkeepIsTrue() public raffleEnterAndTimePassed {
        // Act
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        // Arrange
        uint256 currentBalance = 0;
        uint256 playersCount = 0;
        uint256 raffleState = 0;

        // Act - Assert
        vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance, playersCount, raffleState));
        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public raffleEnterAndTimePassed {
        // Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1]; // entries 1 because the request ID is sent twice in the function (for testing purposes)
        Raffle.RaffleState raffleState = raffle.getRaffleState();

        // Assert
        assert(uint256(requestId) > 0);
        assert(raffleState == Raffle.RaffleState.CALCULATING);
    }

    modifier raffleEnterAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }
}