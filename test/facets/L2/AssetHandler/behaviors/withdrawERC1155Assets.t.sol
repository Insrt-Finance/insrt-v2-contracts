// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import "forge-std/Test.sol";

import { ILayerZeroClientBaseInternal } from "@solidstate/layerzero-client/base/ILayerZeroClientBaseInternal.sol";
import { ILayerZeroEndpoint } from "@solidstate/layerzero-client/interfaces/ILayerZeroEndpoint.sol";

import { L2AssetHandlerTest } from "../AssetHandler.t.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { L2AssetHandlerMock } from "../../../../mocks/L2AssetHandlerMock.t.sol";
import { IL2AssetHandler } from "../../../../../contracts/facets/L2/AssetHandler/IAssetHandler.sol";
import { L2AssetHandlerStorage } from "../../../../../contracts/facets/L2/AssetHandler/Storage.sol";
import { IAssetHandler } from "../../../../../contracts/interfaces/IAssetHandler.sol";
import { PayloadEncoder } from "../../../../../contracts/libraries/PayloadEncoder.sol";

/// @title L2AssetHandler_withdrawERC1155Assets
/// @dev L2AssetHandler test contract for testing expected L2 withdrawERC1155Assets behavior. Tested on an Arbitrum fork.
contract L2AssetHandler_withdrawERC1155Assets is
    L2AssetHandlerMock,
    L2AssetHandlerTest,
    L2ForkTest
{
    /// @dev LayerZero message fee error message.
    bytes internal constant LAYER_ZERO_MESSAGE_FEE_REVERT =
        "LayerZero: not enough native for fees";

    /// @dev Test ERC1155 withdraw payload.
    bytes internal TEST_ERC1155_WITHDRAW_PAYLOAD;

    /// @dev Sets up the test case environment.
    function setUp() public override {
        super.setUp();

        TEST_ERC1155_WITHDRAW_PAYLOAD = abi.encode(
            PayloadEncoder.AssetType.ERC1155,
            address(this),
            BONG_BEARS,
            bongBearTokenIds,
            bongBearTokenAmounts
        );

        (LAYER_ZERO_MESSAGE_FEE, ) = ILayerZeroEndpoint(
            ARBITRUM_LAYER_ZERO_ENDPOINT
        ).estimateFees(
                DESTINATION_LAYER_ZERO_CHAIN_ID,
                address(l2AssetHandler),
                TEST_ERC1155_WITHDRAW_PAYLOAD,
                false,
                ""
            );

        bytes memory encodedData = abi.encode(
            PayloadEncoder.AssetType.ERC1155,
            address(this),
            BONG_BEARS,
            testRisks,
            bongBearTokenIds,
            bongBearTokenAmounts
        );

        this.mock_HandleLayerZeroMessage(
            DESTINATION_LAYER_ZERO_CHAIN_ID, // would be the expected source chain ID in production, here this is a dummy value
            TEST_PATH, // would be the expected path in production, here this is a dummy value
            TEST_NONCE, // dummy nonce value
            encodedData
        );

        // the deposited ERC1155 token amount is stored in a mapping, so we need to compute the storage slot
        bytes32 depositedERC1155TokenAmountStorageSlot = keccak256(
            abi.encode(
                bongBearTokenIds[0], // the deposited ERC1155 token ID
                keccak256(
                    abi.encode(
                        BONG_BEARS, // the deposited ERC1155 token collection
                        keccak256(
                            abi.encode(
                                address(this), // the depositor
                                L2AssetHandlerStorage.STORAGE_SLOT
                            )
                        )
                    )
                )
            )
        );

        uint256 depositedERC1155TokenAmount = uint256(
            vm.load(address(this), depositedERC1155TokenAmountStorageSlot)
        );

        // mappings are hash tables, so this assertion proves that the deposited ERC1155 token amount was
        // set correctly for the depositor, collection, and the given token ID.
        assertEq(depositedERC1155TokenAmount, bongBearTokenAmounts[0]);
    }

    /// @dev Tests withdrawERC1155Assets functionality for withdrawing ERC1155 tokens.
    function test_withdrawERC1155Assets() public {
        // mock the sender to be msg.sender and not the contract in order to have authority to call setLayerZeroEndpoint
        vm.prank(msg.sender);
        this.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);

        // mock the sender to be msg.sender and not the contract in order to have authority to call setLayerZeroTrustedRemoteAddress
        vm.prank(msg.sender);
        this.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        this.withdrawERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that withdrawERC1155Assets functionality emits an ERC1155AssetsWithdrawn event when withdrawing ERC1155 tokens.
    function test_withdrawERC1155AssetsEmitsERC1155AssetsWithdrawnEvent()
        public
    {
        vm.prank(msg.sender);
        this.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);

        vm.prank(msg.sender);
        this.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectEmit();
        emit ERC1155AssetsWithdrawn(
            address(this),
            BONG_BEARS,
            bongBearTokenIds,
            bongBearTokenAmounts
        );

        this.withdrawERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that withdrawERC1155Assets functionality emits a MessageSent event when withdrawing ERC1155 tokens.
    function test_withdrawERC1155AssetsEmitsMessageSent() public {
        vm.prank(msg.sender);
        this.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);

        vm.prank(msg.sender);
        this.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectEmit();
        emit MessageSent(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TEST_ERC1155_WITHDRAW_PAYLOAD,
            address(this),
            address(0),
            "",
            LAYER_ZERO_MESSAGE_FEE
        );

        this.withdrawERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that withdrawERC1155Assets functionality reverts when attempting to withdraw more ERC1155 tokens than the msg.sender has deposited.
    function test_withdrawERC1155AssetsRevertsWhenAttemptingToUndepositMoreThanDepositedAmount()
        public
    {
        vm.prank(msg.sender);
        this.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);

        vm.prank(msg.sender);
        this.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectRevert();

        bongBearTokenAmounts[0]++;

        this.withdrawERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that withdrawERC1155Assets functionality reverts when attempting to withdraw ERC1155 tokens on an unsupported remote chain.
    function test_withdrawERC1155AssetsRevertsWhenAttemptingToUndepositOnAnUnsupportedRemoteChain()
        public
    {
        vm.prank(msg.sender);
        this.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);

        vm.prank(msg.sender);
        this.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        this.withdrawERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID + 1, // unsupported remote chain
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that withdrawERC1155Assets functionality reverts when attempting to withdraw deposited ERC1155 tokens that are not owned by the msg.sender.
    function test_withdrawERC1155AssetsRevertsWhenAttemptingToUndepositSomeoneElsesDepositedTokens()
        public
    {
        vm.prank(msg.sender);
        this.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);

        vm.prank(msg.sender);
        this.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        uint256[] memory bongBearTokenIds = new uint256[](1);

        bongBearTokenIds[
            0
        ] = 66075445032688988859229341194671037535804503065310441849644897862140383199233; // Bong Bear #02

        // deposited ERC1155 token amounts are stored in a mapping, so we need to compute the storage slot to set up this test case
        bytes32 depositedERC1155TokenAmountStorageSlot = keccak256(
            abi.encode(
                bongBearTokenIds[0], // the deposited ERC1155 token ID
                keccak256(
                    abi.encode(
                        BONG_BEARS, // the deposited ERC1155 token collection
                        keccak256(
                            abi.encode(
                                msg.sender, // the depositor
                                L2AssetHandlerStorage.STORAGE_SLOT
                            )
                        )
                    )
                )
            )
        );

        // write the deposited ERC1155 token amount to storage
        vm.store(
            address(l2AssetHandler),
            depositedERC1155TokenAmountStorageSlot,
            bytes32(bongBearTokenAmounts[0])
        );

        vm.expectRevert();

        this.withdrawERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that withdrawERC1155Assets functionality reverts when LayerZero endpoint is not set.
    function test_withdrawERC1155AssetsRevertsWhenLayerZeroEndpointIsNotSet()
        public
    {
        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        this.withdrawERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that withdrawERC1155Assets functionality reverts when LayerZero endpoint is set incorrectly.
    function test_withdrawERC1155AssetsRevertsWhenLayerZeroEndpointIsSetIncorrectly()
        public
    {
        vm.prank(msg.sender);
        this.setLayerZeroEndpoint(address(this)); // incorrect endpoint

        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        this.withdrawERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that withdrawERC1155Assets functionality reverts when LayerZero message fee is not sent.
    function test_withdrawERC1155AssetsRevertsWhenLayerZeroMessageFeeIsNotSent()
        public
    {
        vm.prank(msg.sender);
        this.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);

        vm.prank(msg.sender);
        this.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectRevert(LAYER_ZERO_MESSAGE_FEE_REVERT);

        this.withdrawERC1155Assets( // message fee not sent
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that withdrawERC1155Assets functionality reverts when LayerZero message fee sent is insufficient.
    function test_withdrawERC1155AssetsRevertsWhenLayerZeroMessageFeeSentIsInsufficient()
        public
    {
        vm.prank(msg.sender);
        this.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);

        vm.prank(msg.sender);
        this.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectRevert(LAYER_ZERO_MESSAGE_FEE_REVERT);

        this.withdrawERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE / 6 }( // insufficient message fee
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that withdrawERC1155Assets functionality reverts when LayerZero trusted remote address is not set.
    function test_withdrawERC1155AssetsRevertsWhenLayerZeroTrustedRemoteAddressIsNotSet()
        public
    {
        vm.prank(msg.sender);
        this.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);

        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        this.withdrawERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that withdrawERC1155Assets functionality reverts when tokenIds and amounts length mismatch.
    function test_withdrawERC1155AssetsRevertsWhenTokenIdsAndAmountsLengthMismatch()
        public
    {
        vm.expectRevert(
            IAssetHandler.ERC1155TokenIdsAndAmountsLengthMismatch.selector
        );

        bongBearTokenAmounts.push(uint256(1)); // mismatched lengths

        this.withdrawERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }
}
