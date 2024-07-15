// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Script, console2 } from "forge-std/Script.sol";

import { IMultiSigWallet } from "../../common/post-deployment/IMultiSigWallet.sol";
import { IPerpetualMint } from "../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";
import { IDepositContract } from "../../../contracts/vrf/Supra/IDepositContract.sol";
import { ISupraRouterContract } from "../../../contracts/vrf/Supra/ISupraRouterContract.sol";

/// @title ConfigureVRFSubscription_Base
/// @dev Configures the Supra VRF subscription by adding the PerpetualMint contract as a consumer,
/// and optionally funding the subscription in ETH via the Gnosis Safe Transaction Service API
contract ConfigureVRFSubscription_Base is Script {
    /// @dev runs the script logic
    function run() external {
        // get PerpetualMint address
        address perpetualMint = readCoreAddress();

        // get signer PK
        uint256 signerPK = vm.envUint("SIGNER_PK");

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

        // This version is makes possible to directly make the gnosis safe execute the transactions required by broadcasting the transactions for each signer.
        // In order to accomplish this all the signers PKs need to be provided in the environment variables.
        // This is just a sample code to show how to do it assuming that the number of required signers is 3.
        
        // uint256[] memory signers = new uint256[](3);
        // signers[0] = vm.envUint("SIGNER_1_PK");
        // signers[1] = vm.envUint("SIGNER_2_PK");
        // signers[2] = vm.envUint("SIGNER_3_PK");

        // for(uint i = 0; i < signers.length; i++) {
        //     uint256 contractWhitelistTxId;
        //     uint256 depositFundClientTxId;
        //     vm.startBroadcast(signers[i]);
        //     if(i == 0) {
        //         contractWhitelistTxId = IMultiSigWallet(gnosisSafeAddress).submitTransaction(
        //             supraVRFDepositContract,
        //             0,
        //             addContractToWhitelistTx
        //         );
        //         if(ethAmountToFundSubscription > 0) {
        //             bytes memory depositFundClientTx = abi.encodeWithSelector(
        //                 IDepositContract.depositFundClient.selector
        //             );
        //             depositFundClientTxId = IMultiSigWallet(gnosisSafeAddress).submitTransaction(
        //                 supraVRFDepositContract,
        //                 ethAmountToFundSubscription,
        //                 depositFundClientTx
        //             );
        //         }
        //     }else {
        //         contractWhitelistTxId = IMultiSigWallet(gnosisSafeAddress).confirmTransaction(contractWhitelistTxId);
        //         if(ethAmountToFundSubscription > 0) {
        //             depositFundClientTxId = IMultiSigWallet(gnosisSafeAddress).confirmTransaction(depositFundClientTxId);
        //         }
        //     }
        //     vm.stopBroadcast();
        // }

        vm.startBroadcast(signerPK);

        uint256 contractWhitelistTxId = IMultiSigWallet(gnosisSafeAddress).submitTransaction(
            supraVRFDepositContract,
            0,
            addContractToWhitelistTx
        );

        uint256 depositFundClientTxId;
        
        if (ethAmountToFundSubscription > 0) {
            bytes memory depositFundClientTx = abi.encodeWithSelector(
                IDepositContract.depositFundClient.selector
            );
            depositFundClientTxId = IMultiSigWallet(gnosisSafeAddress).submitTransaction(
                supraVRFDepositContract,
                ethAmountToFundSubscription,
                depositFundClientTx
            );
        }

        vm.stopBroadcast();


        console2.log("Supra VRF Router Address: ", vrfRouter);
        console2.log("Supra VRF Consumer Added: ", perpetualMint);
        console2.log(
            "Supra VRF Subscription Funded: %s.%s ETH",
            envEthAmountToFundSubscription,
            ethAmountToFundSubscription % 1e18
        );
        console2.log(
            "Gnosis Safe Whitelist Transaction ID : %s",
            contractWhitelistTxId
        );

        if(ethAmountToFundSubscription > 0) {
            console2.log(
                "Gnosis Safe Deposit Fund Client Transaction ID : %s",
                depositFundClientTxId
            );
        }

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
