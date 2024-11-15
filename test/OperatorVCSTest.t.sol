// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "../src/OperatorVCS.sol";
import "../src/MockOperatorVault.sol";
import {MockERC20} from "./MockERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OperatorVCSTest is Test {
    OperatorVCS operatorVCS;
    StakeLinkAbstract stakeLinkAbstract;
    MockOperatorVault mockVault;
    MockERC20 token;
    uint256 existingTotalDeposits = 100 ether;

    function setUp() public {
        token = new MockERC20("mockToken","MK", 18, 10 ether);
        
        // Create mock vault with existing deposits
        mockVault = new MockOperatorVault(address(token), existingTotalDeposits);
        
        // Send the rewards that the OperatorVCS will pull from the mockVault
        token.mint(address(mockVault), 10 ether);
        
        stakeLinkAbstract = new StakeLinkAbstract(address(token));
        // Set the totalDeposits (existingTotalDeposits) to match the mockVault's existing deposits
        // because the ideally the OperatorVCS should have the same totalDeposits as the total deposit in all vaults
        operatorVCS = new OperatorVCS(address(token), existingTotalDeposits);

        // Add mock vault to operatorVCS -- we are using one vault for simplicity  
        operatorVCS.addVault(address(mockVault));

        // Set the operatorVCS to the stakeLinkAbstract contract
        stakeLinkAbstract.setVcsAbstract(address(operatorVCS));
    }


    // forge test --match-test testStrategyUpdateDeposits2 -vvv
    function testStrategyUpdateDeposits2() public {
        // check the initial token balance of OperatorVCS and StakeLinkAbstract
        uint256 operatorVCSBal_before = token.balanceOf(address(operatorVCS));

        // Create mock data for the call
        bytes memory data = abi.encode(1); // minRewards = 1

        // Call the function
        uint256 totalFeeAmounts = stakeLinkAbstract.stakingPool_updateStrategyRewards(data);

        // check the token balance of OperatorVCS and StakeLinkAbstract
        uint256 operatorVCSBal_after = token.balanceOf(address(operatorVCS));

        console.log("StakingPool totalFeeAmounts: ", totalFeeAmounts);
        console.log("OperatorVCS balance after: ", operatorVCSBal_after);
    }


    /*
    Logs:
        StakingPool totalFeeAmounts:  10960000000000000000
        OperatorVCS balance after:  10000000000000000000
        
    Despite making minimal changes to the source code we still get errenouse results. 
    First we can see there a double count with how the opRewards received from the mockVault is 
    handled in the StakingPool (960000000000000000).
    Secondly, some how the Initial total reward (the 10 ether sent to the mockVault) is added to the totalFeeAmounts, 
    suggesting there are further issues with how the rewards are being distributed in the OperatorVCS + StakingPoolcontract.
    */
}
