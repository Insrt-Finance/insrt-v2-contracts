// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { ILayerZeroClientBaseInternal } from "@solidstate/layerzero-client/base/ILayerZeroClientBaseInternal.sol";

import { L1AssetHandlerTest } from "../AssetHandler.t.sol";
import { ILayerZeroClientBaseInternalEvents } from "../../../../interfaces/ILayerZeroClientBaseInternalEvents.sol";
import { PayloadEncoder } from "../../../../../contracts/libraries/PayloadEncoder.sol";
import { IAssetHandler } from "../../../../../contracts/interfaces/IAssetHandler.sol";
import { L1ForkTest } from "../../../../../test/L1ForkTest.t.sol";

/// @title L1AssetHandler_stakeERC721Assets
/// @dev L1AssetHandler test contract for testing expected L1 stakeERC721Assets behavior. Tested on a Mainnet fork.
contract L1AssetHandler_stakeERC721Assets is
    ILayerZeroClientBaseInternalEvents,
    L1AssetHandlerTest,
    L1ForkTest
{
    /// @dev LayerZero message fee.
    uint256 internal constant LAYER_ZERO_MESSAGE_FEE = 0.001 ether;

    /// @dev LayerZero message fee error message.
    bytes internal constant LAYER_ZERO_MESSAGE_FEE_REVERT =
        "LayerZero: not enough native for fees";

    /// @dev Sets up the test case environment.
    function setUp() public override {
        super.setUp();

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

    /// @dev Tests stakeERC721Assets functionality for staking ERC721 tokens.
    function test_stakeERC721Assets() public {
        l1AssetHandler.setLayerZeroEndpoint(MAINNET_LAYER_ZERO_ENDPOINT);
        l1AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        l1AssetHandler.stakeERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that stakeERC721Assets functionality emits an ERC721AssetsStaked event when staking ERC721 tokens.
    function test_stakeERC721AssetsEmitsERC721AssetsStakedEvent() public {
        l1AssetHandler.setLayerZeroEndpoint(MAINNET_LAYER_ZERO_ENDPOINT);
        l1AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectEmit();
        emit ERC721AssetsStaked(
            address(this),
            BORED_APE_YACHT_CLUB,
            boredApeYachtClubTokenIds
        );

        l1AssetHandler.stakeERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that stakeERC721Assets functionality emits a MessageSent event when staking ERC721 tokens.
    function test_stakeERC721AssetsEmitsMessageSent() public {
        l1AssetHandler.setLayerZeroEndpoint(MAINNET_LAYER_ZERO_ENDPOINT);
        l1AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectEmit();
        emit MessageSent(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            abi.encode(
                PayloadEncoder.AssetType.ERC721,
                address(this),
                BORED_APE_YACHT_CLUB,
                boredApeYachtClubTokenIds
            ),
            address(this),
            address(0),
            "",
            LAYER_ZERO_MESSAGE_FEE
        );

        l1AssetHandler.stakeERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that stakeERC721Assets functionality reverts when attempting to stake ERC721 tokens on an unsupported remote chain.
    function test_stakeERC721AssetsRevertsWhenAttemptingToStakeOnAnUnsupportedRemoteChain()
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

        l1AssetHandler.stakeERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID + 1, // unsupported remote chain
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that stakeERC721Assets functionality reverts when LayerZero endpoint is not set.
    function test_stakeERC721AssetsRevertsWhenLayerZeroEndpointIsNotSet()
        public
    {
        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        l1AssetHandler.stakeERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that stakeERC721Assets functionality reverts when LayerZero endpoint is set incorrectly.
    function test_stakeERC721AssetsRevertsWhenLayerZeroEndpointIsSetIncorrectly()
        public
    {
        l1AssetHandler.setLayerZeroEndpoint(address(this)); // incorrect endpoint

        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        l1AssetHandler.stakeERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that stakeERC721Assets functionality reverts when LayerZero message fee is not sent.
    function test_stakeERC721AssetsRevertsWhenLayerZeroMessageFeeIsNotSent()
        public
    {
        l1AssetHandler.setLayerZeroEndpoint(MAINNET_LAYER_ZERO_ENDPOINT);
        l1AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectRevert(LAYER_ZERO_MESSAGE_FEE_REVERT);

        l1AssetHandler.stakeERC721Assets( // message fee not sent
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that stakeERC721Assets functionality reverts when LayerZero message fee sent is insufficient.
    function test_stakeERC721AssetsRevertsWhenLayerZeroMessageFeeSentIsInsufficient()
        public
    {
        l1AssetHandler.setLayerZeroEndpoint(MAINNET_LAYER_ZERO_ENDPOINT);
        l1AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectRevert(LAYER_ZERO_MESSAGE_FEE_REVERT);

        l1AssetHandler.stakeERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE / 2 }( // insufficient message fee
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that stakeERC721Assets functionality reverts when LayerZero trusted remote address is not set.
    function test_stakeERC721AssetsRevertsWhenLayerZeroTrustedRemoteAddressIsNotSet()
        public
    {
        l1AssetHandler.setLayerZeroEndpoint(MAINNET_LAYER_ZERO_ENDPOINT);

        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        l1AssetHandler.stakeERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }
}
