// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SmartWallet} from "../src/Smart_Wallet.sol";

contract DeploySmartWallet is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy SmartWallet
        SmartWallet wallet = new SmartWallet(owner);
        console.log("Smart Wallet deployed at:", address(wallet));
        
        vm.stopBroadcast();
    }
}
