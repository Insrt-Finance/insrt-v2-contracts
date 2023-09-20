// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IPausable } from "@solidstate/contracts/security/pausable/IPausable.sol";
import { IERC1155Metadata } from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";

import { ICore } from "../contracts/diamonds/Core/ICore.sol";
import { Core } from "../contracts/diamonds/Core/Core.sol";
import { IERC1155MetadataExtension } from "../contracts/facets/PerpetualMint/IERC1155MetadataExtension.sol";
import { IPerpetualMint } from "../contracts/facets/PerpetualMint/IPerpetualMint.sol";
import { PerpetualMint } from "../contracts/facets/PerpetualMint/PerpetualMint.sol";

/// @title DeployPerpetualMint
/// @dev deploys the Core diamond contract and the PerpetualMint facet, and performs
/// a diamondCut of the PerpetualMint facet onto the Core diamond
contract DeployPerpetualMint is Script {
    /// @dev runs the script logic
    function run() external {
        //NOTE: CHANGE AS NEEDED FOR PRODUCTION
        // address of $MINT token contract
        address mintToken = address(0);
        // Arbitrum mainnet Chainlink VRF Coordinator address
        address VRF_COORDINATOR = 0x41034678D6C633D8a95c75e1138A360a28bA15d1;
        string memory receiptName = "I-O-U";
        string memory receiptSymbol = "IOU";

        // read deployer private key
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // deploy PerpetualMint facet
        PerpetualMint perpetualMint = new PerpetualMint(VRF_COORDINATOR);

        // deploy Core
        Core core = new Core(mintToken, receiptName, receiptSymbol);

        console.log("PerpetualMint Facet Address: ", address(perpetualMint));
        console.log("Core Address: ", address(core));

        // get PerpetualMint facet cuts
        ISolidStateDiamond.FacetCut[]
            memory facetCuts = getPerpetualMintFacetCuts(
                address(perpetualMint)
            );

        // cut PerpetualMint into Core
        ISolidStateDiamond(core).diamondCut(facetCuts, address(0), "");

        vm.stopBroadcast();
    }

    /// @dev provides the facet cuts for cutting PerpetualMint facet into Core
    /// @param facetAddress address of PerpetualMint facet
    function getPerpetualMintFacetCuts(
        address facetAddress
    ) internal pure returns (ISolidStateDiamond.FacetCut[] memory) {
        /// map the ERC1155 test related function selectors to their respective interfaces
        bytes4[] memory erc1155FunctionSelectors = new bytes4[](6);

        erc1155FunctionSelectors[0] = IERC1155.balanceOf.selector;
        erc1155FunctionSelectors[1] = IERC1155.balanceOfBatch.selector;
        erc1155FunctionSelectors[2] = IERC1155.isApprovedForAll.selector;
        erc1155FunctionSelectors[3] = IERC1155.setApprovalForAll.selector;
        erc1155FunctionSelectors[4] = IERC1155.safeTransferFrom.selector;
        erc1155FunctionSelectors[5] = IERC1155.safeBatchTransferFrom.selector;

        ISolidStateDiamond.FacetCut
            memory erc1155FacetCut = IDiamondWritableInternal.FacetCut({
                target: address(facetAddress),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: erc1155FunctionSelectors
            });

        // map the ERC1155Metadata test related function selectors to their respective interfaces
        bytes4[] memory erc1155MetadataFunctionSelectors = new bytes4[](1);

        erc1155MetadataFunctionSelectors[0] = IERC1155Metadata.uri.selector;

        ISolidStateDiamond.FacetCut
            memory erc1155MetadataFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(facetAddress),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: erc1155MetadataFunctionSelectors
            });

        // map the ERC1155Metadata test related function selectors to their respective interfaces
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
                    target: address(facetAddress),
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: erc1155MetadataFunctionSelectors
                });

        // map the Pausable test related function selectors to their respective interfaces
        bytes4[] memory pausableFunctionSelectors = new bytes4[](1);

        pausableFunctionSelectors[0] = IPausable.paused.selector;

        ISolidStateDiamond.FacetCut
            memory pausableFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(facetAddress),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: pausableFunctionSelectors
            });

        // map the PerpetualMint test related function selectors to their respective interfaces
        bytes4[] memory perpetualMintFunctionSelectors = new bytes4[](38);

        perpetualMintFunctionSelectors[0] = IPerpetualMint
            .accruedConsolationFees
            .selector;

        perpetualMintFunctionSelectors[1] = IPerpetualMint
            .accruedMintEarnings
            .selector;

        perpetualMintFunctionSelectors[2] = IPerpetualMint
            .accruedProtocolFees
            .selector;

        perpetualMintFunctionSelectors[3] = IPerpetualMint
            .attemptBatchMintWithEth
            .selector;

        perpetualMintFunctionSelectors[4] = IPerpetualMint
            .attemptBatchMintWithMint
            .selector;

        perpetualMintFunctionSelectors[5] = IPerpetualMint.BASIS.selector;

        perpetualMintFunctionSelectors[6] = IPerpetualMint.burnReceipt.selector;

        perpetualMintFunctionSelectors[7] = IPerpetualMint.cancelClaim.selector;

        perpetualMintFunctionSelectors[8] = IPerpetualMint
            .claimMintEarnings
            .selector;

        perpetualMintFunctionSelectors[9] = IPerpetualMint.claimPrize.selector;

        perpetualMintFunctionSelectors[10] = IPerpetualMint
            .claimProtocolFees
            .selector;

        perpetualMintFunctionSelectors[11] = IPerpetualMint
            .collectionMintPrice
            .selector;

        perpetualMintFunctionSelectors[12] = IPerpetualMint
            .collectionRisk
            .selector;

        perpetualMintFunctionSelectors[13] = IPerpetualMint
            .consolationFeeBP
            .selector;

        perpetualMintFunctionSelectors[14] = IPerpetualMint
            .defaultCollectionMintPrice
            .selector;

        perpetualMintFunctionSelectors[15] = IPerpetualMint
            .defaultCollectionRisk
            .selector;

        perpetualMintFunctionSelectors[16] = IPerpetualMint
            .defaultEthToMintRatio
            .selector;

        perpetualMintFunctionSelectors[17] = IPerpetualMint
            .ethToMintRatio
            .selector;

        perpetualMintFunctionSelectors[18] = IPerpetualMint.mintFeeBP.selector;

        perpetualMintFunctionSelectors[19] = IPerpetualMint.mintToken.selector;

        perpetualMintFunctionSelectors[20] = IPerpetualMint
            .onERC1155Received
            .selector;

        perpetualMintFunctionSelectors[21] = IPerpetualMint.pause.selector;

        perpetualMintFunctionSelectors[22] = IPerpetualMint.redeem.selector;

        perpetualMintFunctionSelectors[23] = IPerpetualMint
            .redemptionFeeBP
            .selector;

        perpetualMintFunctionSelectors[24] = IPerpetualMint
            .setCollectionMintPrice
            .selector;

        perpetualMintFunctionSelectors[25] = IPerpetualMint
            .setCollectionRisk
            .selector;

        perpetualMintFunctionSelectors[26] = IPerpetualMint
            .setConsolationFeeBP
            .selector;

        perpetualMintFunctionSelectors[27] = IPerpetualMint
            .setEthToMintRatio
            .selector;

        perpetualMintFunctionSelectors[28] = IPerpetualMint
            .setMintFeeBP
            .selector;

        perpetualMintFunctionSelectors[29] = IPerpetualMint
            .setMintToken
            .selector;

        perpetualMintFunctionSelectors[30] = IPerpetualMint
            .setReceiptBaseURI
            .selector;

        perpetualMintFunctionSelectors[31] = IPerpetualMint
            .setReceiptTokenURI
            .selector;

        perpetualMintFunctionSelectors[32] = IPerpetualMint
            .setRedemptionFeeBP
            .selector;

        perpetualMintFunctionSelectors[33] = IPerpetualMint.setTiers.selector;

        perpetualMintFunctionSelectors[34] = IPerpetualMint
            .setVRFConfig
            .selector;

        perpetualMintFunctionSelectors[35] = IPerpetualMint.tiers.selector;

        perpetualMintFunctionSelectors[36] = IPerpetualMint.unpause.selector;

        perpetualMintFunctionSelectors[37] = IPerpetualMint.vrfConfig.selector;

        ISolidStateDiamond.FacetCut
            memory perpetualMintFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(facetAddress),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: perpetualMintFunctionSelectors
            });

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](5);

        // omit Ownable and ERC165 since SolidStateDiamond includes those
        facetCuts[0] = erc1155FacetCut;
        facetCuts[1] = erc1155MetadataFacetCut;
        facetCuts[2] = erc1155MetadataExtensionFacetCut;
        facetCuts[3] = pausableFacetCut;
        facetCuts[4] = perpetualMintFacetCut;

        return facetCuts;
    }
}
