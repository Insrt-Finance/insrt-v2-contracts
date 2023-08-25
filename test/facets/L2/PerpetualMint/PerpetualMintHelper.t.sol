// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";

import { IPerpetualMint } from "../../../../contracts/facets/L2/PerpetualMint/IPerpetualMint.sol";
import { PerpetualMintStorage as Storage } from "../../../../contracts/facets/L2/PerpetualMint/Storage.sol";
import { L2AssetHandlerMock } from "../../../mocks/L2AssetHandlerMock.t.sol";
import { VRFConsumerBaseV2Mock } from "../../../mocks/VRFConsumerBaseV2Mock.sol";
import { IPerpetualMintHarness } from "./IPerpetualMintHarness.sol";
import { PerpetualMintHarness } from "./PerpetualMintHarness.t.sol";

/// @title PerpetualMintHelper
/// @dev Test helper contract for setting up PerpetualMint facet for diamond cutting and testing
contract PerpetualMintHelper {
    PerpetualMintHarness public perpetualMintHarnessImplementation;
    L2AssetHandlerMock public l2AssetHandlerMockImplementation;

    // Arbitrum mainnet Chainlink VRF Coordinator address
    address public constant VRF_COORDINATOR =
        0x41034678D6C633D8a95c75e1138A360a28bA15d1;

    /// @dev deploys L2AssetHandlerMock and PerpetualMintHarness implementations
    constructor() {
        perpetualMintHarnessImplementation = new PerpetualMintHarness(
            VRF_COORDINATOR
        );

        l2AssetHandlerMockImplementation = new L2AssetHandlerMock();
    }

    /// @dev provides the facet cuts for setting up PerpetualMint and L2AssetHandlerMock in L2CoreDiamond
    function getFacetCuts()
        public
        view
        returns (ISolidStateDiamond.FacetCut[] memory)
    {
        bytes4[] memory mintingSelectors = new bytes4[](31);
        bytes4[] memory l2AssetHandlerSelectors = new bytes4[](1);

        // map the function selectors to their respective interfaces
        mintingSelectors[0] = IPerpetualMint.attemptBatchMint.selector;
        mintingSelectors[1] = IPerpetualMint.claimAllEarnings.selector;
        mintingSelectors[2] = IPerpetualMint.claimEarnings.selector;
        mintingSelectors[3] = IPerpetualMint.allAvailableEarnings.selector;
        mintingSelectors[4] = IPerpetualMint.availableEarnings.selector;
        mintingSelectors[5] = IPerpetualMint.averageCollectionRisk.selector;
        mintingSelectors[6] = IPerpetualMint.escrowedERC721TokenOwner.selector;
        mintingSelectors[7] = IPerpetualMint.setCollectionMintPrice.selector;
        mintingSelectors[8] = IPerpetualMint.setMintFeeBP.selector;
        mintingSelectors[9] = IPerpetualMint.setVRFConfig.selector;
        mintingSelectors[10] = IPerpetualMint.updateERC1155TokenRisks.selector;
        mintingSelectors[11] = IPerpetualMint.updateERC721TokenRisks.selector;
        mintingSelectors[12] = IPerpetualMint.idleERC1155Tokens.selector;
        mintingSelectors[13] = IPerpetualMint.idleERC721Tokens.selector;
        mintingSelectors[14] = IPerpetualMint.reactivateERC1155Assets.selector;
        mintingSelectors[15] = IPerpetualMint.reactivateERC721Assets.selector;
        mintingSelectors[16] = IPerpetualMint.pause.selector;
        mintingSelectors[17] = IPerpetualMint.unpause.selector;
        mintingSelectors[18] = IPerpetualMint.setMaxActiveTokensLimit.selector;

        mintingSelectors[19] = IPerpetualMintHarness.exposed_balanceOf.selector;
        mintingSelectors[20] = IPerpetualMintHarness
            .exposed_resolveERC721Mints
            .selector;
        mintingSelectors[21] = IPerpetualMintHarness
            .exposed_resolveERC1155Mints
            .selector;
        mintingSelectors[22] = IPerpetualMintHarness
            .exposed_selectToken
            .selector;
        mintingSelectors[23] = IPerpetualMintHarness
            .exposed_selectERC1155Owner
            .selector;
        mintingSelectors[24] = IPerpetualMintHarness
            .exposed_normalizeValue
            .selector;
        mintingSelectors[25] = IPerpetualMintHarness
            .exposed_updateDepositorEarnings
            .selector;
        mintingSelectors[26] = IPerpetualMintHarness
            .exposed_assignEscrowedERC1155Asset
            .selector;
        mintingSelectors[27] = IPerpetualMintHarness
            .exposed_updateSingleERC1155TokenRisk
            .selector;
        mintingSelectors[28] = IPerpetualMintHarness
            .exposed_updateSingleERC721TokenRisk
            .selector;
        mintingSelectors[29] = IPerpetualMintHarness
            .exposed_assignEscrowedERC721Asset
            .selector;

        mintingSelectors[30] = VRFConsumerBaseV2Mock
            .rawFulfillRandomWordsPlus
            .selector;

        l2AssetHandlerSelectors[0] = L2AssetHandlerMock
            .mock_HandleLayerZeroMessage
            .selector;

        ISolidStateDiamond.FacetCut
            memory mintFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(perpetualMintHarnessImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: mintingSelectors
            });

        ISolidStateDiamond.FacetCut
            memory assetHandlerFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(l2AssetHandlerMockImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: l2AssetHandlerSelectors
            });

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](2);

        facetCuts[0] = mintFacetCut;
        facetCuts[1] = assetHandlerFacetCut;

        return facetCuts;
    }
}
