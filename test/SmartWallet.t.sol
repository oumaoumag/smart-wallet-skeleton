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

    function test_Execute() public {
        // Prepare call data for the mock contract
        bytes memory callData = abi.encodeWithSelector(MockContract.setValue.selector, 42);
        
        // Fund the wallet
        vm.deal(address(wallet), 1 ether);
        
        // Execute as owner
        vm.prank(owner);
        wallet.execute(address(mockContract), 0.1 ether, callData);
        
        // Verify results
        assertEq(mockContract.value(), 42);
        assertEq(address(mockContract).balance, 0.1 ether);
        assertEq(wallet.nonce(), 1);
    }
   
}