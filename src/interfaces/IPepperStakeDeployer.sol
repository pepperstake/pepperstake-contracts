// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IPepperStake.sol";

interface IPepperStakeDeployer {
    event DeployPepperStake(
        IPepperStake indexed pepperStake,
        address[] _supervisors,
        uint256 _stakeAmount,
        address[] _unreturnedStakeBeneficiaries,
        uint256 _returnWindowDays,
        uint256 _maxParticipants,
        bool _shouldParticipantsShareUnreturnedStake,
        bool _shouldUseSupervisorInactionGuard,
        string _metadataURI
    );

    function deployPepperStake(
        address[] memory _supervisors,
        uint256 _stakeAmount,
        address[] memory _unreturnedStakeBeneficiaries,
        uint256 _returnWindowDays,
        uint256 _maxParticipants,
        bool _shouldParticipantsShareUnreturnedStake,
        bool _shouldUseSupervisorInactionGuard,
        string memory _metadataURI
    ) external returns (IPepperStake pepperStake);
}
