// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";

/// @title PerpetualMint_assignEscrowedERC721Asset
/// @dev PerpetualMint test contract for testing expected behavior of the assignEscrowedERC721Asset function
contract PerpetualMint_assignEscrowedERC721Asset is
    IPerpetualMintInternal,
    PerpetualMintTest,
    L2ForkTest
{
    //set the contex of which collection will be used in the test suite
    address internal constant COLLECTION = BORED_APE_YACHT_CLUB;

    /// @dev tokenId of ERC721 asset to be transferred
    uint256 tokenId;

    /// @dev risk of token set by depositor prior to transfer
    uint256 tokenRisk;

    uint256 internal constant COLLECTION_EARNINGS = 1 ether;

    // grab BAYC collection earnings storage slot
    bytes32 internal constant collectionEarningsStorageSlot =
        keccak256(
            abi.encode(
                COLLECTION, // the ERC721 collection
                uint256(Storage.STORAGE_SLOT) + 9 // the collectionEarnings storage slot
            )
        );

    /// @dev set up the context for testing
    function setUp() public override {
        super.setUp();

        depositBoredApeYachtClubAssetsMock();

        // instantiate variables used in testing
        tokenId = BORED_APE_YACHT_CLUB_TOKEN_ID_ONE;
        tokenRisk = _tokenRisk(address(perpetualMint), COLLECTION, tokenId);

        vm.store( // overwrite storage
            address(perpetualMint),
            collectionEarningsStorageSlot,
            bytes32(COLLECTION_EARNINGS)
        );
    }

    /// @dev tests that depositor earnings of 'oldOwner' are updated correclty after win
    function test_assignEscrowedERC721AssetUpdatesDepositorEarningsOfOldOwner()
        public
    {
        uint256 totalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );
        assert(totalDepositorRisk != 0);
        assert(_totalRisk(address(perpetualMint), COLLECTION) != 0);

        uint256 currentEarnings = _collectionEarnings(
            address(perpetualMint),
            COLLECTION
        );
        uint256 lastEarnings = _lastCollectionEarnings(
            address(perpetualMint),
            COLLECTION
        );
        uint256 baseMultiplier = (currentEarnings - lastEarnings) /
            _totalRisk(address(perpetualMint), COLLECTION);

        uint256 oldDepositorEarnings = _depositorEarnings(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );
        uint256 multiplierOffset = _multiplierOffset(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        uint256 expectedEarnings = (baseMultiplier - multiplierOffset) *
            totalDepositorRisk;

        perpetualMint.exposed_assignEscrowedERC721Asset(
            minter,
            COLLECTION,
            tokenId
        );

        assert(
            expectedEarnings + oldDepositorEarnings ==
                _depositorEarnings(
                    address(perpetualMint),
                    depositorOne,
                    COLLECTION
                )
        );

        assert(
            baseMultiplier ==
                _baseMultiplier(address(perpetualMint), COLLECTION)
        );

        assert(
            currentEarnings ==
                _lastCollectionEarnings(address(perpetualMint), COLLECTION)
        );
    }

    /// @dev tests that the depositor earnings of the 'newOwner' are updated correctly when they have no
    /// previous deposits in that collection, so no risk
    function test_assignEscrowedERC721AssetUpdatesDepositorEarningsOfNewOwnerWhenNewOwnerHasNoRisk()
        public
    {
        uint256 currentEarnings = _collectionEarnings(
            address(perpetualMint),
            COLLECTION
        );
        uint256 lastEarnings = _lastCollectionEarnings(
            address(perpetualMint),
            COLLECTION
        );
        uint256 baseMultiplier = (currentEarnings - lastEarnings) /
            _totalRisk(address(perpetualMint), COLLECTION);

        perpetualMint.exposed_assignEscrowedERC721Asset(
            minter,
            COLLECTION,
            tokenId
        );

        assert(
            baseMultiplier ==
                _baseMultiplier(address(perpetualMint), COLLECTION)
        );

        assert(
            currentEarnings ==
                _lastCollectionEarnings(address(perpetualMint), COLLECTION)
        );
    }

    /// @dev tests that the depositor earnings of the 'newOwner' are updated correctly when they have
    /// previous deposits in that collection, so has risk
    function test_assignEscrowedERC721AssetUpdatesDepositorEarningsOfNewOwnerWhenNewOwnerHasRisk()
        public
    {
        uint256 currentEarnings = _collectionEarnings(
            address(perpetualMint),
            COLLECTION
        );
        uint256 lastEarnings = _lastCollectionEarnings(
            address(perpetualMint),
            COLLECTION
        );
        uint256 baseMultiplier = (currentEarnings - lastEarnings) /
            _totalRisk(address(perpetualMint), COLLECTION);

        uint256 oldDepositorEarnings = _depositorEarnings(
            address(perpetualMint),
            depositorTwo,
            COLLECTION
        );

        uint256 multiplierOffset = _multiplierOffset(
            address(perpetualMint),
            depositorTwo,
            COLLECTION
        );

        uint256 expectedEarnings = (baseMultiplier - multiplierOffset) *
            _totalDepositorRisk(
                address(perpetualMint),
                depositorTwo,
                COLLECTION
            );

        perpetualMint.exposed_assignEscrowedERC721Asset(
            depositorTwo,
            COLLECTION,
            tokenId
        );

        assert(
            expectedEarnings + oldDepositorEarnings ==
                _depositorEarnings(
                    address(perpetualMint),
                    depositorTwo,
                    COLLECTION
                )
        );

        assert(
            baseMultiplier ==
                _baseMultiplier(address(perpetualMint), COLLECTION)
        );

        assert(
            currentEarnings ==
                _lastCollectionEarnings(address(perpetualMint), COLLECTION)
        );
    }

    /// @dev test that activeTokens of 'oldOwner' are decremented after asset assignment
    function test_assignEscrowedERC721AssetDecrementsOldOwnerActiveTokens()
        public
    {
        uint256 oldActiveTokens = _activeTokens(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        perpetualMint.exposed_assignEscrowedERC721Asset(
            minter,
            COLLECTION,
            tokenId
        );

        uint256 newActiveTokens = _activeTokens(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        assert(oldActiveTokens - newActiveTokens == 1);
    }

    /// @dev test that inactiveTokens of 'newOwner' are incremented after asset assignment
    function test_assignEscrowedERC721AssetIncrementsNewOwnerInactiveTokens()
        public
    {
        uint256 oldInactiveTokens = _inactiveTokens(
            address(perpetualMint),
            minter,
            COLLECTION
        );

        perpetualMint.exposed_assignEscrowedERC721Asset(
            minter,
            COLLECTION,
            tokenId
        );

        uint256 newInactiveTokens = _inactiveTokens(
            address(perpetualMint),
            minter,
            COLLECTION
        );

        assert(newInactiveTokens - oldInactiveTokens == 1);
    }

    /// @dev test that transferred tokenId is removed from activeTokenIds if tokenId tokenRisk is zero
    function test_assignEscrowedERC721AssetRemovesTokenIdFromActiveTokenIds()
        public
    {
        perpetualMint.exposed_assignEscrowedERC721Asset(
            minter,
            COLLECTION,
            tokenId
        );

        uint256[] memory tokenIds = _activeTokenIds(
            address(perpetualMint),
            COLLECTION
        );

        for (uint i; i < tokenIds.length; ++i) {
            assert(tokenIds[i] != tokenId);
        }
    }

    /// @dev test that the 'newOwner' becomes the escrowedERC721TokenOwner
    function test_assignEscrowedERC721AssetMakesNewOwnerTheEscrowedERC721Owner()
        public
    {
        perpetualMint.exposed_assignEscrowedERC721Asset(
            minter,
            COLLECTION,
            tokenId
        );

        assertEq(
            minter,
            _escrowedERC721Owner(address(perpetualMint), COLLECTION, tokenId)
        );
    }

    /// @dev test that totalRisk is decremented after by risk of assigned token
    function test_assignEscrowedERC721AssetDecreasesTotalRiskByTokenRisk()
        public
    {
        uint256 oldTotalRisk = _totalRisk(address(perpetualMint), COLLECTION);

        perpetualMint.exposed_assignEscrowedERC721Asset(
            minter,
            COLLECTION,
            tokenId
        );

        uint256 newTotalRisk = _totalRisk(address(perpetualMint), COLLECTION);

        assert(oldTotalRisk - newTotalRisk == tokenRisk);
    }

    /// @dev test that 'oldOwner' totalDepositorRisk is decreased by the 'oldOWner' address tokenRisk
    function test_assignEscrowedERC721AssetDecreasesTotalDepositorRiskByTokenRisk()
        public
    {
        uint256 oldDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        perpetualMint.exposed_assignEscrowedERC721Asset(
            minter,
            COLLECTION,
            tokenId
        );

        uint256 newDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        assert(oldDepositorRisk - newDepositorRisk == tokenRisk);
    }

    /// @dev test that totalActiveTokens are decremented after asset assignment
    function test_assignEscrowedERC721AssetDecrementsTotalAciveTokens() public {
        uint256 oldActiveTokens = _totalActiveTokens(
            address(perpetualMint),
            COLLECTION
        );

        perpetualMint.exposed_assignEscrowedERC721Asset(
            minter,
            COLLECTION,
            tokenId
        );

        uint256 newActiveTokens = _totalActiveTokens(
            address(perpetualMint),
            COLLECTION
        );

        assert(oldActiveTokens - newActiveTokens == 1);
    }

    /// @dev test that tokenRisk of assigned token is set to zero
    function test_assignEscrowedERC721AssetSetsTokenRiskToZero() public {
        perpetualMint.exposed_assignEscrowedERC721Asset(
            minter,
            COLLECTION,
            tokenId
        );

        assertEq(0, _tokenRisk(address(perpetualMint), COLLECTION, tokenId));
    }
}
