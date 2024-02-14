// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IPausable } from "@solidstate/contracts/security/pausable/IPausable.sol";
import { IERC1155Metadata } from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";

import { IPerpetualMintHarnessBlast } from "../IPerpetualMintHarness.sol";
import { IPerpetualMintHarness } from "../../IPerpetualMintHarness.sol";
import { PerpetualMintHarnessBlastSupra } from "./PerpetualMintHarness.t.sol";
import { IPerpetualMintBlastSupra } from "../../../../../contracts/facets/PerpetualMint/Blast/Supra/IPerpetualMint.sol";
import { IPerpetualMintViewBlastSupra } from "../../../../../contracts/facets/PerpetualMint/Blast/Supra/IPerpetualMintView.sol";
import { PerpetualMintViewBlastSupra } from "../../../../../contracts/facets/PerpetualMint/Blast/Supra/PerpetualMintView.sol";
import { IPerpetualMint } from "../../../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";
import { IPerpetualMintBase } from "../../../../../contracts/facets/PerpetualMint/IPerpetualMintBase.sol";
import { IPerpetualMintView } from "../../../../../contracts/facets/PerpetualMint/IPerpetualMintView.sol";
import { PerpetualMintBase } from "../../../../../contracts/facets/PerpetualMint/PerpetualMintBase.sol";

