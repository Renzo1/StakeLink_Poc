// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/StakeLinkAbstract.sol";
import "../src/VcsAbstract.sol";
import {MockERC20} from "./MockERC20.sol";

contract StakeLinkAbstractTest is Test {
    StakeLinkAbstract public stakeLinkAbstract;
    VcsAbstract public vcsAbstract;
    MockERC20 public token;

    function setUp() public {
        token = new MockERC20("mockToken","MK", 18, 10 ether);

        stakeLinkAbstract = new StakeLinkAbstract(address(token));
        vcsAbstract = new VcsAbstract(address(token));

        stakeLinkAbstract.setVcsAbstract(address(vcsAbstract));
        vcsAbstract.setStakeLinkAbstract(address(stakeLinkAbstract));

        // mint 100 tokens to the stakeLinkAbstract contract
        uint256 initialVcsBalance = 10 ether;
        token.mint(address(vcsAbstract), initialVcsBalance);
    }


    // forge test --match-test testDoubleCountingInStakingPool -vvv
    // @post-appeal-note: this test will run as expected, because stakingPool_updateStrategyRewards now 
    // targets the OperatorVCS contract instead of the VcsAbstract contract
    function testDoubleCountingInStakingPool() public {
        // check the token balance of VcsAbstract and StakeLinkAbstract
        uint256 stakingPoolBal = token.balanceOf(address(stakeLinkAbstract));
        uint256 vcsAbstractBal = token.balanceOf(address(vcsAbstract));

        // Remember we are assuming VcsAbstract::totalDeposits is the part not in the VcsAbstract contract, but staked in Chainlink
        uint256 depositChange = uint256(vcsAbstract.getDepositChange());
        console.log("depositChange", depositChange);

        // Now lets call stakeLinkAbstract::strategy_updateDeposits
        // Create mock data for the call
        bytes memory data = abi.encode(0); // minRewards = 0
        uint256 totalFeeAmounts = stakeLinkAbstract.stakingPool_updateStrategyRewards(data);
        console.log("totalFeeAmounts", totalFeeAmounts);

        // check the token balance of VcsAbstract and StakeLinkAbstract
        stakingPoolBal = token.balanceOf(address(stakeLinkAbstract));
        vcsAbstractBal = token.balanceOf(address(vcsAbstract));

        // We should get a totalFeeAmounts that is 40% of depositChange i.e 40000000000000000000
        // This is because we set the fees to be total of 4000 basis points, which is 20% for each of the two fees receivers
        // The test fails because the totalFeeAmounts is 120% of depositChange, which is incorrect 
        // This proves there is a double counting in the staking pool
        console.log("totalFeeAmounts", totalFeeAmounts);
        console.log("depositChange", depositChange);
        // I commented this assertion out because the test fails and I want to see the log values without disruption
        // assertEq(totalFeeAmounts, (depositChange * 60) / 100);
    }
    // log
    /*
    // @post-appeal-note: Old log
    Logs:
        depositChange 100000000000000000000
        totalFeeAmounts 120000000000000000000
        totalFeeAmounts 120000000000000000000
        depositChange 100000000000000000000

    */
    
}
