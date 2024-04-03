// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IPausable } from "@solidstate/contracts/security/pausable/IPausable.sol";
import { IERC1155Metadata } from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";

import { PerpetualMintHarnessSupraBlast } from "./PerpetualMintHarness.t.sol";
import { IPerpetualMintHarnessBlast } from "../IPerpetualMintHarness.sol";
import { IPerpetualMintHarness } from "../../IPerpetualMintHarness.sol";
import { PerpetualMintHarnessSupra } from "../../Supra/PerpetualMintHarness.t.sol";
import { ICore } from "../../../../../contracts/diamonds/Core/ICore.sol";
import { IPerpetualMintAdminBlast } from "../../../../../contracts/facets/PerpetualMint/Blast/IPerpetualMintAdmin.sol";
import { IPerpetualMintViewBlast } from "../../../../../contracts/facets/PerpetualMint/Blast/IPerpetualMintView.sol";
import { PerpetualMintAdminBlast } from "../../../../../contracts/facets/PerpetualMint/Blast/PerpetualMintAdmin.sol";
import { IPerpetualMintViewSupraBlast } from "../../../../../contracts/facets/PerpetualMint/Blast/Supra/IPerpetualMintView.sol";
import { PerpetualMintViewSupraBlast } from "../../../../../contracts/facets/PerpetualMint/Blast/Supra/PerpetualMintView.sol";
import { IPerpetualMint } from "../../../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";
import { IPerpetualMintAdmin } from "../../../../../contracts/facets/PerpetualMint/IPerpetualMintAdmin.sol";
import { IPerpetualMintBase } from "../../../../../contracts/facets/PerpetualMint/IPerpetualMintBase.sol";
import { IPerpetualMintView } from "../../../../../contracts/facets/PerpetualMint/IPerpetualMintView.sol";
import { PerpetualMintAdmin } from "../../../../../contracts/facets/PerpetualMint/PerpetualMintAdmin.sol";
import { PerpetualMintBase } from "../../../../../contracts/facets/PerpetualMint/PerpetualMintBase.sol";

