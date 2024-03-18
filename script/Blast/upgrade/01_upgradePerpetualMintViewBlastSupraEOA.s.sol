// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IPausable } from "@solidstate/contracts/security/pausable/IPausable.sol";

import { IPerpetualMintView } from "../../../contracts/facets/PerpetualMint/IPerpetualMintView.sol";
import { IPerpetualMintViewBlast } from "../../../contracts/facets/PerpetualMint/Blast/IPerpetualMintView.sol";
import { IPerpetualMintViewBlastSupra } from "../../../contracts/facets/PerpetualMint/Blast/Supra/IPerpetualMintView.sol";
import { PerpetualMintViewBlastSupra } from "../../../contracts/facets/PerpetualMint/Blast/Supra/PerpetualMintView.sol";

/// @title UpgradePerpetualMintViewBlastSupraEOA
/// @dev Deploys a new PerpetualMintViewBlastSupra facet and signs and submits a diamondCut of the PerpetualMintViewBlastSupra facet to the Core diamond
/// using an externally owned account
contract UpgradePerpetualMintViewBlastSupraEOA is Script {
    /// @dev runs the script logic
    function run() external {
        // read deployer private key
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");

        // get CoreBlast PerpetualMint diamond address
        address core = vm.envAddress("CORE_BLAST_ADDRESS");

        // get VRF Router address
        address VRF_ROUTER = vm.envAddress("VRF_ROUTER");

        vm.startBroadcast(deployerPrivateKey);

        // deploy PerpetualMintViewBlastSupra facet
        PerpetualMintViewBlastSupra perpetualMintViewBlastSupra = new PerpetualMintViewBlastSupra(
                VRF_ROUTER
            );

        console.log(
            "New PerpetualMintViewBlastSupra Facet Address: ",
            address(perpetualMintViewBlastSupra)
        );
        console.log("CoreBlast Address: ", core);
        console.log("VRF Router Address: ", VRF_ROUTER);

        // get new PerpetualMintView + PerpetualMintViewBlastSupra facet cuts
        ISolidStateDiamond.FacetCut[]
            memory newPerpetualMintViewFacetCuts = getNewPerpetualMintViewFacetCuts(
                address(perpetualMintViewBlastSupra)
            );

        // get replacement PerpetualMintView + PerpetualMintViewBlastSupra facet cuts
        ISolidStateDiamond.FacetCut[]
            memory replacementPerpetualMintViewFacetCuts = getReplacementPerpetualMintViewFacetCuts(
                address(perpetualMintViewBlastSupra)
            );

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](5);

        facetCuts[0] = newPerpetualMintViewFacetCuts[0];
        facetCuts[1] = replacementPerpetualMintViewFacetCuts[0];
        facetCuts[2] = replacementPerpetualMintViewFacetCuts[1];
        facetCuts[3] = replacementPerpetualMintViewFacetCuts[2];
        facetCuts[4] = replacementPerpetualMintViewFacetCuts[3];

        // cut PerpetualMintView + PerpetualMintViewBlastSupra into Core
        ISolidStateDiamond(payable(core)).diamondCut(facetCuts, address(0), "");

        vm.stopBroadcast();
    }

    /// @dev provides the new facet cuts for cutting PerpetualMintView & PerpetualMintViewBlastSupra facets into Core
    /// @param viewFacetAddress address of PerpetualMintView facet
    function getNewPerpetualMintViewFacetCuts(
        address viewFacetAddress
    ) internal pure returns (ISolidStateDiamond.FacetCut[] memory) {
        // map the PerpetualMintViewBlast related function selectors to their respective interfaces
        bytes4[] memory perpetualMintViewBlastFunctionSelectors = new bytes4[](
            1
        );

        perpetualMintViewBlastFunctionSelectors[0] = IPerpetualMintViewBlast
            .calculateMaxClaimableGas
            .selector;

        ISolidStateDiamond.FacetCut
            memory perpetualMintViewBlastFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: viewFacetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintViewBlastFunctionSelectors
                });

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](1);

        facetCuts[0] = perpetualMintViewBlastFacetCut;

        return facetCuts;
    }

    /// @dev provides the replacement facet cuts for cutting PerpetualMintView facet into Core
    /// @param viewFacetAddress address of PerpetualMintView facet
    function getReplacementPerpetualMintViewFacetCuts(
        address viewFacetAddress
    ) internal pure returns (ISolidStateDiamond.FacetCut[] memory) {
        // map the Pausable function selectors to their respective interfaces
        bytes4[] memory pausableFunctionSelectors = new bytes4[](1);

        pausableFunctionSelectors[0] = IPausable.paused.selector;

        ISolidStateDiamond.FacetCut
            memory pausableFacetCut = IDiamondWritableInternal.FacetCut({
                target: viewFacetAddress,
                action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                selectors: pausableFunctionSelectors
            });

        // map the PerpetualMintView related function selectors to their respective interfaces
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

        ISolidStateDiamond.FacetCut memory perpetualMintViewFacetCut;

        ISolidStateDiamond.FacetCut[] memory facetCuts;

        perpetualMintViewFacetCut = IDiamondWritableInternal.FacetCut({
            target: viewFacetAddress,
            action: IDiamondWritableInternal.FacetCutAction.REPLACE,
            selectors: perpetualMintViewFunctionSelectors
        });

        // map the PerpetualMintViewBlast related function selectors to their respective interfaces
        bytes4[] memory perpetualMintViewBlastFunctionSelectors = new bytes4[](
            1
        );

        perpetualMintViewBlastFunctionSelectors[0] = IPerpetualMintViewBlast
            .blastYieldRisk
            .selector;

        ISolidStateDiamond.FacetCut
            memory perpetualMintViewBlastFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: viewFacetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                    selectors: perpetualMintViewBlastFunctionSelectors
                });

        // map the PerpetualMintViewBlastSupra related function selectors to their respective interfaces
        bytes4[]
            memory perpetualMintViewBlastSupraFunctionSelectors = new bytes4[](
                1
            );

        perpetualMintViewBlastSupraFunctionSelectors[
            0
        ] = IPerpetualMintViewBlastSupra.calculateMintResultBlastSupra.selector;

        ISolidStateDiamond.FacetCut
            memory perpetualMintViewBlastSupraFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: viewFacetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                    selectors: perpetualMintViewBlastSupraFunctionSelectors
                });

        facetCuts = new ISolidStateDiamond.FacetCut[](4);

        facetCuts[0] = pausableFacetCut;
        facetCuts[1] = perpetualMintViewFacetCut;
        facetCuts[2] = perpetualMintViewBlastFacetCut;
        facetCuts[3] = perpetualMintViewBlastSupraFacetCut;

        return facetCuts;
    }
}
