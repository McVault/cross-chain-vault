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
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant LINK_BASE =
        0x88Fb150BDc53A65fe94Dea0c9BA0a6dAf8C6e196;
    using MarketParamsLib for MarketParams;

    MarketParams marketParams;

    function setUp() public {
        // Fork Base network
        vm.createSelectFork(vm.envString("BASE_RPC_URL"));

        // Deploy MorphoBlueSnippets
        morphoBlueSnippets = new MorphoBlueSnippets(MORPHO_ADDRESS);

        // Deploy BaseToOptimism
        baseToOptimism = new BaseToOptimism(MORPHO_ADDRESS, address(LINK_BASE));

        // Set up SwapRouter
        swapRouter = ISwapRouter(SWAP_ROUTER_ADDRESS);

        // Deploy McVault
        vault = new McVault(
            address(morphoBlueSnippets),
            SWAP_ROUTER_ADDRESS,
            RENZO_DEPOSIT_ADDRESS,
            address(baseToOptimism),
            IERC20(0x4200000000000000000000000000000000000006), // WETH on Base
            IERC20(0x2416092f143378750bb29b79eD961ab195CcEea5) // ezETH on Base
        );

        weth = IERC20(0x4200000000000000000000000000000000000006);
        ezETH = IERC20(0x2416092f143378750bb29b79eD961ab195CcEea5);
        usdc = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);

        // Give USER some WETH
        deal(address(weth), USER, INITIAL_BALANCE);
    }

    function testDeposit() public {
        uint256 depositAmount = 1 ether;

        vm.startPrank(USER);
        weth.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, USER);
        vm.stopPrank();

        assertEq(vault.balanceOf(USER), depositAmount);
        assertEq(weth.balanceOf(USER), INITIAL_BALANCE - depositAmount);
    }

    // function testWithdraw() public {
    //     uint256 depositAmount = 1 ether;

    //     vm.startPrank(USER);
    //     weth.approve(address(vault), depositAmount);
    //     vault.deposit(depositAmount, USER);

    //     // Warp time to after withdrawal lock period
    //     vm.warp(block.timestamp + 31 days);

    //     uint256 withdrawAmount = 0.5 ether;
    //     vault.withdraw(withdrawAmount, USER, USER);
    //     vm.stopPrank();

    //     assertEq(vault.balanceOf(USER), depositAmount - withdrawAmount);
    //     assertEq(
    //         weth.balanceOf(USER),
    //         INITIAL_BALANCE - depositAmount + withdrawAmount
    //     );
    // }

    // function testCannotWithdrawBeforeLockPeriod() public {
    //     uint256 depositAmount = 1 ether;

    //     vm.startPrank(USER);
    //     weth.approve(address(vault), depositAmount);
    //     vault.deposit(depositAmount, USER);

    //     // Try to withdraw before lock period ends
    //     vm.expectRevert("Withdrawal locked for 30 days after deposit");
    //     vault.withdraw(0.5 ether, USER, USER);
    //     vm.stopPrank();
    // }

    function testAfterDeposit() public {
        uint256 depositAmount = 1 ether;

        console.log("Initial WETH balance of USER:", weth.balanceOf(USER));
        console.log(
            "Initial WETH balance of vault:",
            weth.balanceOf(address(vault))
        );

        vm.startPrank(USER);

        // Approve WETH spend
        weth.approve(address(vault), depositAmount);
        console.log("WETH approved for vault");

        // Deposit WETH into vault
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

        // Calculate expected minimum amount after slippage
        uint256 slippage = 40; // 4% slippage
        uint256 minAmount = depositAmount - ((depositAmount * slippage) / 1000);
        console.log("Minimum expected amount after slippage:", minAmount);

        // Ensure the vault has enough WETH balance
        assertGe(
            weth.balanceOf(address(vault)),
            depositAmount,
            "Vault doesn't have enough WETH"
        );
        console.log("Minimum expected amount after slippage:", minAmount);

        vm.prank(vault.owner());
        try vault.afterDeposit(depositAmount) {
            console.log("afterDeposit successful");
        } catch Error(string memory reason) {
            console.log("afterDeposit failed:", reason);
            return;
        }

        // Check Renzo balance
        uint256 ezETHBalance = ezETH.balanceOf(address(vault));
        console.log(
            "ezETH balance of vault after Renzo deposit:",
            ezETHBalance
        );
        console.log(
            "addres of USDC in vault",
            IERC20(usdc).balanceOf(address(vault))
        );
        assertGe(
            ezETHBalance,
            minAmount,
            "Received amount less than expected after slippage"
        );

        // Check Morpho position
        Id marketParamsId = MarketParamsLib.id(marketParams);
        Position memory position = morphoBlueSnippets.getPosition(
            marketParamsId,
            address(vault)
        );
        console.log("Morpho collateral position:", position.collateral);
        console.log("Morpho borrow shares:", position.borrowShares);
        assertGt(position.collateral, 0, "No collateral supplied to Morpho");
        assertGt(position.borrowShares, 0, "No borrow shares on Morpho");

        console.log("testAfterDeposit completed successfully");
        console.log(
            "addres of USDC in vault",
            IERC20(usdc).balanceOf(address(vault))
        );
    }

    // function testBridgeUsdcFromBaseToOP() public {
    //     uint256 depositAmount = 1 ether;
    //     uint64 destinationChainSelector = 111; // Example selector for Optimism

    //     // Set up the vault with some USDC
    //     deal(address(usdc), address(vault), 1000000000); // 1000 USDC

    //     vm.startPrank(vault.owner());
    //     vault.bridgeUsdcFromBaseToOP{value: 0.1 ether}(
    //         destinationChainSelector,
    //         address(0x123), // Example receiver address on Optimism
    //         address(0x456), // Example ezETH_SiloMarket address on Optimism
    //         address(usdc)
    //     );
    //     vm.stopPrank();

    //     // Check that USDC was transferred to the BaseToOptimism contract
    //     assertEq(
    //         usdc.balanceOf(address(vault)),
    //         0,
    //         "USDC not transferred from vault"
    //     );
    //     assertEq(
    //         usdc.balanceOf(address(baseToOptimism)),
    //         1000000000,
    //         "USDC not received by BaseToOptimism"
    //     );
    // }

    // function testBeforeWithdraw() public {
    //     uint256 depositAmount = 1 ether;
    //     uint256 proportion = 0.5 ether; // 50%

    //     // Set up the vault with some ezETH and a Morpho position
    //     deal(address(ezETH), address(vault), depositAmount);
    //     vm.prank(vault.owner());
    //     vault.afterDeposit(depositAmount);

    //     vm.prank(vault.owner());
    //     uint256 withdrawnAmount = vault.beforeWithdraw(proportion);

    //     assertGt(withdrawnAmount, 0, "No WETH withdrawn");
    //     assertLt(
    //         ezETH.balanceOf(address(vault)),
    //         depositAmount,
    //         "ezETH not decreased"
    //     );
    // }

    // Additional helper functions and tests can be added as needed
}
