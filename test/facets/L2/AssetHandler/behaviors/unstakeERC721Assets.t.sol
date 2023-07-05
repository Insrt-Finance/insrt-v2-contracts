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

/// @title L2AssetHandler_unstakeERC721Assets
/// @dev L2AssetHandler test contract for testing expected L2 unstakeERC721Assets behavior. Tested on an Arbitrum fork.
contract L2AssetHandler_unstakeERC721Assets is
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

        // staked ERC721 records are stored in a mapping, so we need to compute the storage slot to set up this test case
        bytes32 stakedERC721TokenIdStakedStorageSlot = keccak256(
            abi.encode(
                boredApeYachtClubTokenIds[0], // the staked ERC721 token ID
                keccak256(
                    abi.encode(
                        BORED_APE_YACHT_CLUB, // the staked ERC721 token collection
                        keccak256(
                            abi.encode(
                                address(this), // the stake
                                uint256(L2AssetHandlerStorage.STORAGE_SLOT) + 1 // the stakedERC721Assets storage slot
                            )
                        )
                    )
                )
            )
        );

        // write the staked ERC721 staked state to storage
        vm.store(
            address(l2AssetHandler),
            stakedERC721TokenIdStakedStorageSlot,
            bytes32(uint256(1))
        );
    }

    /// @dev Tests unstakeERC721Assets functionality for unstaking ERC721 tokens.
    function test_unstakeERC721Assets() public {
        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);
        l2AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        l2AssetHandler.unstakeERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that unstakeERC721Assets functionality emits an ERC721AssetsUnstaked event when unstaking ERC721 tokens.
    function test_unstakeERC721AssetsEmitsERC721AssetsUnstakedEvent() public {
        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);
        l2AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectEmit();
        emit ERC721AssetsUnstaked(
            address(this),
            BORED_APE_YACHT_CLUB,
            boredApeYachtClubTokenIds
        );

        l2AssetHandler.unstakeERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that unstakeERC721Assets functionality emits a MessageSent event when unstaking ERC721 tokens.
    function test_unstakeERC721AssetsEmitsMessageSent() public {
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

        l2AssetHandler.unstakeERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that unstakeERC721Assets functionality reverts when attempting to unstake more ERC721 tokens than the msg.sender has staked.
    function test_unstakeERC721AssetsRevertsWhenAttemptingToUnstakeMoreThanStakedAmount()
        public
    {
        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);
        l2AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectRevert(IL2AssetHandler.ERC721TokenNotStaked.selector);

        boredApeYachtClubTokenIds.push(2);

        l2AssetHandler.unstakeERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that unstakeERC721Assets functionality reverts when attempting to unstake ERC721 tokens on an unsupported remote chain.
    function test_unstakeERC721AssetsRevertsWhenAttemptingToUnstakeOnAnUnsupportedRemoteChain()
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

        l2AssetHandler.unstakeERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID + 1, // unsupported remote chain
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that unstakeERC721Assets functionality reverts when attempting to unstake staked ERC721 tokens that are not owned by the msg.sender.
    function test_unstakeERC721AssetsRevertsWhenAttemptingToUnstakeSomeoneElsesStakedTokens()
        public
    {
        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);
        l2AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        uint256[] memory boredApeYachtClubTokenIds = new uint256[](1);

        boredApeYachtClubTokenIds[0] = 2;

        // staked ERC721 records are stored in a mapping, so we need to compute the storage slot to set up this test case
        bytes32 stakedERC721TokenIdStakedStorageSlot = keccak256(
            abi.encode(
                boredApeYachtClubTokenIds[0], // the staked ERC721 token ID
                keccak256(
                    abi.encode(
                        BORED_APE_YACHT_CLUB, // the staked ERC721 token collection
                        keccak256(
                            abi.encode(
                                msg.sender, // the staker
                                uint256(L2AssetHandlerStorage.STORAGE_SLOT) + 1 // the stakedERC721Assets storage slot
                            )
                        )
                    )
                )
            )
        );

        // write the staked ERC721 staked state to storage
        vm.store(
            address(l2AssetHandler),
            stakedERC721TokenIdStakedStorageSlot,
            bytes32(uint256(1))
        );

        vm.expectRevert(IL2AssetHandler.ERC721TokenNotStaked.selector);

        l2AssetHandler.unstakeERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that unstakeERC721Assets functionality reverts when LayerZero endpoint is not set.
    function test_unstakeERC721AssetsRevertsWhenLayerZeroEndpointIsNotSet()
        public
    {
        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        l2AssetHandler.unstakeERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that unstakeERC721Assets functionality reverts when LayerZero endpoint is set incorrectly.
    function test_unstakeERC721AssetsRevertsWhenLayerZeroEndpointIsSetIncorrectly()
        public
    {
        l2AssetHandler.setLayerZeroEndpoint(address(this)); // incorrect endpoint

        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        l2AssetHandler.unstakeERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that unstakeERC721Assets functionality reverts when LayerZero message fee is not sent.
    function test_unstakeERC721AssetsRevertsWhenLayerZeroMessageFeeIsNotSent()
        public
    {
        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);
        l2AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectRevert(LAYER_ZERO_MESSAGE_FEE_REVERT);

        l2AssetHandler.unstakeERC721Assets( // message fee not sent
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that unstakeERC721Assets functionality reverts when LayerZero message fee sent is insufficient.
    function test_unstakeERC721AssetsRevertsWhenLayerZeroMessageFeeSentIsInsufficient()
        public
    {
        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);
        l2AssetHandler.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectRevert(LAYER_ZERO_MESSAGE_FEE_REVERT);

        l2AssetHandler.unstakeERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE / 5 }( // insufficient message fee
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that unstakeERC721Assets functionality reverts when LayerZero trusted remote address is not set.
    function test_unstakeERC721AssetsRevertsWhenLayerZeroTrustedRemoteAddressIsNotSet()
        public
    {
        l2AssetHandler.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);

        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        l2AssetHandler.unstakeERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }
}
