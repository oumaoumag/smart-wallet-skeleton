// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SmartWallet} from "../src/Smart_Wallet.sol";

contract DeploySmartWallet is Script {
    function run() public {
        // Load the private key from the environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the smart wallet with the deployer as the owner
        address owner = vm.addr(deployerPrivateKey);
        SmartWallet wallet = new SmartWallet(owner);
        
        // Log the deployed address
        console.log("Smart Wallet deployed at:", address(wallet));
        console.log("Owner address:", owner);
        
        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}