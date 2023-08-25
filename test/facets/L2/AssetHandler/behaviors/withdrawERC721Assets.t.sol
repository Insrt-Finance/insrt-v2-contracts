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

/// @title L2AssetHandler_withdrawERC721Assets
/// @dev L2AssetHandler test contract for testing expected L2 withdrawERC721Assets behavior. Tested on an Arbitrum fork.
contract L2AssetHandler_withdrawERC721Assets is
    L2AssetHandlerMock,
    L2AssetHandlerTest,
    L2ForkTest
{
    /// @dev LayerZero message fee error message.
    bytes internal constant LAYER_ZERO_MESSAGE_FEE_REVERT =
        "LayerZero: not enough native for fees";

    /// @dev Test ERC721 withdraw payload.
    bytes internal TEST_ERC721_WITHDRAW_PAYLOAD;

    /// @dev Sets up the test case environment.
    function setUp() public override {
        super.setUp();

        TEST_ERC721_WITHDRAW_PAYLOAD = abi.encode(
            AssetType.ERC721,
            address(this),
            BORED_APE_YACHT_CLUB,
            address(this),
            boredApeYachtClubTokenIds
        );

        (LAYER_ZERO_MESSAGE_FEE, ) = ILayerZeroEndpoint(
            ARBITRUM_LAYER_ZERO_ENDPOINT
        ).estimateFees(
                DESTINATION_LAYER_ZERO_CHAIN_ID,
                address(l2AssetHandler),
                TEST_ERC721_WITHDRAW_PAYLOAD,
                false,
                ""
            );

        bytes memory encodedData = abi.encode(
            AssetType.ERC721,
            address(this),
            BORED_APE_YACHT_CLUB,
            address(this),
            testRisks,
            boredApeYachtClubTokenIds
        );

        this.mock_HandleLayerZeroMessage(
            DESTINATION_LAYER_ZERO_CHAIN_ID, // would be the expected source chain ID in production, here this is a dummy value
            TEST_PATH, // would be the expected path in production, here this is a dummy value
            TEST_NONCE, // dummy nonce value
            encodedData
        );

        address escrowedERC721Owner = _escrowedERC721Owner(
            address(this),
            BORED_APE_YACHT_CLUB,
            boredApeYachtClubTokenIds[0]
        );

        // mappings are hash tables, so this assertion proves that the escrowed ERC721 owner
        // was set correctly for the collection and the given token ID.
        assertEq(escrowedERC721Owner, address(this));
    }

    /// @dev Tests withdrawERC721Assets functionality for withdrawing ERC721 tokens.
    function test_withdrawERC721Assets() public {
        // mock the sender to be msg.sender and not the contract in order to have authority to call setLayerZeroEndpoint
        vm.prank(msg.sender);
        this.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);

        // mock the sender to be msg.sender and not the contract in order to have authority to call setLayerZeroTrustedRemoteAddress
        vm.prank(msg.sender);
        this.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        this.withdrawERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            address(this),
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );

        address escrowedERC721Owner = _escrowedERC721Owner(
            address(this),
            BORED_APE_YACHT_CLUB,
            boredApeYachtClubTokenIds[0]
        );

        // mappings are hash tables, so this assertion proves that the escrowed ERC721 owner
        // was updated correctly for the collection, and the given token ID.
        assertEq(escrowedERC721Owner, address(0));

        uint256[] memory activeTokenIds = _activeTokenIds(
            address(this),
            BORED_APE_YACHT_CLUB
        );

        // this assertion proves that the token ID was removed from the set of active token IDs in the collection
        // only a single token was deposited so removing one would leave 0 active tokens
        assert(activeTokenIds.length == 0);

        uint256 activeTokensCount = _activeTokens(
            address(this),
            address(this),
            BORED_APE_YACHT_CLUB
        );

        // this assertion proves that the count of active tokens for the depositor in the collection was decremented correctly
        assertEq(activeTokensCount, 0);

        uint256 tokenRisk = _tokenRisk(
            address(this),
            BORED_APE_YACHT_CLUB,
            boredApeYachtClubTokenIds[0]
        );

        // this assertion proves that the risk for the token ID in the collection was decremented correctly
        assertEq(tokenRisk, 0);

        uint256 totalActiveTokens = _totalActiveTokens(
            address(this),
            BORED_APE_YACHT_CLUB
        );

        // this assertion proves that the total number of active tokens in the collection was decremented correctly
        assertEq(totalActiveTokens, 0);

        uint256 totalDepositorRisk = _totalDepositorRisk(
            address(this),
            address(this),
            BORED_APE_YACHT_CLUB
        );

        // this assertion proves that the total risk for the depositor in the collection was decremented correctly
        assertEq(totalDepositorRisk, 0);

        uint256 totalRisk = _totalRisk(address(this), BORED_APE_YACHT_CLUB);

        // this assertion proves that the total risk in the collection was decremented correctly
        assertEq(totalRisk, 0);

        if (totalActiveTokens == 0) {
            address[] memory activeCollections = _activeCollections(
                address(this)
            );

            // this assertion proves that the collection was removed from the set of active collections
            // since there was only one active collection earlier
            assert(activeCollections.length == 0);
        }
    }

    /// @dev Tests that withdrawERC721Assets functionality emits an ERC721AssetsWithdrawn event when withdrawing ERC721 tokens.
    function test_withdrawERC721AssetsEmitsERC721AssetsWithdrawnEvent() public {
        vm.prank(msg.sender);
        this.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);

        vm.prank(msg.sender);
        this.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectEmit();
        emit ERC721AssetsWithdrawn(
            address(this),
            BORED_APE_YACHT_CLUB,
            address(this),
            boredApeYachtClubTokenIds
        );

        this.withdrawERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            address(this),
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality emits a MessageSent event when withdrawing ERC721 tokens.
    function test_withdrawERC721AssetsEmitsMessageSent() public {
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
            TEST_ERC721_WITHDRAW_PAYLOAD,
            address(this),
            address(0),
            "",
            LAYER_ZERO_MESSAGE_FEE
        );

        this.withdrawERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            address(this),
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality reverts when attempting to withdraw more ERC721 tokens than the msg.sender has deposited.
    function test_withdrawERC721AssetsRevertsWhen_AttemptingToWithdrawMoreThanDepositedAmount()
        public
    {
        vm.prank(msg.sender);
        this.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);

        vm.prank(msg.sender);
        this.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectRevert(IL2AssetHandler.ERC721TokenNotEscrowed.selector);

        boredApeYachtClubTokenIds.push(2);

        this.withdrawERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            address(this),
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality reverts when attempting to withdraw ERC721 tokens on an unsupported remote chain.
    function test_withdrawERC721AssetsRevertsWhen_AttemptingToWithdrawOnAnUnsupportedRemoteChain()
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

        this.withdrawERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            address(this),
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID + 1, // unsupported remote chain
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality reverts when attempting to withdraw deposited ERC721 tokens that are not owned by the msg.sender.
    function test_withdrawERC721AssetsRevertsWhen_AttemptingToWithdrawSomeoneElsesDepositedTokens()
        public
    {
        vm.prank(msg.sender);
        this.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);

        vm.prank(msg.sender);
        this.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        uint256[] memory boredApeYachtClubTokenIds = new uint256[](1);

        boredApeYachtClubTokenIds[0] = 2;

        // escrowed ERC721 owners are stored in a mapping, so we need to compute the storage slot
        bytes32 escrowedERC721OwnerStorageSlot = keccak256(
            abi.encode(
                boredApeYachtClubTokenIds[0], // the deposited ERC721 token ID
                keccak256(
                    abi.encode(
                        BORED_APE_YACHT_CLUB, // the deposited ERC721 collection
                        uint256(PerpetualMintStorage.STORAGE_SLOT) + 17 // the escrowedERC721Owner mapping slot
                    )
                )
            )
        );

        // write the escrowed ERC721 owner to storage
        vm.store(
            address(l2AssetHandler),
            escrowedERC721OwnerStorageSlot,
            bytes32(bytes20(NON_OWNER_TEST_ADDRESS))
        );

        vm.expectRevert(IL2AssetHandler.ERC721TokenNotEscrowed.selector);

        this.withdrawERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            address(this),
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality reverts when LayerZero endpoint is not set.
    function test_withdrawERC721AssetsRevertsWhen_LayerZeroEndpointIsNotSet()
        public
    {
        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        this.withdrawERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            address(this),
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality reverts when LayerZero endpoint is set incorrectly.
    function test_withdrawERC721AssetsRevertsWhen_LayerZeroEndpointIsSetIncorrectly()
        public
    {
        vm.prank(msg.sender);
        this.setLayerZeroEndpoint(address(this)); // incorrect endpoint

        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        this.withdrawERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            address(this),
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality reverts when LayerZero message fee is not sent.
    function test_withdrawERC721AssetsRevertsWhen_LayerZeroMessageFeeIsNotSent()
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

        this.withdrawERC721Assets( // message fee not sent
            address(this),
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality reverts when LayerZero message fee sent is insufficient.
    function test_withdrawERC721AssetsRevertsWhen_LayerZeroMessageFeeSentIsInsufficient()
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

        this.withdrawERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE / 6 }( // insufficient message fee
            address(this),
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality reverts when LayerZero trusted remote address is not set.
    function test_withdrawERC721AssetsRevertsWhen_LayerZeroTrustedRemoteAddressIsNotSet()
        public
    {
        vm.prank(msg.sender);
        this.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);

        vm.expectRevert(
            ILayerZeroClientBaseInternal
                .LayerZeroClientBase__InvalidTrustedRemote
                .selector
        );

        this.withdrawERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            address(this),
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev tests that if there are pending mint requests withdrawing ERC721 assets reverts
    function test_withdrawERC721AssetsRevertsWhen_ThereIsAtLeastOnePendingRequest()
        public
    {
        uint256 mockMintRequestId = 5;

        // calculate pending enumerable set slot
        bytes32 pendingRequestsSlot = keccak256(
            abi.encode(
                BORED_APE_YACHT_CLUB, // address of collection
                uint256(PerpetualMintStorage.STORAGE_SLOT) + 28 // requestIds mapping storage slot
            )
        );

        // store EnumerableSet.UintSet._inner._values length
        vm.store(address(this), pendingRequestsSlot, bytes32(uint256(1)));

        // calculate the PerpetualMint unfulfilled request id slot
        bytes32 pendingRequestIdValueSlot = keccak256(
            abi.encodePacked(pendingRequestsSlot)
        );

        // store the mockMintRequestId in the pendingRequests enumerable set
        vm.store(
            address(this),
            pendingRequestIdValueSlot,
            bytes32(mockMintRequestId)
        );

        // calcaulte the PerpetualMint unfulfilled request id index slot
        bytes32 pendingRequestIdIndexSlot = keccak256(
            abi.encode(
                bytes32(mockMintRequestId),
                uint256(pendingRequestsSlot) + 1
            )
        );

        // store 1 as the index of mockMintRequestId
        vm.store(address(this), pendingRequestIdIndexSlot, bytes32(uint256(1)));

        vm.expectRevert(IGuardsInternal.PendingRequests.selector);

        this.withdrawERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            address(this),
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }
}
