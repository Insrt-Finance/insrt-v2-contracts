// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-safe/BatchScript.sol";

import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";
import { IDiamondWritable } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IPausable } from "@solidstate/contracts/security/pausable/IPausable.sol";
import { IERC1155Metadata } from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";

import { IERC1155MetadataExtension } from "../../../contracts/facets/PerpetualMint/IERC1155MetadataExtension.sol";
import { IPerpetualMint } from "../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";
import { IPerpetualMintBase } from "../../../contracts/facets/PerpetualMint/IPerpetualMintBase.sol";
import { PerpetualMint } from "../../../contracts/facets/PerpetualMint/PerpetualMint.sol";
import { PerpetualMintBase } from "../../../contracts/facets/PerpetualMint/PerpetualMintBase.sol";

/// @title UpgradeAndSplitPerpetualMintArb
/// @dev Upgrades and splits the PerpetualMint facet by deploying a new PerpetualMint facet, deploying the PerpetualMintBase facet and sign and submitting
/// a diamondCut of both facets to the Core diamond via the Gnosis Safe Transaction Service API
contract UpgradeAndSplitPerpetualMintArb is BatchScript {
    /// @dev runs the script logic
    function run() external {
        // read deployer private key
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");

        // get Core PerpetualMint diamond address
        address core = vm.envAddress("CORE_ADDRESS");

        // get Gnosis Safe (protocol owner) address
        address gnosisSafeAddress = vm.envAddress("GNOSIS_SAFE");

        // get VRF Coordinator address
        address VRF_COORDINATOR = vm.envAddress("VRF_COORDINATOR");

        // we only explicitly broadcast facet deployments
        // broadcasting of batch execution gnosis multi-sig transactions is done
        // separately using the Gnosis Safe Transaction Service API
        vm.startBroadcast(deployerPrivateKey);

        // deploy new PerpetualMint facet
        PerpetualMint perpetualMint = new PerpetualMint(VRF_COORDINATOR);

        // deploy new PerpetualMintBase facet
        PerpetualMintBase perpetualMintBase = new PerpetualMintBase(
            VRF_COORDINATOR
        );

        vm.stopBroadcast();

        console2.log(
            "New PerpetualMint Facet Address: ",
            address(perpetualMint)
        );
        console2.log(
            "New PerpetualMintBase Facet Address: ",
            address(perpetualMintBase)
        );
        console2.log("Core Address: ", core);
        console2.log("VRF Coordinator Address: ", VRF_COORDINATOR);

        // get replacement PerpetualMintBase facet cuts
        ISolidStateDiamond.FacetCut[]
            memory replacementPerpetualMintBaseFacetCuts = getReplacementPerpetualMintBaseFacetCuts(
                address(perpetualMintBase)
            );

        // get replacement PerpetualMint facet cuts
        ISolidStateDiamond.FacetCut[]
            memory replacementPerpetualMintFacetCuts = getReplacementPerpetualMintFacetCuts(
                address(perpetualMint)
            );

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](7);

        facetCuts[0] = replacementPerpetualMintBaseFacetCuts[0];
        facetCuts[1] = replacementPerpetualMintBaseFacetCuts[1];
        facetCuts[2] = replacementPerpetualMintBaseFacetCuts[2];
        facetCuts[3] = replacementPerpetualMintFacetCuts[0];
        facetCuts[4] = replacementPerpetualMintFacetCuts[1];
        facetCuts[5] = replacementPerpetualMintFacetCuts[2];
        facetCuts[6] = replacementPerpetualMintFacetCuts[3];

        bytes memory diamondCutTx = abi.encodeWithSelector(
            IDiamondWritable.diamondCut.selector,
            facetCuts,
            address(0),
            ""
        );

        addToBatch(core, diamondCutTx);

        executeBatch(gnosisSafeAddress, true);
    }

    /// @dev provides the replacement facet cuts for cutting PerpetualMintBase facet into Core
    /// @param facetAddress address of PerpetualMintBase facet
    function getReplacementPerpetualMintBaseFacetCuts(
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
                action: IDiamondWritableInternal.FacetCutAction.REPLACE,
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
                    action: IDiamondWritableInternal.FacetCutAction.REPLACE,
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
                    action: IDiamondWritableInternal.FacetCutAction.REPLACE,
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

    /// @dev provides the replacement facet cuts for cutting PerpetualMint facet into Core
    /// @param facetAddress address of PerpetualMint facet
    function getReplacementPerpetualMintFacetCuts(
        address facetAddress
    ) internal pure returns (ISolidStateDiamond.FacetCut[] memory) {
        // map the ERC1155Metadata function selectors to their respective interfaces
        bytes4[] memory erc1155MetadataFunctionSelectors = new bytes4[](1);

        erc1155MetadataFunctionSelectors[0] = IERC1155Metadata.uri.selector;

        ISolidStateDiamond.FacetCut
            memory erc1155MetadataFacetCut = IDiamondWritableInternal.FacetCut({
                target: facetAddress,
                action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                selectors: erc1155MetadataFunctionSelectors
            });

        // map the Pausable function selectors to their respective interfaces
        bytes4[] memory pausableFunctionSelectors = new bytes4[](1);

        pausableFunctionSelectors[0] = IPausable.paused.selector;

        ISolidStateDiamond.FacetCut
            memory pausableFacetCut = IDiamondWritableInternal.FacetCut({
                target: facetAddress,
                action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                selectors: pausableFunctionSelectors
            });

        // map the PerpetualMint related function selectors to their respective interfaces
        bytes4[] memory perpetualMintFunctionSelectors = new bytes4[](27);

        perpetualMintFunctionSelectors[0] = IPerpetualMint
            .attemptBatchMintWithEth
            .selector;

        perpetualMintFunctionSelectors[1] = IPerpetualMint
            .attemptBatchMintWithMint
            .selector;

        perpetualMintFunctionSelectors[2] = IPerpetualMint.burnReceipt.selector;

        perpetualMintFunctionSelectors[3] = IPerpetualMint.cancelClaim.selector;

        perpetualMintFunctionSelectors[4] = IPerpetualMint
            .claimMintEarnings
            .selector;

        perpetualMintFunctionSelectors[5] = IPerpetualMint.claimPrize.selector;

        perpetualMintFunctionSelectors[6] = IPerpetualMint
            .claimProtocolFees
            .selector;

        perpetualMintFunctionSelectors[7] = IPerpetualMint
            .fundConsolationFees
            .selector;

        perpetualMintFunctionSelectors[8] = IPerpetualMint.mintAirdrop.selector;

        perpetualMintFunctionSelectors[9] = IPerpetualMint.pause.selector;

        perpetualMintFunctionSelectors[10] = IPerpetualMint.redeem.selector;

        perpetualMintFunctionSelectors[11] = IPerpetualMint
            .setCollectionConsolationFeeBP
            .selector;

        perpetualMintFunctionSelectors[12] = IPerpetualMint
            .setCollectionMintFeeDistributionRatioBP
            .selector;

        perpetualMintFunctionSelectors[13] = IPerpetualMint
            .setCollectionMintMultiplier
            .selector;

        perpetualMintFunctionSelectors[14] = IPerpetualMint
            .setCollectionMintPrice
            .selector;

        perpetualMintFunctionSelectors[15] = IPerpetualMint
            .setCollectionRisk
            .selector;

        perpetualMintFunctionSelectors[16] = IPerpetualMint
            .setEthToMintRatio
            .selector;

        perpetualMintFunctionSelectors[17] = IPerpetualMint
            .setMintFeeBP
            .selector;

        perpetualMintFunctionSelectors[18] = IPerpetualMint
            .setMintToken
            .selector;

        perpetualMintFunctionSelectors[19] = IPerpetualMint
            .setReceiptBaseURI
            .selector;

        perpetualMintFunctionSelectors[20] = IPerpetualMint
            .setReceiptTokenURI
            .selector;

        perpetualMintFunctionSelectors[21] = IPerpetualMint
            .setRedemptionFeeBP
            .selector;

        perpetualMintFunctionSelectors[22] = IPerpetualMint
            .setRedeemPaused
            .selector;

        perpetualMintFunctionSelectors[23] = IPerpetualMint.setTiers.selector;

        perpetualMintFunctionSelectors[24] = IPerpetualMint
            .setVRFConfig
            .selector;

        perpetualMintFunctionSelectors[25] = IPerpetualMint
            .setVRFSubscriptionBalanceThreshold
            .selector;

        perpetualMintFunctionSelectors[26] = IPerpetualMint.unpause.selector;

        ISolidStateDiamond.FacetCut
            memory perpetualMintFacetCut = IDiamondWritableInternal.FacetCut({
                target: facetAddress,
                action: IDiamondWritableInternal.FacetCutAction.REPLACE,
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
                    action: IDiamondWritableInternal.FacetCutAction.REPLACE,
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
}
