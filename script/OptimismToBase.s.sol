// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {OptimismToBase} from "../src/ccip/optimismToBase.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployOpToBase is Script {
    address constant OP_ROUTER = 0x3206695CaE29952f4b0c22a169725a865bc8Ce0f;
    address constant LINK_OP = 0x350a791Bfc2C21F9Ed5d10980Dad2e2638ffa7f6;
    address constant SILOROUTER = 0xC66D2a90c37c873872281a05445EC0e9e82c76a9;
    address constant USDC = 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85;

    address constant BASE_TO_OP_CONTRACT_ADDRESS = 0xef28Bed882f93EF9d97CD13e9AD2174C360Afbfd;
    uint64 constant BASE_CHAINSELECTOR = 15971525489660198786;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy OptimismToBase Contract
        OptimismToBase opToBase = new OptimismToBase(
            OP_ROUTER,
            LINK_OP,
            SILOROUTER
        );

        console.log(
            "OptimismToBase deployed at:",
            address(opToBase)
        );

        opToBase.allowlistSender(BASE_TO_OP_CONTRACT_ADDRESS, true);
        opToBase.allowlistSourceChain(BASE_CHAINSELECTOR, true);
        opToBase.allowlistDestinationChain(BASE_CHAINSELECTOR, true);

        console.log("Sender allowed... ? ", opToBase.allowlistedSenders(BASE_TO_OP_CONTRACT_ADDRESS));
        console.log("SourceChain allowed... ? ", opToBase.allowlistedSourceChains(BASE_CHAINSELECTOR));
        console.log("DestinationChain allowed... ? ", opToBase.allowlistedDestinationChains(BASE_CHAINSELECTOR));
        
        vm.stopBroadcast();
    }
}
