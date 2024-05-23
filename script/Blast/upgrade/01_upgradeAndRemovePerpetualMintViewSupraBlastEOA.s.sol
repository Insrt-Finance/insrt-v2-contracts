// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IPausable } from "@solidstate/contracts/security/pausable/IPausable.sol";

import { ICore } from "../../../contracts/diamonds/Core/ICore.sol";
import { IPerpetualMintView } from "../../../contracts/facets/PerpetualMint/IPerpetualMintView.sol";
import { IPerpetualMintViewBlast } from "../../../contracts/facets/PerpetualMint/Blast/IPerpetualMintView.sol";
import { IPerpetualMintViewSupraBlast } from "../../../contracts/facets/PerpetualMint/Blast/Supra/IPerpetualMintView.sol";
import { PerpetualMintViewSupraBlast } from "../../../contracts/facets/PerpetualMint/Blast/Supra/PerpetualMintView.sol";

/// @title UpgradeAndRemovePerpetualMintViewSupraBlastEOA
/// @dev Upgrades and removes certain functions from the PerpetualMintViewSupraBlast facet and signs and submits a diamondCut
/// of the PerpetualMintViewSupraBlast facet to the Core diamond using an externally owned account
contract UpgradeAndRemovePerpetualMintViewSupraBlastEOA is Script {
    /// @dev runs the script logic
    function run() external {
        // read deployer private key
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");

        // get CoreBlast PerpetualMint diamond address
        address core = vm.envAddress("CORE_BLAST_ADDRESS");

        // get VRF Router address
        address VRF_ROUTER = vm.envAddress("VRF_ROUTER");

        vm.startBroadcast(deployerPrivateKey);

        // deploy PerpetualMintViewSupraBlast facet
        PerpetualMintViewSupraBlast perpetualMintViewSupraBlast = new PerpetualMintViewSupraBlast(
                VRF_ROUTER
            );

        console.log(
            "New PerpetualMintViewSupraBlast Facet Address: ",
            address(perpetualMintViewSupraBlast)
        );
        console.log("CoreBlast Address: ", core);
        console.log("VRF Router Address: ", VRF_ROUTER);

        // get new PerpetualMintView + PerpetualMintViewSupraBlast facet cuts
        ICore.FacetCut[]
            memory newPerpetualMintViewFacetCuts = getNewPerpetualMintViewFacetCuts(
                address(perpetualMintViewSupraBlast)
            );

        // get removal PerpetualMintView + PerpetualMintViewSupraBlast facet cuts
        ICore.FacetCut[]
            memory removalPerpetualMintViewFacetCuts = getRemovalPerpetualMintViewFacetCuts(
                address(0) // removal target addresses are expected to be zero address
            );

        // get replacement PerpetualMintView + PerpetualMintViewSupraBlast facet cuts
        ICore.FacetCut[]
            memory replacementPerpetualMintViewFacetCuts = getReplacementPerpetualMintViewFacetCuts(
                address(perpetualMintViewSupraBlast)
            );

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](5);

        facetCuts[0] = newPerpetualMintViewFacetCuts[0];
        facetCuts[1] = removalPerpetualMintViewFacetCuts[0];
        facetCuts[2] = replacementPerpetualMintViewFacetCuts[0];
        facetCuts[3] = replacementPerpetualMintViewFacetCuts[1];
        facetCuts[4] = replacementPerpetualMintViewFacetCuts[2];

        // cut PerpetualMintView + PerpetualMintViewSupraBlast into Core
        ICore(payable(core)).diamondCut(facetCuts, address(0), "");

        vm.stopBroadcast();
    }

    /// @dev provides the new facet cuts for cutting PerpetualMintView & PerpetualMintViewSupraBlast facets into Core
    /// @param viewFacetAddress address of PerpetualMintView facet
    function getNewPerpetualMintViewFacetCuts(
        address viewFacetAddress
    ) internal pure returns (ICore.FacetCut[] memory facetCuts) {
        // map the PerpetualMintViewSupraBlast related function selectors to their respective interfaces
        bytes4[]
            memory perpetualMintViewSupraBlastFunctionSelectors = new bytes4[](
                1
            );

        perpetualMintViewSupraBlastFunctionSelectors[
            0
        ] = IPerpetualMintViewSupraBlast.calculateMintResultSupraBlast.selector;

        ICore.FacetCut
            memory perpetualMintViewSupraBlastFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: viewFacetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintViewSupraBlastFunctionSelectors
                });

        facetCuts = new ICore.FacetCut[](1);

        facetCuts[0] = perpetualMintViewSupraBlastFacetCut;
    }

    /// @dev provides the removal facet cuts for removing PerpetualMintView & PerpetualMintViewSupraBlast facets functions from Core
    /// @param facetAddress target address to remove
    function getRemovalPerpetualMintViewFacetCuts(
        address facetAddress
    ) internal pure returns (ICore.FacetCut[] memory facetCuts) {
        // map the PerpetualMintViewSupraBlast related function selectors to their respective interfaces
        bytes4[]
            memory perpetualMintViewSupraBlastFunctionSelectors = new bytes4[](
                1
            );

        perpetualMintViewSupraBlastFunctionSelectors[0] = bytes4(
            keccak256(
                "calculateMintResultSupraBlast(address,uint8,uint256[2],uint256,uint256,bool)"
            )
        );

        ICore.FacetCut
            memory perpetualMintViewSupraBlastFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: facetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.REMOVE,
                    selectors: perpetualMintViewSupraBlastFunctionSelectors
                });

        facetCuts = new ICore.FacetCut[](1);

        facetCuts[0] = perpetualMintViewSupraBlastFacetCut;
    }

    /// @dev provides the replacement facet cuts for cutting PerpetualMintView facet into Core
    /// @param viewFacetAddress address of PerpetualMintView facet
    function getReplacementPerpetualMintViewFacetCuts(
        address viewFacetAddress
    ) internal pure returns (ICore.FacetCut[] memory facetCuts) {
        // map the Pausable function selectors to their respective interfaces
        bytes4[] memory pausableFunctionSelectors = new bytes4[](1);

        pausableFunctionSelectors[0] = IPausable.paused.selector;

        ICore.FacetCut memory pausableFacetCut = IDiamondWritableInternal
            .FacetCut({
                target: viewFacetAddress,
                action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                selectors: pausableFunctionSelectors
            });

        // map the PerpetualMintView related function selectors to their respective interfaces
        bytes4[] memory perpetualMintViewFunctionSelectors = new bytes4[](27);

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
            .mintEarningsBufferBP
            .selector;

        perpetualMintViewFunctionSelectors[16] = IPerpetualMintView
            .mintFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[17] = IPerpetualMintView
            .mintForEthConsolationFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[18] = IPerpetualMintView
            .mintToken
            .selector;

        perpetualMintViewFunctionSelectors[19] = IPerpetualMintView
            .mintTokenConsolationFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[20] = IPerpetualMintView
            .mintTokenTiers
            .selector;

        perpetualMintViewFunctionSelectors[21] = IPerpetualMintView
            .redemptionFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[22] = IPerpetualMintView
            .redeemPaused
            .selector;

        perpetualMintViewFunctionSelectors[23] = IPerpetualMintView
            .SCALE
            .selector;

        perpetualMintViewFunctionSelectors[24] = IPerpetualMintView
            .tiers
            .selector;

        perpetualMintViewFunctionSelectors[25] = IPerpetualMintView
            .vrfConfig
            .selector;

        perpetualMintViewFunctionSelectors[26] = IPerpetualMintView
            .vrfSubscriptionBalanceThreshold
            .selector;

        ICore.FacetCut
            memory perpetualMintViewFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: viewFacetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                    selectors: perpetualMintViewFunctionSelectors
                });

        // map the PerpetualMintViewBlast related function selectors to their respective interfaces
        bytes4[] memory perpetualMintViewBlastFunctionSelectors = new bytes4[](
            2
        );

        perpetualMintViewBlastFunctionSelectors[0] = IPerpetualMintViewBlast
            .blastYieldRisk
            .selector;

        perpetualMintViewBlastFunctionSelectors[1] = IPerpetualMintViewBlast
            .calculateMaxClaimableGas
            .selector;

        ICore.FacetCut
            memory perpetualMintViewBlastFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: viewFacetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                    selectors: perpetualMintViewBlastFunctionSelectors
                });

        facetCuts = new ICore.FacetCut[](3);

        facetCuts[0] = pausableFacetCut;
        facetCuts[1] = perpetualMintViewFacetCut;
        facetCuts[2] = perpetualMintViewBlastFacetCut;
    }
}
