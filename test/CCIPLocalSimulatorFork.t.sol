// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {BurnMintERC677Helper, IERC20} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {BaseToOptimism} from "../src/ccip/baseToOptimism.sol";
import {OptimismToBase} from "../src/ccip/OptimismToBase.sol";

contract CCIPForkTest is Test {
    CCIPLocalSimulatorFork public ccipLocalSimulatorFork;

    IERC20 constant LINK_BASE = IERC20(0x88Fb150BDc53A65fe94Dea0c9BA0a6dAf8C6e196);
    IERC20 constant LINK_OP = IERC20(0x350a791Bfc2C21F9Ed5d10980Dad2e2638ffa7f6);

    IERC20 constant USDC_BASE = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);
    IERC20 constant USDC_OP = IERC20(0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85);

    // Getting USDC tokens
    address constant BASE_WHALE = 0x0B0A5886664376F59C351ba3f598C8A8B4D0A6f3;
    address constant OP_WHALE = 0xacD03D601e5bB1B275Bb94076fF46ED9D753435A;


    uint256 public sourceFork;
    uint256 public destinationFork;

    address public ezETH = 0x2416092f143378750bb29b79eD961ab195CcEea5;

    address public sender;
    address public receiver;

    address public siloAddress = 0x12ee4BE944b993C81b6840e088bA1dCc57F07B1D;
    address public siloRouter = 0xC66D2a90c37c873872281a05445EC0e9e82c76a9;

    IRouterClient public sourceRouter;
    IRouterClient public destinationRouter;

    uint64 public sourceChainSelector;
    uint64 public destinationChainSelector;

    BaseToOptimism public senderContract;
    OptimismToBase public receiverContract;

    IERC20 public sourceLinkToken;

    function setUp() public {
        console.log("Starting setUp()");

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));

        console.log("Setting up SOURCE CHAIN (BASE)");
        string memory SOURCE_RPC_URL = vm.envString("BASE_RPC_URL");
        sourceFork = vm.createSelectFork(SOURCE_RPC_URL);
        console.log("Source fork ID:", sourceFork);
        sender = makeAddr("sender");

        Register.NetworkDetails memory sourceNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        console.log("Source chain ID:", block.chainid);

        sourceLinkToken = IERC20(sourceNetworkDetails.linkAddress);
        sourceRouter = IRouterClient(sourceNetworkDetails.routerAddress);
        sourceChainSelector = sourceNetworkDetails.chainSelector;

        console.log("Creating BaseToOptimism contract");
        senderContract = new BaseToOptimism(address(sourceRouter), address(LINK_BASE));
        console.log("BaseToOptimism contract created at:", address(senderContract));

        console.log("Dealing USDC to sender on BASE");
        deal(address(USDC_BASE), sender, 10000 * 10**6);
        console.log("Sender USDC balance:", USDC_BASE.balanceOf(sender));
        deal(sender, 100 ether);

        console.log("Setting up DESTINATION CHAIN (OPTIMISM)");
        string memory DESTINATION_RPC_URL = vm.envString("OPTIMISM_RPC_URL");
        destinationFork = vm.createSelectFork(DESTINATION_RPC_URL);
        console.log("Destination fork ID:", destinationFork);
        receiver = makeAddr("receiver");

        Register.NetworkDetails memory destinationNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        console.log("Destination chain ID:", block.chainid);

        destinationRouter = IRouterClient(destinationNetworkDetails.routerAddress);
        destinationChainSelector = destinationNetworkDetails.chainSelector;

        console.log("Creating OptimismToBase contract");
        receiverContract = new OptimismToBase(address(destinationRouter), address(LINK_OP), siloRouter);
        console.log("OptimismToBase contract created at:", address(receiverContract));

        console.log("Dealing USDC to receiver on OPTIMISM");
        deal(address(USDC_OP), receiver, 10000 * 10**6);
        console.log("Receiver USDC balance:", USDC_OP.balanceOf(receiver));
        deal(receiver, 100 ether);

        console.log("Performing allowlisting");
        vm.selectFork(sourceFork);
        senderContract.allowlistDestinationChain(destinationChainSelector, true);
        vm.selectFork(destinationFork);
        receiverContract.allowlistSourceChain(sourceChainSelector, true);
        receiverContract.allowlistSender(address(senderContract), true);

        console.log("setUp() completed");
    }

    function test_PayFeesInNative() external {
        console.log("Starting test_PayFeesInNative()");

        vm.selectFork(destinationFork);
        uint256 balanceOfReceiverBefore = USDC_OP.balanceOf(receiver);
        console.log("Initial receiver USDC balance on Optimism:", balanceOfReceiverBefore);

        vm.selectFork(sourceFork);
        vm.startPrank(sender);

        uint256 balanceOfSenderBefore = USDC_BASE.balanceOf(sender);
        console.log("Initial sender USDC balance on Base:", balanceOfSenderBefore);

        uint256 amountToSend = 100 * 10**6;
        console.log("Amount to send:", amountToSend);

        console.log("Approving USDC spend");
        (USDC_BASE).approve(address(senderContract), amountToSend);

        uint256 estimatedFees = senderContract.getEstimatedFees(
            destinationChainSelector, 
            address(receiverContract), 
            ezETH, 
            address(USDC_BASE), 
            amountToSend
        );
        
        console.log("Sending message and paying native fees");
        senderContract.sendMessagePayNative{value : estimatedFees}(
            destinationChainSelector, 
            address(receiverContract), 
            ezETH, 
            address(USDC_BASE), 
            amountToSend
        );

        vm.stopPrank();

        uint256 balanceOfSenderAfter = USDC_BASE.balanceOf(sender);
        console.log("Sender USDC balance after sending:", balanceOfSenderAfter);
        assertEq(balanceOfSenderAfter, balanceOfSenderBefore - amountToSend);

        console.log("Switching chain and routing message");
        ccipLocalSimulatorFork.switchChainAndRouteMessage(destinationFork);

        uint256 balanceOfReceiverAfter = USDC_OP.balanceOf(receiver);
        console.log("Receiver USDC balance after receiving:", balanceOfReceiverAfter);
        assertEq(balanceOfReceiverAfter, balanceOfReceiverBefore + amountToSend);

        console.log("test_PayFeesInNative() completed");
    }
}

