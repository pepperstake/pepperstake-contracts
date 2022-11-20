// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IPepperStake {
    event Stake(address indexed participant, uint256 amount);
    event Sponsor(address indexed participant, uint256 amount);
    event ApproveForParticipants(
        address indexed supervisor,
        address[] completingParticipants
    );
    event ReturnStake(
        address indexed participant,
        uint256 stakeAmount,
        uint256 fee,
        uint256 returnAmount
    );
    event DistributeUnreturnedStake(
        address indexed caller,
        address[] beneficiaries,
        uint256 totalUnreturnedStake,
        uint256 beneficiaryShare
    );
    event DistributeFees(
        address indexed caller,
        uint256 protocolFee,
        address protocolFeeBeneficiary,
        uint256 creatorFee,
        address creatorFeeBeneficiary,
        uint256 supervisorTip,
        address[] supervisors,
        uint256 supervisorShare
    );
    event DistributeSponsorContribution(
        address indexed caller,
        address[] beneficiaries,
        uint256 totalSponsorContribution,
        uint256 beneficiaryShare
    );

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
