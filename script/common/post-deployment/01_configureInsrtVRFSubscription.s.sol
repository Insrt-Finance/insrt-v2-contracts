// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import { IPerpetualMint } from "../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";
import { IInsrtVRFCoordinator } from "../../../contracts/vrf/Insrt/IInsrtVRFCoordinator.sol";

/// @title ConfigureInsrtVRFSubscription
/// @dev configures the Insrt VRF subscription by adding the PerpetualMint contract as a consumer &
/// setting the VRF fulfiller address
contract ConfigureInsrtVRFSubscription is Script {
    /// @dev runs the script logic
    function run() external {
        // read VRF fulfiller address
        address fulfiller = vm.envAddress("VRF_FULFILLER");

        // read new owner address
        address newOwner = vm.envAddress("NEW_VRF_OWNER");

        // get PerpetualMint address
        address perpetualMint = readCoreAddress();

        // get set Insrt VRF Coordinator address
        address insrtVrfCoordinatorAddress = readInsrtVRFCoordinatorAddress();

        // read deployer private key
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");

        IInsrtVRFCoordinator insrtVrfCoordinator = IInsrtVRFCoordinator(
            insrtVrfCoordinatorAddress
        );

        vm.startBroadcast(deployerPrivateKey);

        // used later in the post-deployment process as part of the VRF Config for PerpetualMint
        uint64 subscriptionId = 1;

        insrtVrfCoordinator.addConsumer(subscriptionId, perpetualMint);

        insrtVrfCoordinator.addFulfiller(fulfiller);

        insrtVrfCoordinator.transferOwnership(newOwner);

        console.log(
            "Insrt VRF Coordinator Address: ",
            insrtVrfCoordinatorAddress
        );
        console.log("VRF Consumer Added: ", perpetualMint);
        console.log("VRF Subscription ID: ", subscriptionId);
        console.log(
            "Insrt VRF Coordinator Owner Transfer Requested To New Owner: ",
            newOwner
        );

        writeVRFSubscriptionId(subscriptionId);

        vm.stopBroadcast();
    }

    /// @notice attempts to read the saved address of the Core diamond contract, post-deployment
    /// @return coreAddress address of the deployed Core diamond contract
    function readCoreAddress() internal view returns (address coreAddress) {
        string memory inputDir = string.concat(
            vm.projectRoot(),
            "/broadcast/01_deployPerpetualMint.s.sol/"
        );

        string memory chainDir = string.concat(vm.toString(block.chainid), "/");

        string memory file = string.concat("run-latest-core-address", ".txt");

        return
            vm.parseAddress(
                vm.readFile(string.concat(inputDir, chainDir, file))
            );
    }

    /// @notice attempts to read the saved address of an Insrt VRF Coordinator contract, post-deployment
    /// @return insrtVrfCoordinatorAddress address of the deployed Insrt VRF Coordinator contract
    function readInsrtVRFCoordinatorAddress()
        internal
        view
        returns (address insrtVrfCoordinatorAddress)
    {
        string memory inputDir = string.concat(
            vm.projectRoot(),
            "/broadcast/01_deployInsrtVRFCoordinator.s.sol/"
        );

        string memory chainDir = string.concat(vm.toString(block.chainid), "/");

        string memory file = string.concat(
            "run-latest-insrt-vrf-coordinator-address",
            ".txt"
        );

        return
            vm.parseAddress(
                vm.readFile(string.concat(inputDir, chainDir, file))
            );
    }

    /// @notice writes the created VRF subscription ID to a file
    /// @param subscriptionId the created VRF subscription ID
    function writeVRFSubscriptionId(uint64 subscriptionId) internal {
        string memory inputDir = string.concat(
            vm.projectRoot(),
            "/broadcast/01_configureInsrtVRFSubscription.s.sol/"
        );

        string memory chainDir = string.concat(vm.toString(block.chainid), "/");

        string memory file = string.concat(
            "run-latest-insrt-vrf-subscription-id",
            ".txt"
        );

        vm.writeFile(
            string.concat(inputDir, chainDir, file),
            vm.toString(subscriptionId)
        );
    }
}
