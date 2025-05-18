// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SmartWallet} from "../src/Smart_Wallet.sol";

contract MockContract {
    uint256 public value;
    
    function setValue(uint256 _value) external payable {
        value = _value;
    }
    
    function revertCall() external pure {
        revert("Mock revert");
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

    // Test the constructor
    function test_Constructor() public {
        assertEq(wallet.owner(), owner);
        assertEq(wallet.nonce(), 0);
    }

    // Test execute function
    function test_Execute() public {
        bytes memory callData = abi.encodeWithSelector(MockContract.setValue.selector, 42);
        vm.deal(address(wallet), 1 ether);
        
        vm.prank(owner);
        wallet.execute(address(mockContract), 0.1 ether, callData);
        
        assertEq(mockContract.value(), 42);
        assertEq(address(mockContract).balance, 0.1 ether);
        assertEq(wallet.nonce(), 1);
    }
    
    // Test execute with zero value
    function test_ExecuteZeroValue() public {
        bytes memory callData = abi.encodeWithSelector(MockContract.setValue.selector, 42);
        
        vm.prank(owner);
        wallet.execute(address(mockContract), 0, callData);
        
        assertEq(mockContract.value(), 42);
        assertEq(address(mockContract).balance, 0);
        assertEq(wallet.nonce(), 1);
    }
    
    // Test execute revert for non-owner
    function test_ExecuteRevertNonOwner() public {
        bytes memory callData = abi.encodeWithSelector(MockContract.setValue.selector, 42);
        
        vm.prank(nonOwner);
        vm.expectRevert("Only Owner can execute");
        wallet.execute(address(mockContract), 0.1 ether, callData);
    }
    
    // Test execute revert for insufficient funds
    function test_ExecuteRevertInsufficientFunds() public {
        bytes memory callData = abi.encodeWithSelector(MockContract.setValue.selector, 42);
        
        vm.prank(owner);
        vm.expectRevert("Call failed");
        wallet.execute(address(mockContract), 0.1 ether, callData);
    }
    
    // Test executeBatch function
    function test_ExecuteBatch() public {
        MockContract mockContract2 = new MockContract();
        
        address[] memory targets = new address[](2);
        targets[0] = address(mockContract);
        targets[1] = address(mockContract2);
        
        uint256[] memory values = new uint256[](2);
        values[0] = 0.1 ether;
        values[1] = 0.2 ether;
        
        bytes[] memory callData = new bytes[](2);
        callData[0] = abi.encodeWithSelector(MockContract.setValue.selector, 42);
        callData[1] = abi.encodeWithSelector(MockContract.setValue.selector, 84);
        
        vm.deal(address(wallet), 1 ether);
        
        vm.prank(owner);
        wallet.executeBatch(targets, values, callData);
        
        assertEq(mockContract.value(), 42);
        assertEq(mockContract2.value(), 84);
        assertEq(address(mockContract).balance, 0.1 ether);
        assertEq(address(mockContract2).balance, 0.2 ether);
        assertEq(wallet.nonce(), 1);
    }
    
    // Test executeBatch with empty batch
    function test_ExecuteBatchEmpty() public {
        address[] memory targets = new address[](0);
        uint256[] memory values = new uint256[](0);
        bytes[] memory callData = new bytes[](0);
        
        vm.prank(owner);
        wallet.executeBatch(targets, values, callData);
        
        assertEq(wallet.nonce(), 1);
    }
    
    // Test executeBatch revert for non-owner
    function test_ExecuteBatchRevertNonOwner() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory callData = new bytes[](1);
        
        vm.prank(nonOwner);
        vm.expectRevert("Only Owner can execute");
        wallet.executeBatch(targets, values, callData);
    }
    
    // Test executeBatch revert for array length mismatch
    function test_ExecuteBatchRevertArrayMismatch() public {
        address[] memory targets = new address[](2);
        uint256[] memory values = new uint256[](1);
        bytes[] memory callData = new bytes[](2);
        
        vm.prank(owner);
        vm.expectRevert("Array lengths mismatch");
        wallet.executeBatch(targets, values, callData);
    }
    
    // Test executeBatch with failing call
    function test_ExecuteBatchWithFailingCall() public {
        address[] memory targets = new address[](2);
        targets[0] = address(mockContract);
        targets[1] = address(mockContract);
        
        uint256[] memory values = new uint256[](2);
        values[0] = 0;
        values[1] = 0;
        
        bytes[] memory callData = new bytes[](2);
        callData[0] = abi.encodeWithSelector(MockContract.setValue.selector, 42);
        callData[1] = abi.encodeWithSelector(MockContract.revertCall.selector);
        
        vm.deal(address(wallet), 1 ether);
        
        vm.prank(owner);
        vm.expectRevert("Call failed");
        wallet.executeBatch(targets, values, callData);
        
        assertEq(wallet.nonce(), 0);
    }
    
    // Test validateUserOp function
    function test_ValidateUserOp() public {
        SmartWallet.UserOperation memory op = SmartWallet.UserOperation({
            to: address(mockContract),
            value: 0,
            data: abi.encodeWithSelector(MockContract.setValue.selector, 42),
            nonce: 0
        });
        
        bytes memory signature = abi.encodePacked("signature");
        
        bool isValid = wallet.validateUserOp(op, signature);
        assertTrue(isValid);
    }
    
    // Test validateUserOp with incorrect nonce
    function test_ValidateUserOpIncorrectNonce() public {
        SmartWallet.UserOperation memory op = SmartWallet.UserOperation({
            to: address(mockContract),
            value: 0,
            data: abi.encodeWithSelector(MockContract.setValue.selector, 42),
            nonce: 1
        });
        
        bytes memory signature = abi.encodePacked("signature");
        
        bool isValid = wallet.validateUserOp(op, signature);
        assertFalse(isValid);
    }
    
    // Test validateUserOp with no signature
    function test_ValidateUserOpNoSignature() public {
        SmartWallet.UserOperation memory op = SmartWallet.UserOperation({
            to: address(mockContract),
            value: 0,
            data: abi.encodeWithSelector(MockContract.setValue.selector, 42),
            nonce: 0
        });
        
        bytes memory signature = "";
        
        bool isValid = wallet.validateUserOp(op, signature);
        assertFalse(isValid);
    }
}