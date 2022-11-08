// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IPepperStake.sol";

interface IPepperStakeOracleDelegate {
    function checkForAddresses(address[] memory addresses)
        external
        view
        returns (bool[] memory, uint256 completionCount);
}
