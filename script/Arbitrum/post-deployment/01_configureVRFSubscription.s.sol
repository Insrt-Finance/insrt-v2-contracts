// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import { VRFCoordinatorV2Interface } from "@chainlink/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import { LinkTokenInterface } from "@chainlink/shared/interfaces/LinkTokenInterface.sol";

import { IPerpetualMint } from "../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";

/// @title ConfigureVRFSubscriptionArb
/// @dev configures the VRF subscription by creating a subscription, adding the PerpetualMint contract as a consumer,
/// and optionally funding the subscription with LINK tokens
contract ConfigureVRFSubscriptionArb is Script {
    /// @dev runs the script logic
    function run() external {
        // read $LINK token address
        address linkTokenAddress = vm.envAddress("LINK_TOKEN");

        // read new owner address
        address newOwner = vm.envAddress("NEW_VRF_OWNER");

        // get PerpetualMint address
        address perpetualMint = readCoreAddress();

        // get set Chainlink VRF Coordinator address
        address vrfCoordinator = readVRFCoordinatorAddress();

        uint256 envLinkAmountToFundSubscription = vm.envUint(
            "LINK_FUND_AMOUNT"
        );

        uint96 envVRFSubscriptionBalanceThreshold = uint96(
            vm.envUint("VRF_SUBSCRIPTION_BALANCE_THRESHOLD")
        );

        // scale LINK amount to fund subscription by 1e18
        uint256 linkAmountToFundSubscription = envLinkAmountToFundSubscription *
            1 ether;

        // scale VRF subscription balance threshold by 1e18
        uint96 vrfSubscriptionBalanceThreshold = envVRFSubscriptionBalanceThreshold *
                1 ether;

        // read deployer private key
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");

        LinkTokenInterface linkToken = LinkTokenInterface(linkTokenAddress);

        VRFCoordinatorV2Interface vrfCoordinatorV2 = VRFCoordinatorV2Interface(
            vrfCoordinator
        );

        vm.startBroadcast(deployerPrivateKey);

        uint64 subscriptionId = vrfCoordinatorV2.createSubscription();

        vrfCoordinatorV2.addConsumer(subscriptionId, perpetualMint);

        if (linkAmountToFundSubscription > 0) {
            linkToken.transferAndCall(
                vrfCoordinator,
                linkAmountToFundSubscription,
                abi.encode(subscriptionId)
            );
        }

        IPerpetualMint(perpetualMint).setVRFSubscriptionBalanceThreshold(
            vrfSubscriptionBalanceThreshold
        );

        vrfCoordinatorV2.requestSubscriptionOwnerTransfer(
            subscriptionId,
            newOwner
        );

        console.log("VRF Coordinator Address: ", vrfCoordinator);
        console.log("VRF Consumer Added: ", perpetualMint);
        console.log("VRF Subscription ID: ", subscriptionId);
        console.log(
            "VRF Subscription Funded: %s.%s LINK",
            envLinkAmountToFundSubscription,
            linkAmountToFundSubscription % 1e18
        );
        console.log(
            "VRF Subscription Balance Threshold Set: %s.%s LINK",
            envVRFSubscriptionBalanceThreshold,
            vrfSubscriptionBalanceThreshold % 1e18
        );
        console.log(
            "VRF Subscription Owner Transfer Requested To New Owner: ",
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

    /// @notice attempts to read the saved address of the VRF Coordinator contract, post-deployment
    /// @return vrfCoordinatorAddress address of the deployed VRF Coordinator contract
    function readVRFCoordinatorAddress()
        internal
        view
        returns (address vrfCoordinatorAddress)
    {
        string memory inputDir = string.concat(
            vm.projectRoot(),
            "/broadcast/01_deployPerpetualMint.s.sol/"
        );

        string memory chainDir = string.concat(vm.toString(block.chainid), "/");

        string memory file = string.concat(
            "run-latest-vrf-coordinator-address",
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
            "/broadcast/01_configureVRFSubscription.s.sol/"
        );

        string memory chainDir = string.concat(vm.toString(block.chainid), "/");

        string memory file = string.concat(
            "run-latest-vrf-subscription-id",
            ".txt"
        );

        vm.writeFile(
            string.concat(inputDir, chainDir, file),
            vm.toString(subscriptionId)
        );
    }
}
