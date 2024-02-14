// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IPausable } from "@solidstate/contracts/security/pausable/IPausable.sol";
import { IERC1155Metadata } from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";

import { IPerpetualMintHarness } from "../IPerpetualMintHarness.sol";
import { PerpetualMintHarnessSupra } from "../Supra/PerpetualMintHarness.t.sol";
import { IPerpetualMint } from "../../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";
import { IPerpetualMintBase } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintBase.sol";
import { IPerpetualMintView } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintView.sol";
import { PerpetualMintBase } from "../../../../contracts/facets/PerpetualMint/PerpetualMintBase.sol";
import { IPerpetualMintViewSupra } from "../../../../contracts/facets/PerpetualMint/Supra/IPerpetualMintView.sol";
import { PerpetualMintViewSupra } from "../../../../contracts/facets/PerpetualMint/Supra/PerpetualMintView.sol";

/// @title PerpetualMintHelper_Base
/// @dev Test helper contract for setting up PerpetualMintSupra for diamond cutting and testing, Base-specific
contract PerpetualMintHelper_Base {
    PerpetualMintBase public perpetualMintBaseImplementation;
    PerpetualMintHarnessSupra public perpetualMintHarnessSupraImplementation;
    PerpetualMintViewSupra public perpetualMintViewSupraImplementation;

    // Base mainnet Supra VRF Router address
    address public constant VRF_ROUTER =
        0x73970504Df8290E9A508676a0fbd1B7f4Bcb7f5a;

    /// @dev deploys PerpetualMintHarnessSupra implementation along with PerpetualMintBase and PerpetualMintViewSupra
    constructor() {
        perpetualMintBaseImplementation = new PerpetualMintBase(VRF_ROUTER);

        perpetualMintHarnessSupraImplementation = new PerpetualMintHarnessSupra(
            VRF_ROUTER
        );

        perpetualMintViewSupraImplementation = new PerpetualMintViewSupra(
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
                target: address(perpetualMintViewSupraImplementation),
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
                target: address(perpetualMintHarnessSupraImplementation),
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

        ISolidStateDiamond.FacetCut
            memory perpetualMintViewFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: address(perpetualMintViewSupraImplementation),
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

        ISolidStateDiamond.FacetCut
            memory perpetualMintViewSupraFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: address(perpetualMintViewSupraImplementation),
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintViewSupraFunctionSelectors
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
            .exposed_requestRandomWordsSupra
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
                    target: address(perpetualMintHarnessSupraImplementation),
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
                    target: address(perpetualMintHarnessSupraImplementation),
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: vrfConsumerBaseV2FunctionSelectors
                });

        facetCuts = new ISolidStateDiamond.FacetCut[](7);

        facetCuts[0] = pausableFacetCut;

        facetCuts[1] = perpetualMintBaseFacetCut;

        facetCuts[2] = perpetualMintFacetCut;

        facetCuts[3] = perpetualMintViewFacetCut;

        facetCuts[4] = perpetualMintViewSupraFacetCut;

        facetCuts[5] = perpetualMintHarnessFacetCut;

        facetCuts[6] = vrfConsumerBaseV2FacetCut;
    }
}
