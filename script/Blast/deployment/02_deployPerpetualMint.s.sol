// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IPausable } from "@solidstate/contracts/security/pausable/IPausable.sol";
import { IERC1155Metadata } from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";

import { ICore } from "../../../contracts/diamonds/Core/ICore.sol";
import { IPerpetualMintBlastSupra } from "../../../contracts/facets/PerpetualMint/Blast/Supra/IPerpetualMint.sol";
import { IPerpetualMintViewBlastSupra } from "../../../contracts/facets/PerpetualMint/Blast/Supra/IPerpetualMintView.sol";
import { PerpetualMintBlastSupra } from "../../../contracts/facets/PerpetualMint/Blast/Supra/PerpetualMint.sol";
import { PerpetualMintViewBlastSupra } from "../../../contracts/facets/PerpetualMint/Blast/Supra/PerpetualMintView.sol";
import { IERC1155MetadataExtension } from "../../../contracts/facets/PerpetualMint/IERC1155MetadataExtension.sol";
import { IPerpetualMint } from "../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";
import { IPerpetualMintBase } from "../../../contracts/facets/PerpetualMint/IPerpetualMintBase.sol";
import { IPerpetualMintView } from "../../../contracts/facets/PerpetualMint/IPerpetualMintView.sol";
import { PerpetualMint } from "../../../contracts/facets/PerpetualMint/PerpetualMint.sol";
import { PerpetualMintBase } from "../../../contracts/facets/PerpetualMint/PerpetualMintBase.sol";
import { PerpetualMintView } from "../../../contracts/facets/PerpetualMint/PerpetualMintView.sol";
import { PerpetualMintSupra } from "../../../contracts/facets/PerpetualMint/Supra/PerpetualMint.sol";

