// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { L2AssetHandlerTest } from "../AssetHandler.t.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { L2AssetHandlerMock } from "../../../../mocks/L2AssetHandlerMock.t.sol";
import { AssetType } from "../../../../../contracts/enums/AssetType.sol";
import { IGuardsInternal } from "../../../../../contracts/facets/L2/common/IGuardsInternal.sol";
import { PerpetualMintStorage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";

/// @title L2AssetHandler_handleLayerZeroMessage
/// @dev L2AssetHandler test contract for testing expected L2 _handleLayerZeroMessage behavior. Tested on an Arbitrum fork.
contract L2AssetHandler_handleLayerZeroMessage is
    L2AssetHandlerMock,
    L2AssetHandlerTest,
    L2ForkTest
{
    /// @dev Tests _handleLayerZeroMessage functionality for depositing ERC1155 tokens.
    function test_handleLayerZeroMessageERC1155Deposit() public {
        bytes memory encodedData = abi.encode(
            AssetType.ERC1155,
            msg.sender,
            BONG_BEARS,
            msg.sender,
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

        address[] memory activeERC1155Owners = _activeERC1155Owners(
            address(this),
            BONG_BEARS,
            bongBearTokenIds[0]
        );

        // this assertion proves that the active ERC1155 owner was added to the activeERC1155Owners AddressSet for the given token ID
        assertEq(activeERC1155Owners[0], msg.sender);

        uint256 activeERC1155TokenAmount = _activeERC1155Tokens(
            address(this),
            msg.sender,
            BONG_BEARS,
            bongBearTokenIds[0]
        );

        // this assertion proves that the ERC1155 token amount was added to activeERC1155Tokens
        assertEq(activeERC1155TokenAmount, bongBearTokenAmounts[0]);

        uint256[] memory activeTokenIds = _activeTokenIds(
            address(this),
            BONG_BEARS
        );

        // this assertion proves that the active token ID was added to the activeTokenIds UintSet
        assertEq(activeTokenIds[0], bongBearTokenIds[0]);

        uint256 depositorTokenRisk = _depositorTokenRisk(
            address(this),
            msg.sender,
            BONG_BEARS,
            bongBearTokenIds[0]
        );

        // this assertion proves that the depositor token risk was added to depositorTokenRisk
        assertEq(depositorTokenRisk, testRisks[0]);

        uint256 totalActiveTokens = _totalActiveTokens(
            address(this),
            BONG_BEARS
        );

        // this assertion proves that the total number of active tokens in the collection was updated correctly
        assertEq(totalActiveTokens, bongBearTokenAmounts[0]);

        uint256 totalDepositorRisk = _totalDepositorRisk(
            address(this),
            msg.sender,
            BONG_BEARS
        );

        // this assertion proves that the total risk for the depositor in the collection was updated correctly
        assertEq(totalDepositorRisk, testRisks[0] * bongBearTokenAmounts[0]);

        uint256 totalRisk = _totalRisk(address(this), BONG_BEARS);

        // this assertion proves that the total risk in the collection was updated correctly
        assertEq(totalRisk, testRisks[0] * bongBearTokenAmounts[0]);

        uint256 tokenRisk = _tokenRisk(
            address(this),
            BONG_BEARS,
            bongBearTokenIds[0]
        );

        // this assertion proves that the total risk for the token ID in the collection was updated correctly
        assertEq(tokenRisk, testRisks[0] * bongBearTokenAmounts[0]);

        address[] memory activeCollections = _activeCollections(address(this));

        // this assertion proves that the collection was added to the set of active collections
        assertEq(activeCollections[0], BONG_BEARS);

        AssetType collectionType = _collectionType(address(this), BONG_BEARS);

        assert(collectionType == AssetType.ERC1155);
    }

    /// @dev Tests that _handleLayerZeroMessage emits an ERC1155AssetsDeposited event when depositing ERC1155 tokens.
    function test_handleLayerZeroMessageERC1155DepositEmitsERC1155AssetsDepositedEvent()
        public
    {
        bytes memory encodedData = abi.encode(
            AssetType.ERC1155,
            msg.sender,
            BONG_BEARS,
            msg.sender,
            testRisks,
            bongBearTokenIds,
            bongBearTokenAmounts
        );

        vm.expectEmit();
        emit ERC1155AssetsDeposited(
            msg.sender,
            BONG_BEARS,
            msg.sender,
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
            AssetType.ERC721,
            msg.sender,
            BORED_APE_YACHT_CLUB,
            msg.sender,
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
        assertEq(escrowedERC721Owner, msg.sender);

        uint256[] memory activeTokenIds = _activeTokenIds(
            address(this),
            BORED_APE_YACHT_CLUB
        );

        // this assertion proves that the token ID was added to the set of active token IDs in the collection
        assertEq(activeTokenIds[0], boredApeYachtClubTokenIds[0]);

        uint256 activeTokensCount = _totalActiveTokens(
            address(this),
            BORED_APE_YACHT_CLUB
        );

        // this assertion proves that the count of active tokens for the depositor in the collection was incremented correctly
        assertEq(activeTokensCount, boredApeYachtClubTokenIds.length);

        uint256 tokenRisk = _tokenRisk(
            address(this),
            BORED_APE_YACHT_CLUB,
            boredApeYachtClubTokenIds[0]
        );

        // this assertion proves that the risk for the token ID in the collection was incremented correctly
        assertEq(tokenRisk, testRisks[0]);

        uint256 totalActiveTokens = _totalActiveTokens(
            address(this),
            BORED_APE_YACHT_CLUB
        );

        // this assertion proves that the total number of active tokens in the collection was incremented correctly
        assertEq(totalActiveTokens, boredApeYachtClubTokenIds.length);

        uint256 totalDepositorRisk = _totalDepositorRisk(
            address(this),
            msg.sender,
            BORED_APE_YACHT_CLUB
        );

        // this assertion proves that the total risk for the depositor in the collection was incremented correctly
        assertEq(
            totalDepositorRisk,
            testRisks[0] * boredApeYachtClubTokenIds.length
        );

        uint256 totalRisk = _totalRisk(address(this), BORED_APE_YACHT_CLUB);

        // this assertion proves that the total risk in the collection was incremented correctly
        assertEq(totalRisk, testRisks[0] * boredApeYachtClubTokenIds.length);

        address[] memory activeCollections = _activeCollections(address(this));

        // this assertion proves that the collection was added to the set of active collections
        assertEq(activeCollections[0], BORED_APE_YACHT_CLUB);

        AssetType collectionType = _collectionType(
            address(this),
            BORED_APE_YACHT_CLUB
        );

        assert(collectionType == AssetType.ERC721);
    }

    /// @dev Tests that _handleLayerZeroMessage emits an ERC721AssetsDeposited event when depositing ERC721 tokens.
    function test_handleLayerZeroMessageERC721DepositEmitsERC721AssetsDepositedEvent()
        public
    {
        bytes memory encodedData = abi.encode(
            AssetType.ERC721,
            msg.sender,
            BORED_APE_YACHT_CLUB,
            msg.sender,
            testRisks,
            boredApeYachtClubTokenIds
        );

        vm.expectEmit();
        emit ERC721AssetsDeposited(
            msg.sender,
            BORED_APE_YACHT_CLUB,
            msg.sender,
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
    function test_handleLayerZeroMessageRevertsWhen_InvalidAssetTypeIsReceived()
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

    function test_handleLayerZeroMessageRevertsWhen_TokenAmountsExceedMaxActiveTokens()
        public
    {
        // set maxActiveTokens value to something which will cause a revert
        vm.store(
            address(this),
            bytes32(uint256(PerpetualMintStorage.STORAGE_SLOT) + 27),
            bytes32(0)
        );

        bytes memory encodedData = abi.encode(
            AssetType.ERC1155,
            msg.sender,
            BONG_BEARS,
            msg.sender,
            testRisks,
            bongBearTokenIds,
            bongBearTokenAmounts
        );

        vm.expectRevert(IGuardsInternal.MaxActiveTokensLimitExceeded.selector);
        this.mock_HandleLayerZeroMessage(
            DESTINATION_LAYER_ZERO_CHAIN_ID, // would be the expected source chain ID in production, here this is a dummy value
            TEST_PATH, // would be the expected path in production, here this is a dummy value
            TEST_NONCE, // dummy nonce value
            encodedData
        );

        encodedData = abi.encode(
            AssetType.ERC721,
            msg.sender,
            BORED_APE_YACHT_CLUB,
            msg.sender,
            testRisks,
            boredApeYachtClubTokenIds
        );

        vm.expectRevert(IGuardsInternal.MaxActiveTokensLimitExceeded.selector);
        this.mock_HandleLayerZeroMessage(
            DESTINATION_LAYER_ZERO_CHAIN_ID, // would be the expected source chain ID in production, here this is a dummy value
            TEST_PATH, // would be the expected path in production, here this is a dummy value
            TEST_NONCE, // dummy nonce value
            encodedData
        );
    }
}
