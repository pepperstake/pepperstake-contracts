// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/PepperStake.sol";
import "../src/structs/LaunchPepperStakeData.sol";
import "../src/interfaces/IPepperStakeOracleDelegate.sol";
import "./mock/DummyOracleDelegate.sol";

contract PepperStakeE2ETest is Test {
    address internal _participant = address(bytes20(keccak256("participant")));
    address internal _participant2 =
        address(bytes20(keccak256("participant2")));
    address internal _participant3 =
        address(bytes20(keccak256("participant3")));
    address internal _participant4 =
        address(bytes20(keccak256("participant4")));
    address internal _participant5 =
        address(bytes20(keccak256("participant5")));
    address internal _creator = address(bytes20(keccak256("creator")));
    address internal _sponsor = address(bytes20(keccak256("sponsor")));
    address internal _supervisor = address(bytes20(keccak256("supervisor")));
    address internal _beneficiary = address(bytes20(keccak256("beneficiary")));
    address internal _protocolBeneficiary =
        address(bytes20(keccak256("protocolBeneficiary")));

    PepperStake public pepperStake;
    DummyOracleDelegate public dummyOracleDelegate;

    function setUp() public {
        vm.label(_participant, "participant");
        vm.label(_participant2, "participant2");
        vm.label(_participant3, "participant3");
        vm.label(_participant4, "participant4");
        vm.label(_participant5, "participant5");

        vm.label(_creator, "creator");
        vm.label(_sponsor, "sponsor");
        vm.label(_supervisor, "supervisor");
        vm.label(_beneficiary, "beneficiary");
        vm.label(_protocolBeneficiary, "protocolBeneficiary");

        vm.deal(_participant, 100 ether);
        vm.deal(_participant2, 100 ether);
        vm.deal(_participant3, 100 ether);
        vm.deal(_participant4, 100 ether);
        vm.deal(_participant5, 100 ether);
        vm.deal(_creator, 100 ether);
        vm.deal(_sponsor, 100 ether);
        vm.deal(_supervisor, 100 ether);

        address[] memory supervisors = new address[](1);
        supervisors[0] = _supervisor;

        address[] memory allowList = new address[](4);
        allowList[0] = _participant;
        allowList[1] = _participant2;
        allowList[2] = _participant3;
        allowList[3] = _participant4;

        address[] memory unreturnedStakeBeneficiaries = new address[](1);
        unreturnedStakeBeneficiaries[0] = _beneficiary;

        uint256[] memory stakingTiers = new uint256[](2);
        stakingTiers[0] = 0.05 ether;
        stakingTiers[1] = 0.5 ether;

        dummyOracleDelegate = new DummyOracleDelegate();
        address[] memory oracleDelegates = new address[](1);
        oracleDelegates[0] = address(dummyOracleDelegate);

        uint256 protocolFee = 10_000_000;
        uint256 creatorFee = 10_000_000;
        uint256 supervisorTip = 10_000_000;

        LaunchPepperStakeData memory defaultLaunchData = LaunchPepperStakeData(
            supervisors,
            allowList,
            unreturnedStakeBeneficiaries,
            oracleDelegates,
            stakingTiers,
            14 days,
            allowList.length,
            true,
            false,
            true,
            creatorFee,
            _creator,
            supervisorTip,
            ""
        );

        pepperStake = new PepperStake(
            1,
            defaultLaunchData,
            protocolFee,
            _protocolBeneficiary
        );
    }

    function testE2E() public {
        // Test Entry
        vm.prank(_participant);
        pepperStake.stake{value: 0.05 ether}();
        assertEq(pepperStake.totalStakeAmount(), 0.05 ether);
        vm.prank(_participant2);
        pepperStake.stake{value: 0.5 ether}();
        assertEq(pepperStake.totalStakeAmount(), 0.55 ether);
        vm.prank(_participant3);
        pepperStake.stake{value: 0.5 ether}();
        assertEq(pepperStake.totalStakeAmount(), 1.05 ether);
        vm.prank(_participant4);
        pepperStake.stake{value: 0.05 ether}();
        assertEq(pepperStake.totalStakeAmount(), 1.1 ether);

        // Test non-allowlisted participant
        vm.prank(_participant5);
        vm.expectRevert(
            abi.encodeWithSelector(PepperStake.PARTICIPANT_NOT_ALLOWED.selector)
        );
        pepperStake.stake{value: 0.05 ether}();

        // Test sponsor
        vm.prank(_sponsor);
        pepperStake.sponsor{value: 0.5 ether}();
        assertEq(pepperStake.totalSponsorContribution(), 0.5 ether);
        assertEq(address(pepperStake).balance, 1.6 ether);

        // Test approval
        address[] memory approvedParticipants = new address[](3);
        approvedParticipants[0] = _participant;
        approvedParticipants[1] = _participant2;
        approvedParticipants[2] = _participant3;
        vm.prank(_supervisor);
        pepperStake.approveForParticipants(approvedParticipants);

        // Test participant can't return stake twice
        address[] memory addressToReturn = new address[](1);
        addressToReturn[0] = _participant;
        vm.prank(_supervisor);
        vm.expectRevert(
            abi.encodeWithSelector(PepperStake.INVALID_PARTICIPANT.selector)
        );
        pepperStake.approveForParticipants(addressToReturn);

        // Test post completion distribution
        vm.warp(15 days);
        vm.prank(_supervisor);
        pepperStake.postCompletionWindowDistribution();
        assertEq(address(pepperStake).balance, 0 ether);
        uint256 afterFees = .05 ether * 0.97;
        assert(afterFees < address(_beneficiary).balance);
        assert(address(_beneficiary).balance < afterFees + .001 ether);
    }
}
