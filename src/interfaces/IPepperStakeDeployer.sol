// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IPepperStake.sol";
import "../structs/LaunchPepperStakeData.sol";

interface IPepperStakeDeployer {
    // event DeployPepperStake(
    //     IPepperStake indexed pepperStake,
    //     address[] _supervisors,
    //     uint256 _stakeAmount,
    //     address[] _unreturnedStakeBeneficiaries,
    //     uint256 _returnWindowDays,
    //     uint256 _maxParticipants,
    //     bool _shouldParticipantsShareUnreturnedStake,
    //     bool _shouldUseSupervisorInactionGuard,
    //     string _metadataURI
    // );

    function deployPepperStake(LaunchPepperStakeData memory _launchData)
        external
        returns (IPepperStake pepperStake);
}
