// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/PepperStakeDeployer.sol";
import "../src/interfaces/IPepperStake.sol";
import "../src/structs/LaunchPepperStakeData.sol";

contract PepperStakeDeployerTest is Test {
    PepperStakeDeployer public pepperStakeDeployer;

    function setUp() public {
        pepperStakeDeployer = new PepperStakeDeployer(0, address(0));
    }

    function testDeployPepperStake() public {
        LaunchPepperStakeData memory launchData = LaunchPepperStakeData(
            new address[](0),
            new address[](0),
            new address[](0),
            new address[](0),
            0.05 ether,
            14,
            100,
            false,
            false,
            true,
            ""
        );
        IPepperStake pepperStake = pepperStakeDeployer.deployPepperStake(
            launchData
        );
        assertTrue(address(pepperStake) != address(0));
        assertTrue(pepperStake.PROJECT_ID() == 1);
    }
}
