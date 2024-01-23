// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import { InsrtVRFCoordinator } from "../../../contracts/vrf/Insrt/InsrtVRFCoordinator.sol";

/// @title DeployInsrtVRFCoordinator
/// @dev deploys the InsrtVRFCoordinator contract
contract DeployInsrtVRFCoordinator is Script {
    /// @dev runs the script logic
    function run() external {
        // read deployer private key
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // deploy the Insrt VRF Coordinator
        InsrtVRFCoordinator insrtVrfCoordinator = new InsrtVRFCoordinator();

        console.log(
            "Insrt VRF Coordinator Address: ",
            address(insrtVrfCoordinator)
        );

        writeInsrtVRFCoordinatorAddress(address(insrtVrfCoordinator));

        vm.stopBroadcast();
    }

    /// @notice writes the address of the deployed VRF Coordinator contract
    /// @param insrtVrfCoordinatorAddress address of the deployed VRF Coordinator
    function writeInsrtVRFCoordinatorAddress(
        address insrtVrfCoordinatorAddress
    ) internal {
        string memory inputDir = string.concat(
            vm.projectRoot(),
            "/broadcast/01_deployInsrtVRFCoordinator.s.sol/"
        );

        string memory chainDir = string.concat(vm.toString(block.chainid), "/");

        string memory file = string.concat(
            "run-latest-insrt-vrf-coordinator-address",
            ".txt"
        );

        vm.writeFile(
            string.concat(inputDir, chainDir, file),
            vm.toString(insrtVrfCoordinatorAddress)
        );
    }
}
