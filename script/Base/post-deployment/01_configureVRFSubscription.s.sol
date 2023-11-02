// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-safe/BatchScript.sol";

import { IDepositContract } from "../../../contracts/facets/PerpetualMint/Base/IDepositContract.sol";
import { ISupraRouterContract } from "../../../contracts/facets/PerpetualMint/Base/ISupraRouterContract.sol";
import { IPerpetualMint } from "../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";

/// @title ConfigureVRFSubscriptionBase
/// @dev Configures the Supra VRF subscription by adding the PerpetualMint contract as a consumer,
/// and optionally funding the subscription in ETH via the Gnosis Safe Transaction Service API
contract ConfigureVRFSubscriptionBase is BatchScript {
    /// @dev runs the script logic
    function run() external {
        // get PerpetualMint address
        address perpetualMint = readCoreAddress();

        // get Gnosis Safe (protocol owner) address
        address gnosisSafeAddress = vm.envAddress("GNOSIS_SAFE");

        // get set Supra VRF Router address
        address vrfRouter = readVRFRouterAddress();

        uint256 envEthAmountToFundSubscription = vm.envUint("ETH_FUND_AMOUNT");

        // scale ETH amount to fund subscription by 1e18
        uint256 ethAmountToFundSubscription = envEthAmountToFundSubscription *
            1 ether;

        address supraVRFDepositContract = ISupraRouterContract(vrfRouter)
            ._depositContract();

        bytes memory addContractToWhitelistTx = abi.encodeWithSelector(
            IDepositContract.addContractToWhitelist.selector,
            perpetualMint
        );

        addToBatch(supraVRFDepositContract, addContractToWhitelistTx);

        if (ethAmountToFundSubscription > 0) {
            bytes memory depositFundClientTx = abi.encodeWithSelector(
                IDepositContract.depositFundClient.selector
            );

            addToBatch(
                supraVRFDepositContract,
                ethAmountToFundSubscription,
                depositFundClientTx
            );
        }

        executeBatch(gnosisSafeAddress, true);

        console2.log("Supra VRF Router Address: ", vrfRouter);
        console2.log("Supra VRF Consumer Added: ", perpetualMint);
        console2.log(
            "Supra VRF Subscription Funded: %s.%s ETH",
            envEthAmountToFundSubscription,
            ethAmountToFundSubscription % 1e18
        );
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
