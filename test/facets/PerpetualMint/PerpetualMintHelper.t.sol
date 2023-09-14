// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IPausable } from "@solidstate/contracts/security/pausable/IPausable.sol";

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

    address internal constant MINT_TOKEN = address(0); // dummy address

    /// @dev deploys PerpetualMintHarness implementation
    constructor() {
        perpetualMintHarnessImplementation = new PerpetualMintHarness(
            VRF_COORDINATOR,
            MINT_TOKEN
        );
    }

    /// @dev provides the facet cuts for setting up PerpetualMint in coreDiamond
    function getFacetCuts()
        external
        view
        returns (ISolidStateDiamond.FacetCut[] memory)
    {
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
        bytes4[] memory perpetualMintFunctionSelectors = new bytes4[](35);

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

        perpetualMintFunctionSelectors[6] = IPerpetualMint.cancelClaim.selector;

        perpetualMintFunctionSelectors[7] = IPerpetualMint
            .claimMintEarnings
            .selector;

        perpetualMintFunctionSelectors[8] = IPerpetualMint.claimPrize.selector;

        perpetualMintFunctionSelectors[9] = IPerpetualMint
            .claimProtocolFees
            .selector;

        perpetualMintFunctionSelectors[10] = IPerpetualMint
            .collectionMintPrice
            .selector;

        perpetualMintFunctionSelectors[11] = IPerpetualMint
            .collectionRisk
            .selector;

        perpetualMintFunctionSelectors[12] = IPerpetualMint
            .consolationFeeBP
            .selector;

        perpetualMintFunctionSelectors[13] = IPerpetualMint
            .defaultCollectionMintPrice
            .selector;

        perpetualMintFunctionSelectors[14] = IPerpetualMint
            .defaultCollectionRisk
            .selector;

        perpetualMintFunctionSelectors[15] = IPerpetualMint
            .defaultEthToMintRatio
            .selector;

        perpetualMintFunctionSelectors[16] = IPerpetualMint
            .ethToMintRatio
            .selector;

        perpetualMintFunctionSelectors[17] = IPerpetualMint.mintFeeBP.selector;

        perpetualMintFunctionSelectors[18] = IPerpetualMint.mintToken.selector;

        perpetualMintFunctionSelectors[19] = IPerpetualMint
            .onERC1155Received
            .selector;

        perpetualMintFunctionSelectors[20] = IPerpetualMint.pause.selector;

        perpetualMintFunctionSelectors[21] = IPerpetualMint.redeem.selector;

        perpetualMintFunctionSelectors[22] = IPerpetualMint
            .redemptionFeeBP
            .selector;

        perpetualMintFunctionSelectors[23] = IPerpetualMint
            .setCollectionMintPrice
            .selector;

        perpetualMintFunctionSelectors[24] = IPerpetualMint
            .setCollectionRisk
            .selector;

        perpetualMintFunctionSelectors[25] = IPerpetualMint
            .setConsolationFeeBP
            .selector;

        perpetualMintFunctionSelectors[26] = IPerpetualMint
            .setEthToMintRatio
            .selector;

        perpetualMintFunctionSelectors[27] = IPerpetualMint
            .setMintFeeBP
            .selector;

        perpetualMintFunctionSelectors[28] = IPerpetualMint
            .setMintToken
            .selector;

        perpetualMintFunctionSelectors[29] = IPerpetualMint
            .setRedemptionFeeBP
            .selector;

        perpetualMintFunctionSelectors[30] = IPerpetualMint.setTiers.selector;

        perpetualMintFunctionSelectors[31] = IPerpetualMint
            .setVRFConfig
            .selector;

        perpetualMintFunctionSelectors[32] = IPerpetualMint.tiers.selector;

        perpetualMintFunctionSelectors[33] = IPerpetualMint.unpause.selector;

        perpetualMintFunctionSelectors[34] = IPerpetualMint.vrfConfig.selector;

        ISolidStateDiamond.FacetCut
            memory perpetualMintFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(perpetualMintHarnessImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: perpetualMintFunctionSelectors
            });

        // map the PerpetualMintHarness test related function selectors to their respective interfaces
        bytes4[] memory perpetualMintHarnessFunctionSelectors = new bytes4[](
            15
        );

        perpetualMintHarnessFunctionSelectors[0] = IPerpetualMintHarness
            .exposed_balanceOf
            .selector;

        perpetualMintHarnessFunctionSelectors[1] = IPerpetualMintHarness
            .exposed_enforceBasis
            .selector;

        perpetualMintHarnessFunctionSelectors[2] = IPerpetualMintHarness
            .exposed_enforceNoPendingMints
            .selector;

        perpetualMintHarnessFunctionSelectors[3] = IPerpetualMintHarness
            .exposed_normalizeValue
            .selector;

        perpetualMintHarnessFunctionSelectors[4] = IPerpetualMintHarness
            .exposed_pendingRequestsAdd
            .selector;

        perpetualMintHarnessFunctionSelectors[5] = IPerpetualMintHarness
            .exposed_pendingRequestsAt
            .selector;

        perpetualMintHarnessFunctionSelectors[6] = IPerpetualMintHarness
            .exposed_pendingRequestsLength
            .selector;

        perpetualMintHarnessFunctionSelectors[7] = IPerpetualMintHarness
            .exposed_requestRandomWords
            .selector;

        perpetualMintHarnessFunctionSelectors[8] = IPerpetualMintHarness
            .exposed_requests
            .selector;

        perpetualMintHarnessFunctionSelectors[9] = IPerpetualMintHarness
            .exposed_resolveMints
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
            memory facetCuts = new ISolidStateDiamond.FacetCut[](4);

        facetCuts[0] = pausableFacetCut;

        facetCuts[1] = perpetualMintFacetCut;

        facetCuts[2] = perpetualMintHarnessFacetCut;

        facetCuts[3] = vrfConsumerBaseV2MockFacetCut;

        return facetCuts;
    }
}
