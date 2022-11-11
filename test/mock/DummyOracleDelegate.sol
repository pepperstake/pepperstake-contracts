// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../../src/interfaces/IPepperStakeOracleDelegate.sol";

contract DummyOracleDelegate is IPepperStakeOracleDelegate {
    function checkForAddresses(address[] memory addresses)
        external
        pure
        override
        returns (bool[] memory, uint256 completionCount)
    {
        bool[] memory results = new bool[](addresses.length);
        uint256 count = 0;
        for (uint256 i = 0; i < addresses.length; i++) {
            results[i] = true;
            count++;
        }
        return (results, count);
    }
}
