// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// import {Test, console2} from "forge-std/Test.sol";
// import {BaseToOptimism} from "../src/ccip/baseToOptimism.sol";
// import {OptimismToBase} from "../src/ccip/OptimismToBase.sol";
// import {CCIPLocalSimulator, IRouterClient, LinkToken, BurnMintERC677Helper} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
// import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
// import {ISiloRouter} from "../src/interfaces/silo/ISiloRouter.sol";
// import {ISilo} from "../src/interfaces/silo/ISilo.sol";

// contract TokenDataTransferTest is Test {
//     BaseToOptimism public sender;
//     OptimismToBase public receiver;

//     uint64 chainSelector;
//     BurnMintERC677Helper ccipBnM;
//     address siloRouter;
//     LinkToken linkToken;

//     function setUp() public {
//         CCIPLocalSimulator ccipLocalSimulator = new CCIPLocalSimulator();
//         siloRouter = 0xC66D2a90c37c873872281a05445EC0e9e82c76a9;

//         (
//             uint64 chainSelector_,
//             IRouterClient sourceRouter_,
//             IRouterClient destinationRouter_,
//             ,
//             LinkToken linkToken_,
//             BurnMintERC677Helper ccipBnM_,
//         ) = ccipLocalSimulator.configuration();

//         chainSelector = chainSelector_;
//         ccipBnM = ccipBnM_;
//         linkToken = linkToken_;
//         address sourceRouter = address(sourceRouter_);
//         address destinationRouter = address(destinationRouter_);

//         sender = new BaseToOptimism(sourceRouter, address(linkToken));
//         receiver = new OptimismToBase(destinationRouter, address(linkToken), siloRouter);

//         sender.allowlistDestinationChain(chainSelector, true);
//         receiver.allowlistSourceChain(chainSelector, true);
//         receiver.allowlistSender(address(sender), true);
//     }

//     function testSendAndReceive() public {
//         ccipBnM.drip(address(sender)); // 1e18
//         assertEq(ccipBnM.totalSupply(), 1 ether);
//         linkToken.approve(address(sender), 1 ether);

//         address addressToSend = 0x12ee4BE944b993C81b6840e088bA1dCc57F07B1D;
//         uint256 amountToSend = 100;

//         bytes32 messageId = sender.sendMessagePayLINK(
//             chainSelector,
//             address(receiver),
//             addressToSend,
//             address(ccipBnM),
//             amountToSend
//         );
//         console2.logBytes32(messageId);

//         (
//             bytes32 receivedMessageId,
//             address receivedText,
//             address receivedTokenAddress,
//             uint256 receivedTokenAmount
//         ) = receiver.getLastReceivedMessageDetails();

//         assertEq(messageId, receivedMessageId);
//         assertEq(addressToSend, receivedText);
//         assertEq(amountToSend, receivedTokenAmount);

//         assertEq(ccipBnM.balanceOf(address(sender)), 1 ether - amountToSend);
//         assertEq(ccipBnM.balanceOf(address(receiver)), amountToSend);
//         assertEq(ccipBnM.totalSupply(), 1 ether);
//     }

//     function testSendAndReceiveWithNativeFees() public {
//         ccipBnM.drip(address(sender)); // 1e18
//         assertEq(ccipBnM.totalSupply(), 1 ether);
//         linkToken.approve(address(sender), 1 ether);

//         address addressToSend = 0x12ee4BE944b993C81b6840e088bA1dCc57F07B1D;
//         uint256 amountToSend = 100;

//         bytes32 messageId = sender.sendMessagePayNative{value: 0.1 ether}(
//             chainSelector,
//             address(receiver),
//             addressToSend,
//             address(ccipBnM),
//             amountToSend
//         );
//         console2.logBytes32(messageId);

//         (
//             bytes32 receivedMessageId,
//             address receivedText,
//             address receivedTokenAddress,
//             uint256 receivedTokenAmount
//         ) = receiver.getLastReceivedMessageDetails();

//         assertEq(messageId, receivedMessageId);
//         assertEq(addressToSend, receivedText);
//         assertEq(amountToSend, receivedTokenAmount);

//         assertEq(ccipBnM.balanceOf(address(sender)), 1 ether - amountToSend);
//         assertEq(ccipBnM.balanceOf(address(receiver)), amountToSend);
//         assertEq(ccipBnM.totalSupply(), 1 ether);
//     }

//     function testDepositToSilo() public {
//         ccipBnM.drip(address(sender)); // 1e18
//         assertEq(ccipBnM.totalSupply(), 1 ether);
//         linkToken.approve(address(sender), 1 ether);

//         address addressToSend = 0x12ee4BE944b993C81b6840e088bA1dCc57F07B1D;
//         uint256 amountToSend = 100;

//         bytes32 messageId = sender.sendMessagePayLINK(
//             chainSelector,
//             address(receiver),
//             addressToSend,
//             address(ccipBnM),
//             amountToSend
//         );
//         console2.logBytes32(messageId);

//         (
//             bytes32 receivedMessageId,
//             address receivedText,
//             address receivedTokenAddress,
//             uint256 receivedTokenAmount
//         ) = receiver.getLastReceivedMessageDetails();

//         assertEq(addressToSend, receivedText);
//         assertEq(amountToSend, receivedTokenAmount);

//         assertEq(ccipBnM.balanceOf(address(sender)), 1 ether - amountToSend);
//         assertEq(ccipBnM.balanceOf(address(receiver)), amountToSend);
//         assertEq(ccipBnM.totalSupply(), 1 ether);

//         // Verify the tokens were deposited into the Silo Market
//         uint256 siloBalance = IERC20(address(ccipBnM)).balanceOf(siloRouter);
//         assertEq(siloBalance, amountToSend);
//     }
// }