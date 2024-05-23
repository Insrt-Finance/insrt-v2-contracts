// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-safe/BatchScript.sol";

import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import { IDiamondWritable } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";

import { ICore } from "../../../contracts/diamonds/Core/ICore.sol";
import { IPerpetualMint } from "../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";
import { PerpetualMintSupraBlast } from "../../../contracts/facets/PerpetualMint/Blast/Supra/PerpetualMint.sol";

/// @title UpgradeAndRemovePerpetualMintSupraBlast
/// @dev Deploys a new PerpetualMintSupraBlast facet and signs and submits a diamondCut of the PerpetualMintSupraBlast facet
/// to the CoreBlast diamond via the Gnosis Safe Transaction Service API
contract UpgradePerpetualMintSupraBlast is BatchScript {
    /// @dev runs the script logic
    function run() external {
        // read deployer private key
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");

        // get CoreBlast PerpetualMint diamond address
        address core = vm.envAddress("CORE_BLAST_ADDRESS");

        // get Gnosis Safe (protocol owner) address
        address gnosisSafeAddress = vm.envAddress("GNOSIS_SAFE");

        // get VRF Router address
        address VRF_ROUTER = vm.envAddress("VRF_ROUTER");

        // we only explicitly broadcast facet deployments
        // broadcasting of batch execution gnosis multi-sig transactions is done
        // separately using the Gnosis Safe Transaction Service API
        vm.startBroadcast(deployerPrivateKey);

        // deploy new PerpetualMintSupraBlast facet
        PerpetualMintSupraBlast perpetualMintSupraBlast = new PerpetualMintSupraBlast(
                VRF_ROUTER
            );

        vm.stopBroadcast();

        console2.log(
            "New PerpetualMintSupraBlast Facet Address: ",
            address(perpetualMintSupraBlast)
        );
        console2.log("CoreBlast Address: ", core);
        console2.log("VRF Router Address: ", VRF_ROUTER);

        // get new PerpetualMint + PerpetualMintSupraBlast facet cuts
        ICore.FacetCut[]
            memory newPerpetualMintFacetCuts = getNewPerpetualMintFacetCuts(
                address(perpetualMintSupraBlast)
            );

        // get removal PerpetualMint + PerpetualMintSupraBlast facet cuts
        ICore.FacetCut[]
            memory removalPerpetualMintFacetCuts = getRemovalPerpetualMintFacetCuts(
                address(0) // removal target addresses are expected to be zero address
            );

        // get replacement get PerpetualMint + PerpetualMintSupraBlast facet cuts
        ICore.FacetCut[]
            memory replacementPerpetualMintFacetCuts = getReplacementPerpetualMintFacetCuts(
                address(perpetualMintSupraBlast)
            );

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](4);

        facetCuts[0] = newPerpetualMintFacetCuts[0];
        facetCuts[1] = removalPerpetualMintFacetCuts[0];
        facetCuts[2] = replacementPerpetualMintFacetCuts[0];
        facetCuts[3] = replacementPerpetualMintFacetCuts[1];

        bytes memory diamondCutTx = abi.encodeWithSelector(
            IDiamondWritable.diamondCut.selector,
            facetCuts,
            address(0),
            ""
        );

        addToBatch(core, diamondCutTx);

        executeBatch(gnosisSafeAddress, true);
    }

    /// @dev provides the removal facet cuts for removing PerpetualMint & PerpetualMintSupraBlast facet functions from CoreBlast
    /// @param facetAddress target address to remove
    function getRemovalPerpetualMintFacetCuts(
        address facetAddress
    ) internal pure returns (ICore.FacetCut[] memory facetCuts) {
        // map the PerpetualMint related function selectors to their respective interfaces
        bytes4[] memory perpetualMintFunctionSelectors = new bytes4[](2);

        perpetualMintFunctionSelectors[0] = bytes4(
            keccak256("attemptBatchMintForEthWithEth(address,uint32,uint256)")
        );

        perpetualMintFunctionSelectors[1] = bytes4(
            keccak256(
                "attemptBatchMintForEthWithMint(address,uint256,uint32,uint256)"
            )
        );

        ICore.FacetCut memory perpetualMintFacetCut = IDiamondWritableInternal
            .FacetCut({
                target: facetAddress,
                action: IDiamondWritableInternal.FacetCutAction.REMOVE,
                selectors: perpetualMintFunctionSelectors
            });

        facetCuts = new ICore.FacetCut[](1);

        facetCuts[0] = perpetualMintFacetCut;
    }

    /// @dev provides the new facet cuts for cutting PerpetualMint & PerpetualMintSupraBlast facets
    /// into CoreBlast
    /// @param facetAddress address of PerpetualMint facet
    function getNewPerpetualMintFacetCuts(
        address facetAddress
    ) internal pure returns (ICore.FacetCut[] memory facetCuts) {
        // map the PerpetualMint related function selectors to their respective interfaces
        bytes4[] memory perpetualMintFunctionSelectors = new bytes4[](2);

        perpetualMintFunctionSelectors[0] = IPerpetualMint
            .attemptBatchMintForEthWithEth
            .selector;

        perpetualMintFunctionSelectors[1] = IPerpetualMint
            .attemptBatchMintForEthWithMint
            .selector;

        ICore.FacetCut memory perpetualMintFacetCut = IDiamondWritableInternal
            .FacetCut({
                target: facetAddress,
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: perpetualMintFunctionSelectors
            });

        facetCuts = new ICore.FacetCut[](1);

        facetCuts[0] = perpetualMintFacetCut;
    }

    /// @dev provides the replacement facet cuts for cutting PerpetualMint & PerpetualMintSupraBlast facets
    /// into CoreBlast
    /// @param facetAddress address of PerpetualMint facet
    function getReplacementPerpetualMintFacetCuts(
        address facetAddress
    ) internal pure returns (ICore.FacetCut[] memory facetCuts) {
        // map the PerpetualMint related function selectors to their respective interfaces
        bytes4[] memory perpetualMintFunctionSelectors = new bytes4[](7);

        perpetualMintFunctionSelectors[0] = IPerpetualMint
            .attemptBatchMintForMintWithEth
            .selector;

        perpetualMintFunctionSelectors[1] = IPerpetualMint
            .attemptBatchMintForMintWithMint
            .selector;

        perpetualMintFunctionSelectors[2] = IPerpetualMint
            .attemptBatchMintWithEth
            .selector;

        perpetualMintFunctionSelectors[3] = IPerpetualMint
            .attemptBatchMintWithMint
            .selector;

        perpetualMintFunctionSelectors[4] = IPerpetualMint.claimPrize.selector;

        perpetualMintFunctionSelectors[5] = IPerpetualMint
            .fundConsolationFees
            .selector;

        perpetualMintFunctionSelectors[6] = IPerpetualMint.redeem.selector;

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

        facetCuts = new ICore.FacetCut[](2);

        // omit Ownable since SolidStateDiamond includes those
        facetCuts[0] = perpetualMintFacetCut;
        facetCuts[1] = vrfConsumerBaseV2FacetCut;
    }
}
