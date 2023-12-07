// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IPausable } from "@solidstate/contracts/security/pausable/IPausable.sol";
import { IERC1155Metadata } from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";

import { ICore } from "../../../contracts/diamonds/Core/ICore.sol";
import { Core } from "../../../contracts/diamonds/Core/Core.sol";
import { IPerpetualMintView_Base } from "../../../contracts/facets/PerpetualMint/Base/IPerpetualMintView.sol";
import { PerpetualMint_Base } from "../../../contracts/facets/PerpetualMint/Base/PerpetualMint.sol";
import { PerpetualMintView_Base } from "../../../contracts/facets/PerpetualMint/Base/PerpetualMintView.sol";
import { IERC1155MetadataExtension } from "../../../contracts/facets/PerpetualMint/IERC1155MetadataExtension.sol";
import { IPerpetualMint } from "../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";
import { IPerpetualMintBase } from "../../../contracts/facets/PerpetualMint/IPerpetualMintBase.sol";
import { IPerpetualMintView } from "../../../contracts/facets/PerpetualMint/IPerpetualMintView.sol";
import { PerpetualMintBase } from "../../../contracts/facets/PerpetualMint/PerpetualMintBase.sol";

/// @title DeployPerpetualMint_Base
/// @dev deploys the Core diamond contract, PerpetualMint_Base facet, PerpetualMintBase facet, and PerpetualMintView_Base facet, and performs
/// a diamondCut of the PerpetualMint_Base, PerpetualMintBase, and PerpetualMintView_Base facets onto the Core diamond
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

        // deploy PerpetualMint_Base facet
        PerpetualMint_Base perpetualMint_Base = new PerpetualMint_Base(
            VRF_ROUTER
        );

        // deploy PerpetualMintBase facet
        PerpetualMintBase perpetualMintBase = new PerpetualMintBase(VRF_ROUTER);

        // deploy PerpetualMintView_Base facet
        PerpetualMintView_Base perpetualMintView_Base = new PerpetualMintView_Base(
                VRF_ROUTER
            );

        // deploy Core
        Core core = new Core(mintToken, receiptName, receiptSymbol);

        console.log(
            "PerpetualMint_Base Facet Address: ",
            address(perpetualMint_Base)
        );
        console.log(
            "PerpetualMintBase Facet Address: ",
            address(perpetualMintBase)
        );
        console.log(
            "PerpetualMintView_Base Facet Address: ",
            address(perpetualMintView_Base)
        );
        console.log("Core Address: ", address(core));
        console.log("Supra VRF Router Address: ", VRF_ROUTER);

        writeCoreAddress(address(core));
        writeVRFRouterAddress(VRF_ROUTER);

        // get PerpetualMint facet cuts
        ISolidStateDiamond.FacetCut[]
            memory perpetualMintFacetCuts = getPerpetualMintFacetCuts(
                address(perpetualMint_Base)
            );

        // get PerpetualMintBase facet cuts
        ISolidStateDiamond.FacetCut[]
            memory perpetualMintBaseFacetCuts = getPerpetualMintBaseFacetCuts(
                address(perpetualMintBase)
            );

        // get PerpetualMintView & PerpetualMintView_Base facet cuts
        ISolidStateDiamond.FacetCut[]
            memory perpetualMintViewFacetCuts = getPerpetualMintViewFacetCuts(
                address(perpetualMintView_Base)
            );

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](9);

        facetCuts[0] = perpetualMintFacetCuts[0];
        facetCuts[1] = perpetualMintFacetCuts[1];
        facetCuts[2] = perpetualMintFacetCuts[2];
        facetCuts[3] = perpetualMintFacetCuts[3];
        facetCuts[4] = perpetualMintBaseFacetCuts[0];
        facetCuts[5] = perpetualMintBaseFacetCuts[1];
        facetCuts[6] = perpetualMintBaseFacetCuts[2];
        facetCuts[7] = perpetualMintViewFacetCuts[0];
        facetCuts[8] = perpetualMintViewFacetCuts[1];

        // cut PerpetualMint into Core
        ISolidStateDiamond(core).diamondCut(facetCuts, address(0), "");

        ICore(address(core)).pause();

        console.log("PerpetualMint Paused");

        vm.stopBroadcast();
    }

    /// @dev provides the facet cuts for cutting PerpetualMint facet into Core
    /// @param facetAddress address of PerpetualMint_Base facet
    function getPerpetualMintFacetCuts(
        address facetAddress
    ) internal pure returns (ISolidStateDiamond.FacetCut[] memory) {
        // map the ERC1155Metadata function selectors to their respective interfaces
        bytes4[] memory erc1155MetadataFunctionSelectors = new bytes4[](1);

        erc1155MetadataFunctionSelectors[0] = IERC1155Metadata.uri.selector;

        ISolidStateDiamond.FacetCut
            memory erc1155MetadataFacetCut = IDiamondWritableInternal.FacetCut({
                target: facetAddress,
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: erc1155MetadataFunctionSelectors
            });

        // map the Pausable function selectors to their respective interfaces
        bytes4[] memory pausableFunctionSelectors = new bytes4[](1);

        pausableFunctionSelectors[0] = IPausable.paused.selector;

        ISolidStateDiamond.FacetCut
            memory pausableFacetCut = IDiamondWritableInternal.FacetCut({
                target: facetAddress,
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: pausableFunctionSelectors
            });

        // map the PerpetualMint related function selectors to their respective interfaces
        bytes4[] memory perpetualMintFunctionSelectors = new bytes4[](31);

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
            .setCollectionRisk
            .selector;

        perpetualMintFunctionSelectors[18] = IPerpetualMint
            .setEthToMintRatio
            .selector;

        perpetualMintFunctionSelectors[19] = IPerpetualMint
            .setMintFeeBP
            .selector;

        perpetualMintFunctionSelectors[20] = IPerpetualMint
            .setMintToken
            .selector;

        perpetualMintFunctionSelectors[21] = IPerpetualMint
            .setMintTokenConsolationFeeBP
            .selector;

        perpetualMintFunctionSelectors[22] = IPerpetualMint
            .setMintTokenTiers
            .selector;

        perpetualMintFunctionSelectors[23] = IPerpetualMint
            .setReceiptBaseURI
            .selector;

        perpetualMintFunctionSelectors[24] = IPerpetualMint
            .setReceiptTokenURI
            .selector;

        perpetualMintFunctionSelectors[25] = IPerpetualMint
            .setRedemptionFeeBP
            .selector;

        perpetualMintFunctionSelectors[26] = IPerpetualMint
            .setRedeemPaused
            .selector;

        perpetualMintFunctionSelectors[27] = IPerpetualMint.setTiers.selector;

        perpetualMintFunctionSelectors[28] = IPerpetualMint
            .setVRFConfig
            .selector;

        perpetualMintFunctionSelectors[29] = IPerpetualMint
            .setVRFSubscriptionBalanceThreshold
            .selector;

        perpetualMintFunctionSelectors[30] = IPerpetualMint.unpause.selector;

        ISolidStateDiamond.FacetCut
            memory perpetualMintFacetCut = IDiamondWritableInternal.FacetCut({
                target: facetAddress,
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: perpetualMintFunctionSelectors
            });

        // map the VRFConsumerBaseV2 function selectors to their respective interfaces
        bytes4[] memory vrfConsumerBaseV2FunctionSelectors = new bytes4[](1);

        vrfConsumerBaseV2FunctionSelectors[0] = VRFConsumerBaseV2
            .rawFulfillRandomWords
            .selector;

        ISolidStateDiamond.FacetCut
            memory vrfConsumerBaseV2FacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: facetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: vrfConsumerBaseV2FunctionSelectors
                });

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](6);

        // omit Ownable since SolidStateDiamond includes those
        facetCuts[0] = erc1155MetadataFacetCut;
        facetCuts[1] = pausableFacetCut;
        facetCuts[2] = perpetualMintFacetCut;
        facetCuts[3] = vrfConsumerBaseV2FacetCut;

        return facetCuts;
    }

    /// @dev provides the facet cuts for cutting PerpetualMintBase facet into Core
    /// @param facetAddress address of PerpetualMintBase facet
    function getPerpetualMintBaseFacetCuts(
        address facetAddress
    ) internal pure returns (ISolidStateDiamond.FacetCut[] memory) {
        /// map the ERC1155 function selectors to their respective interfaces
        bytes4[] memory erc1155FunctionSelectors = new bytes4[](6);

        erc1155FunctionSelectors[0] = IERC1155.balanceOf.selector;
        erc1155FunctionSelectors[1] = IERC1155.balanceOfBatch.selector;
        erc1155FunctionSelectors[2] = IERC1155.isApprovedForAll.selector;
        erc1155FunctionSelectors[3] = IERC1155.safeBatchTransferFrom.selector;
        erc1155FunctionSelectors[4] = IERC1155.safeTransferFrom.selector;
        erc1155FunctionSelectors[5] = IERC1155.setApprovalForAll.selector;

        ISolidStateDiamond.FacetCut
            memory erc1155FacetCut = IDiamondWritableInternal.FacetCut({
                target: facetAddress,
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: erc1155FunctionSelectors
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

        ISolidStateDiamond.FacetCut
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

        ISolidStateDiamond.FacetCut
            memory perpetualMintBaseFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: facetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintBaseFunctionSelectors
                });

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](3);

        // omit ERC165 since SolidStateDiamond includes those
        facetCuts[0] = erc1155FacetCut;
        facetCuts[1] = erc1155MetadataExtensionFacetCut;
        facetCuts[2] = perpetualMintBaseFacetCut;

        return facetCuts;
    }

    /// @dev provides the facet cuts for cutting PerpetualMintView & PerpetualMintView_Base facets into Core
    /// @param viewFacetAddress address of PerpetualMintView_Base facet
    function getPerpetualMintViewFacetCuts(
        address viewFacetAddress
    ) internal pure returns (ISolidStateDiamond.FacetCut[] memory) {
        // map the PerpetualMintView related function selectors to their respective interfaces
        bytes4[] memory perpetualMintViewFunctionSelectors = new bytes4[](23);

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
            .calculateMintResult
            .selector;

        perpetualMintViewFunctionSelectors[5] = IPerpetualMintView
            .collectionConsolationFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[6] = IPerpetualMintView
            .collectionMintFeeDistributionRatioBP
            .selector;

        perpetualMintViewFunctionSelectors[7] = IPerpetualMintView
            .collectionMintMultiplier
            .selector;

        perpetualMintViewFunctionSelectors[8] = IPerpetualMintView
            .collectionMintPrice
            .selector;

        perpetualMintViewFunctionSelectors[9] = IPerpetualMintView
            .collectionRisk
            .selector;

        perpetualMintViewFunctionSelectors[10] = IPerpetualMintView
            .defaultCollectionMintPrice
            .selector;

        perpetualMintViewFunctionSelectors[11] = IPerpetualMintView
            .defaultCollectionRisk
            .selector;

        perpetualMintViewFunctionSelectors[12] = IPerpetualMintView
            .defaultEthToMintRatio
            .selector;

        perpetualMintViewFunctionSelectors[13] = IPerpetualMintView
            .ethToMintRatio
            .selector;

        perpetualMintViewFunctionSelectors[14] = IPerpetualMintView
            .mintFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[15] = IPerpetualMintView
            .mintToken
            .selector;

        perpetualMintViewFunctionSelectors[16] = IPerpetualMintView
            .mintTokenConsolationFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[17] = IPerpetualMintView
            .mintTokenTiers
            .selector;

        perpetualMintViewFunctionSelectors[18] = IPerpetualMintView
            .redemptionFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[19] = IPerpetualMintView
            .redeemPaused
            .selector;

        perpetualMintViewFunctionSelectors[20] = IPerpetualMintView
            .tiers
            .selector;

        perpetualMintViewFunctionSelectors[21] = IPerpetualMintView
            .vrfConfig
            .selector;

        perpetualMintViewFunctionSelectors[22] = IPerpetualMintView
            .vrfSubscriptionBalanceThreshold
            .selector;

        ISolidStateDiamond.FacetCut
            memory perpetualMintViewFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: viewFacetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintViewFunctionSelectors
                });

        // map the PerpetualMintView_Base related function selectors to their respective interfaces
        bytes4[] memory perpetualMintView_BaseFunctionSelectors = new bytes4[](
            1
        );

        perpetualMintView_BaseFunctionSelectors[0] = IPerpetualMintView_Base
            .calculateMintResultBase
            .selector;

        ISolidStateDiamond.FacetCut
            memory perpetualMintView_BaseFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: viewFacetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintView_BaseFunctionSelectors
                });

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](2);

        facetCuts[0] = perpetualMintViewFacetCut;
        facetCuts[1] = perpetualMintView_BaseFacetCut;

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
