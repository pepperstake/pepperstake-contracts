// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IPepperStake {
    event Stake(address indexed participant, uint256 amount);
    event Sponsor(address indexed participant, uint256 amount);
    event ApproveForParticipants(
        address indexed supervisor,
        address[] completingParticipants,
        uint256 amount
    );
    event DistributeUnreturnedStake(
        address indexed caller,
        address[] beneficiaries,
        uint256 totalUnreturnedStake,
        uint256 sharePerBeneficiary
    );
    event DistributeSponsorContribution(
        address indexed caller,
        address[] beneficiaries,
        uint256 totalSponsorContribution,
        uint256 sharePerBeneficiary
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