/// @title PerpetualMintHelper_BlastSupra
/// @dev Test helper contract for setting up PerpetualMintSupra for diamond cutting and testing, Blast-specific
contract PerpetualMintHelper_BlastSupra {
    PerpetualMintBase public perpetualMintBaseImplementation;
    PerpetualMintHarnessBlastSupra
        public perpetualMintHarnessBlastSupraImplementation;
    PerpetualMintViewBlastSupra
        public perpetualMintViewBlastSupraImplementation;

    // Blast Sepolia Supra VRF Router address (as of this writing, Blast mainnet is not live)
    address public constant VRF_ROUTER =
        0x2c9e897Ed7d4B1a917046c0d5B0770FE6094A181;

    /// @dev deploys PerpetualMintHarnessBlastSupra implementation along with PerpetualMintBase and PerpetualMintViewBlastSupra
    constructor() {
        perpetualMintBaseImplementation = new PerpetualMintBase(VRF_ROUTER);

        perpetualMintHarnessBlastSupraImplementation = new PerpetualMintHarnessBlastSupra(
            VRF_ROUTER
        );

        perpetualMintViewBlastSupraImplementation = new PerpetualMintViewBlastSupra(
            VRF_ROUTER
        );
    }

    /// @dev provides the facet cuts for setting up PerpetualMint in coreDiamond
    function getFacetCuts()
        external
        view
        returns (ISolidStateDiamond.FacetCut[] memory facetCuts)
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

        // map the Pausable test related function selectors to their respective interfaces
        ISolidStateDiamond.FacetCut memory pausableFacetCut = _createFacetCut(
            address(perpetualMintViewBlastSupraImplementation),
            IDiamondWritableInternal.FacetCutAction.ADD,
            _getPausableFunctionSelectors()
        );

        // map the PerpetualMintBase test related function selectors to their respective interfaces
        ISolidStateDiamond.FacetCut
            memory perpetualMintBaseFacetCut = _createFacetCut(
                address(perpetualMintBaseImplementation),
                IDiamondWritableInternal.FacetCutAction.ADD,
                _getPerpetualMintBaseFunctionSelectors()
            );

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
            memory perpetualMintFacetCut = _createFacetCut(
                address(perpetualMintHarnessBlastSupraImplementation),
                IDiamondWritableInternal.FacetCutAction.ADD,
                perpetualMintFunctionSelectors
            );

        // map the PerpetualMintBlastSupra test related function selectors to their respective interfaces
        ISolidStateDiamond.FacetCut
            memory perpetualMintBlastSupraFacetCut = _createFacetCut(
                address(perpetualMintHarnessBlastSupraImplementation),
                IDiamondWritableInternal.FacetCutAction.ADD,
                _getPerpetualMintBlastSupraFunctionSelectors()
            );

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
            memory perpetualMintViewFacetCut = _createFacetCut(
                address(perpetualMintViewBlastSupraImplementation),
                IDiamondWritableInternal.FacetCutAction.ADD,
                perpetualMintViewFunctionSelectors
            );

        // map the PerpetualMintViewBlastSupra related function selectors to their respective interfaces
        ISolidStateDiamond.FacetCut
            memory perpetualMintViewBlastSupraFacetCut = _createFacetCut(
                address(perpetualMintViewBlastSupraImplementation),
                IDiamondWritableInternal.FacetCutAction.ADD,
                _getPerpetualMintViewBlastSupraFunctionSelectors()
            );

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
            memory perpetualMintHarnessFacetCut = _createFacetCut(
                address(perpetualMintHarnessBlastSupraImplementation),
                IDiamondWritableInternal.FacetCutAction.ADD,
                perpetualMintHarnessFunctionSelectors
            );

        // map the PerpetualMintHarnessBlast test related function selectors to their respective interfaces
        ISolidStateDiamond.FacetCut
            memory perpetualMintHarnessBlastFacetCut = _createFacetCut(
                address(perpetualMintHarnessBlastSupraImplementation),
                IDiamondWritableInternal.FacetCutAction.ADD,
                _getPerpetualMintHarnessBlastFunctionSelectors()
            );

        // map the VRFConsumerBaseV2 test related function selectors to their respective interfaces
        ISolidStateDiamond.FacetCut
            memory vrfConsumerBaseV2FacetCut = _createFacetCut(
                address(perpetualMintHarnessBlastSupraImplementation),
                IDiamondWritableInternal.FacetCutAction.ADD,
                _getVRFConsumerBaseV2FunctionSelectors()
            );

        facetCuts = new ISolidStateDiamond.FacetCut[](10);

        facetCuts[0] = erc1155FacetCut;

        facetCuts[1] = pausableFacetCut;

        facetCuts[2] = perpetualMintBaseFacetCut;

        facetCuts[3] = perpetualMintBlastSupraFacetCut;

        facetCuts[4] = perpetualMintFacetCut;

        facetCuts[5] = perpetualMintViewFacetCut;

        facetCuts[6] = perpetualMintViewBlastSupraFacetCut;

        facetCuts[7] = perpetualMintHarnessFacetCut;

        facetCuts[8] = perpetualMintHarnessBlastFacetCut;

        facetCuts[9] = vrfConsumerBaseV2FacetCut;
    }

    function _createFacetCut(
        address target,
        IDiamondWritableInternal.FacetCutAction action,
        bytes4[] memory selectors
    ) private pure returns (ISolidStateDiamond.FacetCut memory) {
        return
            IDiamondWritableInternal.FacetCut({
                target: target,
                action: action,
                selectors: selectors
            });
    }

    function _getPausableFunctionSelectors()
        private
        pure
        returns (bytes4[] memory selectors)
    {
        selectors = new bytes4[](1);

        selectors[0] = IPausable.paused.selector;
    }

    function _getPerpetualMintBaseFunctionSelectors()
        private
        pure
        returns (bytes4[] memory selectors)
    {
        selectors = new bytes4[](1);

        selectors[0] = IPerpetualMintBase.onERC1155Received.selector;
    }

    function _getPerpetualMintBlastSupraFunctionSelectors()
        private
        pure
        returns (bytes4[] memory selectors)
    {
        selectors = new bytes4[](1);

        selectors[0] = IPerpetualMintBlastSupra.setBlastYieldRisk.selector;
    }

    function _getPerpetualMintHarnessBlastFunctionSelectors()
        private
        pure
        returns (bytes4[] memory selectors)
    {
        selectors = new bytes4[](2);

        selectors[0] = IPerpetualMintHarnessBlast
            .exposed_resolveMintsBlast
            .selector;

        selectors[1] = IPerpetualMintHarnessBlast
            .exposed_resolveMintsForMintBlast
            .selector;
    }

    function _getPerpetualMintViewBlastSupraFunctionSelectors()
        private
        pure
        returns (bytes4[] memory selectors)
    {
        selectors = new bytes4[](2);

        selectors[0] = IPerpetualMintViewBlastSupra.blastYieldRisk.selector;

        selectors[1] = IPerpetualMintViewBlastSupra
            .calculateMintResultBlastSupra
            .selector;
    }

    function _getVRFConsumerBaseV2FunctionSelectors()
        private
        pure
        returns (bytes4[] memory selectors)
    {
        selectors = new bytes4[](1);

        selectors[0] = VRFConsumerBaseV2.rawFulfillRandomWords.selector;
    }
}
