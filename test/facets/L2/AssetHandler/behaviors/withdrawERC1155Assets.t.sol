// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { ILayerZeroClientBaseInternal } from "@solidstate/layerzero-client/base/ILayerZeroClientBaseInternal.sol";
import { ILayerZeroEndpoint } from "@solidstate/layerzero-client/interfaces/ILayerZeroEndpoint.sol";

import { L2AssetHandlerTest } from "../AssetHandler.t.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { L2AssetHandlerMock } from "../../../../mocks/L2AssetHandlerMock.t.sol";
import { AssetType } from "../../../../../contracts/enums/AssetType.sol";
import { IL2AssetHandler } from "../../../../../contracts/facets/L2/AssetHandler/IAssetHandler.sol";
import { IGuardsInternal } from "../../../../../contracts/facets/L2/common/IGuardsInternal.sol";
import { PerpetualMintStorage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";
import { IAssetHandler } from "../../../../../contracts/interfaces/IAssetHandler.sol";

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
            AssetType.ERC1155,
            address(this),
            BONG_BEARS,
            address(this),
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
            AssetType.ERC1155,
            address(this),
            BONG_BEARS,
            address(this),
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

        uint256 activeERC1155TokenAmount = _activeERC1155Tokens(
            address(this),
            address(this),
            BONG_BEARS,
            bongBearTokenIds[0]
        );

        // mappings are hash tables, so this assertion proves that the active ERC1155 token amount was
        // set correctly for the depositor, collection, and the given token ID.
        assertEq(activeERC1155TokenAmount, bongBearTokenAmounts[0]);
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
            msg.sender,
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );

        uint256 activeERC1155TokenAmount = _activeERC1155Tokens(
            address(this),
            address(this),
            BONG_BEARS,
            bongBearTokenIds[0]
        );

        // this assertion proves that the active ERC1155 token amount was decremented correctly.
        assertEq(activeERC1155TokenAmount, 0);

        if (activeERC1155TokenAmount == 0) {
            address[]
                memory activeERC1155OwnersAddressSet = _activeERC1155Owners(
                    address(this),
                    BONG_BEARS,
                    bongBearTokenIds[0]
                );

            // this assertion proves that the ERC1155 owner was removed from the activeERC1155Owners AddressSet for the given token ID
            // since there was only one active owner previously
            assert(activeERC1155OwnersAddressSet.length == 0);

            if (activeERC1155OwnersAddressSet.length == 0) {
                uint256[] memory activeTokenIds = _activeTokenIds(
                    address(this),
                    BONG_BEARS
                );

                // this assertion proves that the active token ID was removed from the activeTokenIds UintSet
                // since there was only one active token previously
                assertEq(activeTokenIds.length, 0);
            }

            uint256 depositorTokenRisk = _depositorTokenRisk(
                address(this),
                address(this),
                BONG_BEARS,
                bongBearTokenIds[0]
            );

            // this assertion proves that the depositor token risk was reset 0 in depositorTokenRisk
            assertEq(depositorTokenRisk, 0);
        }

        uint256 totalActiveTokens = _totalActiveTokens(
            address(this),
            BONG_BEARS
        );

        // this assertion proves that the total number of active tokens in the collection was updated correctly
        assertEq(totalActiveTokens, 0);

        uint256 totalDepositorRisk = _totalDepositorRisk(
            address(this),
            address(this),
            BONG_BEARS
        );

        // this assertion proves that the total risk for the depositor in the collection was updated correctly
        assertEq(totalDepositorRisk, 0);

        uint256 totalRisk = _totalRisk(address(this), BONG_BEARS);

        // this assertion proves that the total risk in the collection was updated correctly
        assertEq(totalRisk, 0);

        uint256 tokenRisk = _tokenRisk(
            address(this),
            BONG_BEARS,
            bongBearTokenIds[0]
        );

        // this assertion proves that the total risk for the token ID in the collection was updated correctly
        assertEq(tokenRisk, 0);

        if (totalActiveTokens == 0) {
            address[] memory activeCollections = _activeCollections(
                address(this)
            );

            // this assertion proves that the collection was removed from the set of active collections
            // as there was only one active collection previously
            assertEq(activeCollections.length, 0);
        }
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
            address(this),
            bongBearTokenIds,
            bongBearTokenAmounts
        );

        this.withdrawERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            address(this),
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
            address(this),
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that withdrawERC1155Assets functionality reverts when attempting to withdraw more ERC1155 tokens than the msg.sender has deposited.
    function test_withdrawERC1155AssetsRevertsWhen_AttemptingToWithdrawMoreThanDepositedAmount()
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
            msg.sender,
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that withdrawERC1155Assets functionality reverts when attempting to withdraw ERC1155 tokens on an unsupported remote chain.
    function test_withdrawERC1155AssetsRevertsWhen_AttemptingToWithdrawOnAnUnsupportedRemoteChain()
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
            msg.sender,
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID + 1, // unsupported remote chain
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that withdrawERC1155Assets functionality reverts when attempting to withdraw deposited ERC1155 tokens that are not owned by the msg.sender.
    function test_withdrawERC1155AssetsRevertsWhen_AttemptingToWithdrawSomeoneElsesDepositedTokens()
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

        // active ERC1155 tokens are stored in a mapping, so we need to compute the storage slot to set up this test case
        bytes32 activeERC1155TokenAmountStorageSlot = keccak256(
            abi.encode(
                bongBearTokenIds[0], // the active ERC1155 token ID
                keccak256(
                    abi.encode(
                        BONG_BEARS, // the active ERC1155 token collection
                        keccak256(
                            abi.encode(
                                msg.sender, // the active ERC1155 token depositor
                                uint256(PerpetualMintStorage.STORAGE_SLOT) + 25 // the activeERC1155Tokens storage slot
                            )
                        )
                    )
                )
            )
        );

        // write the active ERC1155 token amount to storage
        vm.store(
            address(l2AssetHandler),
            activeERC1155TokenAmountStorageSlot,
            bytes32(bongBearTokenAmounts[0])
        );

        vm.expectRevert();

        this.withdrawERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            msg.sender,
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that withdrawERC1155Assets functionality reverts when LayerZero endpoint is not set.
    function test_withdrawERC1155AssetsRevertsWhen_LayerZeroEndpointIsNotSet()
        public
    {
        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        this.withdrawERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            msg.sender,
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that withdrawERC1155Assets functionality reverts when LayerZero endpoint is set incorrectly.
    function test_withdrawERC1155AssetsRevertsWhen_LayerZeroEndpointIsSetIncorrectly()
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
            msg.sender,
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that withdrawERC1155Assets functionality reverts when LayerZero message fee is not sent.
    function test_withdrawERC1155AssetsRevertsWhen_LayerZeroMessageFeeIsNotSent()
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
            msg.sender,
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that withdrawERC1155Assets functionality reverts when LayerZero message fee sent is insufficient.
    function test_withdrawERC1155AssetsRevertsWhen_LayerZeroMessageFeeSentIsInsufficient()
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
            msg.sender,
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that withdrawERC1155Assets functionality reverts when LayerZero trusted remote address is not set.
    function test_withdrawERC1155AssetsRevertsWhen_LayerZeroTrustedRemoteAddressIsNotSet()
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
            msg.sender,
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev Tests that withdrawERC1155Assets functionality reverts when tokenIds and amounts length mismatch.
    function test_withdrawERC1155AssetsRevertsWhen_TokenIdsAndAmountsLengthMismatch()
        public
    {
        vm.expectRevert(
            IAssetHandler.ERC1155TokenIdsAndAmountsLengthMismatch.selector
        );

        bongBearTokenAmounts.push(uint256(1)); // mismatched lengths

        this.withdrawERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            msg.sender,
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }

    /// @dev tests that if there are pending mint requests withdrawing ERC721 assets reverts
    function test_withdrawERC721AssetsRevertsWhen_ThereIsAtLeastOnePendingRequest()
        public
    {
        uint256 mockMintRequestId = 5;

        // calculate pendingRequests enumerable set slot
        bytes32 pendingRequestsSlot = keccak256(
            abi.encode(
                BONG_BEARS, // address of collection
                uint256(PerpetualMintStorage.STORAGE_SLOT) + 28 // requestIds mapping storage slot
            )
        );

        // store EnumerableSet.UintSet._inner._values length
        vm.store(address(this), pendingRequestsSlot, bytes32(uint256(1)));

        // calculate the PerpetualMint pending request id slot
        bytes32 pendingRequestIdValueSlot = keccak256(
            abi.encodePacked(pendingRequestsSlot)
        );

        // store the mockMintRequestId in the pendingRequests enumerable set
        vm.store(
            address(this),
            pendingRequestIdValueSlot,
            bytes32(mockMintRequestId)
        );

        // calcaulte the PerpetualMint pending request id index slot
        bytes32 pendingRequestIdIndexSlot = keccak256(
            abi.encode(
                bytes32(mockMintRequestId),
                uint256(pendingRequestsSlot) + 1
            )
        );

        // store 1 as the index of mockMintRequestId
        vm.store(address(this), pendingRequestIdIndexSlot, bytes32(uint256(1)));

        vm.expectRevert(IGuardsInternal.PendingRequests.selector);

        this.withdrawERC1155Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            address(this),
            BONG_BEARS,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            bongBearTokenIds,
            bongBearTokenAmounts
        );
    }
}
