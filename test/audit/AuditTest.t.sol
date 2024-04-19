// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { TSwapPool } from "../../src/PoolFactory.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract TSwapPoolTest is Test {
    TSwapPool pool;
    ERC20Mock poolToken;
    ERC20Mock weth;

    address liquidityProvider = makeAddr("liquidityProvider");
    address user = makeAddr("user");

    function setUp() public {
        poolToken = new ERC20Mock();
        weth = new ERC20Mock();
        pool = new TSwapPool(address(poolToken), address(weth), "LTokenA", "LA");

        weth.mint(liquidityProvider, 200e18);
        poolToken.mint(liquidityProvider, 200e18);

        weth.mint(user, 1000e18);
        poolToken.mint(user, 1000e18);
    }

    function testInvariantBreak() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        vm.startPrank(user);
        poolToken.approve(address(pool), type(uint256).max);
        uint256 expectedOutput = 1e17;

        for (uint256 i = 0; i < 9; i++) {
            pool.swapExactOutput(poolToken, weth, expectedOutput, uint64(block.timestamp));
        }

        // need to test the invariant, so the expected delta of weth is equal to the actual delta of weth)
        uint256 startingY = weth.balanceOf(address(pool));
        int256 expectedDeltaY = int256(-1) * int256((expectedOutput));

        pool.swapExactOutput(poolToken, weth, expectedOutput, uint64(block.timestamp));

        uint256 endingY = weth.balanceOf(address(pool));
        int256 acutualDeltaY = int256(endingY) - int256(startingY);

        console.log("acutualDeltaY:");
        console.logInt(acutualDeltaY);
        console.log("expectedDeltaY:");
        console.logInt(expectedDeltaY);

        assertEq(expectedDeltaY, acutualDeltaY);
    }

    function testFeesMiscalculation() public {
        //deposit in pool

        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        uint256 outputAmount = 2e18;
        uint256 inputReserves = poolToken.balanceOf(address(pool));
        uint256 outputReserves = weth.balanceOf(address(pool));
        uint256 inputAmountFor2Weth = pool.getInputAmountBasedOnOutput(outputAmount, inputReserves, outputReserves);

        uint256 shouldBe = ((inputReserves * outputAmount) * 1_000) / ((outputReserves - outputAmount) * 997);

        console.log("shouldBe %", shouldBe);
        console.log("inputAmountFor2Weth %", inputAmountFor2Weth);
        assertGt(inputAmountFor2Weth, shouldBe);
    }
}