/// @title DeployPerpetualMint_Blast
/// @dev deploys the CoreBlast diamond contract, PerpetualMintBlastSupra facet, PerpetualMintBase facet, and PerpetualMintViewBlastSupra facet, and performs
/// a diamondCut of the PerpetualMintBlastSupra, PerpetualMintBase, and PerpetualMintViewBlastSupra facets onto the CoreBlast diamond
/// NOTE: Blast Bounty not yet implemented for Insrt VRF functionality
contract DeployPerpetualMint_Blast is Script {
    /// @dev runs the script logic
    function run() external {
        // get Core Blast diamond address
        address payable coreBlastAddress = payable(vm.envAddress("CORE_BLAST"));

        address insrtVrfCoordinator = readInsrtVRFCoordinatorAddress();

        bool insrtVRF = insrtVrfCoordinator != address(0);

        // if InsrtVRFCoordinator has not been deployed, use the Supra VRF Router
        address VRF_ROUTER = insrtVRF
            ? insrtVrfCoordinator
            : vm.envAddress("VRF_ROUTER");

        // read deployer private key
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");

        vm.startBroadcast(deployerPrivateKey);

        ICore.FacetCut[] memory perpetualMintFacetCuts;

        ICore.FacetCut[] memory perpetualMintViewFacetCuts;

        if (insrtVRF) {
            // deploy PerpetualMint facet
            PerpetualMint perpetualMint = new PerpetualMint(VRF_ROUTER);

            // deploy PerpetualMintView facet
            PerpetualMintView perpetualMintView = new PerpetualMintView(
                VRF_ROUTER
            );

            console.log(
                "PerpetualMint Facet Address: ",
                address(perpetualMint)
            );

            console.log(
                "PerpetualMintView Facet Address: ",
                address(perpetualMintView)
            );

            console.log("Insrt VRF Coordinator Address: ", VRF_ROUTER);

            // get PerpetualMint facet cuts
            perpetualMintFacetCuts = getPerpetualMintFacetCuts(
                address(perpetualMint),
                insrtVRF
            );

            // get PerpetualMintView facet cuts
            perpetualMintViewFacetCuts = getPerpetualMintViewFacetCuts(
                address(perpetualMintView),
                insrtVRF
            );
        } else {
            // deploy PerpetualMintBlastSupra facet
            PerpetualMintBlastSupra perpetualMintBlastSupra = new PerpetualMintBlastSupra(
                    VRF_ROUTER
                );

            // deploy PerpetualMintViewBlastSupra facet
            PerpetualMintViewBlastSupra perpetualMintViewBlastSupra = new PerpetualMintViewBlastSupra(
                    VRF_ROUTER
                );

            console.log(
                "PerpetualMintBlastSupra Facet Address: ",
                address(perpetualMintBlastSupra)
            );

            console.log(
                "PerpetualMintViewBlastSupra Facet Address: ",
                address(perpetualMintViewBlastSupra)
            );

            console.log("Supra VRF Router Address: ", VRF_ROUTER);

            // get PerpetualMint + PerpetualMintBlastSupra facet cuts
            perpetualMintFacetCuts = getPerpetualMintFacetCuts(
                address(perpetualMintBlastSupra),
                insrtVRF
            );

            // get PerpetualMintView + PerpetualMintViewBlastSupra facet cuts
            perpetualMintViewFacetCuts = getPerpetualMintViewFacetCuts(
                address(perpetualMintViewBlastSupra),
                insrtVRF
            );
        }

        // deploy PerpetualMintBase facet
        PerpetualMintBase perpetualMintBase = new PerpetualMintBase(VRF_ROUTER);

        console.log(
            "PerpetualMintBase Facet Address: ",
            address(perpetualMintBase)
        );

        console.log("CoreBlast Address: ", coreBlastAddress);

        writeCoreBlastAddress(coreBlastAddress);
        writeVRFRouterAddress(VRF_ROUTER);

        // get PerpetualMintBase facet cuts
        ICore.FacetCut[]
            memory perpetualMintBaseFacetCuts = getPerpetualMintBaseFacetCuts(
                address(perpetualMintBase)
            );

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](
            insrtVRF ? 8 : 10
        );

        facetCuts[0] = perpetualMintFacetCuts[0];
        facetCuts[1] = perpetualMintFacetCuts[1];
        facetCuts[2] = perpetualMintBaseFacetCuts[0];
        facetCuts[3] = perpetualMintBaseFacetCuts[1];
        facetCuts[4] = perpetualMintBaseFacetCuts[2];
        facetCuts[5] = perpetualMintBaseFacetCuts[3];
        facetCuts[6] = perpetualMintViewFacetCuts[0];
        facetCuts[7] = perpetualMintViewFacetCuts[1];

        if (!insrtVRF) {
            facetCuts[8] = perpetualMintFacetCuts[2];
            facetCuts[9] = perpetualMintViewFacetCuts[2];
        }

        ICore coreBlast = ICore(coreBlastAddress);

        // cut PerpetualMint into CoreBlast
        coreBlast.diamondCut(facetCuts, address(0), "");

        coreBlast.pause();

        console.log("PerpetualMint Paused");

        vm.stopBroadcast();
    }

    /// @dev provides the facet cuts for cutting PerpetualMint & PerpetualMintBlastSupra facet into CoreBlast
    /// @param facetAddress address of PerpetualMint facet
    /// @param insrtVRF boolean indicating whether Insrt VRF is being used
    function getPerpetualMintFacetCuts(
        address facetAddress,
        bool insrtVRF
    ) internal pure returns (ICore.FacetCut[] memory) {
        // map the PerpetualMint related function selectors to their respective interfaces
        bytes4[] memory perpetualMintFunctionSelectors = new bytes4[](33);

        perpetualMintFunctionSelectors[0] = IPerpetualMint
            .attemptBatchMintForMintWithEth
            .selector;

        perpetualMintFunctionSelectors[1] = IPerpetualMint
            .attemptBatchMintForMintWithMint
            .selector;

        perpetualMintFunctionSelectors[2] = IPerpetualMint
            .attemptBatchMintWithEth
            .selector;

        perpetualMintFunctionSelectors[3] = IPerpetualMint
            .attemptBatchMintWithMint
            .selector;

        perpetualMintFunctionSelectors[4] = IPerpetualMint.burnReceipt.selector;

        perpetualMintFunctionSelectors[5] = IPerpetualMint.cancelClaim.selector;

        perpetualMintFunctionSelectors[6] = IPerpetualMint
            .claimMintEarnings
            .selector;

        perpetualMintFunctionSelectors[7] = IPerpetualMint.claimPrize.selector;

        perpetualMintFunctionSelectors[8] = IPerpetualMint
            .claimProtocolFees
            .selector;

        perpetualMintFunctionSelectors[9] = IPerpetualMint
            .fundConsolationFees
            .selector;

        perpetualMintFunctionSelectors[10] = IPerpetualMint
            .mintAirdrop
            .selector;

        perpetualMintFunctionSelectors[11] = IPerpetualMint.pause.selector;

        perpetualMintFunctionSelectors[12] = IPerpetualMint.redeem.selector;

        perpetualMintFunctionSelectors[13] = IPerpetualMint
            .setCollectionConsolationFeeBP
            .selector;

        perpetualMintFunctionSelectors[14] = IPerpetualMint
            .setCollectionMintFeeDistributionRatioBP
            .selector;

        perpetualMintFunctionSelectors[15] = IPerpetualMint
            .setCollectionMintMultiplier
            .selector;

        perpetualMintFunctionSelectors[16] = IPerpetualMint
            .setCollectionMintPrice
            .selector;

        perpetualMintFunctionSelectors[17] = IPerpetualMint
            .setCollectionReferralFeeBP
            .selector;

        perpetualMintFunctionSelectors[18] = IPerpetualMint
            .setCollectionRisk
            .selector;

        perpetualMintFunctionSelectors[19] = IPerpetualMint
            .setDefaultCollectionReferralFeeBP
            .selector;

        perpetualMintFunctionSelectors[20] = IPerpetualMint
            .setEthToMintRatio
            .selector;

        perpetualMintFunctionSelectors[21] = IPerpetualMint
            .setMintFeeBP
            .selector;

        perpetualMintFunctionSelectors[22] = IPerpetualMint
            .setMintToken
            .selector;

        perpetualMintFunctionSelectors[23] = IPerpetualMint
            .setMintTokenConsolationFeeBP
            .selector;

        perpetualMintFunctionSelectors[24] = IPerpetualMint
            .setMintTokenTiers
            .selector;

        perpetualMintFunctionSelectors[25] = IPerpetualMint
            .setReceiptBaseURI
            .selector;

        perpetualMintFunctionSelectors[26] = IPerpetualMint
            .setReceiptTokenURI
            .selector;

        perpetualMintFunctionSelectors[27] = IPerpetualMint
            .setRedemptionFeeBP
            .selector;

        perpetualMintFunctionSelectors[28] = IPerpetualMint
            .setRedeemPaused
            .selector;

        perpetualMintFunctionSelectors[29] = IPerpetualMint.setTiers.selector;

        perpetualMintFunctionSelectors[30] = IPerpetualMint
            .setVRFConfig
            .selector;

        perpetualMintFunctionSelectors[31] = IPerpetualMint
            .setVRFSubscriptionBalanceThreshold
            .selector;

        perpetualMintFunctionSelectors[32] = IPerpetualMint.unpause.selector;

        ICore.FacetCut memory perpetualMintFacetCut = IDiamondWritableInternal
            .FacetCut({
                target: facetAddress,
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: perpetualMintFunctionSelectors
            });

        // map the VRFConsumerBaseV2 function selectors to their respective interfaces
        bytes4[] memory vrfConsumerBaseV2FunctionSelectors = new bytes4[](1);

        vrfConsumerBaseV2FunctionSelectors[0] = VRFConsumerBaseV2
            .rawFulfillRandomWords
            .selector;

        ICore.FacetCut
            memory vrfConsumerBaseV2FacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: facetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: vrfConsumerBaseV2FunctionSelectors
                });

        ICore.FacetCut[] memory facetCuts;

        if (insrtVRF) {
            facetCuts = new ICore.FacetCut[](2);

            // omit Ownable since SolidStateDiamond includes those
            facetCuts[0] = perpetualMintFacetCut;
            facetCuts[1] = vrfConsumerBaseV2FacetCut;

            return facetCuts;
        }

        // map the PerpetualMintBlastSupra related function selectors to their respective interfaces
        bytes4[] memory perpetualMintBlastSupraFunctionSelectors = new bytes4[](
            1
        );

        perpetualMintBlastSupraFunctionSelectors = new bytes4[](1);

        perpetualMintBlastSupraFunctionSelectors[0] = IPerpetualMintBlastSupra
            .setBlastYieldRisk
            .selector;

        ICore.FacetCut
            memory perpetualMintBlastSupraFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: facetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintBlastSupraFunctionSelectors
                });

        facetCuts = new ICore.FacetCut[](3);

        // omit Ownable since SolidStateDiamond includes those
        facetCuts[0] = perpetualMintBlastSupraFacetCut;
        facetCuts[1] = perpetualMintFacetCut;
        facetCuts[2] = vrfConsumerBaseV2FacetCut;

        return facetCuts;
    }

    /// @dev provides the facet cuts for cutting PerpetualMintBase facet into Core
    /// @param facetAddress address of PerpetualMintBase facet
    function getPerpetualMintBaseFacetCuts(
        address facetAddress
    ) internal pure returns (ICore.FacetCut[] memory) {
        /// map the ERC1155 function selectors to their respective interfaces
        bytes4[] memory erc1155FunctionSelectors = new bytes4[](6);

        erc1155FunctionSelectors[0] = IERC1155.balanceOf.selector;
        erc1155FunctionSelectors[1] = IERC1155.balanceOfBatch.selector;
        erc1155FunctionSelectors[2] = IERC1155.isApprovedForAll.selector;
        erc1155FunctionSelectors[3] = IERC1155.safeBatchTransferFrom.selector;
        erc1155FunctionSelectors[4] = IERC1155.safeTransferFrom.selector;
        erc1155FunctionSelectors[5] = IERC1155.setApprovalForAll.selector;

        ICore.FacetCut memory erc1155FacetCut = IDiamondWritableInternal
            .FacetCut({
                target: facetAddress,
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: erc1155FunctionSelectors
            });

        // map the ERC1155Metadata function selectors to their respective interfaces
        bytes4[] memory erc1155MetadataFunctionSelectors = new bytes4[](1);

        erc1155MetadataFunctionSelectors[0] = IERC1155Metadata.uri.selector;

        ICore.FacetCut memory erc1155MetadataFacetCut = IDiamondWritableInternal
            .FacetCut({
                target: facetAddress,
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: erc1155MetadataFunctionSelectors
            });

        // map the ERC1155Metadata function selectors to their respective interfaces
        bytes4[]
            memory erc1155MetadataExtensionFunctionSelectors = new bytes4[](2);

        erc1155MetadataExtensionFunctionSelectors[0] = IERC1155MetadataExtension
            .name
            .selector;
        erc1155MetadataExtensionFunctionSelectors[1] = IERC1155MetadataExtension
            .symbol
            .selector;

        ICore.FacetCut
            memory erc1155MetadataExtensionFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: facetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: erc1155MetadataExtensionFunctionSelectors
                });

        // map the PerpetualMintBase related function selectors to their respective interfaces
        bytes4[] memory perpetualMintBaseFunctionSelectors = new bytes4[](1);

        perpetualMintBaseFunctionSelectors[0] = IPerpetualMintBase
            .onERC1155Received
            .selector;

        ICore.FacetCut
            memory perpetualMintBaseFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: facetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintBaseFunctionSelectors
                });

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](4);

        // omit ERC165 since SolidStateDiamond includes those
        facetCuts[0] = erc1155FacetCut;
        facetCuts[1] = erc1155MetadataFacetCut;
        facetCuts[2] = erc1155MetadataExtensionFacetCut;
        facetCuts[3] = perpetualMintBaseFacetCut;

        return facetCuts;
    }

    /// @dev provides the facet cuts for cutting PerpetualMintView & PerpetualMintViewBlastSupra facets into Core
    /// @param viewFacetAddress address of PerpetualMintView facet
    /// @param insrtVRF boolean indicating whether Insrt VRF is being used
    function getPerpetualMintViewFacetCuts(
        address viewFacetAddress,
        bool insrtVRF
    ) internal pure returns (ICore.FacetCut[] memory) {
        // map the Pausable function selectors to their respective interfaces
        bytes4[] memory pausableFunctionSelectors = new bytes4[](1);

        pausableFunctionSelectors[0] = IPausable.paused.selector;

        ICore.FacetCut memory pausableFacetCut = IDiamondWritableInternal
            .FacetCut({
                target: viewFacetAddress,
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: pausableFunctionSelectors
            });

        // map the PerpetualMintView related function selectors to their respective interfaces
        bytes4[] memory perpetualMintViewFunctionSelectors = new bytes4[](
            insrtVRF ? 26 : 25
        );

        perpetualMintViewFunctionSelectors[0] = IPerpetualMintView
            .accruedConsolationFees
            .selector;

        perpetualMintViewFunctionSelectors[1] = IPerpetualMintView
            .accruedMintEarnings
            .selector;

        perpetualMintViewFunctionSelectors[2] = IPerpetualMintView
            .accruedProtocolFees
            .selector;

        perpetualMintViewFunctionSelectors[3] = IPerpetualMintView
            .BASIS
            .selector;

        perpetualMintViewFunctionSelectors[4] = IPerpetualMintView
            .collectionConsolationFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[5] = IPerpetualMintView
            .collectionMintFeeDistributionRatioBP
            .selector;

        perpetualMintViewFunctionSelectors[6] = IPerpetualMintView
            .collectionMintMultiplier
            .selector;

        perpetualMintViewFunctionSelectors[7] = IPerpetualMintView
            .collectionMintPrice
            .selector;

        perpetualMintViewFunctionSelectors[8] = IPerpetualMintView
            .collectionReferralFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[9] = IPerpetualMintView
            .collectionRisk
            .selector;

        perpetualMintViewFunctionSelectors[10] = IPerpetualMintView
            .defaultCollectionMintPrice
            .selector;

        perpetualMintViewFunctionSelectors[11] = IPerpetualMintView
            .defaultCollectionReferralFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[12] = IPerpetualMintView
            .defaultCollectionRisk
            .selector;

        perpetualMintViewFunctionSelectors[13] = IPerpetualMintView
            .defaultEthToMintRatio
            .selector;

        perpetualMintViewFunctionSelectors[14] = IPerpetualMintView
            .ethToMintRatio
            .selector;

        perpetualMintViewFunctionSelectors[15] = IPerpetualMintView
            .mintFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[16] = IPerpetualMintView
            .mintToken
            .selector;

        perpetualMintViewFunctionSelectors[17] = IPerpetualMintView
            .mintTokenConsolationFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[18] = IPerpetualMintView
            .mintTokenTiers
            .selector;

        perpetualMintViewFunctionSelectors[19] = IPerpetualMintView
            .redemptionFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[20] = IPerpetualMintView
            .redeemPaused
            .selector;

        perpetualMintViewFunctionSelectors[21] = IPerpetualMintView
            .SCALE
            .selector;

        perpetualMintViewFunctionSelectors[22] = IPerpetualMintView
            .tiers
            .selector;

        perpetualMintViewFunctionSelectors[23] = IPerpetualMintView
            .vrfConfig
            .selector;

        perpetualMintViewFunctionSelectors[24] = IPerpetualMintView
            .vrfSubscriptionBalanceThreshold
            .selector;

        ICore.FacetCut memory perpetualMintViewFacetCut;

        ICore.FacetCut[] memory facetCuts;

        if (insrtVRF) {
            perpetualMintViewFunctionSelectors[25] = IPerpetualMintView
                .calculateMintResult
                .selector;

            perpetualMintViewFacetCut = IDiamondWritableInternal.FacetCut({
                target: viewFacetAddress,
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: perpetualMintViewFunctionSelectors
            });

            facetCuts = new ICore.FacetCut[](2);

            facetCuts[0] = pausableFacetCut;
            facetCuts[1] = perpetualMintViewFacetCut;

            return facetCuts;
        }

        perpetualMintViewFacetCut = IDiamondWritableInternal.FacetCut({
            target: viewFacetAddress,
            action: IDiamondWritableInternal.FacetCutAction.ADD,
            selectors: perpetualMintViewFunctionSelectors
        });

        // map the PerpetualMintViewBlastSupra related function selectors to their respective interfaces
        bytes4[]
            memory perpetualMintViewBlastSupraFunctionSelectors = new bytes4[](
                2
            );

        perpetualMintViewBlastSupraFunctionSelectors[
            0
        ] = IPerpetualMintViewBlastSupra.blastYieldRisk.selector;

        perpetualMintViewBlastSupraFunctionSelectors[
            1
        ] = IPerpetualMintViewBlastSupra.calculateMintResultBlastSupra.selector;

        ICore.FacetCut
            memory perpetualMintViewBlastSupraFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: viewFacetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintViewBlastSupraFunctionSelectors
                });

        facetCuts = new ICore.FacetCut[](3);

        facetCuts[0] = pausableFacetCut;
        facetCuts[1] = perpetualMintViewFacetCut;
        facetCuts[2] = perpetualMintViewBlastSupraFacetCut;

        return facetCuts;
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

        try vm.readFile(string.concat(inputDir, chainDir, file)) returns (
            string memory fileData
        ) {
            return vm.parseAddress(fileData);
        } catch {
            return address(0);
        }
    }

    function readTokenProxyAddress()
        internal
        view
        returns (address tokenProxyAddress)
    {
        string memory inputDir = string.concat(
            vm.projectRoot(),
            "/broadcast/01_deployToken.s.sol/"
        );

        string memory chainDir = string.concat(vm.toString(block.chainid), "/");

        string memory file = string.concat(
            "run-latest-token-proxy-address",
            ".txt"
        );

        return
            vm.parseAddress(
                vm.readFile(string.concat(inputDir, chainDir, file))
            );
    }

    /// @notice writes the address of the deployed CoreBlast diamond to a file
    /// @param coreBlastAddress address of the deployed CoreBlast diamond
    function writeCoreBlastAddress(address coreBlastAddress) internal {
        string memory inputDir = string.concat(
            vm.projectRoot(),
            "/broadcast/02_deployPerpetualMint.s.sol/"
        );

        string memory chainDir = string.concat(vm.toString(block.chainid), "/");

        string memory file = string.concat(
            "run-latest-core-blast-address",
            ".txt"
        );

        vm.writeFile(
            string.concat(inputDir, chainDir, file),
            vm.toString(coreBlastAddress)
        );
    }

    /// @notice writes the address of the VRF Router set in the deployed Core diamond to a file
    /// @param vrfRouterAddress address of the VRF Router set in the deployed Core diamond
    function writeVRFRouterAddress(address vrfRouterAddress) internal {
        string memory inputDir = string.concat(
            vm.projectRoot(),
            "/broadcast/02_deployPerpetualMint.s.sol/"
        );

        string memory chainDir = string.concat(vm.toString(block.chainid), "/");

        string memory file = string.concat(
            "run-latest-vrf-router-address",
            ".txt"
        );

        vm.writeFile(
            string.concat(inputDir, chainDir, file),
            vm.toString(vrfRouterAddress)
        );
    }
}
