// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import "forge-std/Test.sol";

import { ILayerZeroClientBaseInternal } from "@solidstate/layerzero-client/base/ILayerZeroClientBaseInternal.sol";

import { L2AssetHandlerTest } from "../AssetHandler.t.sol";
import { ILayerZeroClientBaseInternalEvents } from "../../../../interfaces/ILayerZeroClientBaseInternalEvents.sol";
import { L2AssetHandlerStorage } from "../../../../../contracts/facets/L2/AssetHandler/Storage.sol";
import { IL2AssetHandler } from "../../../../../contracts/facets/L2/AssetHandler/IAssetHandler.sol";
import { IAssetHandler } from "../../../../../contracts/interfaces/IAssetHandler.sol";
import { PayloadEncoder } from "../../../../../contracts/libraries/PayloadEncoder.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";

/// @title L2AssetHandler_unstakeERC1155Assets
/// @dev L2AssetHandler test contract for testing expected L2 unstakeERC1155Assets behavior. Tested on an Arbitrum fork.
contract L2AssetHandler_unstakeERC1155Assets is
    ILayerZeroClientBaseInternalEvents,
    L2AssetHandlerTest,
    L2ForkTest
{
    /// @dev LayerZero message fee.
    uint256 internal constant LAYER_ZERO_MESSAGE_FEE = 0.02 ether; // Arbitrum ETH

    /// @dev LayerZero message fee error message.
    bytes internal constant LAYER_ZERO_MESSAGE_FEE_REVERT =
        "LayerZero: not enough native for fees";

    /// @dev Sets up the test case environment.
    function setUp() public override {
        super.setUp();

        // staked ERC1155 token amounts are stored in a mapping, so we need to compute the storage slot to set up the test case
        bytes32 stakedERC1155TokenAmountStorageSlot = keccak256(
            abi.encode(
                bongBearTokenIds[0], // the staked ERC1155 token ID
                keccak256(
                    abi.encode(
                        BONG_BEARS, // the staked ERC1155 token collection
                        keccak256(
                            abi.encode(
                                address(this), // the staker
                                L2AssetHandlerStorage.STORAGE_SLOT
                            )
                        )
                    )
                )
            )
        );

        // write the staked ERC1155 token amount to storage
        vm.store(
            address(l2AssetHandler),
            stakedERC1155TokenAmountStorageSlot,
            bytes32(bongBearTokenAmounts[0])
        );
    }

    /// @dev Tests unstakeERC1155Assets functionality for unstaking ERC1155 tokens.
    function test_unstakeERC1155Assets() public {
        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);
        l2AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        l2AssetHandler.unstakeERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that unstakeERC1155Assets functionality emits an ERC1155AssetsUnstaked event when unstaking ERC1155 tokens.
    function test_unstakeERC1155AssetsEmitsERC1155AssetsUnstakedEvent() public {
        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);
        l2AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectEmit();
        emit ERC1155AssetsUnstaked(
            address(this),
            BONG_BEARS,
            bongBearTokenIds,
            bongBearTokenAmounts
        );

        l2AssetHandler.unstakeERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that unstakeERC1155Assets functionality emits a MessageSent event when unstaking ERC1155 tokens.
    function test_unstakeERC1155AssetsEmitsMessageSent() public {
        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);
        l2AssetHandler.setLayerZeroTrustedRemoteAddress(
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
                bongBearTokenIds,
                bongBearTokenAmounts
            ),
            address(this),
            address(0),
            "",
            LAYER_ZERO_MESSAGE_FEE
        );

        l2AssetHandler.unstakeERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that unstakeERC1155Assets functionality reverts when attempting to unstake more ERC1155 tokens than the msg.sender has staked.
    function test_unstakeERC1155AssetsRevertsWhenAttemptingToUnstakeMoreThanStakedAmount()
        public
    {
        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);
        l2AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectRevert(
            IL2AssetHandler.ERC1155TokenAmountExceedsStakedAmount.selector
        );

        bongBearTokenAmounts[0]++;

        l2AssetHandler.unstakeERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that unstakeERC1155Assets functionality reverts when attempting to unstake ERC1155 tokens on an unsupported remote chain.
    function test_unstakeERC1155AssetsRevertsWhenAttemptingToUnstakeOnAnUnsupportedRemoteChain()
        public
    {
        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);
        l2AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        l2AssetHandler.unstakeERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID + 1, // unsupported remote chain
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that unstakeERC1155Assets functionality reverts when attempting to unstake staked ERC1155 tokens that are not owned by the msg.sender.
    function test_unstakeERC1155AssetsRevertsWhenAttemptingToUnstakeSomeoneElsesStakedTokens()
        public
    {
        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);
        l2AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        uint256[] memory bongBearTokenIds = new uint256[](1);

        bongBearTokenIds[
            0
        ] = 66075445032688988859229341194671037535804503065310441849644897862140383199233; // Bong Bear #02

        // staked ERC1155 token amounts are stored in a mapping, so we need to compute the storage slot to set up this test case
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

        // write the staked ERC1155 token amount to storage
        vm.store(
            address(l2AssetHandler),
            stakedERC1155TokenAmountStorageSlot,
            bytes32(bongBearTokenAmounts[0])
        );

        vm.expectRevert(
            IL2AssetHandler.ERC1155TokenAmountExceedsStakedAmount.selector
        );

        l2AssetHandler.unstakeERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that unstakeERC1155Assets functionality reverts when LayerZero endpoint is not set.
    function test_unstakeERC1155AssetsRevertsWhenLayerZeroEndpointIsNotSet()
        public
    {
        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        l2AssetHandler.unstakeERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that unstakeERC1155Assets functionality reverts when LayerZero endpoint is set incorrectly.
    function test_unstakeERC1155AssetsRevertsWhenLayerZeroEndpointIsSetIncorrectly()
        public
    {
        l2AssetHandler.setLayerZeroEndpoint(address(this)); // incorrect endpoint

        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        l2AssetHandler.unstakeERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that unstakeERC1155Assets functionality reverts when LayerZero message fee is not sent.
    function test_unstakeERC1155AssetsRevertsWhenLayerZeroMessageFeeIsNotSent()
        public
    {
        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);
        l2AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectRevert(LAYER_ZERO_MESSAGE_FEE_REVERT);

        l2AssetHandler.unstakeERC1155Assets( // message fee not sent
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that unstakeERC1155Assets functionality reverts when LayerZero message fee sent is insufficient.
    function test_unstakeERC1155AssetsRevertsWhenLayerZeroMessageFeeSentIsInsufficient()
        public
    {
        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);
        l2AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectRevert(LAYER_ZERO_MESSAGE_FEE_REVERT);

        l2AssetHandler.unstakeERC1155Assets{
            value: LAYER_ZERO_MESSAGE_FEE / 2
        }( // insufficient message fee
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that unstakeERC1155Assets functionality reverts when LayerZero trusted remote address is not set.
    function test_unstakeERC1155AssetsRevertsWhenLayerZeroTrustedRemoteAddressIsNotSet()
        public
    {
        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);

        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        l2AssetHandler.unstakeERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that unstakeERC1155Assets functionality reverts when tokenIds and amounts length mismatch.
    function test_unstakeERC1155AssetsRevertsWhenTokenIdsAndAmountsLengthMismatch()
        public
    {
        vm.expectRevert(
            IAssetHandler.ERC1155TokenIdsAndAmountsLengthMismatch.selector
        );

        bongBearTokenAmounts.push(uint256(1)); // mismatched lengths

        l2AssetHandler.unstakeERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }
}
