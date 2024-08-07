// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/morpho.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MorphoBlueSnippetsTest is Test {
    MorphoBlueSnippets morphoBlueSnippets;
    IERC20 loanToken;
    IERC20 collateralToken;
    address morphoAddress = address(0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb);
    address USER = vm.envAddress("USER");
    address ezETH = vm.envAddress("ezETH");
    uint256 amount = 100 ether;

    // Define market parameters
    MarketParams marketParams;

    function setUp() public {
        // Deploy the MorphoBlueSnippets contract with a dummy Morpho contract address
        morphoBlueSnippets = new MorphoBlueSnippets(morphoAddress);

        // Set up the market parameters
        marketParams.loanToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; //usdc
        marketParams
            .collateralToken = 0xbf5495Efe5DB9ce00f80364C8B423567e58d2110; //ezETH
        marketParams.oracle = 0x895f9dF47F8a68396eD026978A0771C120DFC279;
        marketParams.irm = 0x870aC11D48B15DB9a138Cf899d20F13F79Ba00BC;
        marketParams.lltv = 770000000000000000;

        // Assume loanToken is an IERC20 token
        loanToken = IERC20(marketParams.loanToken);
        collateralToken = IERC20(marketParams.collateralToken);

        // Deal some loan tokens to the test contract
        deal(address(loanToken), address(this), 1000 ether);
    }

    function testGiveCollateral() public {
        vm.startPrank(USER);
        deal(address(loanToken), USER, amount);

        // Approve the MorphoBlueSnippets contract to transfer loan tokens
        loanToken.approve(address(morphoBlueSnippets), amount);

        console.log(
            "user loanTOken balance before:",
            loanToken.balanceOf(USER)
        );
        console.log("user balance before:", IERC20(ezETH).balanceOf(USER));
        // Call the supply function
        (uint256 assetsSupplied, uint256 sharesSupplied) = morphoBlueSnippets
            .supply(marketParams, amount);

        console.log("when supplied", assetsSupplied, sharesSupplied);

        // Check the results (the actual checks depend on the logic inside the mock Morpho contract)
        // assertEq(assetsSupplied, amount, "Assets supplied do not match");
        // assertGt(
        //     sharesSupplied,
        //     0,
        //     "Shares supplied should be greater than zero"
        // );
        console.log(
            "user collateralToken balance later:",
            loanToken.balanceOf(USER)
        );
        console.log("user balance later:", IERC20(ezETH).balanceOf(USER));
        // morphoBlueSnippets.getPosition(
        //     0x28c028a1af0fa01da5b9c46bb8d999e3e8e65b8304edc09fd8cbaef03a64cb35,
        //     USER
        // );
        console.log(
            "USDC balance received:",
            IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).balanceOf(USER)
        );

        vm.stopPrank();
    }
}
