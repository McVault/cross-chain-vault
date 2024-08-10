// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import "../src/ccip/OptimismToBase.sol";
import "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

contract SiloTest is Test {
    OptimismToBase public optimismToBase;
    address public constant ROUTER_ADDRESS = 0x3206695CaE29952f4b0c22a169725a865bc8Ce0f; // Optimism CCIP router
    address public constant LINK_ADDRESS = 0x350a791Bfc2C21F9Ed5d10980Dad2e2638ffa7f6; // LINK token on Optimism
    address public constant SILO_ROUTER_ADDRESS = 0xC66D2a90c37c873872281a05445EC0e9e82c76a9; // Silo Router on Optimism
    address public constant EZETH_SILO_MARKET = 0x12ee4BE944b993C81b6840e088bA1dCc57F07B1D; // ezETH Silo Market on Optimism
    address public constant EZETH_ADDRESS = 0x2416092f143378750bb29b79eD961ab195CcEea5; // ezETH token on Optimism
    address public constant USDC_ADDRESS = 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85;
    address public constant dUSDC_ezETH = 0x2610A59b1f46cF45C9360a3EdB9464610580b653;

    uint256 public constant DEPOSIT_AMOUNT = 1e6; // 1 USDC

    function setUp() public {
        // Fork Optimism mainnet
        vm.createSelectFork("http://127.0.0.1:8546");
        
        // Deploy the contract
        optimismToBase = new OptimismToBase(ROUTER_ADDRESS, LINK_ADDRESS, SILO_ROUTER_ADDRESS);
        
        // Give the OptimismToBase contract some USDC
        deal(USDC_ADDRESS, address(optimismToBase), 1e7);
    }

    function testDepositToSilo() public {

        console.log("OptimismToBase Contract Address: ", address(optimismToBase));

        // Get the initial balances
        uint256 initialUSDCBalance = IERC20(USDC_ADDRESS).balanceOf(EZETH_SILO_MARKET); // scc to market
        uint256 initialDUSDCBalance = IERC20(dUSDC_ezETH).balanceOf(address(optimismToBase)); //0

        console.log("Initial USDC balance of Silo Market:", initialUSDCBalance);
        console.log("Initial dUSDC balance of OptimismToBase:", initialDUSDCBalance);

        // Call the _depositToSilo function
        optimismToBase._depositToSilo(EZETH_SILO_MARKET, USDC_ADDRESS, DEPOSIT_AMOUNT); // 1USDC

        // Get the final balances
        uint256 finalUSDCBalance = IERC20(USDC_ADDRESS).balanceOf(EZETH_SILO_MARKET); //market + 1
        uint256 finalDUSDCBalance = IERC20(dUSDC_ezETH).balanceOf(address(optimismToBase)); // should be 1

        console.log("Final USDC balance of Silo Market:", finalUSDCBalance);
        console.log("Final dUSDC balance of OptimismToBase:", finalDUSDCBalance);

        // Assert that the USDC balance in the Silo market has increased by the deposit amount
        // assertEq(finalUSDCBalance, initialUSDCBalance + DEPOSIT_AMOUNT, "Deposit to Silo failed");

        // Assert that the OptimismToBase contract received dUSDC tokens
        // assertTrue(finalDUSDCBalance > initialDUSDCBalance, "OptimismToBase did not receive dUSDC tokens");
    }
}