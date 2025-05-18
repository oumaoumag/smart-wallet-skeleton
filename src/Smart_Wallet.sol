// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// SmartWallet contract implementing basic EIP-4337 functionality
contract SmartWallet {
    address public owner; // Address of the wallet owner
    uint256 public nonce; // Nonce to prevent replay attacts

    // UserOperation struct for EIP-4337 compatibility
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

    // Execute multiple transactions in a single call
    function executeBatch(address[] calldata to, uint256[] calldata value, bytes[] calldata data) external {
        require(msg.sender == owner, "Only Owner can execute");
        require(to.length == value.length && to.length == data.length, "Array lengths mismatch");
        for (uint i = 0; i < to.length; i++) {
            _call(to[i], value[i], data[i]); 
        }
        nonce++;    // Increment nonce once after batch execution
    }
    
    // Internal function to perform external calls
    function _call(address to, uint256 value, bytes memory data) internal {
        (bool success, ) = to.call{value: value}(data);
        require(success, "Call failed");
    }

    // Validate a UserOperation according to EIP-4337
    function validateUserOp(UserOperation memory op, bytes memory signature) public view returns (bool) {
        if (op.nonce != nonce) {
            return false; // Ensure nonce matches to prevent replays
        }
        // Simulate signature validation: return true if signature exists
        return signature.length > 0;
    }
}

// Paymaster contract for gas sponsorship
contract Paymaster {
    // Event to log when gas is sponsored
    event GasSponsored(address indexed wallet, uint256 gasUsed);
    
    IERC20 public erc20Token;
    uint256 public tokensPerGas;

    constructor(address _erc20Token, uint256 _tokensPerGas) {
        erc20Token = IERC20(_erc20Token);
        tokensPerGas = _tokensPerGas; // e.g., 10^18 tokens per gas unit
    }

    // Update the token-to-gas conversion rate
    function setTokensPerGas(uint256 _tokensPerGas) external {
        tokensPerGas = _tokensPerGas;
    }

    // Sponsor gas using ETH
    function sponsorGas(address wallet, uint256 gasUsed) external {
        emit GasSponsored(wallet, gasUsed);
    }
    
    // Sponsor gas using ERC20 tokens
    function sponsorGasWithERC20(address wallet, uint256 gasUsed, address payer) external {
        uint256 tokenAmount = gasUsed * tokensPerGas;
        
        // Transfer tokens from payer to this contract
        require(erc20Token.transferFrom(payer, address(this), tokenAmount), 
                "Token transfer failed");
        
        // Log the sponsorship
        emit GasSponsored(wallet, gasUsed);
    }
}
