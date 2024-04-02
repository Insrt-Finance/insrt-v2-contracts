// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IPausable } from "@solidstate/contracts/security/pausable/IPausable.sol";
import { IERC1155Metadata } from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";

import { IPerpetualMintHarness } from "../IPerpetualMintHarness.sol";
import { PerpetualMintHarnessSupra } from "../Supra/PerpetualMintHarness.t.sol";
import { ICore } from "../../../../contracts/diamonds/Core/ICore.sol";
import { IPerpetualMint } from "../../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";
import { IPerpetualMintAdmin } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintAdmin.sol";
import { IPerpetualMintBase } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintBase.sol";
import { IPerpetualMintView } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintView.sol";
import { PerpetualMintAdmin } from "../../../../contracts/facets/PerpetualMint/PerpetualMintAdmin.sol";
import { PerpetualMintBase } from "../../../../contracts/facets/PerpetualMint/PerpetualMintBase.sol";
import { IPerpetualMintViewSupra } from "../../../../contracts/facets/PerpetualMint/Supra/IPerpetualMintView.sol";
import { PerpetualMintViewSupra } from "../../../../contracts/facets/PerpetualMint/Supra/PerpetualMintView.sol";

/// @title PerpetualMintHelper_Base
/// @dev Test helper contract for setting up PerpetualMintSupra for diamond cutting and testing, Base-specific
contract PerpetualMintHelper_Base {
    PerpetualMintAdmin public perpetualMintAdminImplementation;
    PerpetualMintBase public perpetualMintBaseImplementation;
    PerpetualMintHarnessSupra public perpetualMintHarnessSupraImplementation;
    PerpetualMintViewSupra public perpetualMintViewSupraImplementation;

    // Base mainnet Supra VRF Router address
    address public constant VRF_ROUTER =
        0x73970504Df8290E9A508676a0fbd1B7f4Bcb7f5a;

    /// @dev deploys PerpetualMintHarnessSupra implementation along with PerpetualMintAdmin, PerpetualMintBase and PerpetualMintViewSupra
    constructor() {
        perpetualMintAdminImplementation = new PerpetualMintAdmin(VRF_ROUTER);

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
        returns (ICore.FacetCut[] memory facetCuts)
    {
        // map the Pausable test related function selectors to their respective interfaces
        ICore.FacetCut memory pausableFacetCut = _createFacetCut(
            address(perpetualMintViewSupraImplementation),
            IDiamondWritableInternal.FacetCutAction.ADD,
            _getPausableFunctionSelectors()
        );

        // map the PerpetualMintBase test related function selectors to their respective interfaces
        ICore.FacetCut memory perpetualMintBaseFacetCut = _createFacetCut(
            address(perpetualMintBaseImplementation),
            IDiamondWritableInternal.FacetCutAction.ADD,
            _getPerpetualMintBaseFunctionSelectors()
        );

        // map the PerpetualMint test related function selectors to their respective interfaces
        ICore.FacetCut memory perpetualMintFacetCut = _createFacetCut(
            address(perpetualMintHarnessSupraImplementation),
            IDiamondWritableInternal.FacetCutAction.ADD,
            _getPerpetualMintFunctionSelectors()
        );

        // map the PerpetualMintAdmin test related function selectors to their respective interfaces
        bytes4[] memory perpetualMintAdminFunctionSelectors = new bytes4[](27);

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
            .setMintFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[16] = IPerpetualMintAdmin
            .setMintToken
            .selector;

        perpetualMintAdminFunctionSelectors[17] = IPerpetualMintAdmin
            .setMintTokenConsolationFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[18] = IPerpetualMintAdmin
            .setMintTokenTiers
            .selector;

        perpetualMintAdminFunctionSelectors[19] = IPerpetualMintAdmin
            .setReceiptBaseURI
            .selector;

        perpetualMintAdminFunctionSelectors[20] = IPerpetualMintAdmin
            .setReceiptTokenURI
            .selector;

        perpetualMintAdminFunctionSelectors[21] = IPerpetualMintAdmin
            .setRedemptionFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[22] = IPerpetualMintAdmin
            .setRedeemPaused
            .selector;

        perpetualMintAdminFunctionSelectors[23] = IPerpetualMintAdmin
            .setTiers
            .selector;

        perpetualMintAdminFunctionSelectors[24] = IPerpetualMintAdmin
            .setVRFConfig
            .selector;

        perpetualMintAdminFunctionSelectors[25] = IPerpetualMintAdmin
            .setVRFSubscriptionBalanceThreshold
            .selector;

        perpetualMintAdminFunctionSelectors[26] = IPerpetualMintAdmin
            .unpause
            .selector;

        ICore.FacetCut
            memory perpetualMintAdminFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: address(perpetualMintAdminImplementation),
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintAdminFunctionSelectors
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

        ICore.FacetCut
            memory perpetualMintViewFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: address(perpetualMintViewSupraImplementation),
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintViewFunctionSelectors
                });

        // map the PerpetualMintViewSupra related function selectors to their respective interfaces
        ICore.FacetCut memory perpetualMintViewSupraFacetCut = _createFacetCut(
            address(perpetualMintViewSupraImplementation),
            IDiamondWritableInternal.FacetCutAction.ADD,
            _getPerpetualMintViewSupraFunctionSelectors()
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
            .exposed_requests
            .selector;

        perpetualMintHarnessFunctionSelectors[7] = IPerpetualMintHarness
            .exposed_resolveMints
            .selector;

        perpetualMintHarnessFunctionSelectors[8] = IPerpetualMintHarness
            .exposed_resolveMintsForMint
            .selector;

        perpetualMintHarnessFunctionSelectors[9] = bytes4(
            keccak256("mintReceipts(address,uint256)")
        );

        perpetualMintHarnessFunctionSelectors[10] = bytes4(
            keccak256("mintReceipts(address,uint256,uint256)")
        );

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

        ICore.FacetCut
            memory perpetualMintHarnessFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: address(perpetualMintHarnessSupraImplementation),
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintHarnessFunctionSelectors
                });

        // map the PerpetualMintHarnessSupra test related function selectors to their respective interfaces
        ICore.FacetCut
            memory perpetualMintHarnessSupraFacetCut = _createFacetCut(
                address(perpetualMintHarnessSupraImplementation),
                IDiamondWritableInternal.FacetCutAction.ADD,
                _getPerpetualMintHarnessSupraFunctionSelectors()
            );

        // map the VRFConsumerBaseV2 test related function selectors to their respective interfaces
        ICore.FacetCut memory vrfConsumerBaseV2FacetCut = _createFacetCut(
            address(perpetualMintHarnessSupraImplementation),
            IDiamondWritableInternal.FacetCutAction.ADD,
            _getVRFConsumerBaseV2FunctionSelectors()
        );

        facetCuts = new ICore.FacetCut[](9);

        facetCuts[0] = pausableFacetCut;

        facetCuts[1] = perpetualMintBaseFacetCut;

        facetCuts[2] = perpetualMintFacetCut;

        facetCuts[3] = perpetualMintAdminFacetCut;

        facetCuts[4] = perpetualMintViewFacetCut;

        facetCuts[5] = perpetualMintViewSupraFacetCut;

        facetCuts[6] = perpetualMintHarnessFacetCut;

        facetCuts[7] = perpetualMintHarnessSupraFacetCut;

        facetCuts[8] = vrfConsumerBaseV2FacetCut;
    }

    function _createFacetCut(
        address target,
        IDiamondWritableInternal.FacetCutAction action,
        bytes4[] memory selectors
    ) private pure returns (ICore.FacetCut memory) {
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

    function _getPerpetualMintFunctionSelectors()
        private
        pure
        returns (bytes4[] memory selectors)
    {
        selectors = new bytes4[](7);

        selectors[0] = IPerpetualMint.attemptBatchMintForMintWithEth.selector;

        selectors[1] = IPerpetualMint.attemptBatchMintForMintWithMint.selector;

        selectors[2] = IPerpetualMint.attemptBatchMintWithEth.selector;

        selectors[3] = IPerpetualMint.attemptBatchMintWithMint.selector;

        selectors[4] = IPerpetualMint.claimPrize.selector;

        selectors[5] = IPerpetualMint.fundConsolationFees.selector;

        selectors[6] = IPerpetualMint.redeem.selector;
    }

    function _getPerpetualMintBaseFunctionSelectors()
        private
        pure
        returns (bytes4[] memory selectors)
    {
        selectors = new bytes4[](1);

        selectors[0] = IPerpetualMintBase.onERC1155Received.selector;
    }

    function _getPerpetualMintHarnessSupraFunctionSelectors()
        private
        pure
        returns (bytes4[] memory selectors)
    {
        selectors = new bytes4[](1);

        selectors[0] = IPerpetualMintHarness
            .exposed_requestRandomWordsSupra
            .selector;
    }

    function _getPerpetualMintViewSupraFunctionSelectors()
        private
        pure
        returns (bytes4[] memory selectors)
    {
        selectors = new bytes4[](1);

        selectors[0] = IPerpetualMintViewSupra
            .calculateMintResultSupra
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
