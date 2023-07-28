// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";

/// @title PerpetualMint_setVRFConfig
/// @dev PerpetualMint test contract for testing expected behavior of the setVRFConfig function
contract PerpetualMint_setVRFConfig is
    PerpetualMintTest,
    L2ForkTest,
    IPerpetualMintInternal
{
    address nonOwner = address(5);
    uint256 newPrice = 0.6 ether;
    Storage.VRFConfig NEW_CONFIG =
        Storage.VRFConfig({
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
    function test_setVRFConfig() public {
        perpetualMint.setVRFConfig(NEW_CONFIG);

        Storage.VRFConfig memory readConfig = _vrfConfig(
            address(perpetualMint)
        );

        assert(NEW_CONFIG.keyHash == readConfig.keyHash);
        assert(NEW_CONFIG.subscriptionId == readConfig.subscriptionId);
        assert(NEW_CONFIG.callbackGasLimit == readConfig.callbackGasLimit);
        assert(NEW_CONFIG.minConfirmations == readConfig.minConfirmations);
    }

    /// @dev tests for the VRFConfigSet event emission after a new VRFConfig is set
    function test_setVRFConfigEmitsVRFConfigSetEvent() public {
        vm.expectEmit();
        emit VRFConfigSet(NEW_CONFIG);
        perpetualMint.setVRFConfig(NEW_CONFIG);
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setVRFConfigRevertsWhen_CallerIsNotOwner() public {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);
        vm.prank(nonOwner);
        perpetualMint.setVRFConfig(NEW_CONFIG);
    }
}
