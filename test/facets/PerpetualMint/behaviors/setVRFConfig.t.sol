// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";
import { VRFConfig } from "../../../../contracts/facets/PerpetualMint/Storage.sol";

/// @title PerpetualMint_setVRFConfig
/// @dev PerpetualMint test contract for testing expected behavior of the setVRFConfig function
contract PerpetualMint_setVRFConfig is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    VRFConfig NEW_CONFIG =
        VRFConfig({
            // Arbitrum 150 GWEI keyhash
            keyHash: bytes32("test"),
            // Initiated Subscription ID
            subscriptionId: uint64(100),
            // Max Callback Gas Limit
            callbackGasLimit: uint32(110),
            // Minimum confimations:
            minConfirmations: uint16(120)
        });

    /// @dev tests the setting of a new VRF Config
    function test_setVRFConfig() external {
        perpetualMint.setVRFConfig(NEW_CONFIG);

        VRFConfig memory vrfConfig = perpetualMint.vrfConfig();

        assert(NEW_CONFIG.keyHash == vrfConfig.keyHash);
        assert(NEW_CONFIG.subscriptionId == vrfConfig.subscriptionId);
        assert(NEW_CONFIG.callbackGasLimit == vrfConfig.callbackGasLimit);
        assert(NEW_CONFIG.minConfirmations == vrfConfig.minConfirmations);
    }

    /// @dev tests for the VRFConfigSet event emission after a new VRFConfig is set
    function test_setVRFConfigEmitsVRFConfigSetEvent() external {
        vm.expectEmit();
        emit VRFConfigSet(NEW_CONFIG);

        perpetualMint.setVRFConfig(NEW_CONFIG);
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setVRFConfigRevertsWhen_CallerIsNotOwner() external {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);
        vm.prank(PERPETUAL_MINT_NON_OWNER);

        perpetualMint.setVRFConfig(NEW_CONFIG);
    }
}
