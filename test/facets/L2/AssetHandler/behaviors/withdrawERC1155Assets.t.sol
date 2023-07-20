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

        // the deposited ERC1155 token amount is stored in a mapping
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

        // this assertion proves that the deposited ERC1155 token amount was decremented correctly.
        assertEq(depositedERC1155TokenAmount, 0);

        // active ERC1155 tokens are stored in a mapping
        bytes32 activeERC1155TokenAmountStorageSlot = keccak256(
            abi.encode(
                bongBearTokenIds[0], // the active ERC1155 token ID
                keccak256(
                    abi.encode(
                        BONG_BEARS, // the active ERC1155 token collection
                        keccak256(
                            abi.encode(
                                address(this), // the active ERC1155 token depositor
                                uint256(PerpetualMintStorage.STORAGE_SLOT) + 23 // the activeERC1155Tokens storage slot
                            )
                        )
                    )
                )
            )
        );

        uint256 activeERC1155TokenAmount = uint256(
            vm.load(address(this), activeERC1155TokenAmountStorageSlot)
        );

        // this assertion proves that the active ERC1155 token amount was decremented correctly.
        assertEq(activeERC1155TokenAmount, 0);

        if (activeERC1155TokenAmount == 0) {
            // active ERC1155 owners are stored as an AddressSet in a mapping
            // this slot defaults to the storage slot of the AddressSet._inner._values array length
            bytes32 activeERC1155OwnersAddressSetStorageSlot = keccak256(
                abi.encode(
                    bongBearTokenIds[0], // the active ERC1155 token ID
                    keccak256(
                        abi.encode(
                            BONG_BEARS, // the active ERC1155 token collection
                            uint256(PerpetualMintStorage.STORAGE_SLOT) + 16 // the activeERC1155Owners storage slot
                        )
                    )
                )
            );

            bytes32 activeERC1155OwnersAddressSetIndexStorageSlot = keccak256(
                abi.encode(
                    address(this), // the active ERC1155 token owner
                    uint256(activeERC1155OwnersAddressSetStorageSlot) + 1 // AddressSet._inner._indexes storage slot
                )
            );

            bytes32 activeERC1155OwnersAddressSetIndex = vm.load(
                address(this),
                activeERC1155OwnersAddressSetIndexStorageSlot
            );

            bytes32 activeERC1155OwnersValueAtAddressSetIndexStorageSlot = keccak256(
                    abi.encode(
                        uint256(activeERC1155OwnersAddressSetStorageSlot) +
                            // add index to storage slot to get the storage slot of the value at the index
                            uint256(activeERC1155OwnersAddressSetIndex) -
                            // subtract 1 to convert to zero-indexing
                            1
                    )
                );

            bytes32 activeERC1155OwnersValueAtAddressSetIndex = vm.load(
                address(this),
                activeERC1155OwnersValueAtAddressSetIndexStorageSlot
            );

            // this assertion proves that the ERC1155 owner was removed from the activeERC1155Owners AddressSet for the given token ID
            assertEq(
                address(
                    uint160(uint256(activeERC1155OwnersValueAtAddressSetIndex))
                ),
                address(0)
            );

            uint256 activeERC1155OwnersAddressSet = uint256(
                vm.load(address(this), activeERC1155OwnersAddressSetStorageSlot)
            );

            if (activeERC1155OwnersAddressSet == 0) {
                // active token ids eligible to be minted are stored as a UintSet in a mapping
                // this slot defaults to the storage slot of the UintSet._inner._values array length
                bytes32 activeTokenIdsUintSetStorageSlot = keccak256(
                    abi.encode(
                        BONG_BEARS, // the active ERC1155 token collection
                        uint256(PerpetualMintStorage.STORAGE_SLOT) + 11 // the activeTokenIds storage slot
                    )
                );

                bytes32 activeTokenIdUintSetIndexStorageSlot = keccak256(
                    abi.encode(
                        bongBearTokenIds[0], // the active ERC1155 token ID
                        uint256(activeTokenIdsUintSetStorageSlot) + 1 // UintSet._inner._indexes storage slot
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
                    vm.load(
                        address(this),
                        activeTokenIdValueAtUintSetIndexStorageSlot
                    )
                );

                // this assertion proves that the active token ID was removed from the activeTokenIds UintSet
                assertEq(activeTokenIdValueAtUintSetIndex, 0);
            }

            // depositor token risk values are stored in a mapping
            bytes32 depositorTokenRiskStorageSlot = keccak256(
                abi.encode(
                    bongBearTokenIds[0], // the active ERC1155 token ID
                    keccak256(
                        abi.encode(
                            BONG_BEARS, // the active ERC1155 token collection
                            keccak256(
                                abi.encode(
                                    address(this), // the active ERC1155 token depositor
                                    uint256(PerpetualMintStorage.STORAGE_SLOT) +
                                        22 // the depositorTokenRisk storage slot
                                )
                            )
                        )
                    )
                )
            );

            uint64 depositorTokenRisk = uint64(
                uint256(vm.load(address(this), depositorTokenRiskStorageSlot))
            );

            // this assertion proves that the depositor token risk was reset 0 in depositorTokenRisk
            assertEq(depositorTokenRisk, 0);
        }

        // the total number of active tokens in the collection is stored in a mapping
        bytes32 totalActiveTokenAmountStorageSlot = keccak256(
            abi.encode(
                BONG_BEARS, // the active ERC1155 token collection
                uint256(PerpetualMintStorage.STORAGE_SLOT) + 10 // the totalActiveTokens storage slot
            )
        );

        uint256 totalActiveTokens = uint256(
            vm.load(address(this), totalActiveTokenAmountStorageSlot)
        );

        // this assertion proves that the total number of active tokens in the collection was updated correctly
        assertEq(totalActiveTokens, 0);

        // the total risk for the depositor in the collection is stored in a mapping
        bytes32 totalDepositorRiskStorageSlot = keccak256(
            abi.encode(
                BONG_BEARS, // the active ERC1155 token collection
                keccak256(
                    abi.encode(
                        address(this), // the depositor
                        uint256(PerpetualMintStorage.STORAGE_SLOT) + 21 // the totalDepositorRisk storage slot
                    )
                )
            )
        );

        uint64 totalDepositorRisk = uint64(
            uint256(
                uint256(vm.load(address(this), totalDepositorRiskStorageSlot))
            )
        );

        // this assertion proves that the total risk for the depositor in the collection was updated correctly
        assertEq(totalDepositorRisk, 0);

        // the total risk for the depositor in the collection is stored in a mapping
        bytes32 totalRiskStorageSlot = keccak256(
            abi.encode(
                BONG_BEARS,
                uint256(PerpetualMintStorage.STORAGE_SLOT) + 9 // the totalRisk storage slot
            )
        );

        uint64 totalRisk = uint64(
            uint256(vm.load(address(this), totalRiskStorageSlot))
        );

        // this assertion proves that the total risk in the collection was updated correctly
        assertEq(totalRisk, 0);

        // the total risk for the token ID in the collection is stored in a mapping
        bytes32 tokenRiskStorageSlot = keccak256(
            abi.encode(
                bongBearTokenIds[0], // the active ERC1155 token ID
                keccak256(
                    abi.encode(
                        BONG_BEARS, // the active ERC1155 token collection
                        uint256(PerpetualMintStorage.STORAGE_SLOT) + 12 // the tokenRisk storage slot
                    )
                )
            )
        );

        uint64 tokenRisk = uint64(
            uint256(vm.load(address(this), tokenRiskStorageSlot))
        );

        // this assertion proves that the total risk for the token ID in the collection was updated correctly
        assertEq(tokenRisk, 0);

        if (totalActiveTokens == 0) {
            // the set of active collections is stored in an AddressSet data structure
            // this slot defaults to the storage slot of the AddressSet._values array length
            bytes32 activeCollectionsSetStorageSlot = bytes32(
                uint256(PerpetualMintStorage.STORAGE_SLOT) + 3 // the activeCollections storage slot
            );

            bytes32 activeCollectionsSetIndexStorageSlot = keccak256(
                abi.encode(
                    BONG_BEARS, // the active ERC1155 token collection
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
