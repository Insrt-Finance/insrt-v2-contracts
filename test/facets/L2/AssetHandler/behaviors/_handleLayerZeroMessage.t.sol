// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { L2AssetHandlerTest } from "../AssetHandler.t.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { L2AssetHandlerMock } from "../../../../mocks/L2AssetHandlerMock.t.sol";
import { L2AssetHandlerStorage } from "../../../../../contracts/facets/L2/AssetHandler/Storage.sol";
import { PayloadEncoder } from "../../../../../contracts/libraries/PayloadEncoder.sol";

/// @title L2AssetHandler_handleLayerZeroMessage
/// @dev L2AssetHandler test contract for testing expected L2 _handleLayerZeroMessage behavior. Tested on a Mainnet fork.
contract L2AssetHandler_handleLayerZeroMessage is
    L2AssetHandlerMock,
    L2AssetHandlerTest,
    L2ForkTest
{
    /// @dev Dummy trusted remote test path.
    bytes internal TEST_PATH =
        bytes.concat(bytes20(vm.addr(1234)), bytes20(vm.addr(5678)));

    /// @dev Dummy test nonce value.
    uint64 internal constant TEST_NONCE = 0;

    /// @dev Tests _handleLayerZeroMessage functionality for staking ERC1155 tokens.
    function test_handleLayerZeroMessageERC1155Staking() public {
        bytes memory encodedData = abi.encode(
            PayloadEncoder.AssetType.ERC1155,
            msg.sender,
            BONG_BEARS,
            bongBearTokenIds,
            bongBearTokenAmounts
        );

        L2AssetHandlerMock(address(this)).mock_HandleLayerZeroMessage(
            DESTINATION_LAYER_ZERO_CHAIN_ID, // would be the expected source chain ID in production, here this is a dummy value
            TEST_PATH, // would be the expected path in production, here this is a dummy value
            TEST_NONCE, // dummy nonce value
            encodedData
        );

        // the staked ERC1155 token amount is stored in a mapping, so we need to compute the storage slot
        bytes32 stakedERC1155TokenAmountStorageSlot = keccak256(
            abi.encode(
                bongBearTokenIds[0], // the staked ERC1155 token ID
                keccak256(
                    abi.encode(
                        BONG_BEARS, // the staked ERC1155 token collection
                        keccak256(
                            abi.encode(
                                msg.sender, // the staker
                                L2AssetHandlerStorage.STORAGE_SLOT
                            )
                        )
                    )
                )
            )
        );

        uint256 stakedERC1155TokenAmount = uint256(
            vm.load(address(this), stakedERC1155TokenAmountStorageSlot)
        );

        // mappings are hash tables, so this assertion proves that the staked ERC1155 token amount was
        // set correctly for the staker, collection, and the given token ID.
        assertEq(stakedERC1155TokenAmount, bongBearTokenAmounts[0]);
    }

    /// @dev Tests that _handleLayerZeroMessage emits an ERC1155AssetsStaked event when staking ERC1155 tokens.
    function test_handleLayerZeroMessageERC1155StakingEmitsERC1155AssetsStakedEvent()
        public
    {
        bytes memory encodedData = abi.encode(
            PayloadEncoder.AssetType.ERC1155,
            msg.sender,
            BONG_BEARS,
            bongBearTokenIds,
            bongBearTokenAmounts
        );

        vm.expectEmit();
        emit ERC1155AssetsStaked(
            msg.sender,
            BONG_BEARS,
            bongBearTokenIds,
            bongBearTokenAmounts
        );

        L2AssetHandlerMock(address(this)).mock_HandleLayerZeroMessage(
            DESTINATION_LAYER_ZERO_CHAIN_ID, // would be the expected source chain ID in production, here this is a dummy value
            TEST_PATH, // would be the expected path in production, here this is a dummy value
            TEST_NONCE, // dummy nonce value
            encodedData
        );
    }

    /// @dev Tests _handleLayerZeroMessage functionality for staking ERC721 tokens.
    function test_handleLayerZeroMessageERC721Staking() public {
        bytes memory encodedData = abi.encode(
            PayloadEncoder.AssetType.ERC721,
            msg.sender,
            BORED_APE_YACHT_CLUB,
            boredApeYachtClubTokenIds
        );

        // record the storage slot of the staked ERC721 token ID
        vm.record();

        L2AssetHandlerMock(address(this)).mock_HandleLayerZeroMessage(
            DESTINATION_LAYER_ZERO_CHAIN_ID, // would be the expected source chain ID in production, here this is a dummy value
            TEST_PATH, // would be the expected path in production, here this is a dummy value
            TEST_NONCE, // dummy nonce value
            encodedData
        );

        // access the storage slot of the staked ERC721 token ID via storageWrites
        (, bytes32[] memory storageWrites) = vm.accesses(address(this));

        uint256 stakedERC721TokenId = uint256(
            vm.load(address(this), storageWrites[0])
        );

        assertEq(stakedERC721TokenId, boredApeYachtClubTokenIds[0]);
    }

    /// @dev Tests that _handleLayerZeroMessage emits an ERC721AssetsStaked event when staking ERC721 tokens.
    function test_handleLayerZeroMessageERC721StakingEmitsERC721AssetsStakedEvent()
        public
    {
        bytes memory encodedData = abi.encode(
            PayloadEncoder.AssetType.ERC721,
            msg.sender,
            BORED_APE_YACHT_CLUB,
            boredApeYachtClubTokenIds
        );

        vm.expectEmit();
        emit ERC721AssetsStaked(
            msg.sender,
            BORED_APE_YACHT_CLUB,
            boredApeYachtClubTokenIds
        );

        L2AssetHandlerMock(address(this)).mock_HandleLayerZeroMessage(
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

        L2AssetHandlerMock(address(this)).mock_HandleLayerZeroMessage(
            DESTINATION_LAYER_ZERO_CHAIN_ID, // would be the expected source chain ID in production, here this is a dummy value
            TEST_PATH, // would be the expected path in production, here this is a dummy value
            TEST_NONCE, // dummy nonce value
            encodedData
        );
    }
}
