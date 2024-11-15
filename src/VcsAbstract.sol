// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./StakeLinkAbstract.sol";

contract VcsAbstract {

    IERC20 public token;
    StakeLinkAbstract public stakeLinkAbstract;
    // mock totalDeposits -- assumes 100 eth is staked in Chainlink
    uint256 public totalDeposits = 100 ether;
    Fee[] internal fees;

    constructor(address _token) {
        token = IERC20(_token);
        addFee();
    }


    function addFee() private {
        fees.push(Fee(address(400), 2_490));
        fees.push(Fee(address(500), 2_490));
    }

    function setStakeLinkAbstract(address _stakeLinkAbstract) public {
        stakeLinkAbstract = StakeLinkAbstract(_stakeLinkAbstract);
    }

    // reference: https://github.com/Cyfrin/2024-09-stakelink/blob/ea5574ebce3a86d10adc2e1a5f6d5512750f7a72/contracts/linkStaking/base/VaultControllerStrategy.sol#L494-L500
    function getDepositChange() public view virtual returns (int) {
        uint256 totalBalance = token.balanceOf(address(this));

        // convert to a simple sum of the balance and the totalDeposits
        // for (uint256 i = 0; i < vaults.length; ++i) {
        //     totalBalance += vaults[i].getTotalDeposits();
        // }
        // totalBalance represents the new rewards this contract received, while totalDeposits represents the amount staked in Chainlink
        totalBalance += totalDeposits;
        

        return int(totalBalance) - int(totalDeposits);
    }

    // @post-appeal-note: This is the orginal strategy_updateDeposits in the PoC. I am going to comment it out and use the one requested by the Judge 
    // reference: https://github.com/Cyfrin/2024-09-stakelink/blob/ea5574ebce3a86d10adc2e1a5f6d5512750f7a72/contracts/linkStaking/base/VaultControllerStrategy.sol#L525-L532
    function strategy_updateDeposits() public returns (int256 depositChange, address[] memory receivers, uint256[] memory amounts) {
        // change fees to fees_length
        depositChange = getDepositChange();
        uint256 newTotalDeposits = totalDeposits;

        if (depositChange > 0) {
            newTotalDeposits += uint256(depositChange);

            receivers = new address[](fees.length);
            amounts = new uint256[](fees.length);

            for (uint256 i = 0; i < fees.length; ++i) {
                receivers[i] = fees[i].receiver;
                amounts[i] = (uint256(depositChange) * fees[i].basisPoints) / 10000;
            }
        } else if (depositChange < 0) {
            newTotalDeposits -= uint256(depositChange * -1);
        }

        uint256 balance = token.balanceOf(address(this));
        if (balance != 0) {
            token.transfer(address(this), balance);
            newTotalDeposits -= balance;
        }

        totalDeposits = newTotalDeposits;
    }
    
}
