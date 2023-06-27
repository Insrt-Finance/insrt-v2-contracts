// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { ILayerZeroClientBaseInternal } from "@solidstate/layerzero-client/base/ILayerZeroClientBaseInternal.sol";

import { L2AssetHandlerTest } from "../AssetHandler.t.sol";

/// @title L2AssetHandler_setLayerZeroTrustedRemoteAddress
/// @dev L2AssetHandler test contract for testing expected setLayerZeroTrustedRemoteAddress behavior.
contract L2AssetHandler_setLayerZeroTrustedRemoteAddress is L2AssetHandlerTest {
    /// @dev Tests that getLayerZeroTrustedRemoteAddress reverts when querying chain IDs without a set trusted remote address.
    /// @notice Since we test expected normal getLayerZeroTrustedRemoteAddress behavior in the setLayerZeroTrustedRemoteAddress behavior test,
    /// we only need to test that getLayerZeroTrustedRemoteAddress reverts when querying chain IDs without a set trusted remote address.
    function test_getLayerZeroTrustedRemoteAddressRevertsWhenQueryingChainIdsWithoutATrustedRemoteAddress()
        public
    {
        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        l2AssetHandler.getLayerZeroTrustedRemoteAddress(69);
    }
}
