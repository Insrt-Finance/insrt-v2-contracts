// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";

import { ICore } from "../../../contracts/diamonds/Core/ICore.sol";
import { IPerpetualMint } from "../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";
import { PerpetualMint } from "../../../contracts/facets/PerpetualMint/PerpetualMint.sol";

/// @title UpgradePerpetualMintArbEOA
/// @dev Deploys a new PerpetualMint facet and signs and submits a diamondCut of the PerpetualMint facet to the Core diamond
/// using an externally owned account
contract UpgradePerpetualMintArbEOA is Script {
    /// @dev runs the script logic
    function run() external {
        // read deployer private key
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");

        // get Core PerpetualMint diamond address
        address core = vm.envAddress("CORE_ADDRESS");

        // get VRF Coordinator address
        address VRF_COORDINATOR = vm.envAddress("VRF_COORDINATOR");

        vm.startBroadcast(deployerPrivateKey);

        // deploy new PerpetualMint facet
        PerpetualMint perpetualMint = new PerpetualMint(VRF_COORDINATOR);

        console.log(
            "New PerpetualMint Facet Address: ",
            address(perpetualMint)
        );
        console.log("Core Address: ", core);
        console.log("VRF Coordinator Address: ", VRF_COORDINATOR);

        // get new PerpetualMint facet cuts
        ICore.FacetCut[]
            memory newPerpetualMintFacetCuts = getNewPerpetualMintFacetCuts(
                address(perpetualMint)
            );

        // get replacement PerpetualMint facet cuts
        ICore.FacetCut[]
            memory replacementPerpetualMintFacetCuts = getReplacementPerpetualMintFacetCuts(
                address(perpetualMint)
            );

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](3);

        facetCuts[0] = newPerpetualMintFacetCuts[0];
        facetCuts[1] = replacementPerpetualMintFacetCuts[0];
        facetCuts[2] = replacementPerpetualMintFacetCuts[1];

        // cut PerpetualMint into Core
        ICore(payable(core)).diamondCut(facetCuts, address(0), "");

        vm.stopBroadcast();
    }

    /// @dev provides the new facet cuts for cutting PerpetualMint facet into Core
    /// @param facetAddress address of PerpetualMint facet
    function getNewPerpetualMintFacetCuts(
        address facetAddress
    ) internal pure returns (ICore.FacetCut[] memory) {
        // map the PerpetualMint related function selectors to their respective interfaces
        bytes4[] memory perpetualMintFunctionSelectors = new bytes4[](1);

        perpetualMintFunctionSelectors[0] = IPerpetualMint
            .attemptBatchMintForEthWithMint
            .selector;

        ICore.FacetCut memory perpetualMintFacetCut = IDiamondWritableInternal
            .FacetCut({
                target: facetAddress,
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: perpetualMintFunctionSelectors
            });

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](1);

        facetCuts[0] = perpetualMintFacetCut;

        return facetCuts;
    }

    /// @dev provides the replacement facet cuts for cutting PerpetualMint facet into Core
    /// @param facetAddress address of PerpetualMint facet
    function getReplacementPerpetualMintFacetCuts(
        address facetAddress
    ) internal pure returns (ICore.FacetCut[] memory) {
        // map the PerpetualMint related function selectors to their respective interfaces
        bytes4[] memory perpetualMintFunctionSelectors = new bytes4[](8);

        perpetualMintFunctionSelectors[0] = IPerpetualMint
            .attemptBatchMintForEthWithEth
            .selector;

        perpetualMintFunctionSelectors[1] = IPerpetualMint
            .attemptBatchMintForMintWithEth
            .selector;

        perpetualMintFunctionSelectors[2] = IPerpetualMint
            .attemptBatchMintForMintWithMint
            .selector;

        perpetualMintFunctionSelectors[3] = IPerpetualMint
            .attemptBatchMintWithEth
            .selector;

        perpetualMintFunctionSelectors[4] = IPerpetualMint
            .attemptBatchMintWithMint
            .selector;

        perpetualMintFunctionSelectors[5] = IPerpetualMint.claimPrize.selector;

        perpetualMintFunctionSelectors[6] = IPerpetualMint
            .fundConsolationFees
            .selector;

        perpetualMintFunctionSelectors[7] = IPerpetualMint.redeem.selector;

        ICore.FacetCut memory perpetualMintFacetCut = IDiamondWritableInternal
            .FacetCut({
                target: facetAddress,
                action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                selectors: perpetualMintFunctionSelectors
            });

        // map the VRFConsumerBaseV2 function selectors to their respective interfaces
        bytes4[] memory vrfConsumerBaseV2FunctionSelectors = new bytes4[](1);

        vrfConsumerBaseV2FunctionSelectors[0] = VRFConsumerBaseV2
            .rawFulfillRandomWords
            .selector;

        ICore.FacetCut
            memory vrfConsumerBaseV2FacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: facetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                    selectors: vrfConsumerBaseV2FunctionSelectors
                });

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](2);

        // omit Ownable since SolidStateDiamond includes those
        facetCuts[0] = perpetualMintFacetCut;
        facetCuts[1] = vrfConsumerBaseV2FacetCut;

        return facetCuts;
    }
}
