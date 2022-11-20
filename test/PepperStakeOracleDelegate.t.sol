// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/PepperStakeDeployer.sol";
import "../src/interfaces/IPepperStake.sol";
import "../src/interfaces/IPepperStakeOracleDelegate.sol";
import "../src/structs/LaunchPepperStakeData.sol";
import "./mock/DummyOracleDelegate.sol";

contract PepperStakeDeployerTest is Test {
    PepperStake public pepperStake;
    DummyOracleDelegate public dummyOracleDelegate;
    address internal _participant = address(bytes20(keccak256("participant")));

    function setUp() public {
        dummyOracleDelegate = new DummyOracleDelegate();
        address[] memory oracleDelegates = new address[](1);
        oracleDelegates[0] = address(dummyOracleDelegate);

        uint256[] memory stakingTiers = new uint256[](1);
        stakingTiers[0] = 0.05 ether;

        LaunchPepperStakeData memory launchData = LaunchPepperStakeData(
            new address[](0),
            new address[](0),
            new address[](0),
            oracleDelegates,
            stakingTiers,
            14 days,
            100,
            false,
            false,
            true,
            ""
        );
        pepperStake = new PepperStake(1, launchData);
        vm.label(_participant, "participant");
        vm.deal(_participant, 100 ether);
    }

    function testOracleDelegate() public {
        address dummyOracleDelegateAddress = address(dummyOracleDelegate);
        assertTrue(pepperStake.oracleDelegates(dummyOracleDelegateAddress));
        assertTrue(pepperStake.supervisors(dummyOracleDelegateAddress));
        vm.prank(_participant);
        pepperStake.stake{value: 0.05 ether}();
        address[] memory participantsToCheck = new address[](1);
        participantsToCheck[0] = address(_participant);
        pepperStake.checkOracle(
            dummyOracleDelegateAddress,
            participantsToCheck
        );
        assertEq(pepperStake.completingParticipantCount(), 1);
    }
}