/// @title PerpetualMintHelper_SupraBlast
/// @dev Test helper contract for setting up PerpetualMintSupra for diamond cutting and testing, Blast-specific
contract PerpetualMintHelper_SupraBlast {
    PerpetualMintAdminBlast public perpetualMintAdminBlastImplementation;
    PerpetualMintBase public perpetualMintBaseImplementation;
    PerpetualMintHarnessSupraBlast
        public perpetualMintHarnessSupraBlastImplementation;
    PerpetualMintViewSupraBlast
        public perpetualMintViewSupraBlastImplementation;

    // Blast mainnet Supra VRF Router address
    address public constant VRF_ROUTER =
        0x82A515c2BEC5C4be8aBBbF0D2F59C19A4547709c;

    /// @dev deploys PerpetualMintHarnessSupraBlast implementation along with PerpetualMintBlastAdmin, PerpetualMintBase and PerpetualMintViewSupraBlast
    constructor() {
        perpetualMintAdminBlastImplementation = new PerpetualMintAdminBlast(
            VRF_ROUTER
        );

        perpetualMintBaseImplementation = new PerpetualMintBase(VRF_ROUTER);

        perpetualMintHarnessSupraBlastImplementation = new PerpetualMintHarnessSupraBlast(
            VRF_ROUTER
        );

        perpetualMintViewSupraBlastImplementation = new PerpetualMintViewSupraBlast(
            VRF_ROUTER
        );
    }

    /// @dev provides the facet cuts for setting up PerpetualMint in coreDiamond
    function getFacetCuts()
        external
        view
        returns (ICore.FacetCut[] memory facetCuts)
    {
        // map the ERC1155 test related function selectors to their respective interfaces
        ICore.FacetCut memory erc1155FacetCut = _createFacetCut(
            address(perpetualMintBaseImplementation),
            IDiamondWritableInternal.FacetCutAction.ADD,
            _getERC1155FunctionSelectors()
        );

        // map the Pausable test related function selectors to their respective interfaces
        ICore.FacetCut memory pausableFacetCut = _createFacetCut(
            address(perpetualMintViewSupraBlastImplementation),
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
            address(perpetualMintHarnessSupraBlastImplementation),
            IDiamondWritableInternal.FacetCutAction.ADD,
            _getPerpetualMintFunctionSelectors()
        );

        // map the PerpetualMintAdminBlast test related function selectors to their respective interfaces
        ICore.FacetCut memory perpetualMintAdminBlastFacetCut = _createFacetCut(
            address(perpetualMintAdminBlastImplementation),
            IDiamondWritableInternal.FacetCutAction.ADD,
            _getPerpetualMintAdminBlastFunctionSelectors()
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
                    target: address(perpetualMintAdminBlastImplementation),
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintAdminFunctionSelectors
                });

        // map the PerpetualMintView test related function selectors to their respective interfaces
        ICore.FacetCut memory perpetualMintViewFacetCut = _createFacetCut(
            address(perpetualMintViewSupraBlastImplementation),
            IDiamondWritableInternal.FacetCutAction.ADD,
            _getPerpetualMintViewFunctionSelectors()
        );

        // map the PerpetualMintViewBlast related function selectors to their respective interfaces
        ICore.FacetCut memory perpetualMintViewBlastFacetCut = _createFacetCut(
            address(perpetualMintViewSupraBlastImplementation),
            IDiamondWritableInternal.FacetCutAction.ADD,
            _getPerpetualMintViewBlastFunctionSelectors()
        );

        // map the PerpetualMintViewSupraBlast related function selectors to their respective interfaces
        ICore.FacetCut
            memory perpetualMintViewSupraBlastFacetCut = _createFacetCut(
                address(perpetualMintViewSupraBlastImplementation),
                IDiamondWritableInternal.FacetCutAction.ADD,
                _getPerpetualMintViewSupraBlastFunctionSelectors()
            );

        // map the PerpetualMintHarness test related function selectors to their respective interfaces
        ICore.FacetCut memory perpetualMintHarnessFacetCut = _createFacetCut(
            address(perpetualMintHarnessSupraBlastImplementation),
            IDiamondWritableInternal.FacetCutAction.ADD,
            _getPerpetualMintHarnessFunctionSelectors()
        );

        // map the PerpetualMintHarnessBlast test related function selectors to their respective interfaces
        ICore.FacetCut
            memory perpetualMintHarnessBlastFacetCut = _createFacetCut(
                address(perpetualMintHarnessSupraBlastImplementation),
                IDiamondWritableInternal.FacetCutAction.ADD,
                _getPerpetualMintHarnessBlastFunctionSelectors()
            );

        // map the PerpetualMintHarnessSupra test related function selectors to their respective interfaces
        ICore.FacetCut
            memory perpetualMintHarnessSupraFacetCut = _createFacetCut(
                address(perpetualMintHarnessSupraBlastImplementation),
                IDiamondWritableInternal.FacetCutAction.ADD,
                _getPerpetualMintHarnessSupraFunctionSelectors()
            );

        // map the VRFConsumerBaseV2 test related function selectors to their respective interfaces
        ICore.FacetCut memory vrfConsumerBaseV2FacetCut = _createFacetCut(
            address(perpetualMintHarnessSupraBlastImplementation),
            IDiamondWritableInternal.FacetCutAction.ADD,
            _getVRFConsumerBaseV2FunctionSelectors()
        );

        facetCuts = new ICore.FacetCut[](13);

        facetCuts[0] = erc1155FacetCut;

        facetCuts[1] = pausableFacetCut;

        facetCuts[2] = perpetualMintBaseFacetCut;

        facetCuts[3] = perpetualMintAdminFacetCut;

        facetCuts[4] = perpetualMintAdminBlastFacetCut;

        facetCuts[5] = perpetualMintFacetCut;

        facetCuts[6] = perpetualMintViewFacetCut;

        facetCuts[7] = perpetualMintViewBlastFacetCut;

        facetCuts[8] = perpetualMintViewSupraBlastFacetCut;

        facetCuts[9] = perpetualMintHarnessFacetCut;

        facetCuts[10] = perpetualMintHarnessBlastFacetCut;

        facetCuts[11] = perpetualMintHarnessSupraFacetCut;

        facetCuts[12] = vrfConsumerBaseV2FacetCut;
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

    function _getERC1155FunctionSelectors()
        private
        pure
        returns (bytes4[] memory selectors)
    {
        selectors = new bytes4[](1);

        selectors[0] = IERC1155.balanceOf.selector;
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

    function _getPerpetualMintAdminBlastFunctionSelectors()
        private
        pure
        returns (bytes4[] memory selectors)
    {
        selectors = new bytes4[](1);

        selectors[0] = IPerpetualMintAdminBlast.setBlastYieldRisk.selector;
    }

    function _getPerpetualMintBaseFunctionSelectors()
        private
        pure
        returns (bytes4[] memory selectors)
    {
        selectors = new bytes4[](1);

        selectors[0] = IPerpetualMintBase.onERC1155Received.selector;
    }

    function _getPerpetualMintHarnessFunctionSelectors()
        private
        pure
        returns (bytes4[] memory selectors)
    {
        selectors = new bytes4[](15);

        selectors[0] = IPerpetualMintHarness.exposed_enforceBasis.selector;

        selectors[1] = IPerpetualMintHarness
            .exposed_enforceNoPendingMints
            .selector;

        selectors[2] = IPerpetualMintHarness.exposed_normalizeValue.selector;

        selectors[3] = IPerpetualMintHarness
            .exposed_pendingRequestsAdd
            .selector;

        selectors[4] = IPerpetualMintHarness.exposed_pendingRequestsAt.selector;

        selectors[5] = IPerpetualMintHarness
            .exposed_pendingRequestsLength
            .selector;

        selectors[6] = IPerpetualMintHarness.exposed_requests.selector;

        selectors[7] = IPerpetualMintHarness.exposed_resolveMints.selector;

        selectors[8] = IPerpetualMintHarness
            .exposed_resolveMintsForMint
            .selector;

        selectors[9] = bytes4(keccak256("mintReceipts(address,uint256)"));

        selectors[10] = bytes4(
            keccak256("mintReceipts(address,uint256,uint256)")
        );

        selectors[11] = IPerpetualMintHarness.setConsolationFees.selector;

        selectors[12] = IPerpetualMintHarness.setMintEarnings.selector;

        selectors[13] = IPerpetualMintHarness.setProtocolFees.selector;

        selectors[14] = IPerpetualMintHarness.setRequests.selector;
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

    function _getPerpetualMintHarnessSupraFunctionSelectors()
        private
        pure
        returns (bytes4[] memory selectors)
    {
        selectors = new bytes4[](1);

        selectors[0] = PerpetualMintHarnessSupraBlast
            .exposed_requestRandomWordsSupra
            .selector;
    }

    function _getPerpetualMintViewFunctionSelectors()
        private
        pure
        returns (bytes4[] memory selectors)
    {
        selectors = new bytes4[](25);

        selectors[0] = IPerpetualMintView.accruedConsolationFees.selector;

        selectors[1] = IPerpetualMintView.accruedMintEarnings.selector;

        selectors[2] = IPerpetualMintView.accruedProtocolFees.selector;

        selectors[3] = IPerpetualMintView.BASIS.selector;

        selectors[4] = IPerpetualMintView.collectionConsolationFeeBP.selector;

        selectors[5] = IPerpetualMintView
            .collectionMintFeeDistributionRatioBP
            .selector;

        selectors[6] = IPerpetualMintView.collectionMintMultiplier.selector;

        selectors[7] = IPerpetualMintView.collectionMintPrice.selector;

        selectors[8] = IPerpetualMintView.collectionReferralFeeBP.selector;

        selectors[9] = IPerpetualMintView.collectionRisk.selector;

        selectors[10] = IPerpetualMintView.defaultCollectionMintPrice.selector;

        selectors[11] = IPerpetualMintView
            .defaultCollectionReferralFeeBP
            .selector;

        selectors[12] = IPerpetualMintView.defaultCollectionRisk.selector;

        selectors[13] = IPerpetualMintView.defaultEthToMintRatio.selector;

        selectors[14] = IPerpetualMintView.ethToMintRatio.selector;

        selectors[15] = IPerpetualMintView.mintFeeBP.selector;

        selectors[16] = IPerpetualMintView.mintToken.selector;

        selectors[17] = IPerpetualMintView.mintTokenConsolationFeeBP.selector;

        selectors[18] = IPerpetualMintView.mintTokenTiers.selector;

        selectors[19] = IPerpetualMintView.redemptionFeeBP.selector;

        selectors[20] = IPerpetualMintView.redeemPaused.selector;

        selectors[21] = IPerpetualMintView.SCALE.selector;

        selectors[22] = IPerpetualMintView.tiers.selector;

        selectors[23] = IPerpetualMintView.vrfConfig.selector;

        selectors[24] = IPerpetualMintView
            .vrfSubscriptionBalanceThreshold
            .selector;
    }

    function _getPerpetualMintViewBlastFunctionSelectors()
        private
        pure
        returns (bytes4[] memory selectors)
    {
        selectors = new bytes4[](1);

        selectors[0] = IPerpetualMintViewBlast.blastYieldRisk.selector;
    }

    function _getPerpetualMintViewSupraBlastFunctionSelectors()
        private
        pure
        returns (bytes4[] memory selectors)
    {
        selectors = new bytes4[](1);

        selectors[0] = IPerpetualMintViewSupraBlast
            .calculateMintResultSupraBlast
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
