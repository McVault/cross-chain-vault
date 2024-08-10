// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import "../src/ccip/OptimismToBase.sol";
import "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

contract SiloTest is Test {
    OptimismToBase public optimismToBase;
    address public constant ROUTER_ADDRESS =
        0x3206695CaE29952f4b0c22a169725a865bc8Ce0f; // Optimism CCIP router
    address public constant LINK_ADDRESS =
        0x350a791Bfc2C21F9Ed5d10980Dad2e2638ffa7f6; // LINK token on Optimism
    address public constant SILO_ROUTER_ADDRESS =
        0xC66D2a90c37c873872281a05445EC0e9e82c76a9; // Silo Router on Optimism
    address public constant EZETH_SILO_MARKET =
        0x12ee4BE944b993C81b6840e088bA1dCc57F07B1D; // ezETH Silo Market on Optimism
    address public constant EZETH_ADDRESS =
        0x2416092f143378750bb29b79eD961ab195CcEea5; // ezETH token on Optimism
    address public constant USDC_ADDRESS =
        0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85;
    address public constant sUSDC_ezETH =
        0x368E6755412184f87436D36558eC3B5f60230c93;

    uint256 public constant DEPOSIT_AMOUNT = 1e6;

    function setUp() public {
        // Fork Optimism mainnet
        string memory OP_RPC_URL = vm.envString("OPTIMISM_RPC_URL");
        vm.createSelectFork(OP_RPC_URL);
        // Deploy the contract
        optimismToBase = new OptimismToBase(
            ROUTER_ADDRESS,
            LINK_ADDRESS,
            SILO_ROUTER_ADDRESS
        );
        deal(USDC_ADDRESS, address(optimismToBase), 1e7);
    }

    // function testDepositToSilo() public {
    //     // Get the initial balance of USDC in the Silo market
    //     deal(USDC_ADDRESS, address(optimismToBase), 1e7);

    //     uint256 initialBalance = IERC20(USDC_ADDRESS).balanceOf(
    //         EZETH_SILO_MARKET
    //     );
    //     uint256 initBal = IERC20(sUSDC_ezETH).balanceOf(
    //         address(optimismToBase)
    //     );

    //     // Call the _depositToSilo function
    //     optimismToBase._depositToSilo(
    //         EZETH_SILO_MARKET,
    //         USDC_ADDRESS,
    //         DEPOSIT_AMOUNT
    //     );

    //     // Get the final balance of USDC in the Silo market
    //     uint256 finalBalance = IERC20(USDC_ADDRESS).balanceOf(
    //         EZETH_SILO_MARKET
    //     );
    //     uint256 afterBal = IERC20(sUSDC_ezETH).balanceOf(
    //         address(optimismToBase)
    //     );
    //     console.log("sUSDC balance of optimismToBase:", afterBal);

    //     // Assert that the balance has increased by the deposit amount
    //     assertEq(
    //         finalBalance,
    //         initialBalance + DEPOSIT_AMOUNT,
    //         "Deposit to Silo failed"
    //     );
    //     assertGt(afterBal, initBal, "Deposit of sUSDC to the contract failed");
    // }

    function testWithdrawFromSilo() public {
        // First, deposit some USDC
        deal(USDC_ADDRESS, address(optimismToBase), 1e7);
        optimismToBase._depositToSilo(
            EZETH_SILO_MARKET,
            USDC_ADDRESS,
            DEPOSIT_AMOUNT
        );

        // Get initial balances
        uint256 initialSUSDCBalance = IERC20(sUSDC_ezETH).balanceOf(
            address(optimismToBase)
        );
        uint256 initialUSDCBalance = IERC20(USDC_ADDRESS).balanceOf(
            address(optimismToBase)
        );

        console.log(
            "Initial sUSDC balance of optimismToBase:",
            initialSUSDCBalance
        );
        console.log(
            "Initial USDC balance of optimismToBase:",
            initialUSDCBalance
        );

        // Perform withdrawal
        optimismToBase.withdrawFromSilo(
            EZETH_SILO_MARKET,
            sUSDC_ezETH,
            initialSUSDCBalance
        );

        // Get final balances
        uint256 finalSUSDCBalance = IERC20(sUSDC_ezETH).balanceOf(
            address(optimismToBase)
        );
        uint256 finalUSDCBalance = IERC20(USDC_ADDRESS).balanceOf(
            address(optimismToBase)
        );

        console.log(
            "Final sUSDC balance of optimismToBase:",
            finalSUSDCBalance
        );
        console.log("Final USDC balance of optimismToBase:", finalUSDCBalance);

        // Assert that sUSDC balance has decreased
        assertEq(
            finalSUSDCBalance, 0, "Withdrawal from Silo failed");

        // Assert that USDC balance has increased
        assertGt(
            finalUSDCBalance,
            initialUSDCBalance,
            "USDC not received after withdrawal"
        );
    }
}
