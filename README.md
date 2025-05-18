# Smart Wallet Skeleton

A minimal smart contract wallet implementation built with Foundry.

## Overview

This project implements a basic smart contract wallet with the following features:
- Owner-based access control
- Single and batch transaction execution
- ERC-4337 compatible UserOperation validation
- Nonce management for replay protection
- Gas sponsorship via Paymaster contract
- ERC20 token-based gas payments

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Solidity ^0.8.13

## Installation

```shell
# Clone the repository
git clone https://github.com/oumaoumag/smart-wallet-skeleton.git
cd smart-wallet-skeleton

# Install dependencies
forge install
forge install OpenZeppelin/openzeppelin-contracts
```

## Build

```shell
forge build
```

## Test

```shell
# Run all tests
forge test

# Run tests with more verbose output
forge test -vvv

# Run tests with gas reporting
forge test --gas-report
```

## Deployment

1. Set up your environment variables in a `.env` file:
```
RPC_URL=https://rpc.sepolia-api.lisk.com
PRIVATE_KEY=your_private_key_here
```

2. Deploy the contracts:
```shell
source .env
forge script script/DeploySmartWallet.s.sol:DeploySmartWallet --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

# To deploy both SmartWallet and Paymaster contracts:
forge script script/DeployContracts.s.sol:DeployContracts --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

## Contract Usage

### Execute a Single Transaction

```solidity
// Execute a transaction to a target contract
wallet.execute(targetAddress, value, callData);
```

### Execute Multiple Transactions

```solidity
// Execute multiple transactions in a single call
address[] memory targets = new address[](2);
uint256[] memory values = new uint256[](2);
bytes[] memory callData = new bytes[](2);

// Set up transaction details
targets[0] = address1;
values[0] = 0.1 ether;
callData[0] = abi.encodeWithSelector(...);

targets[1] = address2;
values[1] = 0.2 ether;
callData[1] = abi.encodeWithSelector(...);

// Execute batch
wallet.executeBatch(targets, values, callData);
```

### ERC-4337 UserOperation Validation

The wallet supports ERC-4337 UserOperation validation for account abstraction:

```solidity
// Create a UserOperation
SmartWallet.UserOperation memory op = SmartWallet.UserOperation({
    to: targetAddress,
    value: amount,
    data: callData,
    nonce: currentNonce
});

// Sign the operation
bytes memory signature = signUserOp(op);

// Validate the operation
wallet.validateUserOp(op, signature);
```

### Gas Sponsorship with Paymaster

The Paymaster contract allows for gas sponsorship in both ETH and ERC20 tokens:

```solidity
// Sponsor gas with ETH
paymaster.sponsorGas(walletAddress, gasUsed);

// Sponsor gas with ERC20 tokens
paymaster.sponsorGasWithERC20(walletAddress, gasUsed, payerAddress);
```

## Deployed Contracts

- Lisk Sepolia Testnet:
  - SmartWallet: [0x350AECDbcaA3557bda602786b0D831655A53ec1D](https://sepolia-blockscout.lisk.com/address/0x350AECDbcaA3557bda602786b0D831655A53ec1D)
  - Paymaster: [0x1234567890123456789012345678901234567890](https://sepolia-blockscout.lisk.com/address/0x1234567890123456789012345678901234567890)
  - MockERC20: [0x0987654321098765432109876543210987654321](https://sepolia-blockscout.lisk.com/address/0x0987654321098765432109876543210987654321)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
