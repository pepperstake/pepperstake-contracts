// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/PepperStake.sol";

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

        PepperStake pepperStake = new PepperStake(
            supervisors,
            0.05 ether,
            unreturnedStakeBeneficiaries,
            14,
            100,
            false,
            true,
            ""
        );
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
        PepperStake pepperStake2 = new PepperStake(
            new address[](0),
            0.05 ether,
            new address[](0),
            14,
            0,
            false,
            true,
            ""
        );
        vm.startPrank(_participant);
        vm.expectRevert(
            abi.encodeWithSelector(
                PepperStake.MAX_PARTICIPANTS_REACHED.selector
            )
        );
        pepperStake2.stake{value: 0.05 ether}();
    }

    function testStakeReturnWindowOver() public {
        PepperStake pepperStake = initializePepperstakeContractWithDefaults();
        vm.warp(15 days);
        vm.startPrank(_participant);
        vm.expectRevert(
            abi.encodeWithSelector(PepperStake.RETURN_WINDOW_OVER.selector)
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
            abi.encodeWithSelector(PepperStake.RETURN_WINDOW_OVER.selector)
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
            abi.encodeWithSelector(PepperStake.RETURN_WINDOW_OVER.selector)
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

    function testPostReturnWindowDistribution() public {
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
        pepperStake.postReturnWindowDistribution();
        assertEq(
            address(pepperStake).balance,
            0 ether,
            "balance is not 0 ether"
        );
    }

    function testPostReturnWindowDistributionReturnWindowNotOver() public {
        PepperStake pepperStake = initializePepperstakeContractWithDefaults();
        vm.startPrank(_supervisor);
        vm.expectRevert(
            abi.encodeWithSelector(PepperStake.RETURN_WINDOW_NOT_OVER.selector)
        );
        pepperStake.postReturnWindowDistribution();
    }

    function testPostReturnWindowDistributionAlreadyCalled() public {
        PepperStake pepperStake = initializePepperstakeContractWithDefaults();
        vm.warp(15 days);
        vm.startPrank(_participant);
        pepperStake.postReturnWindowDistribution();
        vm.expectRevert(
            abi.encodeWithSelector(
                PepperStake
                    .POST_RETURN_WINDOW_DISTRIBUTION_ALREADY_CALLED
                    .selector
            )
        );
        pepperStake.postReturnWindowDistribution();
    }
}
