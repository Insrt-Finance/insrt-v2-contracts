// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";
import { IDiamondWritable } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IPausable } from "@solidstate/contracts/security/pausable/IPausable.sol";
import { IERC1155Metadata } from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";

import { IPerpetualMint } from "../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";
import { PerpetualMint } from "../../../contracts/facets/PerpetualMint/PerpetualMint.sol";

/// @title UpgradeAndRemovePerpetualMintArbEOA
/// @dev Upgrades and removes certain functions from the PerpetualMint facet by deploying a new PerpetualMint facet and signing and submitting
/// a diamondCut of the upgrade & removal PerpetualMint facets to the Core diamond using an externally owned account
contract UpgradeAndRemovePerpetualMintArbEOA is Script {
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
        ISolidStateDiamond.FacetCut[]
            memory newPerpetualMintFacetCuts = getNewPerpetualMintFacetCuts(
                address(perpetualMint)
            );

        // get removal PerpetualMint facet cuts
        ISolidStateDiamond.FacetCut[]
            memory removalPerpetualMintFacetCuts = getRemovalPerpetualMintFacetCuts(
                address(0) // removal target addresses are expected to be zero address
            );

        // get replacement PerpetualMint facet cuts
        ISolidStateDiamond.FacetCut[]
            memory replacementPerpetualMintFacetCuts = getReplacementPerpetualMintFacetCuts(
                address(perpetualMint)
            );

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](6);

        facetCuts[0] = newPerpetualMintFacetCuts[0];
        facetCuts[1] = removalPerpetualMintFacetCuts[0];
        facetCuts[2] = replacementPerpetualMintFacetCuts[0];
        facetCuts[3] = replacementPerpetualMintFacetCuts[1];
        facetCuts[4] = replacementPerpetualMintFacetCuts[2];
        facetCuts[5] = replacementPerpetualMintFacetCuts[3];

        // cut PerpetualMint into Core
        ISolidStateDiamond(payable(core)).diamondCut(facetCuts, address(0), "");

        vm.stopBroadcast();
    }

    /// @dev provides the new facet cuts for cutting PerpetualMint facet into Core
    /// @param facetAddress address of PerpetualMint facet
    function getNewPerpetualMintFacetCuts(
        address facetAddress
    ) internal pure returns (ISolidStateDiamond.FacetCut[] memory) {
        // map the PerpetualMint related function selectors to their respective interfaces
        bytes4[] memory perpetualMintFunctionSelectors = new bytes4[](3);

        perpetualMintFunctionSelectors[0] = IPerpetualMint
            .attemptBatchMintForMintWithEth
            .selector;

        perpetualMintFunctionSelectors[1] = IPerpetualMint
            .attemptBatchMintForMintWithMint
            .selector;

        perpetualMintFunctionSelectors[2] = IPerpetualMint
            .setMintTokenConsolationFeeBP
            .selector;

        ISolidStateDiamond.FacetCut
            memory perpetualMintFacetCut = IDiamondWritableInternal.FacetCut({
                target: facetAddress,
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: perpetualMintFunctionSelectors
            });

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](1);

        facetCuts[0] = perpetualMintFacetCut;

        return facetCuts;
    }

    /// @dev provides the removal facet cuts for removing PerpetualMint facet functions from Core
    /// @param facetAddress target address to remove
    function getRemovalPerpetualMintFacetCuts(
        address facetAddress
    ) internal pure returns (ISolidStateDiamond.FacetCut[] memory) {
        // map the PerpetualMint related function selectors to their respective interfaces
        bytes4[] memory perpetualMintFunctionSelectors = new bytes4[](1);

        perpetualMintFunctionSelectors[0] = bytes4(
            keccak256("setConsolationFeeBP(uint32)")
        );

        ISolidStateDiamond.FacetCut
            memory perpetualMintFacetCut = IDiamondWritableInternal.FacetCut({
                target: facetAddress,
                action: IDiamondWritableInternal.FacetCutAction.REMOVE,
                selectors: perpetualMintFunctionSelectors
            });

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](1);

        facetCuts[0] = perpetualMintFacetCut;

        return facetCuts;
    }

    /// @dev provides the replacement facet cuts for cutting PerpetualMint facet into Core
    /// @param facetAddress address of PerpetualMint facet
    function getReplacementPerpetualMintFacetCuts(
        address facetAddress
    ) internal pure returns (ISolidStateDiamond.FacetCut[] memory) {
        // map the ERC1155Metadata function selectors to their respective interfaces
        bytes4[] memory erc1155MetadataFunctionSelectors = new bytes4[](1);

        erc1155MetadataFunctionSelectors[0] = IERC1155Metadata.uri.selector;

        ISolidStateDiamond.FacetCut
            memory erc1155MetadataFacetCut = IDiamondWritableInternal.FacetCut({
                target: facetAddress,
                action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                selectors: erc1155MetadataFunctionSelectors
            });

        // map the Pausable function selectors to their respective interfaces
        bytes4[] memory pausableFunctionSelectors = new bytes4[](1);

        pausableFunctionSelectors[0] = IPausable.paused.selector;

        ISolidStateDiamond.FacetCut
            memory pausableFacetCut = IDiamondWritableInternal.FacetCut({
                target: facetAddress,
                action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                selectors: pausableFunctionSelectors
            });

        // map the PerpetualMint related function selectors to their respective interfaces
        bytes4[] memory perpetualMintFunctionSelectors = new bytes4[](26);

        perpetualMintFunctionSelectors[0] = IPerpetualMint
            .attemptBatchMintWithEth
            .selector;

        perpetualMintFunctionSelectors[1] = IPerpetualMint
            .attemptBatchMintWithMint
            .selector;

        perpetualMintFunctionSelectors[2] = IPerpetualMint.burnReceipt.selector;

        perpetualMintFunctionSelectors[3] = IPerpetualMint.cancelClaim.selector;

        perpetualMintFunctionSelectors[4] = IPerpetualMint
            .claimMintEarnings
            .selector;

        perpetualMintFunctionSelectors[5] = IPerpetualMint.claimPrize.selector;

        perpetualMintFunctionSelectors[6] = IPerpetualMint
            .claimProtocolFees
            .selector;

        perpetualMintFunctionSelectors[7] = IPerpetualMint
            .fundConsolationFees
            .selector;

        perpetualMintFunctionSelectors[8] = IPerpetualMint.mintAirdrop.selector;

        perpetualMintFunctionSelectors[9] = IPerpetualMint.pause.selector;

        perpetualMintFunctionSelectors[10] = IPerpetualMint.redeem.selector;

        perpetualMintFunctionSelectors[11] = IPerpetualMint
            .setCollectionMintFeeDistributionRatioBP
            .selector;

        perpetualMintFunctionSelectors[12] = IPerpetualMint
            .setCollectionMintMultiplier
            .selector;

        perpetualMintFunctionSelectors[13] = IPerpetualMint
            .setCollectionMintPrice
            .selector;

        perpetualMintFunctionSelectors[14] = IPerpetualMint
            .setCollectionRisk
            .selector;

        perpetualMintFunctionSelectors[15] = IPerpetualMint
            .setEthToMintRatio
            .selector;

        perpetualMintFunctionSelectors[16] = IPerpetualMint
            .setMintFeeBP
            .selector;

        perpetualMintFunctionSelectors[17] = IPerpetualMint
            .setMintToken
            .selector;

        perpetualMintFunctionSelectors[18] = IPerpetualMint
            .setReceiptBaseURI
            .selector;

        perpetualMintFunctionSelectors[19] = IPerpetualMint
            .setReceiptTokenURI
            .selector;

        perpetualMintFunctionSelectors[20] = IPerpetualMint
            .setRedemptionFeeBP
            .selector;

        perpetualMintFunctionSelectors[21] = IPerpetualMint
            .setRedeemPaused
            .selector;

        perpetualMintFunctionSelectors[22] = IPerpetualMint.setTiers.selector;

        perpetualMintFunctionSelectors[23] = IPerpetualMint
            .setVRFConfig
            .selector;

        perpetualMintFunctionSelectors[24] = IPerpetualMint
            .setVRFSubscriptionBalanceThreshold
            .selector;

        perpetualMintFunctionSelectors[25] = IPerpetualMint.unpause.selector;

        ISolidStateDiamond.FacetCut
            memory perpetualMintFacetCut = IDiamondWritableInternal.FacetCut({
                target: facetAddress,
                action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                selectors: perpetualMintFunctionSelectors
            });

        // map the VRFConsumerBaseV2 function selectors to their respective interfaces
        bytes4[] memory vrfConsumerBaseV2FunctionSelectors = new bytes4[](1);

        vrfConsumerBaseV2FunctionSelectors[0] = VRFConsumerBaseV2
            .rawFulfillRandomWords
            .selector;

        ISolidStateDiamond.FacetCut
            memory vrfConsumerBaseV2FacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: facetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                    selectors: vrfConsumerBaseV2FunctionSelectors
                });

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](6);

        // omit Ownable since SolidStateDiamond includes those
        facetCuts[0] = erc1155MetadataFacetCut;
        facetCuts[1] = pausableFacetCut;
        facetCuts[2] = perpetualMintFacetCut;
        facetCuts[3] = vrfConsumerBaseV2FacetCut;

        return facetCuts;
    }
}
