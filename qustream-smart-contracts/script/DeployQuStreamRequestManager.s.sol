// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {QuStreamRequestManager} from "src/QuStreamRequestManager.sol";

/// @dev Deployment script for QuStreamRequestManager
contract DeployQuStreamRequestManager is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address contractOwner = vm.envAddress("CONTRACT_OWNER");
        address qustreamFeeOwner = vm.envAddress("QUSTREAM_FEE_OWNER");
        address encryptionNodeFeeOwner = vm.envAddress("ENCRYPTION_NODE_FEE_OWNER");
        address masterNode = vm.envAddress("MASTER_NODE");
        uint256 userFee = vm.envUint("USER_FEE");
        uint256 qustreamFeePercentage = vm.envUint("QUSTREAM_FEE_PERCENTAGE");

        vm.startBroadcast(deployerPrivateKey);

        new QuStreamRequestManager(
            contractOwner, qustreamFeeOwner, encryptionNodeFeeOwner, masterNode, userFee, qustreamFeePercentage
        );

        vm.stopBroadcast();
    }
}
