// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/morphoBlueSnippets.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MarketParamsLib} from "../src/interfaces/morpho/libraries/MarketParamsLib.sol"; // Import the library;

contract MorphoBlueSnippetsTest is Test {
    using MorphoLib for IMorpho;
    using MorphoBalancesLib for IMorpho;
    using MarketParamsLib for MarketParams; // Use the library

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
        marketParams.loanToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC
        marketParams
            .collateralToken = 0xbf5495Efe5DB9ce00f80364C8B423567e58d2110; // ezETH
        marketParams.oracle = 0x895f9dF47F8a68396eD026978A0771C120DFC279;
        marketParams.irm = 0x870aC11D48B15DB9a138Cf899d20F13F79Ba00BC;
        marketParams.lltv = 770000000000000000;

        loanToken = IERC20(marketParams.loanToken);
        collateralToken = IERC20(marketParams.collateralToken);
    }

    function testGiveCollateral() public {
        vm.startPrank(USER);
        deal(address(collateralToken), USER, amount);

        // Approve the MorphoBlueSnippets contract to transfer loan tokens
        collateralToken.approve(address(morphoBlueSnippets), amount);

        console.log(
            "exETH balance before supplying collateral:",
            collateralToken.balanceOf(USER)
        );

        // call the supplyCollateral function
        uint256 collateralGiven = morphoBlueSnippets.supplyCollateral(
            marketParams,
            amount
        );

        console.log("The collateral given: ", collateralGiven);

        //  ====== supply loan token =======
        /* console.log(
            "user collateralToken balance later:",
            loanToken.balanceOf(USER)
        );
        (uint256 assetsSupplied, uint256 sharesSupplied) = morphoBlueSnippets
            .supply(marketParams, amount);

        console.log("when supplied", assetsSupplied, sharesSupplied);

        console.log(
            "user collateralToken balance later:",
            loanToken.balanceOf(USER)
        ); */
        // console.log("user balance later:", IERC20(ezETH).balanceOf(USER));

        // Get the id using the MarketParamsLib
        Id marketParamsId = MarketParamsLib.id(marketParams);

        Position memory pos = morphoBlueSnippets.getPosition(
            marketParamsId,
            USER
        );

        // Assuming Position struct has fields like `collateralAmount`, `debtAmount`, etc.
        console.log("Position supplyShares:", pos.supplyShares);
        console.log("Position borrowShares:", pos.borrowShares);
        console.log("Position collateral:", pos.collateral);
        // console.log(
        //     "USDC balance received:",
        //     IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48).balanceOf(USER)
        // );

        vm.stopPrank();
    }
}
