// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-safe/BatchScript.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";
import { IDiamondWritable } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";

import { ICore } from "../../../contracts/diamonds/Core/ICore.sol";
import { IPerpetualMintEmergencyWithdraw } from "../../../contracts/facets/PerpetualMint/IPerpetualMintEmergencyWithdraw.sol";
import { PerpetualMintEmergencyWithdraw } from "../../../contracts/facets/PerpetualMint/PerpetualMintEmergencyWithdraw.sol";

/// @title DeployPerpetualMint_EmergencyWithdraw
/// @dev deploys the PerpetualMintEmergencyWithdraw facet
contract DeployPerpetualMint_EmergecnyWithdraw is BatchScript {
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

        // deploy new PerpetualMintEmergencyWithdraw facet
        PerpetualMintEmergencyWithdraw perpetualMintEmergencyWithdraw = new PerpetualMintEmergencyWithdraw(
                VRF_ROUTER
            );

        vm.stopBroadcast();

        console2.log(
            "New PerpetualMintEmergencyWithdraw Facet Address: ",
            address(perpetualMintEmergencyWithdraw)
        );
        console2.log("CoreBlast Address: ", core);
        console2.log("VRF Router Address: ", VRF_ROUTER);

        // get new PerpetualMintEmergencyWithdraw facet cuts
        ICore.FacetCut[]
            memory perpetualMintWithdrawFacetCuts = getPerpetualMintEmergencyWithdrawFacetCuts(
                address(perpetualMintEmergencyWithdraw)
            );

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](1);

        facetCuts[0] = perpetualMintWithdrawFacetCuts[0];

        bytes memory diamondCutTx = abi.encodeWithSelector(
            IDiamondWritable.diamondCut.selector,
            facetCuts,
            address(0),
            ""
        );

        addToBatch(core, diamondCutTx);

        executeBatch(gnosisSafeAddress, true);
    }

    function getPerpetualMintEmergencyWithdrawFacetCuts(
        address facet
    ) internal view returns (ICore.FacetCut[] memory facetCuts) {
        facetCuts = new ICore.FacetCut[](1);

        ICore.FacetCut
            memory perpetualMintEmergencyWithdrawFacetCut = _createFacetCut(
                facet,
                IDiamondWritableInternal.FacetCutAction.ADD,
                _getPerpetualMintEmegencyWithdrawSelectors()
            );

        facetCuts[0] = perpetualMintEmergencyWithdrawFacetCut;
    }

    function _getPerpetualMintEmegencyWithdrawSelectors()
        private
        pure
        returns (bytes4[] memory selectors)
    {
        selectors = new bytes4[](1);

        selectors[0] = IPerpetualMintEmergencyWithdraw
            .withdrawAllFunds
            .selector;
    }

    function _createFacetCut(
        address target,
        IDiamondWritableInternal.FacetCutAction action,
        bytes4[] memory selectors
    ) private pure returns (ICore.FacetCut memory) {
        return
            IDiamondWritableInternal.FacetCut({
                target: target,
                action: action,
                selectors: selectors
            });
    }
}
