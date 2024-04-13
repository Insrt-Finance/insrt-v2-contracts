// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-safe/BatchScript.sol";

import { IDiamondWritable } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";

import { ICore } from "../../../contracts/diamonds/Core/ICore.sol";
import { IPerpetualMintView } from "../../../contracts/facets/PerpetualMint/IPerpetualMintView.sol";
import { PerpetualMintView } from "../../../contracts/facets/PerpetualMint/PerpetualMintView.sol";

/// @title UpgradePerpetualMintViewArb
/// @dev Deploys a new PerpetualMintView facet and signs and submits a diamondCut of the PerpetualMintView facet to the Core diamond
/// via the Gnosis Safe Transaction Service API
contract UpgradePerpetualMintViewArb is BatchScript {
    /// @dev runs the script logic
    function run() external {
        // read deployer private key
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");

        // get Core PerpetualMint diamond address
        address core = vm.envAddress("CORE_ADDRESS");

        // get Gnosis Safe (protocol owner) address
        address gnosisSafeAddress = vm.envAddress("GNOSIS_SAFE");

        // get VRF Coordinator address
        address VRF_COORDINATOR = vm.envAddress("VRF_COORDINATOR");

        // we only explicitly broadcast facet deployments
        // broadcasting of batch execution gnosis multi-sig transactions is done
        // separately using the Gnosis Safe Transaction Service API
        vm.startBroadcast(deployerPrivateKey);

        // deploy PerpetualMintView facet
        PerpetualMintView perpetualMintView = new PerpetualMintView(
            VRF_COORDINATOR
        );

        vm.stopBroadcast();

        console2.log(
            "New PerpetualMintView Facet Address: ",
            address(perpetualMintView)
        );
        console2.log("Core Address: ", core);
        console2.log("VRF Coordinator Address: ", VRF_COORDINATOR);

        // get new PerpetualMintView facet cuts
        ICore.FacetCut[]
            memory newPerpetualMintViewFacetCuts = getNewPerpetualMintViewFacetCuts(
                address(perpetualMintView)
            );

        // get replacement PerpetualMintView facet cuts
        ICore.FacetCut[]
            memory replacementPerpetualMintViewFacetCuts = getReplacementPerpetualMintViewFacetCuts(
                address(perpetualMintView)
            );

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](1);

        facetCuts[0] = replacementPerpetualMintViewFacetCuts[0];

        bytes memory diamondCutTx = abi.encodeWithSelector(
            IDiamondWritable.diamondCut.selector,
            facetCuts,
            address(0),
            ""
        );

        addToBatch(core, diamondCutTx);

        executeBatch(gnosisSafeAddress, true);
    }

    /// @dev provides the new facet cuts for cutting PerpetualMintView facet into Core
    /// @param viewFacetAddress address of PerpetualMintView facet
    function getNewPerpetualMintViewFacetCuts(
        address viewFacetAddress
    ) internal pure returns (ICore.FacetCut[] memory) {
        // map the PerpetualMintView related function selectors to their respective interfaces
        bytes4[] memory perpetualMintViewFunctionSelectors = new bytes4[](2);

        perpetualMintViewFunctionSelectors[0] = IPerpetualMintView
            .mintEarningsBufferBP
            .selector;

        perpetualMintViewFunctionSelectors[1] = IPerpetualMintView
            .mintForEthConsolationFeeBP
            .selector;

        ICore.FacetCut
            memory perpetualMintViewFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: viewFacetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintViewFunctionSelectors
                });

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](1);

        facetCuts[0] = perpetualMintViewFacetCut;

        return facetCuts;
    }

    /// @dev provides the replacement facet cuts for cutting PerpetualMintView facet into Core
    /// @param viewFacetAddress address of PerpetualMintView facet
    function getReplacementPerpetualMintViewFacetCuts(
        address viewFacetAddress
    ) internal pure returns (ICore.FacetCut[] memory) {
        // map the PerpetualMintView related function selectors to their respective interfaces
        bytes4[] memory perpetualMintViewFunctionSelectors = new bytes4[](26);

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
            .mintFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[17] = IPerpetualMintView
            .mintToken
            .selector;

        perpetualMintViewFunctionSelectors[18] = IPerpetualMintView
            .mintTokenConsolationFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[19] = IPerpetualMintView
            .mintTokenTiers
            .selector;

        perpetualMintViewFunctionSelectors[20] = IPerpetualMintView
            .redemptionFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[21] = IPerpetualMintView
            .redeemPaused
            .selector;

        perpetualMintViewFunctionSelectors[22] = IPerpetualMintView
            .SCALE
            .selector;

        perpetualMintViewFunctionSelectors[23] = IPerpetualMintView
            .tiers
            .selector;

        perpetualMintViewFunctionSelectors[24] = IPerpetualMintView
            .vrfConfig
            .selector;

        perpetualMintViewFunctionSelectors[25] = IPerpetualMintView
            .vrfSubscriptionBalanceThreshold
            .selector;

        ICore.FacetCut
            memory perpetualMintViewFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: viewFacetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                    selectors: perpetualMintViewFunctionSelectors
                });

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](1);

        facetCuts[0] = perpetualMintViewFacetCut;

        return facetCuts;
    }
}
