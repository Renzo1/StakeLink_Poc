// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IOperatorVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockOperatorVault is IOperatorVault {
    uint256 public mockDeposits;
    uint256 public mockPrincipal;
    uint256 public mockRewards;
    IERC20 public token;
    uint256 trackedTotalDeposits;
    uint256 unclaimedRewards;

    uint256 operatorRewardPercentage = 1_000; // 10% mock operator rewards

    constructor(address _token, uint256 _existingDeposits) {
        token = IERC20(_token);
        mockDeposits = _existingDeposits;
        mockPrincipal = _existingDeposits;
        trackedTotalDeposits = _existingDeposits;
    }


    modifier onlyVaultController() {
        _;
    }

    // reference: https://github.com/Cyfrin/2024-09-stakelink/blob/ea5574ebce3a86d10adc2e1a5f6d5512750f7a72/contracts/linkStaking/OperatorVault.sol#L179-L207
    function updateDeposits(
        uint256 _minRewards,      // Minimum rewards threshold to trigger claiming
        address _rewardsReceiver  // Address to receive claimed rewards
    ) external onlyVaultController returns (uint256, uint256, uint256) {
        mockRewards = token.balanceOf(address(this)); // these tokens are deposited in test setup

        // The actual function implementation starts here

        uint256 principal = mockPrincipal;
        uint256 rewards = mockRewards;
        uint256 totalDeposits = principal + rewards;
        int256 depositChange = int256(totalDeposits) - int256(uint256(trackedTotalDeposits));
    
        uint256 opRewards;
        if (depositChange > 0) {
            // Calculate operator rewards as percentage of positive deposit change
            opRewards = (uint256(depositChange) * operatorRewardPercentage) / 10000;
            // Add these rewards to unclaimed balance
            unclaimedRewards += opRewards; // removed the safecast
            trackedTotalDeposits = totalDeposits; // removed the safecast
        }
    
        // If minimum rewards threshold is set and current rewards exceed it
        if (_minRewards != 0 && rewards >= _minRewards) {
            // rewardsController.claimReward(); // removed, the test setup sends rewards to the vault
            trackedTotalDeposits -= (rewards);
            totalDeposits -= rewards;
            token.transfer(_rewardsReceiver, rewards); // changed from safeTransfer to transfer
        }
    
        return (totalDeposits, principal, opRewards);
    }
}

