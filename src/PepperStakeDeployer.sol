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
        pepperStake = new PepperStake(
            projectCount,
            _launchData,
            protocolFee,
            protocolFeeBeneficiary
        );
        emit DeployPepperStake(
            pepperStake,
            projectCount,
            _launchData,
            protocolFee,
            protocolFeeBeneficiary
        );
        projectCount++;
    }
}
