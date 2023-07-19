// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { L1AssetHandlerTest } from "../AssetHandler.t.sol";
import { L1ForkTest } from "../../../../L1ForkTest.t.sol";
import { L1AssetHandlerMock } from "../../../../mocks/L1AssetHandlerMock.t.sol";
import { PayloadEncoder } from "../../../../../contracts/libraries/PayloadEncoder.sol";

/// @title L1AssetHandler_handleLayerZeroMessage
/// @dev L1AssetHandler test contract for testing expected L1 _handleLayerZeroMessage behavior. Tested on a Mainnet fork.
contract L1AssetHandler_handleLayerZeroMessage is
    L1AssetHandlerMock,
    L1AssetHandlerTest,
    L1ForkTest
{
    using stdStorage for StdStorage;

    /// @dev Dummy trusted remote test path.
    bytes internal TEST_PATH =
        bytes.concat(bytes20(vm.addr(1234)), bytes20(vm.addr(5678)));

    /// @dev Dummy test nonce value.
    uint64 internal constant TEST_NONCE = 0;

    /// @dev Tests _handleLayerZeroMessage functionality for withdrawing ERC1155 tokens.
    function test_handleLayerZeroMessageERC1155Withdrawal() public {
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

        bytes memory encodedData = abi.encode(
            PayloadEncoder.AssetType.ERC1155,
            msg.sender,
            BONG_BEARS,
            bongBearTokenIds,
            bongBearTokenAmounts
        );

        this.mock_HandleLayerZeroMessage(
            DESTINATION_LAYER_ZERO_CHAIN_ID, // would be the expected source chain ID in production, here this is a dummy value
            TEST_PATH, // would be the expected path in production, here this is a dummy value
            TEST_NONCE, // dummy nonce value
            encodedData
        );

        assert(
            bongBears.balanceOf(msg.sender, bongBearTokenIds[0]) ==
                bongBearTokenAmounts[0]
        );
    }

    /// @dev Tests that _handleLayerZeroMessage emits an ERC1155AssetsWithdrawn event when withdrawing ERC1155 tokens.
    function test_handleLayerZeroMessageERC1155WithdrawalEmitsERC1155AssetsWithdrawnEvent()
        public
    {
        stdstore
            .target(BONG_BEARS)
            .sig(bongBears.balanceOf.selector)
            .with_key(address(this))
            .with_key(bongBearTokenIds[0])
            .checked_write(1);

        bytes memory encodedData = abi.encode(
            PayloadEncoder.AssetType.ERC1155,
            msg.sender,
            BONG_BEARS,
            bongBearTokenIds,
            bongBearTokenAmounts
        );

        vm.expectEmit();
        emit ERC1155AssetsWithdrawn(
            msg.sender,
            BONG_BEARS,
            bongBearTokenIds,
            bongBearTokenAmounts
        );

        this.mock_HandleLayerZeroMessage(
            DESTINATION_LAYER_ZERO_CHAIN_ID, // would be the expected source chain ID in production, here this is a dummy value
            TEST_PATH, // would be the expected path in production, here this is a dummy value
            TEST_NONCE, // dummy nonce value
            encodedData
        );
    }

    /// @dev Tests _handleLayerZeroMessage functionality for withdrawing ERC721 tokens.
    function test_handleLayerZeroMessageERC721Withdrawal() public {
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

        bytes memory encodedData = abi.encode(
            PayloadEncoder.AssetType.ERC721,
            msg.sender,
            BORED_APE_YACHT_CLUB,
            boredApeYachtClubTokenIds
        );

        this.mock_HandleLayerZeroMessage(
            DESTINATION_LAYER_ZERO_CHAIN_ID, // would be the expected source chain ID in production, here this is a dummy value
            TEST_PATH, // would be the expected path in production, here this is a dummy value
            TEST_NONCE, // dummy nonce value
            encodedData
        );
    }

    /// @dev Tests that _handleLayerZeroMessage emits an ERC721AssetsWithdrawn event when withdrawing ERC721 tokens.
    function test_handleLayerZeroMessageERC721WithdrawalEmitsERC721AssetsWithdrawnEvent()
        public
    {
        address ownerToImpersonate = boredApeYachtClub.ownerOf(
            boredApeYachtClubTokenIds[0]
        );

        vm.prank(ownerToImpersonate);
        boredApeYachtClub.transferFrom(
            ownerToImpersonate,
            address(this),
            boredApeYachtClubTokenIds[0]
        );

        bytes memory encodedData = abi.encode(
            PayloadEncoder.AssetType.ERC721,
            msg.sender,
            BORED_APE_YACHT_CLUB,
            boredApeYachtClubTokenIds
        );

        vm.expectEmit();
        emit ERC721AssetsWithdrawn(
            msg.sender,
            BORED_APE_YACHT_CLUB,
            boredApeYachtClubTokenIds
        );

        this.mock_HandleLayerZeroMessage(
            DESTINATION_LAYER_ZERO_CHAIN_ID, // would be the expected source chain ID in production, here this is a dummy value
            TEST_PATH, // would be the expected path in production, here this is a dummy value
            TEST_NONCE, // dummy nonce value
            encodedData
        );
    }

    /// @dev Tests that _handleLayerZeroMessage reverts when an invalid asset type is received.
    function test_handleLayerZeroMessageRevertsWhenInvalidAssetTypeIsReceived()
        public
    {
        bytes memory encodedData = abi.encode(
            bytes32(uint256(2)), // invalid asset type
            msg.sender,
            BONG_BEARS,
            bongBearTokenIds,
            bongBearTokenAmounts
        );

        vm.expectRevert();

        this.mock_HandleLayerZeroMessage(
            DESTINATION_LAYER_ZERO_CHAIN_ID, // would be the expected source chain ID in production, here this is a dummy value
            TEST_PATH, // would be the expected path in production, here this is a dummy value
            TEST_NONCE, // dummy nonce value
            encodedData
        );
    }
}
