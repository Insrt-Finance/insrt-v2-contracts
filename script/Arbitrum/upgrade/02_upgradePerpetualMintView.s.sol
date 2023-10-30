// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-safe/BatchScript.sol";

import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";
import { IDiamondWritable } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";

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
            "New PerpetualMint Facet Address: ",
            address(perpetualMintView)
        );
        console2.log("Core Address: ", core);
        console2.log("VRF Coordinator Address: ", VRF_COORDINATOR);

        // get new PerpetualMintView facet cuts
        ISolidStateDiamond.FacetCut[]
            memory newPerpetualMintViewFacetCuts = getNewPerpetualMintViewFacetCuts(
                address(perpetualMintView)
            );

        // get replacement PerpetualMintView facet cuts
        ISolidStateDiamond.FacetCut[]
            memory replacementPerpetualMintViewFacetCuts = getReplacementPerpetualMintViewFacetCuts(
                address(perpetualMintView)
            );

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](2);

        facetCuts[0] = newPerpetualMintViewFacetCuts[0];
        facetCuts[1] = replacementPerpetualMintViewFacetCuts[0];

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
    ) internal pure returns (ISolidStateDiamond.FacetCut[] memory) {
        // map the PerpetualMintView related function selectors to their respective interfaces
        bytes4[] memory perpetualMintViewFunctionSelectors = new bytes4[](1);

        perpetualMintViewFunctionSelectors[0] = IPerpetualMintView
            .collectionMintMultiplier
            .selector;

        ISolidStateDiamond.FacetCut
            memory perpetualMintViewFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: viewFacetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintViewFunctionSelectors
                });

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](1);

        facetCuts[0] = perpetualMintViewFacetCut;

        return facetCuts;
    }

    /// @dev provides the replacement facet cuts for cutting PerpetualMintView facet into Core
    /// @param viewFacetAddress address of PerpetualMintView facet
    function getReplacementPerpetualMintViewFacetCuts(
        address viewFacetAddress
    ) internal pure returns (ISolidStateDiamond.FacetCut[] memory) {
        // map the PerpetualMintView related function selectors to their respective interfaces
        bytes4[] memory perpetualMintViewFunctionSelectors = new bytes4[](19);

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
            .collectionMintPrice
            .selector;

        perpetualMintViewFunctionSelectors[6] = IPerpetualMintView
            .collectionRisk
            .selector;

        perpetualMintViewFunctionSelectors[7] = IPerpetualMintView
            .consolationFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[8] = IPerpetualMintView
            .defaultCollectionMintPrice
            .selector;

        perpetualMintViewFunctionSelectors[9] = IPerpetualMintView
            .defaultCollectionRisk
            .selector;

        perpetualMintViewFunctionSelectors[10] = IPerpetualMintView
            .defaultEthToMintRatio
            .selector;

        perpetualMintViewFunctionSelectors[11] = IPerpetualMintView
            .ethToMintRatio
            .selector;

        perpetualMintViewFunctionSelectors[12] = IPerpetualMintView
            .mintFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[13] = IPerpetualMintView
            .mintToken
            .selector;

        perpetualMintViewFunctionSelectors[14] = IPerpetualMintView
            .redemptionFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[15] = IPerpetualMintView
            .redeemPaused
            .selector;

        perpetualMintViewFunctionSelectors[16] = IPerpetualMintView
            .tiers
            .selector;

        perpetualMintViewFunctionSelectors[17] = IPerpetualMintView
            .vrfConfig
            .selector;

        perpetualMintViewFunctionSelectors[18] = IPerpetualMintView
            .vrfSubscriptionBalanceThreshold
            .selector;

        ISolidStateDiamond.FacetCut
            memory perpetualMintViewFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: viewFacetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                    selectors: perpetualMintViewFunctionSelectors
                });

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](1);

        facetCuts[0] = perpetualMintViewFacetCut;

        return facetCuts;
    }
}
