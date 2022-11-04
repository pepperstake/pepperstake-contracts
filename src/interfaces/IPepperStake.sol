// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IPepperStake {
    event Stake(address indexed participant, uint256 amount);
    event Sponsor(address indexed participant, uint256 amount);
    event ReturnStake(
        address indexed sponsor,
        address[] completingParticipants,
        uint256 amount
    );
    event DistributeUnreturnedStake(
        address indexed caller,
        address[] unreturnedStakeBeneficiaries,
        uint256 totalUnreturnedStake,
        uint256 sSharePerBeneficiary
    );
    event DistributeSponsorContribution(
        address indexed caller,
        address[] sponsorContributionBeneficiaries,
        uint256 totalSponsorContribution,
        uint256 sharePerBeneficiary
    );

    function stake() external payable;

    function sponsor() external payable;

    function returnStake(address[] memory completingParticipants) external;

    function postReturnWindowDistribution() external;
}
