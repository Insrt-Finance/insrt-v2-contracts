// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IPausable } from "@solidstate/contracts/security/pausable/IPausable.sol";
import { IERC1155Metadata } from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";

import { ICore } from "../../../contracts/diamonds/Core/ICore.sol";
import { Core } from "../../../contracts/diamonds/Core/Core.sol";
import { IERC1155MetadataExtension } from "../../../contracts/facets/PerpetualMint/IERC1155MetadataExtension.sol";
import { IPerpetualMint } from "../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";
import { IPerpetualMintAdmin } from "../../../contracts/facets/PerpetualMint/IPerpetualMintAdmin.sol";
import { IPerpetualMintBase } from "../../../contracts/facets/PerpetualMint/IPerpetualMintBase.sol";
import { IPerpetualMintView } from "../../../contracts/facets/PerpetualMint/IPerpetualMintView.sol";
import { PerpetualMintAdmin } from "../../../contracts/facets/PerpetualMint/PerpetualMintAdmin.sol";
import { PerpetualMintBase } from "../../../contracts/facets/PerpetualMint/PerpetualMintBase.sol";
import { IPerpetualMintViewSupra } from "../../../contracts/facets/PerpetualMint/Supra/IPerpetualMintView.sol";
import { PerpetualMintSupra } from "../../../contracts/facets/PerpetualMint/Supra/PerpetualMint.sol";
import { PerpetualMintViewSupra } from "../../../contracts/facets/PerpetualMint/Supra/PerpetualMintView.sol";

