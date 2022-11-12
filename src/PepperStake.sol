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

    //*********************************************************************//
    // --------------------- public stored properties -------------------- //
    //*********************************************************************//

    uint256 projectId;

    mapping(address => Participant) public participants;
    mapping(address => bool) public supervisors;
    mapping(address => bool) public oracleDelegates;

    uint256[] public stakingTiers;
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
    uint256 public totalSponsorContribution;
    bool public isReturnStakeCalled;
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
            stakingTiers.push(_launchData.stakingTiers[i]);
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
        totalSponsorContribution = 0;
        isReturnStakeCalled = false;
        isPostReturnWindowDistributionCalled = false;

        if (msg.value > 0) {
            _stake();
        }
    }

    function PROJECT_ID() external view returns (uint256) {
        return projectId;
    }

    function IS_SUPERVISOR(address _supervisor) external view returns (bool) {
        return supervisors[_supervisor];
    }

    function IS_ORACLE_DELEGATE(address _oracleDelegate)
        external
        view
        returns (bool)
    {
        return oracleDelegates[_oracleDelegate];
    }

    function END_TIMESTAMP() public view returns (uint256) {
        return completionWindowEndTimestamp;
    }

    function TOTAL_SPONSOR_CONTRIBUTION() public view returns (uint256) {
        return totalSponsorContribution;
    }

    function PARTICIPANT_COUNT() external view returns (uint256) {
        return participantCount;
    }

    function COMPLETING_PARTICIPANT_COUNT() external view returns (uint256) {
        return completingParticipantCount;
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
        for (uint256 i = 0; i < stakingTiers.length; i++) {
            if (msg.value == stakingTiers[i]) {
                Participant memory participantData = Participant({
                    isAllowedToParticipate: true,
                    participated: true,
                    completed: false,
                    stakeAmount: msg.value,
                    stakeTier: i
                });
                participants[msg.sender] = participantData;
                participantList.push(msg.sender);
                participantCount++;
                emit Stake(msg.sender, msg.value);
                return;
            }
        }
        revert INCORRECT_STAKE_AMOUNT();
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

    function returnStake(address[] memory completingParticipants) external {
        if (!supervisors[msg.sender]) revert CALLER_IS_NOT_SUPERVISOR();
        if (block.timestamp > completionWindowEndTimestamp)
            revert COMPLETION_WINDOW_OVER();
        for (uint256 i = 0; i < completingParticipants.length; i++) {
            if (!participants[completingParticipants[i]].participated)
                revert INVALID_PARTICIPANT();
        }

        for (uint256 i = 0; i < completingParticipants.length; i++) {
            address completingParticipant = completingParticipants[i];
            uint256 stakeAmount = participants[completingParticipant]
                .stakeAmount;
            payable(completingParticipant).transfer(stakeAmount);
            participants[completingParticipant].completed = true;
            completingParticipantCount++;
        }
        isReturnStakeCalled = true;

        // emit ReturnStake(msg.sender, completingParticipants, participant.stakeAmount);
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
        this.returnStake(completingParticipants);
    }

    function _distributeUnreturnedStake() private {
        if (participantCount - completingParticipantCount > 0) {
            address[] memory beneficiaries;
            if (shouldUseSupervisorInactionGuard && !isReturnStakeCalled) {
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

    function postCompletionWindowDistribution() external {
        if (block.timestamp <= completionWindowEndTimestamp)
            revert COMPLETION_WINDOW_NOT_OVER();
        if (isPostReturnWindowDistributionCalled)
            revert POST_COMPLETION_WINDOW_DISTRIBUTION_ALREADY_CALLED();
        _distributeSponsorContribution();
        _distributeUnreturnedStake();
        isPostReturnWindowDistributionCalled = true;
    }
}
