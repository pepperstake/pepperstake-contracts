// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/PepperStake.sol";
import "../src/structs/LaunchPepperStakeData.sol";

contract PepperStakeTest is Test {
    address internal _participant = address(bytes20(keccak256("participant")));
    address internal _participant2 =
        address(bytes20(keccak256("participant2")));
    address internal _sponsor = address(bytes20(keccak256("sponsor")));
    address internal _supervisor = address(bytes20(keccak256("supervisor")));

    function setUp() public {
        vm.label(_participant, "participant");
        vm.label(_participant2, "participant2");
        vm.label(_sponsor, "sponsor");
        vm.label(_supervisor, "supervisor");

        vm.deal(_participant, 100 ether);
        vm.deal(_participant2, 100 ether);
        vm.deal(_sponsor, 100 ether);
        vm.deal(_supervisor, 100 ether);
    }

    function initializePepperstakeContractWithDefaults()
        public
        returns (PepperStake)
    {
        address[] memory supervisors = new address[](1);
        supervisors[0] = _supervisor;

        address[] memory unreturnedStakeBeneficiaries = new address[](1);
        unreturnedStakeBeneficiaries[0] = address(
            bytes20(keccak256("PepperstakeDAO"))
        );

        LaunchPepperStakeData memory defaultLaunchData = LaunchPepperStakeData(
            supervisors,
            new address[](0),
            unreturnedStakeBeneficiaries,
            new address[](0),
            0.05 ether,
            14 days,
            100,
            false,
            false,
            true,
            ""
        );

        PepperStake pepperStake = new PepperStake(1, defaultLaunchData);
        return pepperStake;
    }

    function testStake() public {
        PepperStake pepperStake = initializePepperstakeContractWithDefaults();
        vm.prank(_participant);
        pepperStake.stake{value: 0.05 ether}();
        assert(pepperStake.PARTICIPANT_COUNT() == 1);
    }

    function testStakeIncorrectAmount() public {
        PepperStake pepperStake = initializePepperstakeContractWithDefaults();
        vm.prank(_participant);
        vm.expectRevert(
            abi.encodeWithSelector(PepperStake.INCORRECT_STAKE_AMOUNT.selector)
        );
        pepperStake.stake{value: 0.04 ether}();
    }

    function testStakeAlreadyParticipating() public {
        PepperStake pepperStake = initializePepperstakeContractWithDefaults();
        vm.startPrank(_participant);
        pepperStake.stake{value: 0.05 ether}();
        vm.expectRevert(
            abi.encodeWithSelector(PepperStake.ALREADY_PARTICIPATING.selector)
        );
        pepperStake.stake{value: 0.05 ether}();
    }

    function testStakeMaxParticipantsReached() public {
        LaunchPepperStakeData memory launchData = LaunchPepperStakeData(
            new address[](0),
            new address[](0),
            new address[](0),
            new address[](0),
            0.05 ether,
            14 days,
            0,
            false,
            false,
            true,
            ""
        );
        PepperStake pepperStake2 = new PepperStake(1, launchData);
        vm.startPrank(_participant);
        vm.expectRevert(
            abi.encodeWithSelector(
                PepperStake.MAX_PARTICIPANTS_REACHED.selector
            )
        );
        pepperStake2.stake{value: 0.05 ether}();
    }

    function testParticipantAllowList() public {
        address[] memory participantAllowList = new address[](1);
        participantAllowList[0] = _participant;
        LaunchPepperStakeData memory launchData = LaunchPepperStakeData(
            new address[](0),
            participantAllowList,
            new address[](0),
            new address[](0),
            0.05 ether,
            14 days,
            participantAllowList.length,
            true,
            false,
            true,
            ""
        );
        PepperStake pepperStake3 = new PepperStake(1, launchData);
        vm.prank(_participant);
        pepperStake3.stake{value: 0.05 ether}();
        vm.prank(_participant2);
        vm.expectRevert(
            abi.encodeWithSelector(PepperStake.PARTICIPANT_NOT_ALLOWED.selector)
        );
        pepperStake3.stake{value: 0.05 ether}();
    }

    function testStakeReturnWindowOver() public {
        PepperStake pepperStake = initializePepperstakeContractWithDefaults();
        vm.warp(15 days);
        vm.startPrank(_participant);
        vm.expectRevert(
            abi.encodeWithSelector(PepperStake.COMPLETION_WINDOW_OVER.selector)
        );
        pepperStake.stake{value: 0.05 ether}();
    }

    function testSponsor() public {
        PepperStake pepperStake = initializePepperstakeContractWithDefaults();
        vm.startPrank(_sponsor);
        pepperStake.sponsor{value: 0.05 ether}();
        assert(pepperStake.TOTAL_SPONSOR_CONTRIBUTION() == 0.05 ether);
        pepperStake.sponsor{value: 0.05 ether}();
        assert(pepperStake.TOTAL_SPONSOR_CONTRIBUTION() == 0.1 ether);
    }

    function testSponsorReturnWindowOver() public {
        PepperStake pepperStake = initializePepperstakeContractWithDefaults();
        vm.warp(15 days);
        vm.startPrank(_sponsor);
        vm.expectRevert(
            abi.encodeWithSelector(PepperStake.COMPLETION_WINDOW_OVER.selector)
        );
        pepperStake.sponsor{value: 0.05 ether}();
    }

    function testReturnStake() public {
        PepperStake pepperStake = initializePepperstakeContractWithDefaults();
        vm.prank(_participant);
        pepperStake.stake{value: 0.05 ether}();
        vm.prank(_supervisor);
        address[] memory completingParticipantList = new address[](1);
        completingParticipantList[0] = _participant;
        pepperStake.returnStake(completingParticipantList);
        assert(pepperStake.COMPLETING_PARTICIPANT_COUNT() == 1);
    }

    function testReturnStakeCallerIsNotSupervisor() public {
        PepperStake pepperStake = initializePepperstakeContractWithDefaults();
        vm.startPrank(_participant);
        address[] memory completingParticipantList = new address[](1);
        completingParticipantList[0] = _participant;
        vm.expectRevert(
            abi.encodeWithSelector(
                PepperStake.CALLER_IS_NOT_SUPERVISOR.selector
            )
        );
        pepperStake.returnStake(completingParticipantList);
    }

    function testReturnStakeReturnWindowOver() public {
        PepperStake pepperStake = initializePepperstakeContractWithDefaults();
        vm.prank(_participant);
        pepperStake.stake{value: 0.05 ether}();
        vm.warp(15 days);
        address[] memory completingParticipantList = new address[](1);
        completingParticipantList[0] = _participant;
        vm.startPrank(_supervisor);
        vm.expectRevert(
            abi.encodeWithSelector(PepperStake.COMPLETION_WINDOW_OVER.selector)
        );
        pepperStake.returnStake(completingParticipantList);
    }

    function testReturnStakeInvalidParticipant() public {
        PepperStake pepperStake = initializePepperstakeContractWithDefaults();
        vm.prank(_participant);
        pepperStake.stake{value: 0.05 ether}();
        address[] memory completingParticipantList = new address[](1);
        completingParticipantList[0] = address(bytes20(keccak256("invalid")));
        vm.startPrank(_supervisor);
        vm.expectRevert(
            abi.encodeWithSelector(PepperStake.INVALID_PARTICIPANT.selector)
        );
        pepperStake.returnStake(completingParticipantList);
    }

    function testReturnStakeEmptyList() public {
        PepperStake pepperStake = initializePepperstakeContractWithDefaults();
        vm.prank(_participant);
        pepperStake.stake{value: 0.05 ether}();
        address[] memory completingParticipantList = new address[](0);
        vm.startPrank(_supervisor);
        pepperStake.returnStake(completingParticipantList);
        assert(pepperStake.COMPLETING_PARTICIPANT_COUNT() == 0);
    }

    function testPostCompletionWindowDistribution() public {
        PepperStake pepperStake = initializePepperstakeContractWithDefaults();
        vm.prank(_participant);
        pepperStake.stake{value: 0.05 ether}();
        vm.prank(_participant2);
        pepperStake.stake{value: 0.05 ether}();
        vm.prank(_sponsor);
        pepperStake.sponsor{value: 0.05 ether}();
        assertEq(
            address(pepperStake).balance,
            0.15 ether,
            "balance is not 0.15 ether"
        );
        address[] memory completingParticipantList = new address[](1);
        completingParticipantList[0] = _participant;
        vm.prank(_supervisor);
        pepperStake.returnStake(completingParticipantList);
        assertEq(
            address(pepperStake).balance,
            0.1 ether,
            "balance is not 0.1 ether"
        );
        vm.warp(15 days);
        vm.startPrank(_supervisor);
        pepperStake.postCompletionWindowDistribution();
        assertEq(
            address(pepperStake).balance,
            0 ether,
            "balance is not 0 ether"
        );
    }

    function testPostCompletionWindowDistributionReturnWindowNotOver() public {
        PepperStake pepperStake = initializePepperstakeContractWithDefaults();
        vm.startPrank(_supervisor);
        vm.expectRevert(
            abi.encodeWithSelector(
                PepperStake.COMPLETION_WINDOW_NOT_OVER.selector
            )
        );
        pepperStake.postCompletionWindowDistribution();
    }

    function testPostCompletionWindowDistributionAlreadyCalled() public {
        PepperStake pepperStake = initializePepperstakeContractWithDefaults();
        vm.warp(15 days);
        vm.startPrank(_participant);
        pepperStake.postCompletionWindowDistribution();
        vm.expectRevert(
            abi.encodeWithSelector(
                PepperStake
                    .POST_COMPLETION_WINDOW_DISTRIBUTION_ALREADY_CALLED
                    .selector
            )
        );
        pepperStake.postCompletionWindowDistribution();
    }

    function testCreatorParticipation() public {
        LaunchPepperStakeData memory defaultLaunchData = LaunchPepperStakeData(
            new address[](0),
            new address[](0),
            new address[](0),
            new address[](0),
            0.05 ether,
            14 days,
            100,
            false,
            false,
            true,
            ""
        );
        vm.prank(_participant);
        PepperStake pepperStakeParticipateOnCreate = new PepperStake{
            value: 0.05 ether
        }(1, defaultLaunchData);
        assert(pepperStakeParticipateOnCreate.PARTICIPANT_COUNT() == 1);
    }

    function testCreatorParticipationWithIncorrectAmount() public {
        LaunchPepperStakeData memory defaultLaunchData = LaunchPepperStakeData(
            new address[](0),
            new address[](0),
            new address[](0),
            new address[](0),
            0.1 ether,
            14 days,
            100,
            false,
            false,
            true,
            ""
        );
        vm.prank(_participant);
        vm.expectRevert(
            abi.encodeWithSelector(PepperStake.INCORRECT_STAKE_AMOUNT.selector)
        );
        new PepperStake{value: 0.5 ether}(1, defaultLaunchData);

        vm.prank(_participant);
        vm.expectRevert(
            abi.encodeWithSelector(PepperStake.INCORRECT_STAKE_AMOUNT.selector)
        );
        new PepperStake{value: 0.15 ether}(1, defaultLaunchData);
    }
}
