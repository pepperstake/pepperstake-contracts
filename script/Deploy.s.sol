// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/PepperStake.sol";
import "../src/PepperStakeDeployer.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    PepperStakeDeployer pepperStakeDeployer;

    function run() external {
        vm.startBroadcast();

        pepperStakeDeployer = new PepperStakeDeployer(0, address(0));

        console.log(address(pepperStakeDeployer));
    }
}
