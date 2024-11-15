// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IOperatorVault {
    function updateDeposits(uint256 minRewards, address receiver) external returns (uint256 deposits, uint256 principal, uint256 rewards);
}