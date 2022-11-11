// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IPepperStakeDeployer.sol";
import "./PepperStake.sol";

contract PepperStakeDeployer is IPepperStakeDeployer {
    uint256 public protocolFee;
    address public protocolFeeBeneficiary;

    constructor(uint256 _protocolFee, address _protocolFeeBeneficiary) {
        protocolFee = _protocolFee;
        protocolFeeBeneficiary = _protocolFeeBeneficiary;
    }

    //*********************************************************************//
    // ---------------------- external transactions ---------------------- //
    //*********************************************************************//

    /** 
    @notice 
    Allows anyone to deploy a new PepperStake contract.
  */
    function deployPepperStake(
        address[] memory _supervisors,
        uint256 _stakeAmount,
        address[] memory _unreturnedStakeBeneficiaries,
        uint256 _returnWindowDays,
        uint256 _maxParticipants,
        bool _shouldParticipantsShareUnreturnedStake,
        bool _shouldUseSupervisorInactionGuard,
        string memory _metadataURI,
        address[] memory _oracleDelegates
    ) external returns (IPepperStake pepperStake) {
        pepperStake = new PepperStake(
            _supervisors,
            _stakeAmount,
            _unreturnedStakeBeneficiaries,
            _returnWindowDays,
            _maxParticipants,
            _shouldParticipantsShareUnreturnedStake,
            _shouldUseSupervisorInactionGuard,
            _metadataURI,
            _oracleDelegates
        );
        emit DeployPepperStake(
            pepperStake,
            _supervisors,
            _stakeAmount,
            _unreturnedStakeBeneficiaries,
            _returnWindowDays,
            _maxParticipants,
            _shouldParticipantsShareUnreturnedStake,
            _shouldUseSupervisorInactionGuard,
            _metadataURI
        );
    }
}
