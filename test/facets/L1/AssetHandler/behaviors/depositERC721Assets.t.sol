// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { ILayerZeroClientBaseInternal } from "@solidstate/layerzero-client/base/ILayerZeroClientBaseInternal.sol";
import { ILayerZeroEndpoint } from "@solidstate/layerzero-client/interfaces/ILayerZeroEndpoint.sol";

import { L1AssetHandlerTest } from "../AssetHandler.t.sol";
import { ILayerZeroClientBaseInternalEvents } from "../../../../interfaces/ILayerZeroClientBaseInternalEvents.sol";
import { L1ForkTest } from "../../../../L1ForkTest.t.sol";
import { IAssetHandler } from "../../../../../contracts/interfaces/IAssetHandler.sol";
import { PayloadEncoder } from "../../../../../contracts/libraries/PayloadEncoder.sol";

/// @title L1AssetHandler_depositERC721Assets
/// @dev L1AssetHandler test contract for testing expected L1 depositERC721Assets behavior. Tested on a Mainnet fork.
contract L1AssetHandler_depositERC721Assets is
    ILayerZeroClientBaseInternalEvents,
    L1AssetHandlerTest,
    L1ForkTest
{
    /// @dev LayerZero message fee error message.
    bytes internal constant LAYER_ZERO_MESSAGE_FEE_REVERT =
        "LayerZero: not enough native for fees";

    /// @dev Test ERC721 deposit payload.
    bytes internal TEST_ERC721_DEPOSIT_PAYLOAD;

    /// @dev Sets up the test case environment.
    function setUp() public override {
        super.setUp();

        TEST_ERC721_DEPOSIT_PAYLOAD = abi.encode(
            PayloadEncoder.AssetType.ERC721,
            address(this),
            BORED_APE_YACHT_CLUB,
            testRisks,
            boredApeYachtClubTokenIds
        );

        (LAYER_ZERO_MESSAGE_FEE, ) = ILayerZeroEndpoint(
            MAINNET_LAYER_ZERO_ENDPOINT
        ).estimateFees(
                DESTINATION_LAYER_ZERO_CHAIN_ID,
                address(l1AssetHandler),
                TEST_ERC721_DEPOSIT_PAYLOAD,
                false,
                ""
            );

        address ownerToImpersonate = boredApeYachtClub.ownerOf(
            boredApeYachtClubTokenIds[0]
        );

        vm.prank(ownerToImpersonate);
        boredApeYachtClub.transferFrom(
            ownerToImpersonate,
            address(this),
            boredApeYachtClubTokenIds[0]
        );

        assert(
            boredApeYachtClub.ownerOf(boredApeYachtClubTokenIds[0]) ==
                address(this)
        );

        boredApeYachtClub.setApprovalForAll(address(l1AssetHandler), true);
    }

    /// @dev Tests depositERC721Assets functionality for depositing ERC721 tokens.
    function test_depositERC721Assets() public {
        l1AssetHandler.setLayerZeroEndpoint(MAINNET_LAYER_ZERO_ENDPOINT);
        l1AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        l1AssetHandler.depositERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            testRisks,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that depositERC721Assets functionality emits an ERC721AssetsDeposited event when depositing ERC721 tokens.
    function test_depositERC721AssetsEmitsERC721AssetsDepositedEvent() public {
        l1AssetHandler.setLayerZeroEndpoint(MAINNET_LAYER_ZERO_ENDPOINT);
        l1AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectEmit();
        emit ERC721AssetsDeposited(
            address(this),
            BORED_APE_YACHT_CLUB,
            testRisks,
            boredApeYachtClubTokenIds
        );

        l1AssetHandler.depositERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            testRisks,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that depositERC721Assets functionality emits a MessageSent event when depositing ERC721 tokens.
    function test_depositERC721AssetsEmitsMessageSent() public {
        l1AssetHandler.setLayerZeroEndpoint(MAINNET_LAYER_ZERO_ENDPOINT);
        l1AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectEmit();
        emit MessageSent(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TEST_ERC721_DEPOSIT_PAYLOAD,
            address(this),
            address(0),
            "",
            LAYER_ZERO_MESSAGE_FEE
        );

        l1AssetHandler.depositERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            testRisks,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that depositERC721Assets functionality reverts when attempting to deposit ERC721 tokens on an unsupported remote chain.
    function test_depositERC721AssetsRevertsWhenAttemptingToDepositOnAnUnsupportedRemoteChain()
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

        l1AssetHandler.depositERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID + 1, // unsupported remote chain
            testRisks,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that depositERC721Assets functionality reverts when LayerZero endpoint is not set.
    function test_depositERC721AssetsRevertsWhenLayerZeroEndpointIsNotSet()
        public
    {
        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        l1AssetHandler.depositERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            testRisks,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that depositERC721Assets functionality reverts when LayerZero endpoint is set incorrectly.
    function test_depositERC721AssetsRevertsWhenLayerZeroEndpointIsSetIncorrectly()
        public
    {
        l1AssetHandler.setLayerZeroEndpoint(address(this)); // incorrect endpoint

        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        l1AssetHandler.depositERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            testRisks,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that depositERC721Assets functionality reverts when LayerZero message fee is not sent.
    function test_depositERC721AssetsRevertsWhenLayerZeroMessageFeeIsNotSent()
        public
    {
        l1AssetHandler.setLayerZeroEndpoint(MAINNET_LAYER_ZERO_ENDPOINT);
        l1AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectRevert(LAYER_ZERO_MESSAGE_FEE_REVERT);

        l1AssetHandler.depositERC721Assets( // message fee not sent
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            testRisks,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that depositERC721Assets functionality reverts when LayerZero message fee sent is insufficient.
    function test_depositERC721AssetsRevertsWhenLayerZeroMessageFeeSentIsInsufficient()
        public
    {
        l1AssetHandler.setLayerZeroEndpoint(MAINNET_LAYER_ZERO_ENDPOINT);
        l1AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectRevert(LAYER_ZERO_MESSAGE_FEE_REVERT);

        l1AssetHandler.depositERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE / 3 }( // insufficient message fee
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            testRisks,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that depositERC721Assets functionality reverts when LayerZero trusted remote address is not set.
    function test_depositERC721AssetsRevertsWhenLayerZeroTrustedRemoteAddressIsNotSet()
        public
    {
        l1AssetHandler.setLayerZeroEndpoint(MAINNET_LAYER_ZERO_ENDPOINT);

        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        l1AssetHandler.depositERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            testRisks,
            boredApeYachtClubTokenIds
        );
    }
}
