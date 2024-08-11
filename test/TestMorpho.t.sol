// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/morphoBlueSnippets.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MarketParamsLib} from "../src/interfaces/morpho/libraries/MarketParamsLib.sol"; // Import the library;

contract MorphoBlueSnippetsTest is Test {
    using MorphoLib for IMorpho;
    using MorphoBalancesLib for IMorpho;
    using MarketParamsLib for MarketParams;

    IMorpho public morpho;

    MorphoBlueSnippets morphoBlueSnippets;
    IERC20 loanToken;
    IERC20 collateralToken;
    address morphoAddress = address(0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb);
    address USER = vm.envAddress("USER");
    address ezETH = vm.envAddress("ezETH");
    uint256 amount = 1 ether;

    MarketParams marketParams;

    function setUp() public {
        // Deploy
        morphoBlueSnippets = new MorphoBlueSnippets(morphoAddress);
        console.log("deployed to: ", address(morphoBlueSnippets));

        marketParams.loanToken = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // USDC
        marketParams
            .collateralToken = 0x2416092f143378750bb29b79eD961ab195CcEea5; // ezETH
        marketParams.oracle = 0x1BAaB21821c6468f8aee73ee60Fd8Fdc39c0C973;
        marketParams.irm = 0x46415998764C29aB2a25CbeA6254146D50D22687;
        marketParams.lltv = 770000000000000000;

        loanToken = IERC20(marketParams.loanToken);
        collateralToken = IERC20(marketParams.collateralToken);
        morpho = IMorpho(morphoAddress);
    }

    function testGiveCollateral() internal {
        vm.startPrank(USER);
        console.log("=====1(start)=====");

        deal(address(collateralToken), USER, amount);

        collateralToken.approve(address(morphoBlueSnippets), amount);

        console.log(
            "exETH balance before supplying collateral:",
            collateralToken.balanceOf(USER)
        );

        uint256 collateralGiven = morphoBlueSnippets.supplyCollateral(
            marketParams,
            amount
        );

        console.log("The collateral given: ", collateralGiven);

        assertEq(collateralGiven, amount, "supplyCollateral failed");

        // Get the id using the MarketParamsLib
        Id marketParamsId = MarketParamsLib.id(marketParams);

        Position memory pos = morphoBlueSnippets.getPosition(
            marketParamsId,
            address(morphoBlueSnippets)
        );

        console.log("Position supplyShares:", pos.supplyShares);
        console.log("Position borrowShares:", pos.borrowShares);
        console.log("Position collateral:", pos.collateral);
        console.log("=====1(end)====");
        vm.stopPrank();
    }

    function testAuthorizeAndSupply() internal {
        testGiveCollateral();
        vm.startPrank(USER);
        console.log("=====2(start)====");

        morphoBlueSnippets.setAuthorization(true);
        bool authorizationStatus = morphoBlueSnippets.isAuthorization(
            address(morphoBlueSnippets)
        );
        console.log("authorizationStatus", authorizationStatus);
        assertEq(authorizationStatus, true);

        console.log("gonna go borrow USDC now");
        (uint256 assetsBorrowed, uint256 sharesBorrowed) = morphoBlueSnippets
            .borrow(marketParams, 2000000000, address(morphoBlueSnippets)); // pass how much usdc to borrow (consider LTV)
        console.log(
            "assetsBorrowed & sharesBorrowed: ",
            assetsBorrowed,
            sharesBorrowed
        );
        console.log("=====2(end)====");

        vm.stopPrank();
    }

    function testRepay() internal {
        testAuthorizeAndSupply();
        vm.startPrank(USER);
        console.log("=====3(start)====");

        morphoBlueSnippets.repayNew(marketParams, 2000000000);

        console.log("=====3(end)====");
        vm.stopPrank();
    }

    function testWithdrawCollateral() public {
        testRepay();
        vm.startPrank(USER);
        console.log("=====4(start)====");
        // Get the id using the MarketParamsLib
        Id marketParamsId = MarketParamsLib.id(marketParams);

        Position memory pos = morphoBlueSnippets.getPosition(
            marketParamsId,
            address(morphoBlueSnippets)
        );

        console.log("Position collateral:", pos.collateral);

        morphoBlueSnippets.withdrawCollateral(
            marketParams,
            0.5 ether,
            address(morphoBlueSnippets)
        ); // rn kept .5 to check if its working (to withdraw all collateral have to use some view fn)
        console.log("=====4(end)====");
        vm.stopPrank();
    }
}
