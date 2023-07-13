// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import "forge-std/Test.sol";

import { ILayerZeroClientBaseInternal } from "@solidstate/layerzero-client/base/ILayerZeroClientBaseInternal.sol";

import { L2AssetHandlerTest } from "../AssetHandler.t.sol";
import { ILayerZeroClientBaseInternalEvents } from "../../../../interfaces/ILayerZeroClientBaseInternalEvents.sol";
import { L2AssetHandlerStorage } from "../../../../../contracts/facets/L2/AssetHandler/Storage.sol";
import { IL2AssetHandler } from "../../../../../contracts/facets/L2/AssetHandler/IAssetHandler.sol";
import { PayloadEncoder } from "../../../../../contracts/libraries/PayloadEncoder.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";

/// @title L2AssetHandler_withdrawERC721Assets
/// @dev L2AssetHandler test contract for testing expected L2 withdrawERC721Assets behavior. Tested on an Arbitrum fork.
contract L2AssetHandler_withdrawERC721Assets is
    ILayerZeroClientBaseInternalEvents,
    L2AssetHandlerTest,
    L2ForkTest
{
    /// @dev LayerZero message fee error message.
    bytes internal constant LAYER_ZERO_MESSAGE_FEE_REVERT =
        "LayerZero: not enough native for fees";

    /// @dev Sets up the test case environment.
    function setUp() public override {
        super.setUp();

        // deposited ERC721 records are stored in a mapping, so we need to compute the storage slot to set up this test case
        bytes32 depositedERC721TokenIdDepositedStorageSlot = keccak256(
            abi.encode(
                boredApeYachtClubTokenIds[0], // the deposited ERC721 token ID
                keccak256(
                    abi.encode(
                        BORED_APE_YACHT_CLUB, // the deposited ERC721 token collection
                        keccak256(
                            abi.encode(
                                address(this), // the depositor
                                uint256(L2AssetHandlerStorage.STORAGE_SLOT) + 1 // the depositedERC721Assets storage slot
                            )
                        )
                    )
                )
            )
        );

        // write the deposited ERC721 deposited state to storage
        vm.store(
            address(l2AssetHandler),
            depositedERC721TokenIdDepositedStorageSlot,
            bytes32(uint256(1))
        );
    }

    /// @dev Tests withdrawERC721Assets functionality for withdrawing ERC721 tokens.
    function test_withdrawERC721Assets() public {
        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);
        l2AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        l2AssetHandler.withdrawERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality emits an ERC721AssetsWithdrawn event when withdrawing ERC721 tokens.
    function test_withdrawERC721AssetsEmitsERC721AssetsWithdrawnEvent() public {
        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);
        l2AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectEmit();
        emit ERC721AssetsWithdrawn(
            address(this),
            BORED_APE_YACHT_CLUB,
            boredApeYachtClubTokenIds
        );

        l2AssetHandler.withdrawERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality emits a MessageSent event when withdrawing ERC721 tokens.
    function test_withdrawERC721AssetsEmitsMessageSent() public {
        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);
        l2AssetHandler.setLayerZeroTrustedRemoteAddress(
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

        l2AssetHandler.withdrawERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality reverts when attempting to withdraw more ERC721 tokens than the msg.sender has deposited.
    function test_withdrawERC721AssetsRevertsWhenAttemptingToUndepositMoreThanDepositedAmount()
        public
    {
        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);
        l2AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectRevert(IL2AssetHandler.ERC721TokenNotDeposited.selector);

        boredApeYachtClubTokenIds.push(2);

        l2AssetHandler.withdrawERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality reverts when attempting to withdraw ERC721 tokens on an unsupported remote chain.
    function test_withdrawERC721AssetsRevertsWhenAttemptingToUndepositOnAnUnsupportedRemoteChain()
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

        l2AssetHandler.withdrawERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID + 1, // unsupported remote chain
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality reverts when attempting to withdraw deposited ERC721 tokens that are not owned by the msg.sender.
    function test_withdrawERC721AssetsRevertsWhenAttemptingToUndepositSomeoneElsesDepositedTokens()
        public
    {
        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);
        l2AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        uint256[] memory boredApeYachtClubTokenIds = new uint256[](1);

        boredApeYachtClubTokenIds[0] = 2;

        // deposited ERC721 records are stored in a mapping, so we need to compute the storage slot to set up this test case
        bytes32 depositedERC721TokenIdDepositedStorageSlot = keccak256(
            abi.encode(
                boredApeYachtClubTokenIds[0], // the deposited ERC721 token ID
                keccak256(
                    abi.encode(
                        BORED_APE_YACHT_CLUB, // the deposited ERC721 token collection
                        keccak256(
                            abi.encode(
                                msg.sender, // the depositor
                                uint256(L2AssetHandlerStorage.STORAGE_SLOT) + 1 // the depositedERC721Assets storage slot
                            )
                        )
                    )
                )
            )
        );

        // write the deposited ERC721 deposited state to storage
        vm.store(
            address(l2AssetHandler),
            depositedERC721TokenIdDepositedStorageSlot,
            bytes32(uint256(1))
        );

        vm.expectRevert(IL2AssetHandler.ERC721TokenNotDeposited.selector);

        l2AssetHandler.withdrawERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality reverts when LayerZero endpoint is not set.
    function test_withdrawERC721AssetsRevertsWhenLayerZeroEndpointIsNotSet()
        public
    {
        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        l2AssetHandler.withdrawERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality reverts when LayerZero endpoint is set incorrectly.
    function test_withdrawERC721AssetsRevertsWhenLayerZeroEndpointIsSetIncorrectly()
        public
    {
        l2AssetHandler.setLayerZeroEndpoint(address(this)); // incorrect endpoint

        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        l2AssetHandler.withdrawERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality reverts when LayerZero message fee is not sent.
    function test_withdrawERC721AssetsRevertsWhenLayerZeroMessageFeeIsNotSent()
        public
    {
        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);
        l2AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectRevert(LAYER_ZERO_MESSAGE_FEE_REVERT);

        l2AssetHandler.withdrawERC721Assets( // message fee not sent
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality reverts when LayerZero message fee sent is insufficient.
    function test_withdrawERC721AssetsRevertsWhenLayerZeroMessageFeeSentIsInsufficient()
        public
    {
        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);
        l2AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectRevert(LAYER_ZERO_MESSAGE_FEE_REVERT);

        l2AssetHandler.withdrawERC721Assets{
            value: LAYER_ZERO_MESSAGE_FEE / 5
        }( // insufficient message fee
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality reverts when LayerZero trusted remote address is not set.
    function test_withdrawERC721AssetsRevertsWhenLayerZeroTrustedRemoteAddressIsNotSet()
        public
    {
        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);

        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        l2AssetHandler.withdrawERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }
}
