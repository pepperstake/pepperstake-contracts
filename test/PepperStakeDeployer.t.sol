// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/PepperStakeDeployer.sol";
import "../src/interfaces/IPepperStake.sol";

contract PepperStakeDeployerTest is Test {
    PepperStakeDeployer public pepperStakeDeployer;

    function setUp() public {
        pepperStakeDeployer = new PepperStakeDeployer(0, address(0));
    }

    function testDeployPepperStake() public {
        IPepperStake pepperStake = pepperStakeDeployer.deployPepperStake(
            new address[](0),
            0.05 ether,
            new address[](0),
            14,
            100,
            false,
            true,
            "",
            new address[](0)
        );
        assertTrue(address(pepperStake) != address(0));
    }
}
