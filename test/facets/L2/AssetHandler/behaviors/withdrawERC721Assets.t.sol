// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { ILayerZeroClientBaseInternal } from "@solidstate/layerzero-client/base/ILayerZeroClientBaseInternal.sol";
import { ILayerZeroEndpoint } from "@solidstate/layerzero-client/interfaces/ILayerZeroEndpoint.sol";

import { L2AssetHandlerTest } from "../AssetHandler.t.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { L2AssetHandlerMock } from "../../../../mocks/L2AssetHandlerMock.t.sol";
import { IL2AssetHandler } from "../../../../../contracts/facets/L2/AssetHandler/IAssetHandler.sol";
import { L2AssetHandlerStorage } from "../../../../../contracts/facets/L2/AssetHandler/Storage.sol";
import { PerpetualMintStorage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";
import { PayloadEncoder } from "../../../../../contracts/libraries/PayloadEncoder.sol";

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
            PayloadEncoder.AssetType.ERC721,
            address(this),
            BORED_APE_YACHT_CLUB,
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
            PayloadEncoder.AssetType.ERC721,
            address(this),
            BORED_APE_YACHT_CLUB,
            testRisks,
            boredApeYachtClubTokenIds
        );

        this.mock_HandleLayerZeroMessage(
            DESTINATION_LAYER_ZERO_CHAIN_ID, // would be the expected source chain ID in production, here this is a dummy value
            TEST_PATH, // would be the expected path in production, here this is a dummy value
            TEST_NONCE, // dummy nonce value
            encodedData
        );

        // the deposited ERC721 token deposited boolean is stored in a mapping, so we need to compute the storage slot
        bytes32 depositedERC721TokenDepositedStorageSlot = keccak256(
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

        uint256 depositedERC721TokenDeposited = uint256(
            vm.load(address(this), depositedERC721TokenDepositedStorageSlot)
        );

        // mappings are hash tables, so this assertion proves that the deposited ERC721 token deposited boolean
        // was set correctly for the depositor, collection, and the given token ID.
        assertEq(depositedERC721TokenDeposited, 1); // 1 is true
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
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );

        // the deposited ERC721 token deposited boolean is stored in a mapping, so we need to compute the storage slot
        bytes32 depositedERC721TokenDepositedStorageSlot = keccak256(
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

        uint256 depositedERC721TokenDeposited = uint256(
            vm.load(address(this), depositedERC721TokenDepositedStorageSlot)
        );

        // this assertion proves that the deposited ERC721 token deposited boolean
        // was updated correctly for the depositor, collection, and the given token ID.
        assertEq(depositedERC721TokenDeposited, 0); // 0 is false

        // the active token IDs in the collection is stored in a UintSet data structure
        // this slot defaults to the storage slot of the UintSet._values array length
        bytes32 activeTokenIdsUintSetStorageSlot = keccak256(
            abi.encode(
                BORED_APE_YACHT_CLUB, // the active ERC721 token collection
                uint256(PerpetualMintStorage.STORAGE_SLOT) + 11 // the activeTokenIds storage slot
            )
        );

        bytes32 activeTokenIdUintSetIndexStorageSlot = keccak256(
            abi.encode(
                boredApeYachtClubTokenIds[0], // the active ERC721 token ID
                uint256(activeTokenIdsUintSetStorageSlot) + 1 // Set._inner._indexes storage slot
            )
        );

        bytes32 activeTokenIdUintSetIndex = vm.load(
            address(this),
            activeTokenIdUintSetIndexStorageSlot
        );

        bytes32 activeTokenIdValueAtUintSetIndexStorageSlot = keccak256(
            abi.encode(
                uint256(activeTokenIdsUintSetStorageSlot) +
                    // add index to storage slot to get the storage slot of the value at the index
                    uint256(activeTokenIdUintSetIndex) -
                    // subtract 1 to convert to zero-indexing
                    1
            )
        );

        uint256 activeTokenIdValueAtUintSetIndex = uint256(
            vm.load(address(this), activeTokenIdValueAtUintSetIndexStorageSlot)
        );

        // this assertion proves that the token ID was removed from the set of active token IDs in the collection
        assertEq(activeTokenIdValueAtUintSetIndex, 0);

        // the count of active tokens for the depositor in the collection is stored in a mapping
        bytes32 activeTokensCountStorageSlot = keccak256(
            abi.encode(
                BORED_APE_YACHT_CLUB, // the active ERC721 token collection
                keccak256(
                    abi.encode(
                        address(this), // the depositor
                        uint256(PerpetualMintStorage.STORAGE_SLOT) + 19 // the activeTokens storage slot
                    )
                )
            )
        );

        uint256 activeTokensCount = uint256(
            vm.load(address(this), activeTokensCountStorageSlot)
        );

        // this assertion proves that the count of active tokens for the depositor in the collection was decremented correctly
        assertEq(activeTokensCount, 0);

        // the risk for the depositor and the token ID in the collection is stored in a mapping
        bytes32 depositorTokenRiskStorageSlot = keccak256(
            abi.encode(
                boredApeYachtClubTokenIds[0], // the active ERC721 token ID
                keccak256(
                    abi.encode(
                        BORED_APE_YACHT_CLUB, // the active ERC721 token collection
                        keccak256(
                            abi.encode(
                                address(this), // the depositor
                                uint256(PerpetualMintStorage.STORAGE_SLOT) + 22 // the depositorTokenRisk storage slot
                            )
                        )
                    )
                )
            )
        );

        uint64 depositorTokenRisk = uint64(
            uint256(vm.load(address(this), depositorTokenRiskStorageSlot))
        );

        // this assertion proves that the risk for the depositor and the token ID in the collection was reset correctly
        assertEq(depositorTokenRisk, 0);

        // the risk for the token ID in the collection is stored in a mapping
        bytes32 tokenRiskStorageSlot = keccak256(
            abi.encode(
                boredApeYachtClubTokenIds[0], // the active ERC721 token ID
                keccak256(
                    abi.encode(
                        BORED_APE_YACHT_CLUB, // the active ERC721 token collection
                        uint256(PerpetualMintStorage.STORAGE_SLOT) + 12 // the tokenRisk storage slot
                    )
                )
            )
        );

        uint64 tokenRisk = uint64(
            uint256(vm.load(address(this), tokenRiskStorageSlot))
        );

        // this assertion proves that the risk for the token ID in the collection was decremented correctly
        assertEq(tokenRisk, 0);

        // the total number of active tokens in the collection is stored in a mapping
        bytes32 totalActiveTokensStorageSlot = keccak256(
            abi.encode(
                BORED_APE_YACHT_CLUB, // the active ERC721 token collection
                uint256(PerpetualMintStorage.STORAGE_SLOT) + 10 // the totalActiveTokens storage slot
            )
        );

        uint256 totalActiveTokens = uint256(
            vm.load(address(this), totalActiveTokensStorageSlot)
        );

        // this assertion proves that the total number of active tokens in the collection was decremented correctly
        assertEq(totalActiveTokens, 0);

        // the total risk for the depositor in the collection is stored in a mapping
        bytes32 totalDepositorRiskStorageSlot = keccak256(
            abi.encode(
                BORED_APE_YACHT_CLUB, // the active ERC721 token collection
                keccak256(
                    abi.encode(
                        address(this), // the depositor
                        uint256(PerpetualMintStorage.STORAGE_SLOT) + 21 // the totalDepositorRisk storage slot
                    )
                )
            )
        );

        uint64 totalDepositorRisk = uint64(
            uint256(vm.load(address(this), totalDepositorRiskStorageSlot))
        );

        // this assertion proves that the total risk for the depositor in the collection was decremented correctly
        assertEq(totalDepositorRisk, 0);

        // the total risk in the collection is stored in a mapping
        bytes32 totalRiskStorageSlot = keccak256(
            abi.encode(
                BORED_APE_YACHT_CLUB, // the active ERC721 token collection
                uint256(PerpetualMintStorage.STORAGE_SLOT) + 9 // the totalRisk storage slot
            )
        );

        uint64 totalRisk = uint64(
            uint256(vm.load(address(this), totalRiskStorageSlot))
        );

        // this assertion proves that the total risk in the collection was decremented correctly
        assertEq(totalRisk, 0);

        if (totalActiveTokens == 0) {
            // the set of active collections is stored in an AddressSet data structure
            // this slot defaults to the storage slot of the AddressSet._values array length
            bytes32 activeCollectionsSetStorageSlot = bytes32(
                uint256(PerpetualMintStorage.STORAGE_SLOT) + 3 // the activeCollections storage slot
            );

            bytes32 activeCollectionsSetIndexStorageSlot = keccak256(
                abi.encode(
                    BORED_APE_YACHT_CLUB, // the active ERCE721 token collection
                    uint256(activeCollectionsSetStorageSlot) + 1 // Set._inner._indexes storage slot
                )
            );

            bytes32 activeCollectionsSetIndex = vm.load(
                address(this),
                activeCollectionsSetIndexStorageSlot
            );

            bytes32 activeCollectionsValueAtSetIndexStorageSlot = keccak256(
                abi.encode(
                    uint256(activeCollectionsSetStorageSlot) +
                        // add index to storage slot to get the storage slot of the value at the index
                        uint256(activeCollectionsSetIndex) -
                        // subtract 1 to convert to zero-indexing
                        1
                )
            );

            bytes32 activeCollectionsValueAtSetIndex = vm.load(
                address(this),
                activeCollectionsValueAtSetIndexStorageSlot
            );

            // this assertion proves that the collection was removed from the set of active collections
            assertEq(
                address(uint160(uint256(activeCollectionsValueAtSetIndex))),
                address(0)
            );
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
            boredApeYachtClubTokenIds
        );

        this.withdrawERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
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
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality reverts when attempting to withdraw more ERC721 tokens than the msg.sender has deposited.
    function test_withdrawERC721AssetsRevertsWhenAttemptingToUndepositMoreThanDepositedAmount()
        public
    {
        vm.prank(msg.sender);
        this.setLayerZeroEndpoint(ARBITRUM_LAYER_ZERO_ENDPOINT);

        vm.prank(msg.sender);
        this.setLayerZeroTrustedRemoteAddress(
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            TRUSTED_REMOTE_ADDRESS_TEST_ADDRESS_IN_BYTES
        );

        vm.expectRevert(IL2AssetHandler.ERC721TokenNotDeposited.selector);

        boredApeYachtClubTokenIds.push(2);

        this.withdrawERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality reverts when attempting to withdraw ERC721 tokens on an unsupported remote chain.
    function test_withdrawERC721AssetsRevertsWhenAttemptingToUndepositOnAnUnsupportedRemoteChain()
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
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID + 1, // unsupported remote chain
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality reverts when attempting to withdraw deposited ERC721 tokens that are not owned by the msg.sender.
    function test_withdrawERC721AssetsRevertsWhenAttemptingToUndepositSomeoneElsesDepositedTokens()
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

        this.withdrawERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
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

        this.withdrawERC721Assets{ value: LAYER_ZERO_MESSAGE_FEE }(
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality reverts when LayerZero endpoint is set incorrectly.
    function test_withdrawERC721AssetsRevertsWhenLayerZeroEndpointIsSetIncorrectly()
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
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality reverts when LayerZero message fee is not sent.
    function test_withdrawERC721AssetsRevertsWhenLayerZeroMessageFeeIsNotSent()
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
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality reverts when LayerZero message fee sent is insufficient.
    function test_withdrawERC721AssetsRevertsWhenLayerZeroMessageFeeSentIsInsufficient()
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
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }

    /// @dev Tests that withdrawERC721Assets functionality reverts when LayerZero trusted remote address is not set.
    function test_withdrawERC721AssetsRevertsWhenLayerZeroTrustedRemoteAddressIsNotSet()
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
            BORED_APE_YACHT_CLUB,
            DESTINATION_LAYER_ZERO_CHAIN_ID,
            boredApeYachtClubTokenIds
        );
    }
}
