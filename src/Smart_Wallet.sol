// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// SmartWallet contract simulating basc features from EIP-4337
contract SmartWallet {
    address public owner; // Address of the wallet owner
    uint256 public nonce; // Nonce to prevent replay attacts

    // Struct to represent a UserOperation, simulating EIP-4337
    struct UserOperation {
        address to;     // Target address to call
        uint256 value;  // Changed from 'values' to 'value' to match test usage
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
        require(msg.sender == owner, "Only Owner can execute"); // Remove the extra space if it exists
        _call(to, value, data);
        nonce++;
    }

    // Execute multipe calls in one transaction (Bonus Feature)
    function executeBatch(address[] calldata to, uint256[] calldata value, bytes[] calldata data) external {
        require(msg.sender == owner, "Only Owner can execute");
        require(to.length == value.length && to.length == data.length, "Array lengths mismatch");
        for (uint i = 0; i < to.length; i++) {
            _call(to[i], value[i], data[i]); // Fixed: Added the data parameter
        }
        nonce++;    // Increment nonce once after batch execution
    }
    
    // Internal helper function to perform a call
    function _call(address to, uint256 value, bytes memory data) internal {
        (bool success, ) = to.call{value: value}(data);
        require(success, "Call failed");
    }

    // Simulate validation of a UserOperation as per EIP-4337
    function validateUserOp(UserOperation memory op, bytes memory signature) public view returns (bool) {
        if (op.nonce != nonce) {
            return false; // Ensure nonce matches to prevent replays
        }
        // Simulate signature validation: return true if signature exists
        // In a real implementation, this would verify the signature against the owner
        return signature.length > 0;
    }
}

// Paymaster contract to simulate gas sponsorship
contract Paymaster {
    // Event to log when gas is sponsored
    event GasSponsored(address indexed wallet, uint256 gasUsed);

    // Function to simulate sponsoring gas for a wallet
    function sponsorGas(address wallet, uint256 gasUsed) external {
        // In practice, this would check conditions (e.g., token balance) before sponsoring
        // Here, it simply logs the sponsorship event
        emit GasSponsored(wallet, gasUsed);
    }
}
