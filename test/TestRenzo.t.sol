// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Renzosnippets} from "../src/renzoSnippets.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RenzosnippetsTest is Test {
    Renzosnippets public renzosnippets;
    uint256 amount;
    address USER = makeAddr("USER");

    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant ezETH = 0x2416092f143378750bb29b79eD961ab195CcEea5;
    address constant renzoDepositAddress =
        0xf25484650484DE3d554fB0b7125e7696efA4ab99;

    function setUp() public {
        // Fork Base mainnet

        renzosnippets = new Renzosnippets(renzoDepositAddress);
        amount = 1000000000000000000; // 0.048 WETH
    }

    function testDeposit() public {
        vm.startPrank(USER);

        // Deal WETH tokens to USER
        deal(WETH, USER, amount); // 0.098 WETH

        console.log("Initial WETH Balance:", IERC20(WETH).balanceOf(USER));

        // Approve the Renzosnippets contract to spend WETH on behalf of USER
        IERC20(WETH).approve(address(renzosnippets), amount);

        // Record balances before deposit
        uint256 wethBalanceBefore = IERC20(WETH).balanceOf(USER);
        uint256 ezETHBalanceBefore = IERC20(ezETH).balanceOf(
            address(renzosnippets)
        );

        // Call deposit with appropriate parameters
        uint256 receivedEzETH = renzosnippets.depositOnRenzo(
            amount,
            amount - 100000000000000000, // Adjust this minOut value as needed
            block.timestamp + 1 hours
        );

        // Record balances after deposit
        uint256 wethBalanceAfter = IERC20(WETH).balanceOf(USER);
        uint256 ezETHBalanceAfter = IERC20(ezETH).balanceOf(
            address(renzosnippets)
        );

        console.log("WETH Balance after Deposit:", wethBalanceAfter);
        console.log("ezETH Balance after Deposit:", ezETHBalanceAfter);

        // Assertions
        assertEq(
            wethBalanceAfter,
            wethBalanceBefore - amount,
            "Incorrect WETH balance after deposit"
        );
        assertGt(
            ezETHBalanceAfter,
            ezETHBalanceBefore,
            "ezETH balance should increase"
        );
        assertEq(
            ezETHBalanceAfter - ezETHBalanceBefore,
            receivedEzETH,
            "Received ezETH amount mismatch"
        );

        vm.stopPrank();
    }
}
