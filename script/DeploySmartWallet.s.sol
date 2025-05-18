// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SmartWallet, Paymaster} from "../src/Smart_Wallet.sol";

contract DeployContracts is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(deployerPrivateKey);
        
        // ERC20 token address for the Paymaster (replace with actual token address)
        address erc20Token = address(0x123...); // Example token address
        uint256 tokensPerGas = 1e15; // Example: 0.001 tokens per gas unit
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy SmartWallet
        SmartWallet wallet = new SmartWallet(owner);
        console.log("Smart Wallet deployed at:", address(wallet));
        
        // Deploy Paymaster
        Paymaster paymaster = new Paymaster(erc20Token, tokensPerGas);
        console.log("Paymaster deployed at:", address(paymaster));
        
        vm.stopBroadcast();
    }
}