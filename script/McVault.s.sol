// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {McVault} from "../src/McVault.sol";
import {MorphoBlueSnippets} from "../src/morphoBlueSnippets.sol";
import {BaseToOptimism} from "../src/ccip/baseToOptimism.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployMcVault is Script {
    address constant MORPHO_ADDRESS =
        0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
    address constant RENZO_DEPOSIT_ADDRESS =
        0xf25484650484DE3d554fB0b7125e7696efA4ab99;
    address constant SWAP_ROUTER_ADDRESS =
        0x2626664c2603336E57B271c5C0b26F421741e481;
    address constant BASE_ROUTER = 0x881e3A65B4d4a04dD529061dd0071cf975F58bCD;
    address constant LINK_BASE = 0x88Fb150BDc53A65fe94Dea0c9BA0a6dAf8C6e196;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant EZETH = 0x2416092f143378750bb29b79eD961ab195CcEea5;
    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    uint64 OP_CHAINSELECTOR = 3734403246176062136;
    address constant OP_TO_BASE_CONTRACT_ADDRESS = ; // TO DO : CONTRACT ADDRESS AFTER DEPLOYMENT

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy MorphoBlueSnippets
        MorphoBlueSnippets morphoBlueSnippets = new MorphoBlueSnippets(
            MORPHO_ADDRESS
        );
        console.log(
            "MorphoBlueSnippets deployed at:",
            address(morphoBlueSnippets)
        );

        // Deploy BaseToOptimism
        BaseToOptimism baseToOptimism = new BaseToOptimism(
            BASE_ROUTER,
            LINK_BASE
        );
        console.log("BaseToOptimism deployed at:", address(baseToOptimism));

        baseToOptimism.allowlistSender(OP_TO_BASE_CONTRACT_ADDRESS, true);
        baseToOptimism.allowlistSourceChain(OP_CHAINSELECTOR, true);
        baseToOptimism.allowlistDestinationChain(OP_CHAINSELECTOR, true);




        // Deploy McVault
        McVault vault = new McVault(
            address(morphoBlueSnippets),
            SWAP_ROUTER_ADDRESS,
            RENZO_DEPOSIT_ADDRESS,
            address(baseToOptimism),
            IERC20(WETH),
            IERC20(EZETH),
            USDC
        );
        console.log("McVault deployed at:", address(vault));

        vm.stopBroadcast();
    }
}
