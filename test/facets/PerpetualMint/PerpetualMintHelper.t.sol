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
import { PerpetualMintStorage as Storage } from "../../../contracts/facets/PerpetualMint/Storage.sol";

/// @title PerpetualMintHelper
/// @dev Test helper contract for setting up PerpetualMint facet for diamond cutting and testing
contract PerpetualMintHelper {
    PerpetualMintHarness public perpetualMintHarnessImplementation;

    // Arbitrum mainnet Chainlink VRF Coordinator address
    address public constant VRF_COORDINATOR =
        0x41034678D6C633D8a95c75e1138A360a28bA15d1;

    /// @dev deploys PerpetualMintHarness implementation
    constructor() {
        perpetualMintHarnessImplementation = new PerpetualMintHarness(
            VRF_COORDINATOR
        );
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
                target: address(perpetualMintHarnessImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: erc1155FunctionSelectors
            });

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
        bytes4[] memory perpetualMintFunctionSelectors = new bytes4[](41);

        perpetualMintFunctionSelectors[0] = IPerpetualMint
            .accruedConsolationFees
            .selector;

        perpetualMintFunctionSelectors[1] = IPerpetualMint
            .accruedMintEarnings
            .selector;

        perpetualMintFunctionSelectors[2] = IPerpetualMint
            .accruedProtocolFees
            .selector;

        perpetualMintFunctionSelectors[3] = IPerpetualMint.mintAirdrop.selector;

        perpetualMintFunctionSelectors[4] = IPerpetualMint
            .attemptBatchMintWithEth
            .selector;

        perpetualMintFunctionSelectors[5] = IPerpetualMint
            .attemptBatchMintWithMint
            .selector;

        perpetualMintFunctionSelectors[6] = IPerpetualMint.BASIS.selector;

        perpetualMintFunctionSelectors[7] = IPerpetualMint.burnReceipt.selector;

        perpetualMintFunctionSelectors[8] = IPerpetualMint.cancelClaim.selector;

        perpetualMintFunctionSelectors[9] = IPerpetualMint
            .claimMintEarnings
            .selector;

        perpetualMintFunctionSelectors[10] = IPerpetualMint.claimPrize.selector;

        perpetualMintFunctionSelectors[11] = IPerpetualMint
            .claimProtocolFees
            .selector;

        perpetualMintFunctionSelectors[12] = IPerpetualMint
            .collectionMintPrice
            .selector;

        perpetualMintFunctionSelectors[13] = IPerpetualMint
            .collectionPriceToMintRatioBP
            .selector;

        perpetualMintFunctionSelectors[14] = IPerpetualMint
            .collectionRisk
            .selector;

        perpetualMintFunctionSelectors[15] = IPerpetualMint
            .consolationFeeBP
            .selector;

        perpetualMintFunctionSelectors[16] = IPerpetualMint
            .defaultCollectionMintPrice
            .selector;

        perpetualMintFunctionSelectors[17] = IPerpetualMint
            .defaultCollectionRisk
            .selector;

        perpetualMintFunctionSelectors[18] = IPerpetualMint
            .defaultEthToMintRatio
            .selector;

        perpetualMintFunctionSelectors[19] = IPerpetualMint
            .ethToMintRatio
            .selector;

        perpetualMintFunctionSelectors[20] = IPerpetualMint.mintFeeBP.selector;

        perpetualMintFunctionSelectors[21] = IPerpetualMint.mintToken.selector;

        perpetualMintFunctionSelectors[22] = IPerpetualMint
            .onERC1155Received
            .selector;

        perpetualMintFunctionSelectors[23] = IPerpetualMint.pause.selector;

        perpetualMintFunctionSelectors[24] = IPerpetualMint.redeem.selector;

        perpetualMintFunctionSelectors[25] = IPerpetualMint
            .redemptionFeeBP
            .selector;

        perpetualMintFunctionSelectors[26] = IPerpetualMint
            .setCollectionMintPrice
            .selector;

        perpetualMintFunctionSelectors[27] = IPerpetualMint
            .setCollectionPriceToMintRatioBP
            .selector;

        perpetualMintFunctionSelectors[28] = IPerpetualMint
            .setCollectionRisk
            .selector;

        perpetualMintFunctionSelectors[29] = IPerpetualMint
            .setConsolationFeeBP
            .selector;

        perpetualMintFunctionSelectors[30] = IPerpetualMint
            .setEthToMintRatio
            .selector;

        perpetualMintFunctionSelectors[31] = IPerpetualMint
            .setMintFeeBP
            .selector;

        perpetualMintFunctionSelectors[32] = IPerpetualMint
            .setMintToken
            .selector;

        perpetualMintFunctionSelectors[33] = IPerpetualMint
            .setReceiptBaseURI
            .selector;

        perpetualMintFunctionSelectors[34] = IPerpetualMint
            .setReceiptTokenURI
            .selector;

        perpetualMintFunctionSelectors[35] = IPerpetualMint
            .setRedemptionFeeBP
            .selector;

        perpetualMintFunctionSelectors[36] = IPerpetualMint.setTiers.selector;

        perpetualMintFunctionSelectors[37] = IPerpetualMint
            .setVRFConfig
            .selector;

        perpetualMintFunctionSelectors[38] = IPerpetualMint.tiers.selector;

        perpetualMintFunctionSelectors[39] = IPerpetualMint.unpause.selector;

        perpetualMintFunctionSelectors[40] = IPerpetualMint.vrfConfig.selector;

        ISolidStateDiamond.FacetCut
            memory perpetualMintFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(perpetualMintHarnessImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: perpetualMintFunctionSelectors
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
            .exposed_requestRandomWords
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

        facetCuts[0] = erc1155FacetCut;

        facetCuts[1] = erc1155MetadataFacetCut;

        facetCuts[2] = pausableFacetCut;

        facetCuts[3] = perpetualMintFacetCut;

        facetCuts[4] = perpetualMintHarnessFacetCut;

        facetCuts[5] = vrfConsumerBaseV2MockFacetCut;

        return facetCuts;
    }
}
