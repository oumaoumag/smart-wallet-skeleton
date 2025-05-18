// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
        require(msg.sender == owner, "Only Owner can execute"); 
        _call(to, value, data);
        nonce++;
    }

    // Execute multipe calls in one transaction (Bonus Feature)
    function executeBatch(address[] calldata to, uint256[] calldata value, bytes[] calldata data) external {
        require(msg.sender == owner, "Only Owner can execute");
        require(to.length == value.length && to.length == data.length, "Array lengths mismatch");
        for (uint i = 0; i < to.length; i++) {
            _call(to[i], value[i], data[i]); 
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

// Paymaster contract to simulate gas sponsorship with ERC20 token support
contract Paymaster {
    // Event to log when gas is sponsored
    event GasSponsored(address indexed wallet, uint256 gasUsed);
    
    IERC20 public erc20Token;
    uint256 public tokensPerGas;

    constructor(address _erc20Token, uint256 _tokensPerGas) {
        erc20Token = IERC20(_erc20Token);
        tokensPerGas = _tokensPerGas; // e.g., 10^18 tokens per gas unit
    }

    // Optional: Function to update tokensPerGas if needed
    function setTokensPerGas(uint256 _tokensPerGas) external {
        tokensPerGas = _tokensPerGas;
    }

    // Function to sponsor gas for a wallet using ETH
    function sponsorGas(address wallet, uint256 gasUsed) external {
        // In practice, this would check conditions before sponsoring
        // Here, it simply logs the sponsorship event
        emit GasSponsored(wallet, gasUsed);
    }
    
    // Function to sponsor gas for a wallet using ERC20 tokens (Bonus Feature)
    function sponsorGasWithERC20(address wallet, uint256 gasUsed, address payer) external {
        uint256 tokenAmount = gasUsed * tokensPerGas;
        
        // Transfer tokens from payer to this contract
        require(erc20Token.transferFrom(payer, address(this), tokenAmount), 
                "Token transfer failed");
        
        // Log the sponsorship
        emit GasSponsored(wallet, gasUsed);
    }
}
