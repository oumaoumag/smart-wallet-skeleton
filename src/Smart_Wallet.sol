// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// SmartWallet contract simulating basc features from EIP-4337
contract SmartWallet {
    address public owner; // Address of the wallet owner
    uint256 public nonce; // Nonce to prevent replay attacts

    // Struct to represent a UserOperation, simulating EIP-4337
    struct UserOperation {
        address to;     // Target address to call
        uint256 values; // ETH value to send
        bytes data;     // Calldata for the call
        uint256 nonce;  // Nonce for this operation
    }

    // Contructor sets the initial owner 
    constructor(address _owner) {
        owner = _owner;
        nonce = 0;
    }

    // Execute a single call to another contract or send ETH, restricted to owner
    function execute(address to, uint256 value, bytes calldata data) external {
        require(msg.sender == owner, "Only  Owner can execute");
        _call(to, value, data);     // Perform the call
        nonce++;                    // Increment nonce after successful execution
    }
    
}