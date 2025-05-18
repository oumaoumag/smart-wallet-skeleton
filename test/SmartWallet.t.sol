// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SmartWallet, Paymaster} from "../src/Smart_Wallet.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

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
    SmartWallet wallet;
    Paymaster paymaster;
    MockContract mockContract;
    MockERC20 mockToken;
    
    address owner = address(0x1);
    address user = address(0x2);
    
    function setUp() public {
        // Fund the owner and user with ETH
        vm.deal(owner, 10 ether);
        vm.deal(user, 10 ether);
        
        // Deploy contracts
        wallet = new SmartWallet(owner);
        mockContract = new MockContract();
        mockToken = new MockERC20("Test Token", "TEST", 18);
        paymaster = new Paymaster(address(mockToken), 1e15); // 0.001 tokens per gas
        
        // Mint tokens to user
        mockToken.mint(user, 1000 * 10**18);
        
        // Approve tokens for paymaster
        vm.prank(user);
        mockToken.approve(address(paymaster), type(uint256).max);
    }
    
    function test_Constructor() public {
        assertEq(wallet.owner(), owner);
        assertEq(wallet.nonce(), 0);
    }
    
    function test_Execute() public {
        uint256 value = 123;
        bytes memory data = abi.encodeWithSelector(MockContract.setValue.selector, value);
        
        vm.prank(owner);
        wallet.execute(address(mockContract), 0, data);
        
        assertEq(mockContract.value(), value);
        assertEq(wallet.nonce(), 1);
    }
    
    function test_ExecuteWithValue() public {
        uint256 initialBalance = address(mockContract).balance;
        uint256 sendAmount = 1 ether;
        
        vm.prank(owner);
        vm.deal(address(wallet), sendAmount);
        wallet.execute(address(mockContract), sendAmount, "");
        
        assertEq(address(mockContract).balance, initialBalance + sendAmount);
        assertEq(wallet.nonce(), 1);
    }
    
    function test_ExecuteOnlyOwner() public {
        bytes memory data = abi.encodeWithSelector(MockContract.setValue.selector, 123);
        
        vm.prank(user); // Not the owner
        vm.expectRevert("Only Owner can execute");
        wallet.execute(address(mockContract), 0, data);
    }
    
    function test_ExecuteFailedCall() public {
        bytes memory data = abi.encodeWithSelector(MockContract.revertCall.selector);
        
        vm.prank(owner);
        vm.expectRevert("Call failed");
        wallet.execute(address(mockContract), 0, data);
    }
    
    function test_ExecuteBatch() public {
        address[] memory targets = new address[](2);
        uint256[] memory values = new uint256[](2);
        bytes[] memory callData = new bytes[](2);
        
        targets[0] = address(mockContract);
        values[0] = 0;
        callData[0] = abi.encodeWithSelector(MockContract.setValue.selector, 123);
        
        targets[1] = address(mockContract);
        values[1] = 0;
        callData[1] = abi.encodeWithSelector(MockContract.setValue.selector, 456);
        
        vm.prank(owner);
        wallet.executeBatch(targets, values, callData);
        
        // Only the last call's effect should remain
        assertEq(mockContract.value(), 456);
        assertEq(wallet.nonce(), 1);
    }
    
    function test_ExecuteBatchWithValues() public {
        uint256 initialBalance = address(mockContract).balance;
        uint256 sendAmount1 = 0.5 ether;
        uint256 sendAmount2 = 0.3 ether;
        
        address[] memory targets = new address[](2);
        uint256[] memory values = new uint256[](2);
        bytes[] memory callData = new bytes[](2);
        
        targets[0] = address(mockContract);
        values[0] = sendAmount1;
        callData[0] = "";
        
        targets[1] = address(mockContract);
        values[1] = sendAmount2;
        callData[1] = "";
        
        vm.prank(owner);
        vm.deal(address(wallet), sendAmount1 + sendAmount2);
        wallet.executeBatch(targets, values, callData);
        
        assertEq(address(mockContract).balance, initialBalance + sendAmount1 + sendAmount2);
        assertEq(wallet.nonce(), 1);
    }
    
    function test_ExecuteBatchArrayLengthMismatch() public {
        address[] memory targets = new address[](2);
        uint256[] memory values = new uint256[](1); // Mismatch
        bytes[] memory callData = new bytes[](2);
        
        vm.prank(owner);
        vm.expectRevert("Array lengths mismatch");
        wallet.executeBatch(targets, values, callData);
    }
    
    function test_ValidateUserOp() public {
        SmartWallet.UserOperation memory op = SmartWallet.UserOperation({
            to: address(mockContract),
            value: 0,
            data: abi.encodeWithSelector(MockContract.setValue.selector, 123),
            nonce: 0
        });
        
        bytes memory signature = hex"1234"; // Any non-empty signature
        
        bool isValid = wallet.validateUserOp(op, signature);
        assertTrue(isValid);
    }
    
    function test_ValidateUserOpInvalidNonce() public {
        SmartWallet.UserOperation memory op = SmartWallet.UserOperation({
            to: address(mockContract),
            value: 0,
            data: abi.encodeWithSelector(MockContract.setValue.selector, 123),
            nonce: 1 // Invalid nonce
        });
        
        bytes memory signature = hex"1234";
        
        bool isValid = wallet.validateUserOp(op, signature);
        assertFalse(isValid);
    }
    
    function test_ValidateUserOpEmptySignature() public {
        SmartWallet.UserOperation memory op = SmartWallet.UserOperation({
            to: address(mockContract),
            value: 0,
            data: abi.encodeWithSelector(MockContract.setValue.selector, 123),
            nonce: 0
        });
        
        bytes memory signature = ""; // Empty signature
        
        bool isValid = wallet.validateUserOp(op, signature);
        assertFalse(isValid);
    }
    
    function test_PaymasterSponsorGas() public {
        uint256 gasUsed = 100000;
        
        vm.expectEmit(true, true, true, true);
        emit Paymaster.GasSponsored(address(wallet), gasUsed);
        
        paymaster.sponsorGas(address(wallet), gasUsed);
    }
    
    function test_PaymasterSponsorGasWithERC20() public {
        uint256 gasUsed = 100000;
        uint256 expectedTokenAmount = gasUsed * paymaster.tokensPerGas();
        uint256 initialBalance = mockToken.balanceOf(user);
        
        vm.expectEmit(true, true, true, true);
        emit Paymaster.GasSponsored(address(wallet), gasUsed);
        
        vm.prank(user);
        paymaster.sponsorGasWithERC20(address(wallet), gasUsed, user);
        
        // Check token balances
        assertEq(mockToken.balanceOf(user), initialBalance - expectedTokenAmount);
        assertEq(mockToken.balanceOf(address(paymaster)), expectedTokenAmount);
    }
    
    function test_PaymasterSetTokensPerGas() public {
        uint256 newTokensPerGas = 2e15;
        
        paymaster.setTokensPerGas(newTokensPerGas);
        
        assertEq(paymaster.tokensPerGas(), newTokensPerGas);
    }
}
