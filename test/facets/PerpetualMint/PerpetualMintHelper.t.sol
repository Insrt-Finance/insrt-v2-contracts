// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IPausable } from "@solidstate/contracts/security/pausable/IPausable.sol";
import { IERC1155Metadata } from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";

import { IPerpetualMintHarness } from "./IPerpetualMintHarness.sol";
import { PerpetualMintHarness } from "./PerpetualMintHarness.t.sol";
import { VRFConsumerBaseV2Mock } from "../../mocks/VRFConsumerBaseV2Mock.sol";
import { ICore } from "../../../contracts/diamonds/Core/ICore.sol";
import { IPerpetualMint } from "../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";
import { IPerpetualMintAdmin } from "../../../contracts/facets/PerpetualMint/IPerpetualMintAdmin.sol";
import { IPerpetualMintBase } from "../../../contracts/facets/PerpetualMint/IPerpetualMintBase.sol";
import { IPerpetualMintView } from "../../../contracts/facets/PerpetualMint/IPerpetualMintView.sol";
import { PerpetualMintAdmin } from "../../../contracts/facets/PerpetualMint/PerpetualMintAdmin.sol";
import { PerpetualMintBase } from "../../../contracts/facets/PerpetualMint/PerpetualMintBase.sol";
import { PerpetualMintView } from "../../../contracts/facets/PerpetualMint/PerpetualMintView.sol";
import { PerpetualMintStorage as Storage } from "../../../contracts/facets/PerpetualMint/Storage.sol";
import { InsrtVRFCoordinator } from "../../../contracts/vrf/Insrt/InsrtVRFCoordinator.sol";

