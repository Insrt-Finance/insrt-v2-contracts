// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";

import { IPerpetualMint } from "../../../../contracts/facets/L2/PerpetualMint/IPerpetualMint.sol";
import { PerpetualMintStorage as Storage } from "../../../../contracts/facets/L2/PerpetualMint/Storage.sol";
import { DepositFacetMock } from "../../../mocks/DepositFacetMock.t.sol";
import { IDepositFacetMock } from "../../../interfaces/IDepositFacetMock.sol";
import { IPerpetualMintHarness } from "./IPerpetualMintHarness.t.sol";
import { PerpetualMintHarness } from "./PerpetualMintHarness.t.sol";

/// @title PerpetualMintHelper
/// @dev Test helper contract for setting up PerpetualMint facet for diamond cutting and testing
contract PerpetualMintHelper {
    PerpetualMintHarness public perpetualMintHarnessImplementation;
    DepositFacetMock public depositFacetMockImplementation;

    // Arbitrum mainnet Chainlink VRF Coordinator address
    address public constant VRF_COORDINATOR =
        address(0x41034678D6C633D8a95c75e1138A360a28bA15d1);

    /// @dev deploys DepositFacetMock and PerpetualMintHarness implementations
    constructor() {
        perpetualMintHarnessImplementation = new PerpetualMintHarness(
            VRF_COORDINATOR
        );

        depositFacetMockImplementation = new DepositFacetMock();
    }

    /// @dev provides the facet cuts for setting up PerpetualMint and DepositFacetMock in L1CoreDiamond
    function getFacetCuts()
        public
        view
        returns (ISolidStateDiamond.FacetCut[] memory)
    {
        bytes4[] memory mintingSelectors = new bytes4[](22);
        bytes4[] memory depositSelectors = new bytes4[](1);

        // map the function selectors to their respective interfaces
        mintingSelectors[0] = IPerpetualMint.attemptMint.selector;
        mintingSelectors[1] = IPerpetualMint.claimAllEarnings.selector;
        mintingSelectors[2] = IPerpetualMint.claimEarnings.selector;
        mintingSelectors[3] = IPerpetualMint.allAvailableEarnings.selector;
        mintingSelectors[4] = IPerpetualMint.availableEarnings.selector;
        mintingSelectors[5] = IPerpetualMint.averageCollectionRisk.selector;
        mintingSelectors[6] = IPerpetualMint.escrowedERC721TokenOwner.selector;
        mintingSelectors[7] = IPerpetualMint.setCollectionMintPrice.selector;
        mintingSelectors[8] = IPerpetualMint.setVRFConfig.selector;
        mintingSelectors[9] = IPerpetualMint.updateERC1155TokenRisks.selector;
        mintingSelectors[10] = IPerpetualMint.updateERC721TokenRisks.selector;
        mintingSelectors[11] = IPerpetualMint.idleERC1155Tokens.selector;
        mintingSelectors[12] = IPerpetualMint.idleERC721Tokens.selector;
        mintingSelectors[13] = IPerpetualMintHarness
            .exposed_resolveERC721Mint
            .selector;
        mintingSelectors[14] = IPerpetualMintHarness
            .exposed_resolveERC1155Mint
            .selector;
        mintingSelectors[15] = IPerpetualMintHarness
            .exposed_selectToken
            .selector;
        mintingSelectors[16] = IPerpetualMintHarness
            .exposed_selectERC1155Owner
            .selector;
        mintingSelectors[17] = IPerpetualMintHarness
            .exposed_chunk128to64
            .selector;
        mintingSelectors[18] = IPerpetualMintHarness
            .exposed_chunk256to128
            .selector;
        mintingSelectors[19] = IPerpetualMintHarness
            .exposed_normalizeValue
            .selector;
        mintingSelectors[20] = IPerpetualMintHarness
            .exposed_updateDepositorEarnings
            .selector;
        mintingSelectors[21] = IPerpetualMintHarness
            .exposed_assignEscrowedERC1155Asset
            .selector;

        depositSelectors[0] = IDepositFacetMock.depositAsset.selector;

        ISolidStateDiamond.FacetCut
            memory mintFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(perpetualMintHarnessImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: mintingSelectors
            });

        ISolidStateDiamond.FacetCut
            memory stakingFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(depositFacetMockImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: depositSelectors
            });

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](2);

        facetCuts[0] = mintFacetCut;
        facetCuts[1] = stakingFacetCut;

        return facetCuts;
    }
}
