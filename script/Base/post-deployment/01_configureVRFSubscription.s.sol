// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import { IDepositContract } from "../../../contracts/facets/PerpetualMint/Base/IDepositContract.sol";
import { ISupraRouterContract } from "../../../contracts/facets/PerpetualMint/Base/ISupraRouterContract.sol";
import { IPerpetualMint } from "../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";

/// @title ConfigureVRFSubscriptionBase
/// @dev configures the Supra VRF subscription by adding the PerpetualMint contract as a consumer,
/// and optionally funding the subscription in ETH
contract ConfigureVRFSubscriptionBase is Script {
    /// @dev runs the script logic
    function run() external {
        // get PerpetualMint address
        address perpetualMint = readCoreAddress();

        // get set Supra VRF Router address
        address vrfRouter = readVRFRouterAddress();

        uint256 envEthAmountToFundSubscription = vm.envUint("ETH_FUND_AMOUNT");

        // scale ETH amount to fund subscription by 1e18
        uint256 ethAmountToFundSubscription = envEthAmountToFundSubscription *
            1 ether;

        // read deployer private key
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");

        IDepositContract supraVRFDepositContract = IDepositContract(
            ISupraRouterContract(vrfRouter)._depositContract()
        );

        vm.startBroadcast(deployerPrivateKey);

        supraVRFDepositContract.addContractToWhitelist(perpetualMint);

        if (ethAmountToFundSubscription > 0) {
            supraVRFDepositContract.depositFundClient{
                value: ethAmountToFundSubscription
            }();
        }

        console.log("Supra VRF Router Address: ", vrfRouter);
        console.log("Supra VRF Consumer Added: ", perpetualMint);
        console.log(
            "Supra VRF Subscription Funded: %s.%s ETH",
            envEthAmountToFundSubscription,
            ethAmountToFundSubscription % 1e18
        );

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

    /// @notice attempts to read the saved address of the Supra VRF Router contract, post-deployment
    /// @return vrfRouterAddress address of the deployed Supra VRF Router contract
    function readVRFRouterAddress()
        internal
        view
        returns (address vrfRouterAddress)
    {
        string memory inputDir = string.concat(
            vm.projectRoot(),
            "/broadcast/01_deployPerpetualMint.s.sol/"
        );

        string memory chainDir = string.concat(vm.toString(block.chainid), "/");

        string memory file = string.concat(
            "run-latest-vrf-router-address",
            ".txt"
        );

        return
            vm.parseAddress(
                vm.readFile(string.concat(inputDir, chainDir, file))
            );
    }
}
