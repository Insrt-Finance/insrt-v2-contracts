// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IPausable } from "@solidstate/contracts/security/pausable/IPausable.sol";
import { IERC1155Metadata } from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";

import { PerpetualMintHarnessBase } from "./PerpetualMintHarness.t.sol";
import { IPerpetualMintHarness } from "../IPerpetualMintHarness.sol";
import { IPerpetualMint } from "../../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";
import { IPerpetualMintView } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintView.sol";
import { PerpetualMintView } from "../../../../contracts/facets/PerpetualMint/PerpetualMintView.sol";

/// @title PerpetualMintHelperBase
/// @dev Test helper contract for setting up PerpetualMint facet for diamond cutting and testing, Base-specific
contract PerpetualMintHelperBase {
    PerpetualMintHarnessBase public perpetualMintHarnessBaseImplementation;
    PerpetualMintView public perpetualMintViewImplementation;

    // Base mainnet Supra VRF Router address
    address public constant VRF_ROUTER =
        0x73970504Df8290E9A508676a0fbd1B7f4Bcb7f5a;

    /// @dev deploys PerpetualMintHarnessBase & PerpetualMintView implementations
    constructor() {
        perpetualMintHarnessBaseImplementation = new PerpetualMintHarnessBase(
            VRF_ROUTER
        );
        perpetualMintViewImplementation = new PerpetualMintView(VRF_ROUTER);
    }

    /// @dev provides the facet cuts for setting up PerpetualMint in coreDiamond
    function getFacetCuts()
        external
        view
        returns (ISolidStateDiamond.FacetCut[] memory)
    {
        // map the ERC1155 test related function selectors to their respective interfaces
        bytes4[] memory erc1155FunctionSelectors = new bytes4[](1);

        erc1155FunctionSelectors[0] = IERC1155.balanceOf.selector;

        ISolidStateDiamond.FacetCut
            memory erc1155FacetCut = IDiamondWritableInternal.FacetCut({
                target: address(perpetualMintHarnessBaseImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: erc1155FunctionSelectors
            });

        // map the ERC1155Metadata test related function selectors to their respective interfaces
        bytes4[] memory erc1155MetadataFunctionSelectors = new bytes4[](1);

        erc1155MetadataFunctionSelectors[0] = IERC1155Metadata.uri.selector;

        ISolidStateDiamond.FacetCut
            memory erc1155MetadataFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(perpetualMintHarnessBaseImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: erc1155MetadataFunctionSelectors
            });

        // map the Pausable test related function selectors to their respective interfaces
        bytes4[] memory pausableFunctionSelectors = new bytes4[](1);

        pausableFunctionSelectors[0] = IPausable.paused.selector;

        ISolidStateDiamond.FacetCut
            memory pausableFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(perpetualMintHarnessBaseImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: pausableFunctionSelectors
            });

        // map the PerpetualMint test related function selectors to their respective interfaces
        bytes4[] memory perpetualMintFunctionSelectors = new bytes4[](28);

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

        perpetualMintFunctionSelectors[9] = IPerpetualMint
            .onERC1155Received
            .selector;

        perpetualMintFunctionSelectors[10] = IPerpetualMint.pause.selector;

        perpetualMintFunctionSelectors[11] = IPerpetualMint.redeem.selector;

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
            .setConsolationFeeBP
            .selector;

        perpetualMintFunctionSelectors[17] = IPerpetualMint
            .setEthToMintRatio
            .selector;

        perpetualMintFunctionSelectors[18] = IPerpetualMint
            .setMintFeeBP
            .selector;

        perpetualMintFunctionSelectors[19] = IPerpetualMint
            .setMintToken
            .selector;

        perpetualMintFunctionSelectors[20] = IPerpetualMint
            .setReceiptBaseURI
            .selector;

        perpetualMintFunctionSelectors[21] = IPerpetualMint
            .setReceiptTokenURI
            .selector;

        perpetualMintFunctionSelectors[22] = IPerpetualMint
            .setRedemptionFeeBP
            .selector;

        perpetualMintFunctionSelectors[23] = IPerpetualMint
            .setRedeemPaused
            .selector;

        perpetualMintFunctionSelectors[24] = IPerpetualMint.setTiers.selector;

        perpetualMintFunctionSelectors[25] = IPerpetualMint
            .setVRFConfig
            .selector;

        perpetualMintFunctionSelectors[26] = IPerpetualMint
            .setVRFSubscriptionBalanceThreshold
            .selector;

        perpetualMintFunctionSelectors[27] = IPerpetualMint.unpause.selector;

        ISolidStateDiamond.FacetCut
            memory perpetualMintFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(perpetualMintHarnessBaseImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: perpetualMintFunctionSelectors
            });

        // map the PerpetualMintView test related function selectors to their respective interfaces
        bytes4[] memory perpetualMintViewFunctionSelectors = new bytes4[](21);

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
            .collectionMintFeeDistributionRatioBP
            .selector;

        perpetualMintViewFunctionSelectors[6] = IPerpetualMintView
            .collectionMintMultiplier
            .selector;

        perpetualMintViewFunctionSelectors[7] = IPerpetualMintView
            .collectionMintPrice
            .selector;

        perpetualMintViewFunctionSelectors[8] = IPerpetualMintView
            .collectionRisk
            .selector;

        perpetualMintViewFunctionSelectors[9] = IPerpetualMintView
            .consolationFeeBP
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
            .redemptionFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[17] = IPerpetualMintView
            .redeemPaused
            .selector;

        perpetualMintViewFunctionSelectors[18] = IPerpetualMintView
            .tiers
            .selector;

        perpetualMintViewFunctionSelectors[19] = IPerpetualMintView
            .vrfConfig
            .selector;

        perpetualMintViewFunctionSelectors[20] = IPerpetualMintView
            .vrfSubscriptionBalanceThreshold
            .selector;

        ISolidStateDiamond.FacetCut
            memory perpetualMintViewFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: address(perpetualMintViewImplementation),
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintViewFunctionSelectors
                });

        // map the PerpetualMintHarness test related function selectors to their respective interfaces
        bytes4[] memory perpetualMintHarnessFunctionSelectors = new bytes4[](
            14
        );

        perpetualMintHarnessFunctionSelectors[0] = IPerpetualMintHarness
            .exposed_enforceBasis
            .selector;

        perpetualMintHarnessFunctionSelectors[1] = IPerpetualMintHarness
            .exposed_enforceNoPendingMints
            .selector;

        perpetualMintHarnessFunctionSelectors[2] = IPerpetualMintHarness
            .exposed_normalizeValue
            .selector;

        perpetualMintHarnessFunctionSelectors[3] = IPerpetualMintHarness
            .exposed_pendingRequestsAdd
            .selector;

        perpetualMintHarnessFunctionSelectors[4] = IPerpetualMintHarness
            .exposed_pendingRequestsAt
            .selector;

        perpetualMintHarnessFunctionSelectors[5] = IPerpetualMintHarness
            .exposed_pendingRequestsLength
            .selector;

        perpetualMintHarnessFunctionSelectors[6] = IPerpetualMintHarness
            .exposed_requestRandomWordsBase
            .selector;

        perpetualMintHarnessFunctionSelectors[7] = IPerpetualMintHarness
            .exposed_requests
            .selector;

        perpetualMintHarnessFunctionSelectors[8] = IPerpetualMintHarness
            .exposed_resolveMints
            .selector;

        perpetualMintHarnessFunctionSelectors[9] = IPerpetualMintHarness
            .mintReceipts
            .selector;

        perpetualMintHarnessFunctionSelectors[10] = IPerpetualMintHarness
            .setConsolationFees
            .selector;

        perpetualMintHarnessFunctionSelectors[11] = IPerpetualMintHarness
            .setMintEarnings
            .selector;

        perpetualMintHarnessFunctionSelectors[12] = IPerpetualMintHarness
            .setProtocolFees
            .selector;

        perpetualMintHarnessFunctionSelectors[13] = IPerpetualMintHarness
            .setRequests
            .selector;

        ISolidStateDiamond.FacetCut
            memory perpetualMintHarnessFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: address(perpetualMintHarnessBaseImplementation),
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintHarnessFunctionSelectors
                });

        // map the VRFConsumerBaseV2 test related function selectors to their respective interfaces
        bytes4[] memory vrfConsumerBaseV2FunctionSelectors = new bytes4[](1);

        vrfConsumerBaseV2FunctionSelectors[0] = VRFConsumerBaseV2
            .rawFulfillRandomWords
            .selector;

        ISolidStateDiamond.FacetCut
            memory vrfConsumerBaseV2FacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: address(perpetualMintHarnessBaseImplementation),
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: vrfConsumerBaseV2FunctionSelectors
                });

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](7);

        facetCuts[0] = erc1155FacetCut;

        facetCuts[1] = erc1155MetadataFacetCut;

        facetCuts[2] = pausableFacetCut;

        facetCuts[3] = perpetualMintFacetCut;

        facetCuts[4] = perpetualMintViewFacetCut;

        facetCuts[5] = perpetualMintHarnessFacetCut;

        facetCuts[6] = vrfConsumerBaseV2FacetCut;

        return facetCuts;
    }
}
