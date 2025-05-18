// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SmartWallet} from "../src/Smart_Wallet.sol";

contract MockContract {
    uint256 public value;
    
    function setValue(uint256 _value) external payable {
        value = _value;
    }
    
    receive() external payable {}
}

contract SmartWalletTest is Test {
    SmartWallet public wallet;
    MockContract public mockContract;
    address owner = address(0x1);
    address nonOwner = address(0x2);

    function setUp() public {
        // Fund the owner with ETH
        vm.deal(owner, 10 ether);
        
        // Deploy contracts
        wallet = new SmartWallet(owner);
        mockContract = new MockContract();
    }

   
}