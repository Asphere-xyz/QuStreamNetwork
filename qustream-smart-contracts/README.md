# QuStream Smart Contracts

This repository contains the core smart contracts for the QuStream protocol, including:

- **QuStreamRequestManager**: Manages encryption requests, withdrawal addresses and fee logic.

We use [Foundry](https://book.getfoundry.sh/) for development, testing, and deployment.

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

### Documentation

https://book.getfoundry.sh/

### Usage

#### Build

```shell
$ forge build
```

#### Test

```shell
$ forge test
```

#### Test Coverage

```shell
$ forge coverage --no-match-coverage "(script|test)"
```

#### Format

```shell
$ forge fmt
```


#### Deploy QuStreamRequestManager

1. Copy `.env.example` to `.env` and fill in your deployment values:

	- `PRIVATE_KEY` - private key for deployment (never commit this value)
	- `CONTRACT_OWNER` - address for contract ownership
	- `QUSTREAM_FEE_OWNER` - address to receive QuStream portion of the fees
	- `ENCRYPTION_NODE_FEE_OWNER` - address to receive encryption nodes portion of the fees
	- `MASTER_NODE` - address that is allowed to process requests
	- `USER_FEE` - User fee amount in wei
	- `QUSTREAM_FEE_PERCENTAGE` - Percentage of the user fee that goes to QuStream

2. Run deployment script:

	```shell
	forge script script/DeployQuStreamRequestManager.s.sol:DeployQuStreamRequestManager \
		--rpc-url <your_rpc_url> \
		--broadcast
	```

> **Note:** `.env.example` provides a template for required variables. Do not commit your real `.env` file with secrets, especially `PRIVATE_KEY`.