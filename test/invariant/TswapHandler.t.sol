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
    uint256 public immutable MIN_WETH_TO_DEPOSIT;

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
    address user = makeAddr("user");

    constructor(TSwapPool _tSwapPool, ERC20Mock _poolToken, ERC20Mock _weth) {
        tSwapPool = _tSwapPool;
        poolToken = _poolToken;
        weth = _weth;
        MIN_WETH_TO_DEPOSIT = tSwapPool.getMinimumWethDepositAmount();
    }

    function swapExactOutput(uint256 outputAmount) public {
        // swap output
        //    function swapExactOutput(
        //     IERC20 inputToken,
        //     IERC20 outputToken,
        //     uint256 outputAmount,
        //     uint64 deadline
        // )
        // bounds:
        // inputToken need to be weth or the other
        // outputToken need to be weth or the other
        // outputToken and inputToken need to always be different
        // outputAmount need to be reasonable
        // need to  update the balances and deltas before and after

        outputAmount = bound(outputAmount, 1, type(uint64).max);
        ERC20Mock inputToken;
        ERC20Mock outputToken;
        if (outputAmount % 2 == 0) {
            inputToken = weth;
            outputToken = poolToken;
        } else {
            inputToken = poolToken;
            outputToken = weth;
        }
        uint256 inputAmount = tSwapPool.getInputAmountBasedOnOutput(
            outputAmount, inputToken.balanceOf(address(tSwapPool)), outputToken.balanceOf(address(tSwapPool))
        );

        vm.assume(outputToken.balanceOf(address(tSwapPool)) > MIN_WETH_TO_DEPOSIT);

        // get starting balances and deltas
        // outputToken is the one that goes out from pool
        if (outputToken == weth) {
            _updateStartingBalanceAndDeltas(int256(outputAmount) * -1, int256(inputAmount));
        } else {
            _updateStartingBalanceAndDeltas(int256(inputAmount), int256(outputAmount) * -1);
        }

        //////////// swap!! ////////////

        // mint necessary tokens to user
        inputToken.mint(user, inputAmount);

        vm.startPrank(user);
        // approve pool to spend those tokens
        inputToken.approve(address(tSwapPool), inputAmount);

        // swap
        tSwapPool.swapExactOutput(inputToken, outputToken, outputAmount, uint64(block.timestamp));
        vm.stopPrank();

        // update ending balances and deltas
        _updateEndingBalanceAndDeltas();
    }

    function deposit(uint256 wethAmount) public {
        // make a reasonable amount with bound

        wethAmount = bound(wethAmount, MIN_WETH_TO_DEPOSIT, type(uint64).max);

        uint256 minimumLiquidityTokensToMint = wethAmount;
        uint256 maximumPoolTokensToDeposit =
            tSwapPool.getPoolTokensToDepositBasedOnWeth(uint256(minimumLiquidityTokensToMint));

        weth.mint(lp, wethAmount);
        poolToken.mint(lp, maximumPoolTokensToDeposit);

        // before depositing, check the balance of the pool
        _updateStartingBalanceAndDeltas(int256(wethAmount), int256(maximumPoolTokensToDeposit));

        vm.startPrank(lp);
        weth.approve(address(tSwapPool), type(uint256).max);
        poolToken.approve(address(tSwapPool), type(uint256).max);

        tSwapPool.deposit(wethAmount, 0, maximumPoolTokensToDeposit, uint64(block.timestamp));

        vm.stopPrank();

        _updateEndingBalanceAndDeltas();
    }

    ////////// helpers //////////
    function _updateStartingBalanceAndDeltas(int256 _wethAmount, int256 _poolTokenAmount) private {
        poolWethStartingBalance = int256(weth.balanceOf(address(tSwapPool)));
        poolTokenStartingBalance = int256(poolToken.balanceOf(address(tSwapPool)));
        poolWethExpectedDelta = _wethAmount;
        poolTokenExpectedDelta = _poolTokenAmount;
    }

    function _updateEndingBalanceAndDeltas() private {
        poolWethEndingBalance = int256(weth.balanceOf(address(tSwapPool)));
        poolTokenEndingBalance = int256(poolToken.balanceOf(address(tSwapPool)));

        poolWethactualDelta = poolWethEndingBalance - poolWethStartingBalance;
        poolTokenActualDelta = poolTokenEndingBalance - poolTokenStartingBalance;
    }
}
