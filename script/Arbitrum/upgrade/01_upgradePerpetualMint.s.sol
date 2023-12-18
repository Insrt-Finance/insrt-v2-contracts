// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-safe/BatchScript.sol";

import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";
import { IDiamondWritable } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IPausable } from "@solidstate/contracts/security/pausable/IPausable.sol";
import { IERC1155Metadata } from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";

import { IPerpetualMint } from "../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";
import { PerpetualMint } from "../../../contracts/facets/PerpetualMint/PerpetualMint.sol";

/// @title UpgradePerpetualMintArb
/// @dev Deploys a new PerpetualMint facet and signs and submits a diamondCut of the PerpetualMint facet to the Core diamond
/// via the Gnosis Safe Transaction Service API
contract UpgradePerpetualMintArb is BatchScript {
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

        // deploy new PerpetualMint facet
        PerpetualMint perpetualMint = new PerpetualMint(VRF_COORDINATOR);

        vm.stopBroadcast();

        console2.log(
            "New PerpetualMint Facet Address: ",
            address(perpetualMint)
        );
        console2.log("Core Address: ", core);
        console2.log("VRF Coordinator Address: ", VRF_COORDINATOR);

        // get new PerpetualMint facet cuts
        ISolidStateDiamond.FacetCut[]
            memory newPerpetualMintFacetCuts = getNewPerpetualMintFacetCuts(
                address(perpetualMint)
            );

        // get replacement PerpetualMint facet cuts
        ISolidStateDiamond.FacetCut[]
            memory replacementPerpetualMintFacetCuts = getReplacementPerpetualMintFacetCuts(
                address(perpetualMint)
            );

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](5);

        facetCuts[0] = newPerpetualMintFacetCuts[0];
        facetCuts[1] = replacementPerpetualMintFacetCuts[0];
        facetCuts[2] = replacementPerpetualMintFacetCuts[1];
        facetCuts[3] = replacementPerpetualMintFacetCuts[2];
        facetCuts[4] = replacementPerpetualMintFacetCuts[3];

        bytes memory diamondCutTx = abi.encodeWithSelector(
            IDiamondWritable.diamondCut.selector,
            facetCuts,
            address(0),
            ""
        );

        addToBatch(core, diamondCutTx);

        executeBatch(gnosisSafeAddress, true);
    }

    /// @dev provides the new facet cuts for cutting PerpetualMint facet into Core
    /// @param facetAddress address of PerpetualMint facet
    function getNewPerpetualMintFacetCuts(
        address facetAddress
    ) internal pure returns (ISolidStateDiamond.FacetCut[] memory) {
        // map the PerpetualMint related function selectors to their respective interfaces
        bytes4[] memory perpetualMintFunctionSelectors = new bytes4[](2);

        perpetualMintFunctionSelectors[0] = IPerpetualMint
            .setCollectionReferralFeeBP
            .selector;

        perpetualMintFunctionSelectors[1] = IPerpetualMint
            .setDefaultCollectionReferralFeeBP
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
        bytes4[] memory perpetualMintFunctionSelectors = new bytes4[](31);

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

        perpetualMintFunctionSelectors[4] = IPerpetualMint.burnReceipt.selector;

        perpetualMintFunctionSelectors[5] = IPerpetualMint.cancelClaim.selector;

        perpetualMintFunctionSelectors[6] = IPerpetualMint
            .claimMintEarnings
            .selector;

        perpetualMintFunctionSelectors[7] = IPerpetualMint.claimPrize.selector;

        perpetualMintFunctionSelectors[8] = IPerpetualMint
            .claimProtocolFees
            .selector;

        perpetualMintFunctionSelectors[9] = IPerpetualMint
            .fundConsolationFees
            .selector;

        perpetualMintFunctionSelectors[10] = IPerpetualMint
            .mintAirdrop
            .selector;

        perpetualMintFunctionSelectors[11] = IPerpetualMint.pause.selector;

        perpetualMintFunctionSelectors[12] = IPerpetualMint.redeem.selector;

        perpetualMintFunctionSelectors[13] = IPerpetualMint
            .setCollectionConsolationFeeBP
            .selector;

        perpetualMintFunctionSelectors[14] = IPerpetualMint
            .setCollectionMintFeeDistributionRatioBP
            .selector;

        perpetualMintFunctionSelectors[15] = IPerpetualMint
            .setCollectionMintMultiplier
            .selector;

        perpetualMintFunctionSelectors[16] = IPerpetualMint
            .setCollectionMintPrice
            .selector;

        perpetualMintFunctionSelectors[17] = IPerpetualMint
            .setCollectionRisk
            .selector;

        perpetualMintFunctionSelectors[18] = IPerpetualMint
            .setEthToMintRatio
            .selector;

        perpetualMintFunctionSelectors[19] = IPerpetualMint
            .setMintFeeBP
            .selector;

        perpetualMintFunctionSelectors[20] = IPerpetualMint
            .setMintToken
            .selector;

        perpetualMintFunctionSelectors[21] = IPerpetualMint
            .setMintTokenConsolationFeeBP
            .selector;

        perpetualMintFunctionSelectors[22] = IPerpetualMint
            .setMintTokenTiers
            .selector;

        perpetualMintFunctionSelectors[23] = IPerpetualMint
            .setReceiptBaseURI
            .selector;

        perpetualMintFunctionSelectors[24] = IPerpetualMint
            .setReceiptTokenURI
            .selector;

        perpetualMintFunctionSelectors[25] = IPerpetualMint
            .setRedemptionFeeBP
            .selector;

        perpetualMintFunctionSelectors[26] = IPerpetualMint
            .setRedeemPaused
            .selector;

        perpetualMintFunctionSelectors[27] = IPerpetualMint.setTiers.selector;

        perpetualMintFunctionSelectors[28] = IPerpetualMint
            .setVRFConfig
            .selector;

        perpetualMintFunctionSelectors[29] = IPerpetualMint
            .setVRFSubscriptionBalanceThreshold
            .selector;

        perpetualMintFunctionSelectors[30] = IPerpetualMint.unpause.selector;

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