/// @title DeployPerpetualMint_Base
/// @dev deploys the Core diamond contract, PerpetualMintSupra facet, PerpetualMintAdmin facet, PerpetualMintBase facet, and PerpetualMintViewSupra facet,
/// and performs a diamondCut of the PerpetualMintSupra, PerpetualMintAdmin, PerpetualMintBase, and PerpetualMintViewSupra facets onto the Core diamond
contract DeployPerpetualMint_Base is Script {
    /// @dev runs the script logic
    function run() external {
        // read address of $MINT token contract
        address mintToken = readTokenProxyAddress();
        // Supra VRF Router address
        address VRF_ROUTER = vm.envAddress("VRF_ROUTER");

        string memory receiptName = "Ticket";
        string memory receiptSymbol = "TICKET";

        // read deployer private key
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // deploy PerpetualMintSupra facet
        PerpetualMintSupra perpetualMintSupra = new PerpetualMintSupra(
            VRF_ROUTER
        );

        // deploy PerpetualMintAdmin facet
        PerpetualMintAdmin perpetualMintAdmin = new PerpetualMintAdmin(
            VRF_ROUTER
        );

        // deploy PerpetualMintBase facet
        PerpetualMintBase perpetualMintBase = new PerpetualMintBase(VRF_ROUTER);

        // deploy PerpetualMintViewSupra facet
        PerpetualMintViewSupra perpetualMintViewSupra = new PerpetualMintViewSupra(
                VRF_ROUTER
            );

        // deploy Core
        Core core = new Core(mintToken, receiptName, receiptSymbol);

        console.log(
            "PerpetualMintSupra Facet Address: ",
            address(perpetualMintSupra)
        );
        console.log(
            "PerpetualMintAdmin Facet Address: ",
            address(perpetualMintAdmin)
        );
        console.log(
            "PerpetualMintBase Facet Address: ",
            address(perpetualMintBase)
        );
        console.log(
            "PerpetualMintViewSupra Facet Address: ",
            address(perpetualMintViewSupra)
        );
        console.log("Core Address: ", address(core));
        console.log("Supra VRF Router Address: ", VRF_ROUTER);

        writeCoreAddress(address(core));
        writeVRFRouterAddress(VRF_ROUTER);

        // get PerpetualMint facet cuts
        ICore.FacetCut[]
            memory perpetualMintFacetCuts = getPerpetualMintFacetCuts(
                address(perpetualMintSupra)
            );

        // get PerpetualMintAdmin facet cuts
        ICore.FacetCut[]
            memory perpetualMintAdminFacetCuts = getPerpetualMintAdminFacetCuts(
                address(perpetualMintAdmin)
            );

        // get PerpetualMintBase facet cuts
        ICore.FacetCut[]
            memory perpetualMintBaseFacetCuts = getPerpetualMintBaseFacetCuts(
                address(perpetualMintBase)
            );

        // get PerpetualMintView & PerpetualMintViewSupra facet cuts
        ICore.FacetCut[]
            memory perpetualMintViewFacetCuts = getPerpetualMintViewFacetCuts(
                address(perpetualMintViewSupra)
            );

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](10);

        facetCuts[0] = perpetualMintFacetCuts[0];
        facetCuts[1] = perpetualMintFacetCuts[1];
        facetCuts[2] = perpetualMintAdminFacetCuts[0];
        facetCuts[3] = perpetualMintBaseFacetCuts[0];
        facetCuts[4] = perpetualMintBaseFacetCuts[1];
        facetCuts[5] = perpetualMintBaseFacetCuts[2];
        facetCuts[6] = perpetualMintBaseFacetCuts[3];
        facetCuts[7] = perpetualMintViewFacetCuts[0];
        facetCuts[8] = perpetualMintViewFacetCuts[1];
        facetCuts[9] = perpetualMintViewFacetCuts[2];

        // cut PerpetualMint into Core
        core.diamondCut(facetCuts, address(0), "");

        ICore(payable(core)).pause();

        console.log("PerpetualMint Paused");

        vm.stopBroadcast();
    }

    /// @dev provides the facet cuts for cutting PerpetualMint facet into Core
    /// @param facetAddress address of PerpetualMintSupra facet
    function getPerpetualMintFacetCuts(
        address facetAddress
    ) internal pure returns (ICore.FacetCut[] memory) {
        // map the PerpetualMint related function selectors to their respective interfaces
        bytes4[] memory perpetualMintFunctionSelectors = new bytes4[](9);

        perpetualMintFunctionSelectors[0] = IPerpetualMint
            .attemptBatchMintForEthWithEth
            .selector;

        perpetualMintFunctionSelectors[1] = IPerpetualMint
            .attemptBatchMintForEthWithMint
            .selector;

        perpetualMintFunctionSelectors[2] = IPerpetualMint
            .attemptBatchMintForMintWithEth
            .selector;

        perpetualMintFunctionSelectors[3] = IPerpetualMint
            .attemptBatchMintForMintWithMint
            .selector;

        perpetualMintFunctionSelectors[4] = IPerpetualMint
            .attemptBatchMintWithEth
            .selector;

        perpetualMintFunctionSelectors[5] = IPerpetualMint
            .attemptBatchMintWithMint
            .selector;

        perpetualMintFunctionSelectors[6] = IPerpetualMint.claimPrize.selector;

        perpetualMintFunctionSelectors[7] = IPerpetualMint
            .fundConsolationFees
            .selector;

        perpetualMintFunctionSelectors[8] = IPerpetualMint.redeem.selector;

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

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](2);

        // omit Ownable since SolidStateDiamond includes those
        facetCuts[0] = perpetualMintFacetCut;
        facetCuts[1] = vrfConsumerBaseV2FacetCut;

        return facetCuts;
    }

    /// @dev provides the facet cuts for cutting PerpetualMintAdmin facet into Core
    /// @param facetAddress address of PerpetualMintAdmin facet
    function getPerpetualMintAdminFacetCuts(
        address facetAddress
    ) internal pure returns (ICore.FacetCut[] memory) {
        // map the PerpetualMintAdmin related function selectors to their respective interfaces
        bytes4[] memory perpetualMintAdminFunctionSelectors = new bytes4[](29);

        perpetualMintAdminFunctionSelectors[0] = IPerpetualMintAdmin
            .burnReceipt
            .selector;

        perpetualMintAdminFunctionSelectors[1] = IPerpetualMintAdmin
            .cancelClaim
            .selector;

        perpetualMintAdminFunctionSelectors[2] = bytes4(
            keccak256("claimMintEarnings()")
        );

        perpetualMintAdminFunctionSelectors[3] = bytes4(
            keccak256("claimMintEarnings(uint256)")
        );

        perpetualMintAdminFunctionSelectors[4] = IPerpetualMintAdmin
            .claimProtocolFees
            .selector;

        perpetualMintAdminFunctionSelectors[5] = IPerpetualMintAdmin
            .mintAirdrop
            .selector;

        perpetualMintAdminFunctionSelectors[6] = IPerpetualMintAdmin
            .pause
            .selector;

        perpetualMintAdminFunctionSelectors[7] = IPerpetualMintAdmin
            .setCollectionConsolationFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[8] = IPerpetualMintAdmin
            .setCollectionMintFeeDistributionRatioBP
            .selector;

        perpetualMintAdminFunctionSelectors[9] = IPerpetualMintAdmin
            .setCollectionMintMultiplier
            .selector;

        perpetualMintAdminFunctionSelectors[10] = IPerpetualMintAdmin
            .setCollectionMintPrice
            .selector;

        perpetualMintAdminFunctionSelectors[11] = IPerpetualMintAdmin
            .setCollectionReferralFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[12] = IPerpetualMintAdmin
            .setCollectionRisk
            .selector;

        perpetualMintAdminFunctionSelectors[13] = IPerpetualMintAdmin
            .setDefaultCollectionReferralFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[14] = IPerpetualMintAdmin
            .setEthToMintRatio
            .selector;

        perpetualMintAdminFunctionSelectors[15] = IPerpetualMintAdmin
            .setMintEarningsBufferBP
            .selector;

        perpetualMintAdminFunctionSelectors[16] = IPerpetualMintAdmin
            .setMintFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[17] = IPerpetualMintAdmin
            .setMintForEthConsolationFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[18] = IPerpetualMintAdmin
            .setMintToken
            .selector;

        perpetualMintAdminFunctionSelectors[19] = IPerpetualMintAdmin
            .setMintTokenConsolationFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[20] = IPerpetualMintAdmin
            .setMintTokenTiers
            .selector;

        perpetualMintAdminFunctionSelectors[21] = IPerpetualMintAdmin
            .setReceiptBaseURI
            .selector;

        perpetualMintAdminFunctionSelectors[22] = IPerpetualMintAdmin
            .setReceiptTokenURI
            .selector;

        perpetualMintAdminFunctionSelectors[23] = IPerpetualMintAdmin
            .setRedemptionFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[24] = IPerpetualMintAdmin
            .setRedeemPaused
            .selector;

        perpetualMintAdminFunctionSelectors[25] = IPerpetualMintAdmin
            .setTiers
            .selector;

        perpetualMintAdminFunctionSelectors[26] = IPerpetualMintAdmin
            .setVRFConfig
            .selector;

        perpetualMintAdminFunctionSelectors[27] = IPerpetualMintAdmin
            .setVRFSubscriptionBalanceThreshold
            .selector;

        perpetualMintAdminFunctionSelectors[28] = IPerpetualMintAdmin
            .unpause
            .selector;

        ICore.FacetCut
            memory perpetualMintAdminFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: facetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintAdminFunctionSelectors
                });

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](1);

        // omit Ownable since SolidStateDiamond includes those
        facetCuts[0] = perpetualMintAdminFacetCut;

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

    /// @dev provides the facet cuts for cutting PerpetualMintView & PerpetualMintViewSupra facets into Core
    /// @param viewFacetAddress address of PerpetualMintViewSupra facet
    function getPerpetualMintViewFacetCuts(
        address viewFacetAddress
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
        bytes4[] memory perpetualMintViewFunctionSelectors = new bytes4[](27);

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
            .mintEarningsBufferBP
            .selector;

        perpetualMintViewFunctionSelectors[16] = IPerpetualMintView
            .mintFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[17] = IPerpetualMintView
            .mintForEthConsolationFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[18] = IPerpetualMintView
            .mintToken
            .selector;

        perpetualMintViewFunctionSelectors[19] = IPerpetualMintView
            .mintTokenConsolationFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[20] = IPerpetualMintView
            .mintTokenTiers
            .selector;

        perpetualMintViewFunctionSelectors[21] = IPerpetualMintView
            .redemptionFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[22] = IPerpetualMintView
            .redeemPaused
            .selector;

        perpetualMintViewFunctionSelectors[23] = IPerpetualMintView
            .SCALE
            .selector;

        perpetualMintViewFunctionSelectors[24] = IPerpetualMintView
            .tiers
            .selector;

        perpetualMintViewFunctionSelectors[25] = IPerpetualMintView
            .vrfConfig
            .selector;

        perpetualMintViewFunctionSelectors[26] = IPerpetualMintView
            .vrfSubscriptionBalanceThreshold
            .selector;

        ICore.FacetCut
            memory perpetualMintViewFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: viewFacetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintViewFunctionSelectors
                });

        // map the PerpetualMintViewSupra related function selectors to their respective interfaces
        bytes4[] memory perpetualMintViewSupraFunctionSelectors = new bytes4[](
            1
        );

        perpetualMintViewSupraFunctionSelectors[0] = IPerpetualMintViewSupra
            .calculateMintResultSupra
            .selector;

        ICore.FacetCut
            memory perpetualMintViewSupraFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: viewFacetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintViewSupraFunctionSelectors
                });

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](3);

        facetCuts[0] = pausableFacetCut;
        facetCuts[1] = perpetualMintViewFacetCut;
        facetCuts[2] = perpetualMintViewSupraFacetCut;

        return facetCuts;
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

    /// @notice writes the address of the deployed Core diamond to a file
    /// @param coreAddress address of the deployed Core diamond
    function writeCoreAddress(address coreAddress) internal {
        string memory inputDir = string.concat(
            vm.projectRoot(),
            "/broadcast/01_deployPerpetualMint.s.sol/"
        );

        string memory chainDir = string.concat(vm.toString(block.chainid), "/");

        string memory file = string.concat("run-latest-core-address", ".txt");

        vm.writeFile(
            string.concat(inputDir, chainDir, file),
            vm.toString(coreAddress)
        );
    }

    /// @notice writes the address of the Supra VRF Router set in the deployed Core diamond to a file
    /// @param vrfRouterAddress address of the Supra VRF Router set in the deployed Core diamond
    function writeVRFRouterAddress(address vrfRouterAddress) internal {
        string memory inputDir = string.concat(
            vm.projectRoot(),
            "/broadcast/01_deployPerpetualMint.s.sol/"
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
