// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IPausable } from "@solidstate/contracts/security/pausable/IPausable.sol";
import { IERC1155Metadata } from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";

import { IPerpetualMintHarness } from "./IPerpetualMintHarness.sol";
import { PerpetualMintHarness } from "./PerpetualMintHarness.t.sol";
import { VRFConsumerBaseV2Mock } from "../../mocks/VRFConsumerBaseV2Mock.sol";
import { IPerpetualMint } from "../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";
import { IPerpetualMintBase } from "../../../contracts/facets/PerpetualMint/IPerpetualMintBase.sol";
import { IPerpetualMintView } from "../../../contracts/facets/PerpetualMint/IPerpetualMintView.sol";
import { PerpetualMintBase } from "../../../contracts/facets/PerpetualMint/PerpetualMintBase.sol";
import { PerpetualMintView } from "../../../contracts/facets/PerpetualMint/PerpetualMintView.sol";
import { PerpetualMintStorage as Storage } from "../../../contracts/facets/PerpetualMint/Storage.sol";

/// @title PerpetualMintHelper
/// @dev Test helper contract for setting up PerpetualMint for diamond cutting and testing
contract PerpetualMintHelper {
    PerpetualMintBase public perpetualMintBaseImplementation;
    PerpetualMintHarness public perpetualMintHarnessImplementation;
    PerpetualMintView public perpetualMintViewImplementation;

    // Arbitrum mainnet Chainlink VRF Coordinator address
    address public constant VRF_COORDINATOR =
        0x41034678D6C633D8a95c75e1138A360a28bA15d1;

    /// @dev deploys PerpetualMintHarness implementation along with PerpetualMintBase and PerpetualMintView
    constructor() {
        perpetualMintBaseImplementation = new PerpetualMintBase(
            VRF_COORDINATOR
        );

        perpetualMintHarnessImplementation = new PerpetualMintHarness(
            VRF_COORDINATOR
        );

        perpetualMintViewImplementation = new PerpetualMintView(
            VRF_COORDINATOR
        );
    }

    /// @dev provides the facet cuts for setting up PerpetualMintBase in the Core Diamond for testing
    function getPerpetualMintBaseTestFacetCuts()
        external
        view
        returns (ISolidStateDiamond.FacetCut[] memory)
    {
        // map the ERC1155 test related function selectors to their respective interfaces
        bytes4[] memory erc1155FunctionSelectors = new bytes4[](1);

        erc1155FunctionSelectors[0] = IERC1155.balanceOf.selector;

        ISolidStateDiamond.FacetCut
            memory erc1155FacetCut = IDiamondWritableInternal.FacetCut({
                target: address(perpetualMintBaseImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: erc1155FunctionSelectors
            });

        // map the PerpetualMintBase test related function selectors to their respective interfaces
        bytes4[] memory perpetualMintBaseFunctionSelectors = new bytes4[](1);

        perpetualMintBaseFunctionSelectors[0] = IPerpetualMintBase
            .onERC1155Received
            .selector;

        ISolidStateDiamond.FacetCut
            memory perpetualMintBaseFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: address(perpetualMintBaseImplementation),
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintBaseFunctionSelectors
                });

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](2);

        facetCuts[0] = erc1155FacetCut;

        facetCuts[1] = perpetualMintBaseFacetCut;

        return facetCuts;
    }

    /// @dev provides the facet cuts for setting up PerpetualMint in the Core Diamond for testing
    function getPerpetualMintTestFacetCuts()
        external
        view
        returns (ISolidStateDiamond.FacetCut[] memory)
    {
        // map the ERC1155Metadata test related function selectors to their respective interfaces
        bytes4[] memory erc1155MetadataFunctionSelectors = new bytes4[](1);

        erc1155MetadataFunctionSelectors[0] = IERC1155Metadata.uri.selector;

        ISolidStateDiamond.FacetCut
            memory erc1155MetadataFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(perpetualMintHarnessImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: erc1155MetadataFunctionSelectors
            });

        // map the Pausable test related function selectors to their respective interfaces
        bytes4[] memory pausableFunctionSelectors = new bytes4[](1);

        pausableFunctionSelectors[0] = IPausable.paused.selector;

        ISolidStateDiamond.FacetCut
            memory pausableFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(perpetualMintHarnessImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: pausableFunctionSelectors
            });

        // map the PerpetualMint test related function selectors to their respective interfaces
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

        ISolidStateDiamond.FacetCut
            memory perpetualMintFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(perpetualMintHarnessImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: perpetualMintFunctionSelectors
            });

        // map the PerpetualMintView test related function selectors to their respective interfaces
        bytes4[] memory perpetualMintViewFunctionSelectors = new bytes4[](25);

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
            .collectionReferralFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[10] = IPerpetualMintView
            .collectionRisk
            .selector;

        perpetualMintViewFunctionSelectors[11] = IPerpetualMintView
            .defaultCollectionMintPrice
            .selector;

        perpetualMintViewFunctionSelectors[12] = IPerpetualMintView
            .defaultCollectionReferralFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[13] = IPerpetualMintView
            .defaultCollectionRisk
            .selector;

        perpetualMintViewFunctionSelectors[14] = IPerpetualMintView
            .defaultEthToMintRatio
            .selector;

        perpetualMintViewFunctionSelectors[15] = IPerpetualMintView
            .ethToMintRatio
            .selector;

        perpetualMintViewFunctionSelectors[16] = IPerpetualMintView
            .mintFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[17] = IPerpetualMintView
            .mintToken
            .selector;

        perpetualMintViewFunctionSelectors[18] = IPerpetualMintView
            .mintTokenConsolationFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[19] = IPerpetualMintView
            .mintTokenTiers
            .selector;

        perpetualMintViewFunctionSelectors[20] = IPerpetualMintView
            .redemptionFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[21] = IPerpetualMintView
            .redeemPaused
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

        ISolidStateDiamond.FacetCut
            memory perpetualMintViewFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: address(perpetualMintViewImplementation),
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintViewFunctionSelectors
                });

        // map the PerpetualMintHarness test related function selectors to their respective interfaces
        bytes4[] memory perpetualMintHarnessFunctionSelectors = new bytes4[](
            15
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
            .exposed_requestRandomWords
            .selector;

        perpetualMintHarnessFunctionSelectors[7] = IPerpetualMintHarness
            .exposed_requests
            .selector;

        perpetualMintHarnessFunctionSelectors[8] = IPerpetualMintHarness
            .exposed_resolveMints
            .selector;

        perpetualMintHarnessFunctionSelectors[9] = IPerpetualMintHarness
            .exposed_resolveMintsForMint
            .selector;

        perpetualMintHarnessFunctionSelectors[10] = IPerpetualMintHarness
            .mintReceipts
            .selector;

        perpetualMintHarnessFunctionSelectors[11] = IPerpetualMintHarness
            .setConsolationFees
            .selector;

        perpetualMintHarnessFunctionSelectors[12] = IPerpetualMintHarness
            .setMintEarnings
            .selector;

        perpetualMintHarnessFunctionSelectors[13] = IPerpetualMintHarness
            .setProtocolFees
            .selector;

        perpetualMintHarnessFunctionSelectors[14] = IPerpetualMintHarness
            .setRequests
            .selector;

        ISolidStateDiamond.FacetCut
            memory perpetualMintHarnessFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: address(perpetualMintHarnessImplementation),
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintHarnessFunctionSelectors
                });

        // map the VRFConsumerBaseV2Mock test related function selectors to their respective interfaces
        bytes4[] memory vrfConsumerBaseV2MockFunctionSelectors = new bytes4[](
            1
        );

        vrfConsumerBaseV2MockFunctionSelectors[0] = VRFConsumerBaseV2Mock
            .rawFulfillRandomWordsPlus
            .selector;

        ISolidStateDiamond.FacetCut
            memory vrfConsumerBaseV2MockFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: address(perpetualMintHarnessImplementation),
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: vrfConsumerBaseV2MockFunctionSelectors
                });

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](6);

        facetCuts[0] = erc1155MetadataFacetCut;

        facetCuts[1] = pausableFacetCut;

        facetCuts[2] = perpetualMintFacetCut;

        facetCuts[3] = perpetualMintViewFacetCut;

        facetCuts[4] = perpetualMintHarnessFacetCut;

        facetCuts[5] = vrfConsumerBaseV2MockFacetCut;

        return facetCuts;
    }
}
