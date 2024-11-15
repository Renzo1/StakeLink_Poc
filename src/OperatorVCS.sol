// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./StakeLinkAbstract.sol";
import "./IOperatorVault.sol";

contract OperatorVCS {
    IERC20 public token;
    StakeLinkAbstract public stakeLinkAbstract;
    uint256 public totalDeposits;
    Fee[] internal fees;
    IOperatorVault[] public vaults;
    uint256 public unclaimedOperatorRewards;

    struct Fee {
        address receiver;
        uint256 basisPoints;
    }

    modifier onlyStakingPool() {
        _;
    }

    constructor(address _token, uint256 _existingTotalDeposits) {
        token = IERC20(_token);
        totalDeposits = _existingTotalDeposits;
        addFee();
    }

    function addVault(address vault) external {
        vaults.push(IOperatorVault(vault));
    }

    function addFee() private {
        fees.push(Fee(address(400), 2_490));
        fees.push(Fee(address(500), 2_490));
    }

    // @post-appeal-note: requested function with zero changes. All judges comments are still intact
    function strategy_updateDeposits(
        bytes calldata _data
    ) external onlyStakingPool returns (int256 depositChange, address[] memory receivers, uint256[] memory amounts) {
        uint256 minRewards = _data.length == 0 ? 0 : abi.decode(_data, (uint256));
        uint256 newTotalDeposits = totalDeposits;
        uint256 newTotalPrincipalDeposits;
        uint256 vaultDeposits;
        uint256 operatorRewards;
    
        // First calculate operator rewards
        uint256 vaultCount = vaults.length;
        address receiver = address(this);
        for (uint256 i = 0; i < vaultCount; ++i) {
            (uint256 deposits, uint256 principal, uint256 rewards) = IOperatorVault(
                address(vaults[i])
            ).updateDeposits(minRewards, receiver);
            vaultDeposits += deposits;
            newTotalPrincipalDeposits += principal;
            operatorRewards += rewards;
        }
    
        uint256 balance = token.balanceOf(address(this));
        depositChange = int256(vaultDeposits + balance) - int256(totalDeposits);
    
        // Operator rewards handling - completely separate from protocol fees
        if (operatorRewards != 0) {
            receivers = new address[](1 + (depositChange > 0 ? fees.length : 0));
            amounts = new uint256[](receivers.length);
            receivers[0] = address(this);  // The VCS itself receives operator rewards
            amounts[0] = operatorRewards;
            unclaimedOperatorRewards += operatorRewards;
        }
    
        // Protocol fees - only if there was a positive deposit change
        if (depositChange > 0) {
            newTotalDeposits += uint256(depositChange);
    
            // If no operator rewards were claimed
            if (receivers.length == 0) {
                receivers = new address[](fees.length);
                amounts = new uint256[](fees.length);
    
                for (uint256 i = 0; i < fees.length; ++i) {
                    receivers[i] = fees[i].receiver;
                    amounts[i] = (uint256(depositChange) * fees[i].basisPoints) / 10000;
                }
            } else {
                // If operator rewards exist, offset the fee indices by 1
                for (uint256 i = 1; i < receivers.length; ++i) {
                    receivers[i] = fees[i - 1].receiver;
                    amounts[i] = (uint256(depositChange) * fees[i - 1].basisPoints) / 10000;
                }
            }
        }

        totalDeposits = newTotalDeposits;
    }
}