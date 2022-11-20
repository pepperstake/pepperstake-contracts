// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

struct Participant {
    bool isAllowedToParticipate;
    bool participated;
    bool completed;
    uint256 stakeAmount;
}
