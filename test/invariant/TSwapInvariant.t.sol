// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { StdInvariant } from "forge-std/StdInvariant.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { TSwapPool } from "../../src/TSwapPool.sol";
import { TSwapHandler } from "./TSwapHandler.t.sol";

contract TSwapInvariant is Test {
    TSwapPool pool;
    ERC20Mock poolToken;
    ERC20Mock weth;
    TSwapHandler tSwapHandler;

    uint256 constant WETH_TOKEN_STARTING_BAL = 100e18;
    uint256 constant POOL_TOKEN_STARTING_BAL = 200e18;

    address liquidityProvider = address(this);
    address user = makeAddr("user");

    function setUp() public {
        poolToken = new ERC20Mock();
        weth = new ERC20Mock();
        pool = new TSwapPool(address(poolToken), address(weth), "LTokenA", "LA");

        weth.mint(liquidityProvider, WETH_TOKEN_STARTING_BAL);
        poolToken.mint(liquidityProvider, POOL_TOKEN_STARTING_BAL);

        poolToken.approve(address(pool), type(uint256).max);
        weth.approve(address(pool), type(uint256).max);

        pool.deposit(WETH_TOKEN_STARTING_BAL, WETH_TOKEN_STARTING_BAL, POOL_TOKEN_STARTING_BAL, uint64(block.timestamp));

        //---> addressing the handler in the invariant tests
        tSwapHandler = new TSwapHandler(pool, poolToken, weth);

        bytes4[] memory selectors = new bytes4[](2); //change when you do the other functions

        selectors[0] = TSwapHandler.deposit.selector;
        selectors[1] = TSwapHandler.swapExactOutput.selector;

        targetSelector(FuzzSelector({ addr: address(tSwapHandler), selectors: selectors }));
        targetContract(address(tSwapHandler));
    }

    // Final invariant equation without fees:
    // ∆x = (β/(1-β)) * x
    // ∆y = (α/(1+α)) * y
    function invariant_constant_product_of_tokens_should_stay_the_same() public {
        assertEq(tSwapHandler.poolWethExpectedDelta(), tSwapHandler.poolWethactualDelta());
        assertEq(tSwapHandler.poolTokenExpectedDelta(), tSwapHandler.poolTokenActualDelta());
    }
}
