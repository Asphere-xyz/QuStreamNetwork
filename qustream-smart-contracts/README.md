# QuStream Smart Contracts

This repository contains the core smart contracts for the QuStream protocol, including:

- **QuStreamRequestManager**: Manages encryption requests.

We use [Hardhat](https://hardhat.org/) for development, testing, and deployment.

## Usage

### Install dependencies

```shell
npm install
```

### Running Tests

To run all the tests in the project, execute the following command:

```shell
npx hardhat test --coverage
```

### Deploying the contract

#### 1. Set your funded deployer private key to the `PRIVATE_KEY` config variable using `hardhat-keystore`.

- Once you execute the command below you will be prompted to set a keystore password and then to enter your private key.

```shell
npx hardhat keystore set PRIVATE_KEY
```

#### 2. Adjust contract constructor parameters in [./ignition/modules/QuStreamRequestManager.parameters.json](./ignition/modules/QuStreamRequestManager.parameters.json).

| Name                       | Type    | Description |
|----------------------------|---------|-------------|
| `CONTRACT_OWNER`           | address | The owner of the contract. Has permission to update master node. |
| `MASTER_NODE`              | address | Address allowed to process and update requests. Must not be zero address. |

#### 3. Execute the deployment script.

- Specify the network using the `--network` flag. `qustreamLocalnet` for local zombienet deployment, `qustreamTestnet` for testnet deployment and `qustreamMainnet` for mainnet deployment.
- Optionally use `--reset` flag if you want to redeploy the contract after successful initial deployment. Hardhat Ignition stores deployment data in `./ignition/deployments` and without passing the flag the tool finds an existing deployment and does not redeploy the contract, instead it returns the existing contract address.

```shell
npx hardhat ignition deploy ./ignition/modules/QuStreamRequestManager.ts  --network qustreamLocalnet --parameters ./ignition/modules/QuStreamRequestManager.parameters.json
```
