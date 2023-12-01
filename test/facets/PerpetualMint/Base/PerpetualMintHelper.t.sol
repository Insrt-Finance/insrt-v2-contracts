// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IPausable } from "@solidstate/contracts/security/pausable/IPausable.sol";
import { IERC1155Metadata } from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";

import { PerpetualMintHarness_Base } from "./PerpetualMintHarness.t.sol";
import { IPerpetualMintHarness } from "../IPerpetualMintHarness.sol";
import { IPerpetualMintView_Base } from "../../../../contracts/facets/PerpetualMint/Base/IPerpetualMintView.sol";
import { PerpetualMintView_Base } from "../../../../contracts/facets/PerpetualMint/Base/PerpetualMintView.sol";
import { IPerpetualMint } from "../../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";
import { IPerpetualMintBase } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintBase.sol";
import { IPerpetualMintView } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintView.sol";
import { PerpetualMintBase } from "../../../../contracts/facets/PerpetualMint/PerpetualMintBase.sol";

/// @title PerpetualMintHelper_Base
/// @dev Test helper contract for setting up PerpetualMint_Base for diamond cutting and testing, Base-specific
contract PerpetualMintHelper_Base {
    PerpetualMintBase public perpetualMintBaseImplementation;
    PerpetualMintHarness_Base public perpetualMintHarness_BaseImplementation;
    PerpetualMintView_Base public perpetualMintView_BaseImplementation;

    // Base mainnet Supra VRF Router address
    address public constant VRF_ROUTER =
        0x73970504Df8290E9A508676a0fbd1B7f4Bcb7f5a;

    /// @dev deploys PerpetualMintHarness_Base implementation along with PerpetualMintBase and PerpetualMintView_Base
    constructor() {
        perpetualMintBaseImplementation = new PerpetualMintBase(VRF_ROUTER);

        perpetualMintHarness_BaseImplementation = new PerpetualMintHarness_Base(
            VRF_ROUTER
        );

        perpetualMintView_BaseImplementation = new PerpetualMintView_Base(
            VRF_ROUTER
        );
    }

    /// @dev provides the facet cuts for setting up PerpetualMint in coreDiamond
    function getFacetCuts()
        external
        view
        returns (ISolidStateDiamond.FacetCut[] memory facetCuts)
    {
        // map the Pausable test related function selectors to their respective interfaces
        bytes4[] memory pausableFunctionSelectors = new bytes4[](1);

        pausableFunctionSelectors[0] = IPausable.paused.selector;

        ISolidStateDiamond.FacetCut
            memory pausableFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(perpetualMintHarness_BaseImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: pausableFunctionSelectors
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

        // map the PerpetualMint test related function selectors to their respective interfaces
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
            .setCollectionMintFeeDistributionRatioBP
            .selector;

        perpetualMintFunctionSelectors[12] = IPerpetualMint
            .setCollectionMintMultiplier
            .selector;

        perpetualMintFunctionSelectors[13] = IPerpetualMint
            .setCollectionMintPrice
            .selector;

        perpetualMintFunctionSelectors[14] = IPerpetualMint
            .setCollectionRisk
            .selector;

        perpetualMintFunctionSelectors[15] = IPerpetualMint
            .setConsolationFeeBP
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
                target: address(perpetualMintHarness_BaseImplementation),
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
                    target: address(perpetualMintView_BaseImplementation),
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
                    target: address(perpetualMintView_BaseImplementation),
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintView_BaseFunctionSelectors
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
                    target: address(perpetualMintHarness_BaseImplementation),
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
                    target: address(perpetualMintHarness_BaseImplementation),
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: vrfConsumerBaseV2FunctionSelectors
                });

        facetCuts = new ISolidStateDiamond.FacetCut[](7);

        facetCuts[0] = pausableFacetCut;

        facetCuts[1] = perpetualMintBaseFacetCut;

        facetCuts[2] = perpetualMintFacetCut;

        facetCuts[3] = perpetualMintViewFacetCut;

        facetCuts[4] = perpetualMintView_BaseFacetCut;

        facetCuts[5] = perpetualMintHarnessFacetCut;

        facetCuts[6] = vrfConsumerBaseV2FacetCut;
    }
}
