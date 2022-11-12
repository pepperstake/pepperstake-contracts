// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

struct LaunchPepperStakeData {
    address[] supervisors;
    address[] participantAllowList;
    address[] unreturnedStakeBeneficiaries;
    address[] oracleDelegateAddresses;
    uint256[] stakingTiers;
    uint256 completionWindowSeconds;
    uint256 maxParticipants;
    bool shouldUseParticipantAllowList;
    bool shouldParticipantsShareUnreturnedStake;
    bool shouldUseSupervisorInactionGuard;
    string metadataURI;
}
