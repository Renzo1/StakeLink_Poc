## Proof of Code
Here is a Proof of Code validating this submission above. 
This PoC shows that the calculate `totalFeeAmounts` value in stakingPool::updateStrategyRewards is in fact double counted. 
This was achieved by mocking the minimum relevant parts of the StakingPool and VaultControllerStrategy contract.

To run this test you need to do the following. 
- Create a new foundry project
- Install openzeppellin library
- And copy the following files

## File 1: remapping.txt
create a 'remapping.txt' file in your root directory and add this line
```
@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/
```

## File 2: MockERC20.sol
create a 'MockERC20.sol' file in your `test/` directory and add this code
```js
// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.25;

// Open Zeppelin dependencies
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    uint8 internal _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_,
        uint256 deployerBalance
    )
        ERC20(name, symbol)
    {
        _decimals = decimals_;
        _mint(msg.sender, deployerBalance);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}


```

## File 3: StakeLinkAbstract.sol
create a 'StakeLinkAbstract.sol' file in your `src/` directory and add this code
> Note: this is the abstracted contract of StakingPool and VaultControllerStrategy
```js


```

## File 4: StakeLinkAbstract.sol
create a 'StakeLinkAbstract.sol' file in your `src/` directory and add this code
> Note: this is the abstracted contract of StakingPool and VaultControllerStrategy
```js


```

## File 2: StakeLinkAbstractTest.t.sol
create a 'StakeLinkAbstractTest.t.sol' file in your `test/` directory and add this code
> Note: this is the abstracted contract of StakingPool and VaultControllerStrategy
```js


```

Note: 

