// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IPepperStake.sol";
import "./interfaces/IPepperStakeOracleDelegate.sol";

import "./structs/Participant.sol";
import "./structs/LaunchPepperStakeData.sol";

import "forge-std/console.sol";

contract PepperStake is IPepperStake {
    //*********************************************************************//
    // --------------------------- custom errors ------------------------- //
    //*********************************************************************//

    error MAX_PARTICIPANTS_REACHED();
    error PARTICIPANT_NOT_ALLOWED();
    error INCORRECT_STAKE_AMOUNT();
    error ALREADY_PARTICIPATING();
    error COMPLETION_WINDOW_OVER();
    error COMPLETION_WINDOW_NOT_OVER();
    error CALLER_IS_NOT_SUPERVISOR();
    error INVALID_PARTICIPANT();
    error POST_COMPLETION_WINDOW_DISTRIBUTION_ALREADY_CALLED();
    error INVALID_ORACLE_DELEGATE();
    error NOT_AUTHORIZED_TO_RETURN_STAKE_FOR_PARTICIPANT();
    error PARTICIPANT_LIST_AND_SHOULD_RETURN_STAKE_LIST_LENGTHS_MISMATCH();
    error PARTICIPANT_HAS_NOT_COMPLETED();
    error STAKE_ALREADY_RETURNED();

    //*********************************************************************//
    // --------------------- public stored properties -------------------- //
    //*********************************************************************//

    uint256 public projectId;

    mapping(address => Participant) public participants;
    mapping(address => bool) public supervisors;
    mapping(address => bool) public oracleDelegates;
    mapping(uint256 => bool) public stakingTiers;

    address[] public unreturnedStakeBeneficiaries;
    uint256 public completionWindowSeconds;
    uint256 public maxParticipants;
    bool public shouldUseParticipantAllowList;
    bool public shouldParticipantsShareUnreturnedStake;
    bool public shouldUseSupervisorInactionGuard;
    string public metadataURI;

    // Internal State
    address[] public participantList;
    uint256 public completionWindowEndTimestamp;
    uint256 public participantCount;
    uint256 public completingParticipantCount;
    uint256 public totalStakeAmount;
    uint256 public totalSponsorContribution;
    uint256 public totalReturnedStakeAmount;
    bool public hasSupervisorActed;
    bool public isPostReturnWindowDistributionCalled;

    constructor(uint256 _projectId, LaunchPepperStakeData memory _launchData)
        payable
    {
        projectId = _projectId;

        // Set up supervisors
        for (uint256 i = 0; i < _launchData.supervisors.length; i++) {
            supervisors[_launchData.supervisors[i]] = true;
        }

        // Set up oracle delegates
        for (
            uint256 i = 0;
            i < _launchData.oracleDelegateAddresses.length;
            i++
        ) {
            oracleDelegates[_launchData.oracleDelegateAddresses[i]] = true;
            supervisors[_launchData.oracleDelegateAddresses[i]] = true;
        }

        if (_launchData.shouldUseParticipantAllowList) {
            for (
                uint256 i = 0;
                i < _launchData.participantAllowList.length;
                i++
            ) {
                participants[_launchData.participantAllowList[i]]
                    .isAllowedToParticipate = true;
            }
        }

        for (uint256 i = 0; i < _launchData.stakingTiers.length; i++) {
            stakingTiers[_launchData.stakingTiers[i]] = true;
        }

        unreturnedStakeBeneficiaries = _launchData.unreturnedStakeBeneficiaries;
        completionWindowSeconds = _launchData.completionWindowSeconds;
        maxParticipants = _launchData.maxParticipants;
        shouldParticipantsShareUnreturnedStake = _launchData
            .shouldParticipantsShareUnreturnedStake;
        shouldUseSupervisorInactionGuard = _launchData
            .shouldUseSupervisorInactionGuard;
        shouldUseParticipantAllowList = _launchData
            .shouldUseParticipantAllowList;
        metadataURI = _launchData.metadataURI;

        supervisors[address(this)] = true;

        completionWindowEndTimestamp =
            block.timestamp +
            completionWindowSeconds;
        participantCount = 0;
        completingParticipantCount = 0;
        totalStakeAmount = 0;
        totalReturnedStakeAmount = 0;
        totalSponsorContribution = 0;
        hasSupervisorActed = false;
        isPostReturnWindowDistributionCalled = false;

        if (msg.value > 0) {
            _stake();
        }
    }

    function getParticipant(address _participant)
        external
        view
        returns (Participant memory)
    {
        return participants[_participant];
    }

    function _stake() private {
        if (
            shouldUseParticipantAllowList &&
            !participants[msg.sender].isAllowedToParticipate
        ) {
            revert PARTICIPANT_NOT_ALLOWED();
        }
        if (participantCount >= maxParticipants)
            revert MAX_PARTICIPANTS_REACHED();
        if (participants[msg.sender].participated)
            revert ALREADY_PARTICIPATING();
        if (block.timestamp > completionWindowEndTimestamp)
            revert COMPLETION_WINDOW_OVER();
        if (!stakingTiers[msg.value]) revert INCORRECT_STAKE_AMOUNT();

        Participant memory participantData = Participant({
            isAllowedToParticipate: true,
            participated: true,
            completed: false,
            stakeReturned: false,
            stakeAmount: msg.value
        });
        participants[msg.sender] = participantData;
        participantList.push(msg.sender);
        participantCount++;
        totalStakeAmount += msg.value;

        emit Stake(msg.sender, msg.value);
    }

    function stake() external payable {
        _stake();
    }

    function sponsor() external payable {
        if (block.timestamp > completionWindowEndTimestamp)
            revert COMPLETION_WINDOW_OVER();
        totalSponsorContribution += msg.value;

        emit Sponsor(msg.sender, msg.value);
    }

    function approveForParticipants(address[] memory _completingParticipants)
        external
    {
        if (!supervisors[msg.sender]) revert CALLER_IS_NOT_SUPERVISOR();
        if (block.timestamp > completionWindowEndTimestamp)
            revert COMPLETION_WINDOW_OVER();
        for (uint256 i = 0; i < _completingParticipants.length; i++) {
            if (!participants[_completingParticipants[i]].participated)
                revert INVALID_PARTICIPANT();
        }

        for (uint256 i = 0; i < _completingParticipants.length; i++) {
            address completingParticipant = _completingParticipants[i];
            participants[completingParticipant].completed = true;
            completingParticipantCount++;
        }
        hasSupervisorActed = true;
    }

    function returnStake(address[] memory _participants) external {
        bool isReturningForSelf = _participants.length == 1 &&
            _participants[0] == msg.sender;
        if (!supervisors[msg.sender] && !isReturningForSelf)
            revert NOT_AUTHORIZED_TO_RETURN_STAKE_FOR_PARTICIPANT();
        for (uint256 i = 0; i < _participants.length; i++) {
            if (!participants[_participants[i]].completed)
                revert PARTICIPANT_HAS_NOT_COMPLETED();
            if (participants[_participants[i]].stakeReturned)
                revert STAKE_ALREADY_RETURNED();
        }

        for (uint256 i = 0; i < _participants.length; i++) {
            address completingParticipant = _participants[i];
            uint256 stakeAmount = participants[completingParticipant]
                .stakeAmount;
            payable(completingParticipant).transfer(stakeAmount);
            participants[completingParticipant].stakeReturned = true;
            totalReturnedStakeAmount += stakeAmount;
        }
    }

    function checkOracle(
        address _oracleDelegate,
        address[] memory participantsToCheck
    ) external {
        if (!oracleDelegates[_oracleDelegate]) revert INVALID_ORACLE_DELEGATE();
        IPepperStakeOracleDelegate oracleDelegate = IPepperStakeOracleDelegate(
            _oracleDelegate
        );
        (bool[] memory results, uint256 completionCount) = oracleDelegate
            .checkForAddresses(participantsToCheck);
        address[] memory completingParticipants = new address[](
            completionCount
        );
        uint256 winnerCount = 0;
        for (uint256 i = 0; i < results.length; i++) {
            if (results[i]) {
                completingParticipants[winnerCount] = participantsToCheck[i];
                winnerCount++;
            }
        }
        this.approveForParticipants(completingParticipants);
    }

    function _distributeUnreturnedStake() private {
        for (uint256 i = 0; i < participantList.length; i++) {
            address participant = participantList[i];
            if (
                participants[participant].completed &&
                !participants[participant].stakeReturned
            ) {
                uint256 stakeAmount = participants[participant].stakeAmount;
                payable(participant).transfer(stakeAmount);
                participants[participant].stakeReturned = true;
                totalReturnedStakeAmount += stakeAmount;
            }
        }
    }

    function _distributeSponsorContribution() private {
        // TODO: Handle case with sponsor contribution but no completing participants
        if (completingParticipantCount > 0) {
            uint256 beneficiaryShare = totalSponsorContribution /
                completingParticipantCount;
            address[] memory beneficiaries = new address[](
                completingParticipantCount
            );
            uint256 beneficiaryIndex = 0;
            for (uint256 i = 0; i < participantCount; i++) {
                address participant = participantList[i];
                if (participants[participant].completed) {
                    payable(participant).transfer(beneficiaryShare);
                    beneficiaries[beneficiaryIndex] = participant;
                    beneficiaryIndex++;
                }
            }

            emit DistributeSponsorContribution(
                msg.sender,
                beneficiaries,
                totalSponsorContribution,
                beneficiaryShare
            );
        }
    }

    function _distributeUnapprovedStake() private {
        if (participantCount - completingParticipantCount > 0) {
            address[] memory beneficiaries;
            if (shouldUseSupervisorInactionGuard && !hasSupervisorActed) {
                // Inaction Guard is true, no supervisor ever called returnStake()
                beneficiaries = participantList;
            } else {
                beneficiaries = unreturnedStakeBeneficiaries;
            }
            uint256 unreturnedStake = address(this).balance;
            uint256 beneficiaryShare = unreturnedStake /
                (participantCount - completingParticipantCount);
            for (uint256 i = 0; i < beneficiaries.length; i++) {
                payable(beneficiaries[i]).transfer(beneficiaryShare);
            }

            emit DistributeUnreturnedStake(
                msg.sender,
                beneficiaries,
                unreturnedStake,
                beneficiaryShare
            );
        }
    }

    function postCompletionWindowDistribution() external {
        if (block.timestamp <= completionWindowEndTimestamp)
            revert COMPLETION_WINDOW_NOT_OVER();
        if (isPostReturnWindowDistributionCalled)
            revert POST_COMPLETION_WINDOW_DISTRIBUTION_ALREADY_CALLED();
        _distributeUnreturnedStake();
        _distributeSponsorContribution();
        _distributeUnapprovedStake();
        isPostReturnWindowDistributionCalled = true;
    }
}
