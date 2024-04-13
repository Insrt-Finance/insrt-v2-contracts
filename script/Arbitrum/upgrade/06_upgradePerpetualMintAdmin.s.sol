// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-safe/BatchScript.sol";

import { IDiamondWritable } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";

import { ICore } from "../../../contracts/diamonds/Core/ICore.sol";
import { IPerpetualMintAdmin } from "../../../contracts/facets/PerpetualMint/IPerpetualMintAdmin.sol";
import { PerpetualMintAdmin } from "../../../contracts/facets/PerpetualMint/PerpetualMintAdmin.sol";

/// @title UpgradePerpetualMintAdminArb
/// @dev Deploys a new PerpetualMintAdmin facet and signs and submits a diamondCut of the PerpetualMintAdmin facet to the Core diamond
/// via the Gnosis Safe Transaction Service API
contract UpgradePerpetualMintAdminArb is BatchScript {
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

        // deploy PerpetualMintAdmin facet
        PerpetualMintAdmin perpetualMintAdmin = new PerpetualMintAdmin(
            VRF_COORDINATOR
        );

        vm.stopBroadcast();

        console2.log(
            "New PerpetualMintAdmin Facet Address: ",
            address(perpetualMintAdmin)
        );
        console2.log("Core Address: ", core);
        console2.log("VRF Coordinator Address: ", VRF_COORDINATOR);

        // get new PerpetualMintAdmin facet cuts
        ICore.FacetCut[]
            memory newPerpetualMintAdminFacetCuts = getNewPerpetualMintAdminFacetCuts(
                address(perpetualMintAdmin)
            );

        // get replacement PerpetualMintAdmin facet cuts
        ICore.FacetCut[]
            memory replacementPerpetualMintAdminFacetCuts = getReplacementPerpetualMintAdminFacetCuts(
                address(perpetualMintAdmin)
            );

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](2);

        facetCuts[0] = newPerpetualMintAdminFacetCuts[0];
        facetCuts[1] = replacementPerpetualMintAdminFacetCuts[0];

        bytes memory diamondCutTx = abi.encodeWithSelector(
            IDiamondWritable.diamondCut.selector,
            facetCuts,
            address(0),
            ""
        );

        addToBatch(core, diamondCutTx);

        executeBatch(gnosisSafeAddress, true);
    }

    /// @dev provides the new facet cuts for cutting PerpetualMintAdmin facet into Core
    /// @param viewFacetAddress address of PerpetualMintAdmin facet
    function getNewPerpetualMintAdminFacetCuts(
        address viewFacetAddress
    ) internal pure returns (ICore.FacetCut[] memory) {
        // map the PerpetualMintAdmin related function selectors to their respective interfaces
        bytes4[] memory perpetualMintAdminFunctionSelectors = new bytes4[](2);

        perpetualMintAdminFunctionSelectors[0] = IPerpetualMintAdmin
            .setMintEarningsBufferBP
            .selector;

        perpetualMintAdminFunctionSelectors[1] = IPerpetualMintAdmin
            .setMintForEthConsolationFeeBP
            .selector;

        ICore.FacetCut
            memory perpetualMintAdminFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: viewFacetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintAdminFunctionSelectors
                });

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](1);

        facetCuts[0] = perpetualMintAdminFacetCut;

        return facetCuts;
    }

    /// @dev provides the replacement facet cuts for cutting PerpetualMintAdmin facet into Core
    /// @param viewFacetAddress address of PerpetualMintAdmin facet
    function getReplacementPerpetualMintAdminFacetCuts(
        address viewFacetAddress
    ) internal pure returns (ICore.FacetCut[] memory) {
        // map the PerpetualMintAdmin related function selectors to their respective interfaces
        bytes4[] memory perpetualMintAdminFunctionSelectors = new bytes4[](27);

        perpetualMintAdminFunctionSelectors[0] = IPerpetualMintAdmin
            .burnReceipt
            .selector;

        perpetualMintAdminFunctionSelectors[1] = IPerpetualMintAdmin
            .cancelClaim
            .selector;

        perpetualMintAdminFunctionSelectors[2] = bytes4(
            keccak256("claimMintEarnings()")
        );

        perpetualMintAdminFunctionSelectors[3] = bytes4(
            keccak256("claimMintEarnings(uint256)")
        );

        perpetualMintAdminFunctionSelectors[4] = IPerpetualMintAdmin
            .claimProtocolFees
            .selector;

        perpetualMintAdminFunctionSelectors[5] = IPerpetualMintAdmin
            .mintAirdrop
            .selector;

        perpetualMintAdminFunctionSelectors[6] = IPerpetualMintAdmin
            .pause
            .selector;

        perpetualMintAdminFunctionSelectors[7] = IPerpetualMintAdmin
            .setCollectionConsolationFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[8] = IPerpetualMintAdmin
            .setCollectionMintFeeDistributionRatioBP
            .selector;

        perpetualMintAdminFunctionSelectors[9] = IPerpetualMintAdmin
            .setCollectionMintMultiplier
            .selector;

        perpetualMintAdminFunctionSelectors[10] = IPerpetualMintAdmin
            .setCollectionMintPrice
            .selector;

        perpetualMintAdminFunctionSelectors[11] = IPerpetualMintAdmin
            .setCollectionReferralFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[12] = IPerpetualMintAdmin
            .setCollectionRisk
            .selector;

        perpetualMintAdminFunctionSelectors[13] = IPerpetualMintAdmin
            .setDefaultCollectionReferralFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[14] = IPerpetualMintAdmin
            .setEthToMintRatio
            .selector;

        perpetualMintAdminFunctionSelectors[15] = IPerpetualMintAdmin
            .setMintFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[16] = IPerpetualMintAdmin
            .setMintToken
            .selector;

        perpetualMintAdminFunctionSelectors[17] = IPerpetualMintAdmin
            .setMintTokenConsolationFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[18] = IPerpetualMintAdmin
            .setMintTokenTiers
            .selector;

        perpetualMintAdminFunctionSelectors[19] = IPerpetualMintAdmin
            .setReceiptBaseURI
            .selector;

        perpetualMintAdminFunctionSelectors[20] = IPerpetualMintAdmin
            .setReceiptTokenURI
            .selector;

        perpetualMintAdminFunctionSelectors[21] = IPerpetualMintAdmin
            .setRedemptionFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[22] = IPerpetualMintAdmin
            .setRedeemPaused
            .selector;

        perpetualMintAdminFunctionSelectors[23] = IPerpetualMintAdmin
            .setTiers
            .selector;

        perpetualMintAdminFunctionSelectors[24] = IPerpetualMintAdmin
            .setVRFConfig
            .selector;

        perpetualMintAdminFunctionSelectors[25] = IPerpetualMintAdmin
            .setVRFSubscriptionBalanceThreshold
            .selector;

        perpetualMintAdminFunctionSelectors[26] = IPerpetualMintAdmin
            .unpause
            .selector;

        ICore.FacetCut
            memory perpetualMintAdminFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: viewFacetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.REPLACE,
                    selectors: perpetualMintAdminFunctionSelectors
                });

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](1);

        facetCuts[0] = perpetualMintAdminFacetCut;

        return facetCuts;
    }
}
