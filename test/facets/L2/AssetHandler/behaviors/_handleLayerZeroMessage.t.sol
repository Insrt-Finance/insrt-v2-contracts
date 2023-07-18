// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { L2AssetHandlerTest } from "../AssetHandler.t.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { L2AssetHandlerMock } from "../../../../mocks/L2AssetHandlerMock.t.sol";
import { L2AssetHandlerStorage } from "../../../../../contracts/facets/L2/AssetHandler/Storage.sol";
import { PerpetualMintStorage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";
import { PayloadEncoder } from "../../../../../contracts/libraries/PayloadEncoder.sol";

/// @title L2AssetHandler_handleLayerZeroMessage
/// @dev L2AssetHandler test contract for testing expected L2 _handleLayerZeroMessage behavior. Tested on a Mainnet fork.
contract L2AssetHandler_handleLayerZeroMessage is
    L2AssetHandlerMock,
    L2AssetHandlerTest,
    L2ForkTest
{
    /// @dev Tests _handleLayerZeroMessage functionality for depositing ERC1155 tokens.
    function test_handleLayerZeroMessageERC1155Deposit() public {
        bytes memory encodedData = abi.encode(
            PayloadEncoder.AssetType.ERC1155,
            msg.sender,
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
                                msg.sender, // the depositor
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

        // this assertion proves that the deposited ERC1155 token amount was
        // set correctly for the depositor, collection, and the given token ID.
        assertEq(depositedERC1155TokenAmount, bongBearTokenAmounts[0]);

        // active ERC1155 owners are stored as an AddressSet in a mapping, so we need to compute the storage slot
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
                msg.sender, // the active ERC1155 token owner
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

        // this assertion proves that the active ERC1155 owner was added to the activeERC1155Owners AddressSet for the given token ID
        assertEq(
            address(
                uint160(uint256(activeERC1155OwnersValueAtAddressSetIndex))
            ),
            msg.sender
        );

        // active ERC1155 tokens are stored in a mapping, so we need to compute the storage slot
        bytes32 activeERC1155TokenAmountStorageSlot = keccak256(
            abi.encode(
                bongBearTokenIds[0], // the active ERC1155 token ID
                keccak256(
                    abi.encode(
                        BONG_BEARS, // the active ERC1155 token collection
                        keccak256(
                            abi.encode(
                                msg.sender, // the active ERC1155 token depositor
                                uint256(PerpetualMintStorage.STORAGE_SLOT) + 23 // the activeERC1155Tokens storage slot
                            )
                        )
                    )
                )
            )
        );

        bytes32 activeERC1155TokenAmount = vm.load(
            address(this),
            activeERC1155TokenAmountStorageSlot
        );

        // this assertion proves that the ERC1155 token amount was added to activeERC1155Tokens
        assertEq(uint256(activeERC1155TokenAmount), bongBearTokenAmounts[0]);

        // active token ids eligible to be minted are stored as a UintSet in a mapping, so we need to compute the storage slot
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

        bytes32 activeTokenIdValueAtUintSetIndex = vm.load(
            address(this),
            activeTokenIdValueAtUintSetIndexStorageSlot
        );

        // this assertion proves that the active token ID was added to the activeTokenIds UintSet
        assertEq(
            uint256(activeTokenIdValueAtUintSetIndex),
            bongBearTokenIds[0]
        );

        // depositor token risk values are stored in a mapping, so we need to compute the storage slot
        bytes32 depositorTokenRiskStorageSlot = keccak256(
            abi.encode(
                bongBearTokenIds[0], // the active ERC1155 token ID
                keccak256(
                    abi.encode(
                        BONG_BEARS, // the active ERC1155 token collection
                        keccak256(
                            abi.encode(
                                msg.sender, // the active ERC1155 token depositor
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

        // this assertion proves that the depositor token risk was added to depositorTokenRisk
        assertEq(depositorTokenRisk, testRisks[0]);

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
        assertEq(totalActiveTokens, bongBearTokenAmounts[0]);

        // the total risk for the depositor in the collection is stored in a mapping
        bytes32 totalDepositorRiskStorageSlot = keccak256(
            abi.encode(
                BONG_BEARS, // the active ERC1155 token collection
                keccak256(
                    abi.encode(
                        msg.sender, // the depositor
                        uint256(PerpetualMintStorage.STORAGE_SLOT) + 21 // the totalDepositorRisk storage slot
                    )
                )
            )
        );

        uint64 totalDepositorRisk = uint64(
            uint256(vm.load(address(this), totalDepositorRiskStorageSlot))
        );

        // this assertion proves that the total risk for the depositor in the collection was updated correctly
        assertEq(totalDepositorRisk, testRisks[0] * bongBearTokenAmounts[0]);

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
        assertEq(totalRisk, testRisks[0] * bongBearTokenAmounts[0]);

        // the total risk for the token ID in the collection is stored in a mapping
        bytes32 totalTokenRiskStorageSlot = keccak256(
            abi.encode(
                bongBearTokenIds[0], // the active ERC1155 token ID
                keccak256(
                    abi.encode(
                        BONG_BEARS, // the active ERC1155 token collection
                        uint256(PerpetualMintStorage.STORAGE_SLOT) + 15 // the totalTokenRisk storage slot
                    )
                )
            )
        );

        uint64 totalTokenRisk = uint64(
            uint256(vm.load(address(this), totalTokenRiskStorageSlot))
        );

        // this assertion proves that the total risk for the token ID in the collection was updated correctly
        assertEq(totalTokenRisk, testRisks[0] * bongBearTokenAmounts[0]);

        // the set of active collections is stored in an AddressSet data structure
        // this slot defaults to the storage slot of the AddressSet._values array length
        bytes32 activeCollectionsSetStorageSlot = bytes32(
            uint256(PerpetualMintStorage.STORAGE_SLOT) + 3 // the activeCollections storage slot
        );

        bytes32 activeCollectionsSetIndexStorageSlot = keccak256(
            abi.encode(
                BONG_BEARS, // the active ERC1155 token collection
                uint256(activeCollectionsSetStorageSlot) + 1 // Set.inner._indexes storage slot
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

        // this assertion proves that the collection was added to the set of active collections
        assertEq(
            address(uint160(uint256(activeCollectionsValueAtSetIndex))),
            BONG_BEARS
        );
    }

    /// @dev Tests that _handleLayerZeroMessage emits an ERC1155AssetsDeposited event when depositing ERC1155 tokens.
    function test_handleLayerZeroMessageERC1155DepositEmitsERC1155AssetsDepositedEvent()
        public
    {
        bytes memory encodedData = abi.encode(
            PayloadEncoder.AssetType.ERC1155,
            msg.sender,
            BONG_BEARS,
            testRisks,
            bongBearTokenIds,
            bongBearTokenAmounts
        );

        vm.expectEmit();
        emit ERC1155AssetsDeposited(
            msg.sender,
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
    }

    /// @dev Tests _handleLayerZeroMessage functionality for depositing ERC721 tokens.
    function test_handleLayerZeroMessageERC721Deposit() public {
        bytes memory encodedData = abi.encode(
            PayloadEncoder.AssetType.ERC721,
            msg.sender,
            BORED_APE_YACHT_CLUB,
            testRisks,
            boredApeYachtClubTokenIds
        );

        // record the storage slot of the deposited ERC721 token ID
        vm.record();

        this.mock_HandleLayerZeroMessage(
            DESTINATION_LAYER_ZERO_CHAIN_ID, // would be the expected source chain ID in production, here this is a dummy value
            TEST_PATH, // would be the expected path in production, here this is a dummy value
            TEST_NONCE, // dummy nonce value
            encodedData
        );

        // access the storage slot of the deposited ERC721 token ID via storageWrites
        (, bytes32[] memory storageWrites) = vm.accesses(address(this));

        uint256 depositedERC721TokenId = uint256(
            vm.load(address(this), storageWrites[0])
        );

        assertEq(depositedERC721TokenId, boredApeYachtClubTokenIds[0]);
    }

    /// @dev Tests that _handleLayerZeroMessage emits an ERC721AssetsDeposited event when depositing ERC721 tokens.
    function test_handleLayerZeroMessageERC721DepositEmitsERC721AssetsDepositedEvent()
        public
    {
        bytes memory encodedData = abi.encode(
            PayloadEncoder.AssetType.ERC721,
            msg.sender,
            BORED_APE_YACHT_CLUB,
            testRisks,
            boredApeYachtClubTokenIds
        );

        vm.expectEmit();
        emit ERC721AssetsDeposited(
            msg.sender,
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
    }

    /// @dev Tests that _handleLayerZeroMessage reverts when an invalid asset type is received.
    function test_handleLayerZeroMessageRevertsWhenInvalidAssetTypeIsReceived()
        public
    {
        bytes memory encodedData = abi.encode(
            bytes32(uint256(2)), // invalid asset type
            msg.sender,
            BONG_BEARS,
            testRisks,
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
