// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IPepperStake {
    event Stake(address indexed participant, uint256 amount);
    event Sponsor(address indexed sponsor, uint256 amount);
    event ApproveForParticipants(
        address indexed supervisor,
        address[] participants
    );
    event ReturnStake(
        address indexed participant,
        uint256 stakeAmount,
        uint256 fee,
        uint256 returnAmount
    );
    event DistributeSponsorContribution(
        address indexed caller,
        address[] beneficiaries,
        uint256 amount,
        uint256 beneficiaryShare
    );
    event DistributeFees(
        address indexed caller,
        uint256 protocolFeeAmount,
        address protocolFeeBeneficiary,
        uint256 creatorFeeAmount,
        address creatorFeeBeneficiary,
        uint256 supervisorTipAmount,
        address[] supervisors,
        uint256 supervisorShare
    );
    event DistributeUnreturnedStake(
        address indexed caller,
        address[] beneficiaries,
        uint256 amount,
        uint256 beneficiaryShare
    );

    event PostCompletionWindowDistribution(address indexed caller);

    function stake() external payable;

    function sponsor() external payable;

    function approveForParticipants(address[] memory _participants) external;

    function checkOracle(
        address _oracleDelegate,
        address[] memory _participants
    ) external;

    function postCompletionWindowDistribution() external;

    function PROJECT_ID() external view returns (uint256);
}
