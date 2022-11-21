// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IPepperStake.sol";
import "../structs/LaunchPepperStakeData.sol";

interface IPepperStakeDeployer {
    event DeployPepperStake(
        IPepperStake indexed pepperStake,
        uint256 projectId,
        LaunchPepperStakeData launchData,
        uint256 protocolFee,
        address protocolFeeBeneficiary
    );

    function deployPepperStake(LaunchPepperStakeData memory _launchData)
        external
        returns (IPepperStake pepperStake);
}
