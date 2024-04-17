// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { TSwapPool } from "../../src/TSwapPool.sol";

/**
 * probably I want to mess up with these methods:
 *  "deposit(uint256,uint256,uint256,uint64)": "4b785efe",
 *  "swapExactInput(address,uint256,address,uint256,uint64)": "3dd5e20d",
 *  "swapExactOutput(address,address,uint256,uint64)": "4e6d9df8",
 *  "withdraw(uint256,uint256,uint256,uint64)": "8933da3a"
 */
contract TSwapHandler is Test {
    TSwapPool tSwapPool;
    ERC20Mock poolToken;
    ERC20Mock weth;

    // our ghost variables
    // starting amounts
    int256 public poolWethStartingBalance;
    int256 public poolTokenStartingBalance;

    int256 public poolWethEndingBalance;
    int256 public poolTokenEndingBalance;

    // expected deltas
    int256 public poolWethExpectedDelta;
    int256 public poolTokenExpectedDelta;

    // actual deltas
    int256 public poolWethactualDelta;
    int256 public poolTokenActualDelta;

    address lp = makeAddr("lp");

    constructor(TSwapPool _tSwapPool, ERC20Mock _poolToken, ERC20Mock _weth) {
        tSwapPool = _tSwapPool;
        poolToken = _poolToken;
        weth = _weth;
    }

    function deposit(uint256 wethAmount) public {
        // make a reasonable amount with bound
        uint256 minWethTODeposit = tSwapPool.getMinimumWethDepositAmount();
        wethAmount = bound(wethAmount, minWethTODeposit, type(uint64).max);

        uint256 minimumLiquidityTokensToMint = wethAmount;
        uint256 maximumPoolTokensToDeposit =
            tSwapPool.getPoolTokensToDepositBasedOnWeth(uint256(minimumLiquidityTokensToMint));

        weth.mint(lp, wethAmount);
        poolToken.mint(lp, maximumPoolTokensToDeposit);

        // before depositing, check the balance of the pool
        _updateStartingBalanceAndDeltas(wethAmount, maximumPoolTokensToDeposit);

        vm.startPrank(lp);
        weth.approve(address(tSwapPool), type(uint256).max);
        poolToken.approve(address(tSwapPool), type(uint256).max);

        tSwapPool.deposit(wethAmount, minimumLiquidityTokensToMint, maximumPoolTokensToDeposit, uint64(block.timestamp));

        vm.stopPrank();
        _updateEndingBalanceAndDeltas();
    }

    ////////// helpers //////////
    function _updateStartingBalanceAndDeltas(uint256 _wethAmount, uint256 _poolTokenAmount) private {
        poolWethStartingBalance = int256(weth.balanceOf(address(tSwapPool)));
        poolTokenStartingBalance = int256(poolToken.balanceOf(address(tSwapPool)));
        poolWethExpectedDelta = int256(_wethAmount);
        poolTokenExpectedDelta = int256(_poolTokenAmount);
    }

    function _updateEndingBalanceAndDeltas() private {
        poolWethEndingBalance = int256(weth.balanceOf(address(tSwapPool)));
        poolTokenEndingBalance = int256(poolToken.balanceOf(address(tSwapPool)));

        poolWethactualDelta = poolWethEndingBalance - poolWethStartingBalance;
        poolTokenActualDelta = poolTokenEndingBalance - poolTokenStartingBalance;
    }
}