//     function test_transferTokensFromEoaToEoaPayFeesInNative() external {
//         (
//             Client.EVMTokenAmount[] memory tokensToSendDetails,
//             uint256 amountToSend
//         ) = prepareScenario();
//         vm.selectFork(destinationFork);
//         uint256 balanceOfReceiverBefore = USDC_OP.balanceOf(receiver);

//         vm.selectFork(sourceFork);
//         uint256 balanceOfSenderBefore = USDC_BASE.balanceOf(sender);

//         vm.startPrank(sender);
//         deal(sender, 5 ether);

//         Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
//             receiver: abi.encode(receiver),
//             data: abi.encode(""),
//             tokenAmounts: tokensToSendDetails,
//             extraArgs: Client._argsToBytes(
//                 Client.EVMExtraArgsV1({gasLimit: 0})
//             ),
//             feeToken: address(0)
//         });

//         uint256 fees = sourceRouter.getFee(destinationChainSelector, message);
//         sourceRouter.ccipSend{value: fees}(destinationChainSelector, message);
//         vm.stopPrank();

//         uint256 balanceOfSenderAfter = USDC_BASE.balanceOf(sender);
//         assertEq(balanceOfSenderAfter, balanceOfSenderBefore - amountToSend);

//         ccipLocalSimulatorFork.switchChainAndRouteMessage(destinationFork);
//         uint256 balanceOfReceiverAfter = USDC_OP.balanceOf(receiver);
//         assertEq(balanceOfReceiverAfter, balanceOfReceiverBefore + amountToSend);
//     }
