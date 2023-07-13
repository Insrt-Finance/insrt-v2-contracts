// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import "forge-std/Test.sol";

import { ILayerZeroClientBaseInternal } from "@solidstate/layerzero-client/base/ILayerZeroClientBaseInternal.sol";

import { L1AssetHandlerTest } from "../AssetHandler.t.sol";
import { L1ForkTest } from "../../../../L1ForkTest.t.sol";
import { ILayerZeroClientBaseInternalEvents } from "../../../../interfaces/ILayerZeroClientBaseInternalEvents.sol";
import { PayloadEncoder } from "../../../../../contracts/libraries/PayloadEncoder.sol";
import { IAssetHandler } from "../../../../../contracts/interfaces/IAssetHandler.sol";

/// @title L1AssetHandler_depositERC1155Assets
/// @dev L1AssetHandler test contract for testing expected L1 depositERC1155Assets behavior. Tested on a Mainnet fork.
contract L1AssetHandler_depositERC1155Assets is
    ILayerZeroClientBaseInternalEvents,
    L1AssetHandlerTest,
    L1ForkTest
{
    using stdStorage for StdStorage;

    /// @dev LayerZero message fee error message.
    bytes internal constant LAYER_ZERO_MESSAGE_FEE_REVERT =
        "LayerZero: not enough native for fees";

    /// @dev Sets up the test case environment.
    function setUp() public override {
        super.setUp();

        stdstore
            .target(BONG_BEARS)
            .sig(bongBears.balanceOf.selector)
            .with_key(address(this))
            .with_key(bongBearTokenIds[0])
            .checked_write(bongBearTokenAmounts[0]);

        assert(
            bongBears.balanceOf(address(this), bongBearTokenIds[0]) ==
                bongBearTokenAmounts[0]
        );

        bongBears.setApprovalForAll(address(l1AssetHandler), true);
    }

    /// @dev Tests depositERC1155Assets functionality for depositing ERC1155 tokens.
    function test_depositERC1155Assets() public {
        l1AssetHandler.setLayerZeroEndpoint(MAINNET_LAYER_ZERO_ENDPOINT);
        l1AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        l1AssetHandler.depositERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            RISK,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that depositERC1155Assets functionality emits an ERC1155AssetsDeposited event when depositing ERC1155 tokens.
    function test_depositERC1155AssetsEmitsERC1155AssetsDepositedEvent()
        public
    {
        l1AssetHandler.setLayerZeroEndpoint(MAINNET_LAYER_ZERO_ENDPOINT);
        l1AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectEmit();
        emit ERC1155AssetsDeposited(
            address(this),
            BONG_BEARS,
            RISK,
            bongBearTokenIds,
            bongBearTokenAmounts
        );

        l1AssetHandler.depositERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            RISK,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that depositERC1155Assets functionality emits a MessageSent event when depositing ERC1155 tokens.
    function test_depositERC1155AssetsEmitsMessageSent() public {
        l1AssetHandler.setLayerZeroEndpoint(MAINNET_LAYER_ZERO_ENDPOINT);
        l1AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectEmit();
        emit MessageSent(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            abi.encode(
                PayloadEncoder.AssetType.ERC1155,
                address(this),
                BONG_BEARS,
                RISK,
                bongBearTokenIds,
                bongBearTokenAmounts
            ),
            address(this),
            address(0),
            "",
            LAYER_ZERO_MESSAGE_FEE
        );

        l1AssetHandler.depositERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            RISK,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that depositERC1155Assets functionality reverts when attempting to deposit ERC1155 tokens on an unsupported remote chain.
    function test_depositERC1155AssetsRevertsWhenAttemptingToDepositOnAnUnsupportedRemoteChain()
        public
    {
        l1AssetHandler.setLayerZeroEndpoint(MAINNET_LAYER_ZERO_ENDPOINT);
        l1AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        l1AssetHandler.depositERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID + 1, // unsupported remote chain
            RISK,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that depositERC1155Assets functionality reverts when LayerZero endpoint is not set.
    function test_depositERC1155AssetsRevertsWhenLayerZeroEndpointIsNotSet()
        public
    {
        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        l1AssetHandler.depositERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            RISK,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that depositERC1155Assets functionality reverts when LayerZero endpoint is set incorrectly.
    function test_depositERC1155AssetsRevertsWhenLayerZeroEndpointIsSetIncorrectly()
        public
    {
        l1AssetHandler.setLayerZeroEndpoint(address(this)); // incorrect endpoint

        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        l1AssetHandler.depositERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            RISK,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that depositERC1155Assets functionality reverts when LayerZero message fee is not sent.
    function test_depositERC1155AssetsRevertsWhenLayerZeroMessageFeeIsNotSent()
        public
    {
        l1AssetHandler.setLayerZeroEndpoint(MAINNET_LAYER_ZERO_ENDPOINT);
        l1AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectRevert(LAYER_ZERO_MESSAGE_FEE_REVERT);

        l1AssetHandler.depositERC1155Assets( // message fee not sent
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            RISK,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that depositERC1155Assets functionality reverts when LayerZero message fee sent is insufficient.
    function test_depositERC1155AssetsRevertsWhenLayerZeroMessageFeeSentIsInsufficient()
        public
    {
        l1AssetHandler.setLayerZeroEndpoint(MAINNET_LAYER_ZERO_ENDPOINT);
        l1AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectRevert(LAYER_ZERO_MESSAGE_FEE_REVERT);

        l1AssetHandler.depositERC1155Assets{
            value: LAYER_ZERO_MESSAGE_FEE / 3
        }( // insufficient message fee
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            RISK,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that depositERC1155Assets functionality reverts when LayerZero trusted remote address is not set.
    function test_depositERC1155AssetsRevertsWhenLayerZeroTrustedRemoteAddressIsNotSet()
        public
    {
        l1AssetHandler.setLayerZeroEndpoint(MAINNET_LAYER_ZERO_ENDPOINT);

        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        l1AssetHandler.depositERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            RISK,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that depositERC1155Assets functionality reverts when tokenIds and amounts length mismatch.
    function test_depositERC1155AssetsRevertsWhenTokenIdsAndAmountsLengthMismatch()
        public
    {
        vm.expectRevert(
            IAssetHandler.ERC1155TokenIdsAndAmountsLengthMismatch.selector
        );

        bongBearTokenAmounts.push(uint256(1)); // mismatched lengths

        l1AssetHandler.depositERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            RISK,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }
}
