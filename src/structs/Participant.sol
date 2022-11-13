// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

struct Participant {
    bool isAllowedToParticipate;
    bool participated;
    bool completed;
    bool stakeReturned;
    uint256 stakeAmount;
}
