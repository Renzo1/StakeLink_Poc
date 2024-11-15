// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./VcsAbstract.sol";
import "./OperatorVCS.sol";

struct Fee {
    // address to recieve fee
    address receiver;
    // value of fee in basis points
    uint256 basisPoints;
}


contract StakeLinkAbstract {
    uint256 public totalStaked;
    // @post-appeal-note 1: adding this variable because we need it now, since we are uncommenting some code lines
    // also, feel free to set it to whatever value you like, it's irrelevant to the test
    uint256 public totalShares = 0 ether;

    // mock token
    IERC20 public token;
    // @post-appeal-note: changing the variable from vcsAbstract to operatorVCS
    OperatorVCS public operatorVCS;
    
    constructor(address _token) {
        token = IERC20(_token);
        addFee();
    }

    // helper function to add vcsAbstract to the stakeLinkAbstract contract
    function setVcsAbstract(address _opsAbstract) public {
        // @post-appeal-note: changing the variable from vcsAbstract to operatorVCS
        operatorVCS = OperatorVCS(_opsAbstract);
    }


    Fee[] internal fees;

    function addFee() private {
        fees.push(Fee(address(100), 2_490));
        fees.push(Fee(address(200), 2_490));
    }

    ///////// MOCK FUNCTIONS /////////

    // mock StakingPool::_updateStrategyRewards function
    function stakingPool_updateStrategyRewards(bytes calldata _data) public returns (uint256) {
        // changed all _strategyIdxs.length to strategies_length
        uint256 strategies_length = 1;

        int256 totalRewards;
        uint256 totalFeeAmounts;
        uint256 totalFeeCount;
        address[][] memory receivers = new address[][](strategies_length + 1);
        uint256[][] memory feeAmounts = new uint256[][](strategies_length + 1);

        // sum up rewards and fees across strategies
        for (uint256 i = 0; i < strategies_length; ++i) {
            // IStrategy strategy = IStrategy(strategies[_strategyIdxs[i]]);

            // mock IStrategy::updateDeposits function
            // Instead of calling strategy we just call the strategy_updateDeposits function to return the values
            // @post-appeal-note 2: Note that we could have mocked this part of the code, as all we need are the values
            // returned here and the tokens sent into this contract. We added the VcsAbract contect to make the PoC richer and easier to understand
            (
                int256 depositChange,
                address[] memory strategyReceivers,
                uint256[] memory strategyFeeAmounts
            ) = operatorVCS.strategy_updateDeposits(_data); // @post-appeal-note: changing the variable from vcsAbstract to operatorVCS
            totalRewards += depositChange;

            if (strategyReceivers.length != 0) {
                receivers[i] = strategyReceivers;
                feeAmounts[i] = strategyFeeAmounts;
                totalFeeCount += receivers[i].length;
                for (uint256 j = 0; j < strategyReceivers.length; ++j) {
                    totalFeeAmounts += strategyFeeAmounts[j];
                }
            }
        }

        // update totalStaked if there was a net change in deposits
        if (totalRewards != 0) {
            totalStaked = uint256(int256(totalStaked) + totalRewards);
        }

        // calulate fees if net positive rewards were earned
        if (totalRewards > 0) {
            receivers[receivers.length - 1] = new address[](fees.length);
            feeAmounts[feeAmounts.length - 1] = new uint256[](fees.length);
            totalFeeCount += fees.length;

            for (uint256 i = 0; i < fees.length; i++) {
                receivers[receivers.length - 1][i] = fees[i].receiver;
                feeAmounts[feeAmounts.length - 1][i] =
                    (uint256(totalRewards) * fees[i].basisPoints) /
                    10000;
                totalFeeAmounts += feeAmounts[feeAmounts.length - 1][i];
            }
        }


        // We want to return the totalFeeAmounts to compare with the expected value
        return (totalFeeAmounts);


        // @post-appeal-note 3: Everything after this line is commented out, because all I need to show you was 
        // the value of totalFeeAmounts and the rest of the code is not relevant to the test. 
        // You may want to argue that the next code line is necessary to stop this bug but that will be a false argument
        // as the line only sets the totalFeeAmounts to 0 if it's >= totalStaked, which is not a viable security measure.
        // This is because if the double count give us a value that is less than the totalStaked, the bug will less obvious,

        // if (totalFeeAmounts >= totalStaked) {
        //     totalFeeAmounts = 0;
        // }

        // // distribute fees to receivers if there are any
        // if (totalFeeAmounts > 0) {
        //     uint256 sharesToMint = (totalFeeAmounts * totalShares) /
        //         (totalStaked - totalFeeAmounts);
        //     // @post-appeal-note 5: to avoid further mocking and abstraction, I am going to comment out the internal functions we haven't implemented
        //     // _mintShares(address(this), sharesToMint);

        //     uint256 feesPaidCount;
        //     for (uint256 i = 0; i < receivers.length; i++) {
        //         for (uint256 j = 0; j < receivers[i].length; j++) {
        //             if (feesPaidCount == totalFeeCount - 1) {
        //                 // transferAndCallFrom(
        //                 //     address(this),
        //                 //     receivers[i][j],
        //                 //     balanceOf(address(this)),
        //                 //     "0x"
        //                 // );
        //             } else {
        //                 // transferAndCallFrom(address(this), receivers[i][j], feeAmounts[i][j], "0x");
        //                 feesPaidCount++;
        //             }
        //         }
        //     }
        // }

        // emit UpdateStrategyRewards(msg.sender, totalStaked, totalRewards, totalFeeAmounts);
    }
}
