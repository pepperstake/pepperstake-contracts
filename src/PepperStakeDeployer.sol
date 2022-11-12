// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IPepperStakeDeployer.sol";
import "./PepperStake.sol";

contract PepperStakeDeployer is IPepperStakeDeployer {
    uint256 public protocolFee;
    address public protocolFeeBeneficiary;

    uint256 public projectCount;

    constructor(uint256 _protocolFee, address _protocolFeeBeneficiary) {
        protocolFee = _protocolFee;
        protocolFeeBeneficiary = _protocolFeeBeneficiary;
        projectCount = 1;
    }

    //*********************************************************************//
    // ---------------------- external transactions ---------------------- //
    //*********************************************************************//

    /** 
    @notice 
    Allows anyone to deploy a new PepperStake contract.
  */
    function deployPepperStake(LaunchPepperStakeData memory _launchData)
        external
        returns (IPepperStake pepperStake)
    {
        pepperStake = new PepperStake(projectCount, _launchData);
        projectCount++;
        // emit DeployPepperStake(
        //     pepperStake,
        //     _supervisors,
        //     _stakeAmount,
        //     _unreturnedStakeBeneficiaries,
        //     _returnWindowDays,
        //     _maxParticipants,
        //     _shouldParticipantsShareUnreturnedStake,
        //     _shouldUseSupervisorInactionGuard,
        //     _metadataURI
        // );
    }
}
