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
    
    function test_ExecuteRevertNonOwner() public {
        bytes memory callData = abi.encodeWithSelector(MockContract.setValue.selector, 42);
        
        // Try to execute as non-owner
        vm.prank(nonOwner);
        vm.expectRevert("Only Owner can execute");
        wallet.execute(address(mockContract), 0.1 ether, callData);
    }
    
    function test_ExecuteBatch() public {
        // Create a second mock contract
        MockContract mockContract2 = new MockContract();
        
        // Prepare arrays for batch execution
        address[] memory targets = new address[](2);
        targets[0] = address(mockContract);
        targets[1] = address(mockContract2);
        
        uint256[] memory values = new uint256[](2);
        values[0] = 0.1 ether;
        values[1] = 0.2 ether;
        
        bytes[] memory callData = new bytes[](2);
        callData[0] = abi.encodeWithSelector(MockContract.setValue.selector, 42);
        callData[1] = abi.encodeWithSelector(MockContract.setValue.selector, 84);
        
        // Fund the wallet
        vm.deal(address(wallet), 1 ether);
        
        // Execute batch as owner
        vm.prank(owner);
        wallet.executeBatch(targets, values, callData);
        
        // Verify results
        assertEq(mockContract.value(), 42);
        assertEq(mockContract2.value(), 84);
        assertEq(address(mockContract).balance, 0.1 ether);
        assertEq(address(mockContract2).balance, 0.2 ether);
        assertEq(wallet.nonce(), 1);
    }
    
   
}