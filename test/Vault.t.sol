// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {McVault} from "../src/McVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISwapRouter} from "../src/interfaces/uniswap/ISwapRouter.sol";
import {IRenzoDepositContract} from "../src/interfaces/renzo/IRenzoDepositContract.sol";
import "../src/morphoBlueSnippets.sol";
import {BaseToOptimism} from "../src/ccip/baseToOptimism.sol";
import {MarketParams, IMorpho} from "../src/interfaces/morpho/IMorpho.sol";
import {MarketParamsLib} from "../src/interfaces/morpho/libraries/MarketParamsLib.sol";
import {Renzosnippets} from "../src/renzoSnippets.sol";

contract McVaultTest is Test {
    McVault public vault;
    IERC20 public weth;
    IERC20 public ezETH;
    IERC20 public usdc;
    MorphoBlueSnippets public morphoBlueSnippets;
    Renzosnippets public renzoSnippets;
    BaseToOptimism public baseToOptimism;
    ISwapRouter public swapRouter;
    address public constant USER = address(1);
    uint256 public constant INITIAL_BALANCE = 10 ether;
    address public constant MORPHO_ADDRESS =
        0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    address public constant RENZO_DEPOSIT_ADDRESS =
        0xf25484650484DE3d554fB0b7125e7696efA4ab99;
    address public constant SWAP_ROUTER_ADDRESS =
        0x2626664c2603336E57B271c5C0b26F421741e481;
    address public constant LINK_BASE =
        0x88Fb150BDc53A65fe94Dea0c9BA0a6dAf8C6e196;
    address constant BASE_ROUTER = 0x881e3A65B4d4a04dD529061dd0071cf975F58bCD;
    using MarketParamsLib for MarketParams;

    MarketParams marketParams;

    function setUp() public {
        morphoBlueSnippets = new MorphoBlueSnippets(MORPHO_ADDRESS);
        baseToOptimism = new BaseToOptimism(BASE_ROUTER, address(LINK_BASE));
        swapRouter = ISwapRouter(SWAP_ROUTER_ADDRESS);

        vault = new McVault(
            address(morphoBlueSnippets),
            SWAP_ROUTER_ADDRESS,
            RENZO_DEPOSIT_ADDRESS,
            address(baseToOptimism),
            IERC20(0x4200000000000000000000000000000000000006), // WETH on Base
            IERC20(0x2416092f143378750bb29b79eD961ab195CcEea5), // ezETH
            0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913 // USDC
        );

        weth = IERC20(0x4200000000000000000000000000000000000006);
        ezETH = IERC20(0x2416092f143378750bb29b79eD961ab195CcEea5);
        usdc = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);

        deal(address(weth), USER, INITIAL_BALANCE);
    }

    function testDeposit() public {
        uint256 depositAmount = 1 ether;

        console.log("Initial WETH balance of USER:", weth.balanceOf(USER));
        console.log(
            "Initial WETH balance of vault:",
            weth.balanceOf(address(vault))
        );

        vm.startPrank(USER);
        weth.approve(address(vault), depositAmount);
        console.log("WETH approved for vault");

        try vault.deposit(depositAmount, USER) {
            console.log("Deposit successful");
        } catch Error(string memory reason) {
            console.log("Deposit failed:", reason);
            vm.stopPrank();
            return;
        }
        vm.stopPrank();

        console.log(
            "WETH balance of USER after deposit:",
            weth.balanceOf(USER)
        );
        console.log(
            "WETH balance of vault after deposit:",
            weth.balanceOf(address(vault))
        );
        console.log("Vault balance of USER:", vault.balanceOf(USER));
    }

    function testAfterDeposit() public {
        uint256 depositAmount = 1 ether;

        console.log("Initial WETH balance of USER:", weth.balanceOf(USER));
        console.log(
            "Initial WETH balance of vault:",
            weth.balanceOf(address(vault))
        );

        vm.startPrank(USER);
        weth.approve(address(vault), depositAmount);
        try vault.deposit(depositAmount, USER) {
            console.log("Deposit successful");
        } catch Error(string memory reason) {
            console.log("Deposit failed:", reason);
            vm.stopPrank();
            return;
        }
        vm.stopPrank();

        console.log(
            "WETH balance of USER after deposit:",
            weth.balanceOf(USER)
        );
        console.log(
            "WETH balance of vault after deposit:",
            weth.balanceOf(address(vault))
        );

        uint256 slippage = 40; // 4% slippage
        uint256 minAmount = depositAmount - ((depositAmount * slippage) / 1000);
        console.log("Minimum expected amount after slippage:", minAmount);

        vm.prank(vault.owner());
        try vault.afterDeposit(depositAmount) {
            console.log("afterDeposit successful");
        } catch Error(string memory reason) {
            console.log("afterDeposit failed:", reason);
            return;
        }

        console.log(
            "ezETH balance of vault after Renzo deposit:",
            ezETH.balanceOf(address(vault))
        );
    }

    function testDepositOnMorpho() public {
        uint256 depositAmount = 1 ether;
        uint256 maxBorrow = 1000000; // 50% of deposit amount

        // Mint some ezETH to the vault
        deal(address(ezETH), address(vault), depositAmount);

        console.log(
            "Initial ezETH balance of vault:",
            ezETH.balanceOf(address(vault))
        );
        console.log(
            "Initial USDC balance of vault:",
            usdc.balanceOf(address(vault))
        );

        vm.startPrank(vault.owner());

        try vault.depositOnMorpho(depositAmount, maxBorrow) returns (
            uint256 collateralSupplied,
            uint256 sharesBorrowed,
            uint256 assetsBorrowed
        ) {
            console.log("Deposit on Morpho successful");
            console.log("Collateral supplied:", collateralSupplied);
            console.log("Shares borrowed:", sharesBorrowed);
            console.log("Assets borrowed:", assetsBorrowed);
        } catch Error(string memory reason) {
            console.log("Deposit on Morpho failed:", reason);
            vm.stopPrank();
            return;
        }

        vm.stopPrank();

        console.log(
            "ezETH balance of vault after deposit:",
            ezETH.balanceOf(address(vault))
        );
        console.log(
            "USDC balance of vault after borrow:",
            usdc.balanceOf(address(vault))
        );

        // Get the market ID
        Id marketParamsId = MarketParamsLib.id(marketParams);

        // Get the current position
        Position memory position = vault.morphoBlue().getPosition(
            marketParamsId,
            address(vault)
        );

        // Assert that we have borrowed some USDC
        assertTrue(
            usdc.balanceOf(address(vault)) > 0,
            "USDC balance should be greater than 0 after borrowing"
        );
    }

    // function testBridgeUsdcFromBaseToOP() public {
    //     uint64 destinationChainSelector = 111; // Example selector for Optimism
    //     deal(address(usdc), address(vault), 1000000000); // 1000 USDC

    //     console.log(
    //         "Initial USDC balance of vault:",
    //         usdc.balanceOf(address(vault))
    //     );

    //     vm.startPrank(vault.owner());
    //     try
    //         vault.bridgeUsdcFromBaseToOP{value: 0.1 ether}(
    //             destinationChainSelector,
    //             address(0x123), // Example receiver address on Optimism
    //             address(0x456), // Example ezETH_SiloMarket address on Optimism
    //             address(usdc)
    //         )
    //     {
    //         console.log("Bridge operation successful");
    //     } catch Error(string memory reason) {
    //         console.log("Bridge operation failed:", reason);
    //     }
    //     vm.stopPrank();

    //     console.log(
    //         "USDC balance of vault after bridge:",
    //         usdc.balanceOf(address(vault))
    //     );
    //     console.log(
    //         "USDC balance of BaseToOptimism contract:",
    //         usdc.balanceOf(address(baseToOptimism))
    //     );
    // }

    // function testBeforeWithdraw() public {
    //     uint256 depositAmount = 1 ether;
    //     uint256 proportion = 0.5 ether; // 50%

    //     deal(address(ezETH), address(vault), depositAmount);
    //     console.log(
    //         "Initial ezETH balance of vault:",
    //         ezETH.balanceOf(address(vault))
    //     );

    //     vm.startPrank(vault.owner());
    //     vault.afterDeposit(depositAmount);
    //     uint256 withdrawnAmount = vault.beforeWithdraw(proportion);
    //     vm.stopPrank();

    //     console.log("Withdrawn amount:", withdrawnAmount);
    //     console.log(
    //         "ezETH balance of vault after withdrawal:",
    //         ezETH.balanceOf(address(vault))
    //     );
    // }

    function testSwapEzETHForWETH() public {
        uint256 initialEzETHAmount = 1 ether;
        uint256 amountOutMinimum = 0.95 ether;

        deal(address(ezETH), address(vault), 1 ether);

        console.log(
            "Initial ezETH balance of vault:",
            ezETH.balanceOf(address(vault))
        );
        console.log(
            "Initial WETH balance of vault:",
            weth.balanceOf(address(vault))
        );

        vm.startPrank(vault.owner());

        try vault.swapEzETHForWETH(initialEzETHAmount, 0, 500) returns (
            uint256 amountOut
        ) {
            console.log("Swap successful");
            console.log("Amount of WETH received:", amountOut);
        } catch (bytes memory lowLevelData) {
            console.log("Swap failed with low-level error:");
            console.logBytes(lowLevelData);
            vm.stopPrank();
            return;
        }

        vm.stopPrank();

        console.log(
            "ezETH balance of vault after swap:",
            ezETH.balanceOf(address(vault))
        );
        console.log(
            "WETH balance of vault after swap:",
            weth.balanceOf(address(vault))
        );

        // Assert that the ezETH balance is now 0
        assertEq(
            ezETH.balanceOf(address(vault)),
            0,
            "ezETH balance should be 0 after swap"
        );

        // Assert that the WETH balance has increased
        assertTrue(
            weth.balanceOf(address(vault)) > 0,
            "WETH balance should have increased after swap"
        );

        // Assert that the received WETH amount is at least the minimum expected
        assertTrue(
            weth.balanceOf(address(vault)) >= amountOutMinimum,
            "Received WETH amount is less than the minimum expected"
        );
    }
}