/// @title PerpetualMintHelper
/// @dev Test helper contract for setting up PerpetualMint for diamond cutting and testing
contract PerpetualMintHelper {
    PerpetualMintAdmin public perpetualMintAdminImplementation;
    PerpetualMintBase public perpetualMintBaseImplementation;
    PerpetualMintHarness public perpetualMintHarnessImplementation;
    PerpetualMintView public perpetualMintViewImplementation;

    // Arbitrum mainnet Chainlink VRF Coordinator address
    address public constant CHAINLINK_VRF_COORDINATOR =
        0x41034678D6C633D8a95c75e1138A360a28bA15d1;

    // The VRF Coordinator address used for testing
    address public immutable VRF_COORDINATOR;

    /// @dev deploys PerpetualMintHarness implementation along with PerpetualMintAdmin, PerpetualMintBase and PerpetualMintView
    /// @param insrtVrfCoordinator boolean indicating whether to use our custom VRF Coordinator or Chainlink's VRF Coordinator on Arbitrum mainnet
    constructor(bool insrtVrfCoordinator) {
        VRF_COORDINATOR = insrtVrfCoordinator
            ? address(new InsrtVRFCoordinator())
            : CHAINLINK_VRF_COORDINATOR;

        perpetualMintAdminImplementation = new PerpetualMintAdmin(
            VRF_COORDINATOR
        );

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

    /// @dev provides the facet cuts for setting up PerpetualMintAdmin in the Core Diamond for testing
    function getPerpetualMintAdminTestFacetCuts()
        external
        view
        returns (ICore.FacetCut[] memory)
    {
        // map the PerpetualMintAdmin test related function selectors to their respective interfaces
        bytes4[] memory perpetualMintAdminFunctionSelectors = new bytes4[](29);

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
            .setMintEarningsBufferBP
            .selector;

        perpetualMintAdminFunctionSelectors[16] = IPerpetualMintAdmin
            .setMintFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[17] = IPerpetualMintAdmin
            .setMintForEthConsolationFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[18] = IPerpetualMintAdmin
            .setMintToken
            .selector;

        perpetualMintAdminFunctionSelectors[19] = IPerpetualMintAdmin
            .setMintTokenConsolationFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[20] = IPerpetualMintAdmin
            .setMintTokenTiers
            .selector;

        perpetualMintAdminFunctionSelectors[21] = IPerpetualMintAdmin
            .setReceiptBaseURI
            .selector;

        perpetualMintAdminFunctionSelectors[22] = IPerpetualMintAdmin
            .setReceiptTokenURI
            .selector;

        perpetualMintAdminFunctionSelectors[23] = IPerpetualMintAdmin
            .setRedemptionFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[24] = IPerpetualMintAdmin
            .setRedeemPaused
            .selector;

        perpetualMintAdminFunctionSelectors[25] = IPerpetualMintAdmin
            .setTiers
            .selector;

        perpetualMintAdminFunctionSelectors[26] = IPerpetualMintAdmin
            .setVRFConfig
            .selector;

        perpetualMintAdminFunctionSelectors[27] = IPerpetualMintAdmin
            .setVRFSubscriptionBalanceThreshold
            .selector;

        perpetualMintAdminFunctionSelectors[28] = IPerpetualMintAdmin
            .unpause
            .selector;

        ICore.FacetCut
            memory perpetualMintAdminFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: address(perpetualMintAdminImplementation),
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintAdminFunctionSelectors
                });

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](1);

        facetCuts[0] = perpetualMintAdminFacetCut;

        return facetCuts;
    }

    /// @dev provides the facet cuts for setting up PerpetualMintBase in the Core Diamond for testing
    function getPerpetualMintBaseTestFacetCuts()
        external
        view
        returns (ICore.FacetCut[] memory)
    {
        // map the ERC1155 test related function selectors to their respective interfaces
        bytes4[] memory erc1155FunctionSelectors = new bytes4[](1);

        erc1155FunctionSelectors[0] = IERC1155.balanceOf.selector;

        ICore.FacetCut memory erc1155FacetCut = IDiamondWritableInternal
            .FacetCut({
                target: address(perpetualMintBaseImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: erc1155FunctionSelectors
            });

        // map the ERC1155Metadata test related function selectors to their respective interfaces
        bytes4[] memory erc1155MetadataFunctionSelectors = new bytes4[](1);

        erc1155MetadataFunctionSelectors[0] = IERC1155Metadata.uri.selector;

        ICore.FacetCut memory erc1155MetadataFacetCut = IDiamondWritableInternal
            .FacetCut({
                target: address(perpetualMintBaseImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: erc1155MetadataFunctionSelectors
            });

        // map the Pausable test related function selectors to their respective interfaces
        bytes4[] memory pausableFunctionSelectors = new bytes4[](1);

        pausableFunctionSelectors[0] = IPausable.paused.selector;

        ICore.FacetCut memory pausableFacetCut = IDiamondWritableInternal
            .FacetCut({
                target: address(perpetualMintViewImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: pausableFunctionSelectors
            });

        // map the PerpetualMintBase test related function selectors to their respective interfaces
        bytes4[] memory perpetualMintBaseFunctionSelectors = new bytes4[](1);

        perpetualMintBaseFunctionSelectors[0] = IPerpetualMintBase
            .onERC1155Received
            .selector;

        ICore.FacetCut
            memory perpetualMintBaseFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: address(perpetualMintBaseImplementation),
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintBaseFunctionSelectors
                });

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](4);

        facetCuts[0] = erc1155FacetCut;

        facetCuts[1] = erc1155MetadataFacetCut;

        facetCuts[2] = pausableFacetCut;

        facetCuts[3] = perpetualMintBaseFacetCut;

        return facetCuts;
    }

    /// @dev provides the facet cuts for setting up PerpetualMint in the Core Diamond for testing
    function getPerpetualMintTestFacetCuts()
        external
        view
        returns (ICore.FacetCut[] memory)
    {
        // map the PerpetualMint test related function selectors to their respective interfaces
        bytes4[] memory perpetualMintFunctionSelectors = new bytes4[](9);

        perpetualMintFunctionSelectors[0] = IPerpetualMint
            .attemptBatchMintForEthWithEth
            .selector;

        perpetualMintFunctionSelectors[1] = IPerpetualMint
            .attemptBatchMintForEthWithMint
            .selector;

        perpetualMintFunctionSelectors[2] = IPerpetualMint
            .attemptBatchMintForMintWithEth
            .selector;

        perpetualMintFunctionSelectors[3] = IPerpetualMint
            .attemptBatchMintForMintWithMint
            .selector;

        perpetualMintFunctionSelectors[4] = IPerpetualMint
            .attemptBatchMintWithEth
            .selector;

        perpetualMintFunctionSelectors[5] = IPerpetualMint
            .attemptBatchMintWithMint
            .selector;

        perpetualMintFunctionSelectors[6] = IPerpetualMint.claimPrize.selector;

        perpetualMintFunctionSelectors[7] = IPerpetualMint
            .fundConsolationFees
            .selector;

        perpetualMintFunctionSelectors[8] = IPerpetualMint.redeem.selector;

        ICore.FacetCut memory perpetualMintFacetCut = IDiamondWritableInternal
            .FacetCut({
                target: address(perpetualMintHarnessImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: perpetualMintFunctionSelectors
            });

        // map the PerpetualMintView test related function selectors to their respective interfaces
        bytes4[] memory perpetualMintViewFunctionSelectors = new bytes4[](28);

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
            .mintEarningsBufferBP
            .selector;

        perpetualMintViewFunctionSelectors[17] = IPerpetualMintView
            .mintFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[18] = IPerpetualMintView
            .mintForEthConsolationFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[19] = IPerpetualMintView
            .mintToken
            .selector;

        perpetualMintViewFunctionSelectors[20] = IPerpetualMintView
            .mintTokenConsolationFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[21] = IPerpetualMintView
            .mintTokenTiers
            .selector;

        perpetualMintViewFunctionSelectors[22] = IPerpetualMintView
            .redemptionFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[23] = IPerpetualMintView
            .redeemPaused
            .selector;

        perpetualMintViewFunctionSelectors[24] = IPerpetualMintView
            .SCALE
            .selector;

        perpetualMintViewFunctionSelectors[25] = IPerpetualMintView
            .tiers
            .selector;

        perpetualMintViewFunctionSelectors[26] = IPerpetualMintView
            .vrfConfig
            .selector;

        perpetualMintViewFunctionSelectors[27] = IPerpetualMintView
            .vrfSubscriptionBalanceThreshold
            .selector;

        ICore.FacetCut
            memory perpetualMintViewFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: address(perpetualMintViewImplementation),
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintViewFunctionSelectors
                });

        // map the PerpetualMintHarness test related function selectors to their respective interfaces
        bytes4[] memory perpetualMintHarnessFunctionSelectors = new bytes4[](
            17
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
            .exposed_resolveMintsForEth
            .selector;

        perpetualMintHarnessFunctionSelectors[10] = IPerpetualMintHarness
            .exposed_resolveMintsForMint
            .selector;

        perpetualMintHarnessFunctionSelectors[11] = bytes4(
            keccak256("mintReceipts(address,uint256)")
        );

        perpetualMintHarnessFunctionSelectors[12] = bytes4(
            keccak256("mintReceipts(address,uint256,uint256)")
        );

        perpetualMintHarnessFunctionSelectors[13] = IPerpetualMintHarness
            .setConsolationFees
            .selector;

        perpetualMintHarnessFunctionSelectors[14] = IPerpetualMintHarness
            .setMintEarnings
            .selector;

        perpetualMintHarnessFunctionSelectors[15] = IPerpetualMintHarness
            .setProtocolFees
            .selector;

        perpetualMintHarnessFunctionSelectors[16] = IPerpetualMintHarness
            .setRequests
            .selector;

        ICore.FacetCut
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

        ICore.FacetCut
            memory vrfConsumerBaseV2MockFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: address(perpetualMintHarnessImplementation),
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: vrfConsumerBaseV2MockFunctionSelectors
                });

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](4);

        if (VRF_COORDINATOR == CHAINLINK_VRF_COORDINATOR) {
            facetCuts[0] = perpetualMintFacetCut;

            facetCuts[1] = perpetualMintViewFacetCut;

            facetCuts[2] = perpetualMintHarnessFacetCut;

            facetCuts[3] = vrfConsumerBaseV2MockFacetCut;

            return facetCuts;
        }

        // map the VRFConsumerBaseV2 function selectors to their respective interfaces
        bytes4[] memory vrfConsumerBaseV2FunctionSelectors = new bytes4[](1);

        vrfConsumerBaseV2FunctionSelectors[0] = VRFConsumerBaseV2
            .rawFulfillRandomWords
            .selector;

        ICore.FacetCut
            memory vrfConsumerBaseV2FacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: address(perpetualMintHarnessImplementation),
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: vrfConsumerBaseV2FunctionSelectors
                });

        facetCuts[0] = perpetualMintFacetCut;

        facetCuts[1] = perpetualMintViewFacetCut;

        facetCuts[2] = perpetualMintHarnessFacetCut;

        facetCuts[3] = vrfConsumerBaseV2FacetCut;

        return facetCuts;
    }
}
