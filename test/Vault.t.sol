// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Vault, MarketParams} from "../src/Vault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VaultTest is Test {
    Vault public vault;
    uint256 amount;
    address USER = vm.envAddress("USER");
    address USDC = vm.envAddress("USDC");
    type Id is bytes32;
    bytes32 constant MARKET_ID =
        0x28c028a1af0fa01da5b9c46bb8d999e3e8e65b8304edc09fd8cbaef03a64cb35;

    function setUp() public {
        vault = new Vault(0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb);
        amount = 1000000000;
    }

    MarketParams public marketParams;

    function testSupply() public {
        vm.startPrank(USER);

        // bytes32 id = stringToBytes32(
        //     "0x28c028a1af0fa01da5b9c46bb8d999e3e8e65b8304edc09fd8cbaef03a64cb35"
        // );
        // Deal USDC tokens to USER
        deal(USDC, USER, amount);

        // Approve the Vault contract to spend USDC on behalf of USER
        IERC20(USDC).approve(address(vault), amount);
        // Define MarketParams
        // (
        //     address loanToken,
        //     address collateralToken,
        //     address oracle,
        //     address irm,
        //     uint256 lltv
        // ) = vault.idToParams(Id id);
        marketParams = MarketParams(
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            0xbf5495Efe5DB9ce00f80364C8B423567e58d2110,
            0x895f9dF47F8a68396eD026978A0771C120DFC279,
            0x870aC11D48B15DB9a138Cf899d20F13F79Ba00BC,
            770000000000000000
        );
        // Call depositOnMorpho with appropriate parameters
        vault.depositOnMorpho(marketParams, amount, 0, USER, hex"");

        vm.stopPrank();
    }
}
