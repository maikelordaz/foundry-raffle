// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Test, console} from "forge-std/test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    /* Events */
    // Redeclare the events from the Raffle contract to use them in the tests
    event RaffleEnter(address indexed player);

    Raffle raffle;
    HelperConfig helperConfig;

    uint64 subscriptionId;
    bytes32 gasLane;
    uint256 interval;
    uint256 entranceFee;
    uint32 callbackGasLimit;
    address vrfCoordinatorV2;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
            subscriptionId,
            gasLane,
            interval,
            entranceFee,
            callbackGasLimit,
            vrfCoordinatorV2
        ) = helperConfig.activeNetworkConfig();

        vm.deal(PLAYER, STARTING_BALANCE);
    }

    function testRaffleInitializeInOpenState() public {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /***************************** Enter Raffle  *****************************/
    function testRaffleRevertWhenYouDontPayEnough() public {
        vm.prank(PLAYER);

        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);

        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEmitsEventsOnEntrance() public {
        vm.prank(PLAYER);

        // vm.expectEmit only checks for topics, or indexed parameters, like next line
        // vm.expectEmit(bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData, address emitter);
        // checkData are the non-indexed parameters
        // So first have to say how the event is
        vm.expectEmit(true, false, false, false, address(raffle));

        // Then manually emit the event
        emit RaffleEnter(PLAYER);

        // And last call the function that should emit the event
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCantEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        // vm.warp sets the block timestamp to the given value
        vm.warp(block.timestamp + interval + 1);

        // vm.roll sets the block number to the given value, this is not necessary, but it's a good practice
        vm.roll(block.number + 1);

        raffle.performUpkeep("");

        // vm.expectRevert expect the next real call to revert
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        // The next call will be done by PLAYER
        vm.prank(PLAYER);

        // The next call will revert called by PLAYER
        raffle.enterRaffle{value: entranceFee}();
    }
}
