// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";

/// @title PerpetualMint_assignEscrowedERC1155Asset
/// @dev PerpetualMint test contract for testing expected behavior of the assignEscrowedERC1155 function
contract PerpetualMint_assignEscrowedERC1155Asset is
    IPerpetualMintInternal,
    PerpetualMintTest,
    L2ForkTest
{
    address internal constant COLLECTION = PARALLEL_ALPHA;

    uint256 internal constant COLLECTION_EARNINGS = 1 ether;

    // grab COLLECTION collection earnings storage slot
    bytes32 internal collectionEarningsStorageSlot =
        keccak256(
            abi.encode(
                COLLECTION, // the ERC721 collection
                uint256(Storage.STORAGE_SLOT) + 9 // the collectionEarnings storage slot
            )
        );

    /// @dev tokenId of ERC1155 asset to be transferred
    uint256 tokenId;

    /// @dev risk of token set by depositor prior to transfer
    uint256 tokenRisk;

    /// @dev activeERC1155Tokens storage slot
    bytes32 slot;

    /// @dev set up the context for testing
    function setUp() public override {
        super.setUp();

        depositParallelAlphaAssetsMock();

        // instantiate variables used in testing
        tokenId = PARALLEL_ALPHA_TOKEN_ID_ONE;
        tokenRisk = _depositorTokenRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION,
            tokenId
        );

        // grab slot of activeERC1155Tokens
        slot = keccak256(
            abi.encode(
                tokenId, // id of token
                keccak256(
                    abi.encode(
                        COLLECTION, // address of collection
                        keccak256(
                            abi.encode(
                                depositorTwo, // address of depositor
                                uint256(Storage.STORAGE_SLOT) + 25 // activeERC1155Tokens mapping storage slot
                            )
                        )
                    )
                )
            )
        );

        //overwrite storage to set activeERC1155 tokens to 1 for testing
        vm.store(address(perpetualMint), slot, bytes32(uint256(1)));

        //overwrite storage
        vm.store(
            address(perpetualMint),
            collectionEarningsStorageSlot,
            bytes32(COLLECTION_EARNINGS)
        );
    }

    /// @dev tests that baseMultiplier and lastCollectionEarnings are updated for 'newOwner' when
    /// 'newOwner' has no risk
    function test_assignEscrowedERC1155AssetsUpdatesDepositorEarningsForNewOwnerWhenNewOwnerrHasNoRisk()
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

        perpetualMint.exposed_assignEscrowedERC1155Asset(
            depositorOne,
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

    /// @dev tests that depositorEarnings are updated correctly when 'newOwner' has risk
    function test_assignEscrowedERC1155AssetsUpdatesDepositorEarningsForNewOwnerWhenNewOwnerHasRisk()
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
        uint256 totalDepositorRisk = _totalDepositorRisk(
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
            totalDepositorRisk;

        perpetualMint.exposed_assignEscrowedERC1155Asset(
            depositorOne,
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

    /// @dev tests that depositorEarnings of 'oldOwner' are updated
    function test_assignEscrowedERC1155AssetUpdatesDepositorEarningsOfOldOwner()
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

        perpetualMint.exposed_assignEscrowedERC1155Asset(
            depositorOne,
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

    /// @dev test that activeTokens of 'from' are decremented after asset assignment
    function test_assignEscrowedERC1155AssetDecrementsFromActiveTokens()
        public
    {
        uint256 oldActiveTokens = _activeERC1155Tokens(
            address(perpetualMint),
            depositorOne,
            COLLECTION,
            tokenId
        );

        perpetualMint.exposed_assignEscrowedERC1155Asset(
            depositorOne,
            minter,
            COLLECTION,
            tokenId
        );

        uint256 newActiveTokens = _activeERC1155Tokens(
            address(perpetualMint),
            depositorOne,
            COLLECTION,
            tokenId
        );

        assert(oldActiveTokens - newActiveTokens == 1);
    }

    /// @dev test that inactiveTokens of 'to' address are increment after asset assignment
    function test_assignEscrowedERC1155AssetIncrementsToInactiveTokens()
        public
    {
        uint256 oldInactiveTokens = _inactiveERC1155Tokens(
            address(perpetualMint),
            minter,
            COLLECTION,
            tokenId
        );

        perpetualMint.exposed_assignEscrowedERC1155Asset(
            depositorOne,
            minter,
            COLLECTION,
            tokenId
        );

        uint256 newInactiveTokens = _inactiveERC1155Tokens(
            address(perpetualMint),
            minter,
            COLLECTION,
            tokenId
        );

        assert(newInactiveTokens - oldInactiveTokens == 1);
    }

    /// @dev test that totalActiveTokens are decremented after asset assignment
    function test_assignEscrowedERC1155AssetDecrementsTotalAciveTokens()
        public
    {
        uint256 oldActiveTokens = _totalActiveTokens(
            address(perpetualMint),
            COLLECTION
        );

        perpetualMint.exposed_assignEscrowedERC1155Asset(
            depositorOne,
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

    /// @dev test that totalRisk is decremented after by risk of assigned token
    function test_assignEscrowedERC1155AssetDecreasesTotalRiskByTokenRisk()
        public
    {
        uint256 oldTotalRisk = _totalRisk(address(perpetualMint), COLLECTION);

        perpetualMint.exposed_assignEscrowedERC1155Asset(
            depositorOne,
            minter,
            COLLECTION,
            tokenId
        );

        uint256 newTotalRisk = _totalRisk(address(perpetualMint), COLLECTION);

        assert(oldTotalRisk - newTotalRisk == tokenRisk);
    }

    /// @dev test that tokenRisk of tokenId is decreased by the 'from' address depositorTokenRisk
    function test_assignEscrowedERC1155AssetDecreasesTokenRiskByFromTokenRisk()
        public
    {
        uint256 oldTokenRisk = _tokenRisk(
            address(perpetualMint),
            COLLECTION,
            tokenId
        );

        perpetualMint.exposed_assignEscrowedERC1155Asset(
            depositorOne,
            minter,
            COLLECTION,
            tokenId
        );

        uint256 newTokenRisk = _tokenRisk(
            address(perpetualMint),
            COLLECTION,
            tokenId
        );

        assert(oldTokenRisk - newTokenRisk == tokenRisk);
    }

    /// @dev test that 'from' totalDepositorRisk is decreased by the 'from' address depositorTokenRisk
    function test_assignEscrowedERC1155AssetDecreasesTotalDepositorRiskByTokenRisk()
        public
    {
        uint256 oldDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        perpetualMint.exposed_assignEscrowedERC1155Asset(
            depositorOne,
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

    /// @dev test that 'from' address is removed to activeERC1155Owners if 'from' activeERC1155Tokens is zero
    function test_assignEscrowedERC1155AssetRemovesFromFromActiveERC1155OwnersIfFromActiveERC1155TokensIsZero()
        public
    {
        perpetualMint.exposed_assignEscrowedERC1155Asset(
            depositorTwo,
            minter,
            COLLECTION,
            tokenId
        );

        address[] memory owners = _activeERC1155Owners(
            address(perpetualMint),
            COLLECTION,
            tokenId
        );

        for (uint i; i < owners.length; ++i) {
            assert(owners[i] != depositorTwo);
        }
    }

    /// @dev test that originOwner depositTokenRisk is deleted if originalOwner activeERC1155 tokens are zero
    function test_assignEscrowedERC1155AssetDeletesOriginalOwnerDepositorTokenRiskIfOriginalOwnerActiveERC1155TokensIsZero()
        public
    {
        perpetualMint.exposed_assignEscrowedERC1155Asset(
            depositorTwo,
            minter,
            COLLECTION,
            tokenId
        );

        uint256 risk = _depositorTokenRisk(
            address(perpetualMint),
            depositorTwo,
            COLLECTION,
            tokenId
        );

        assert(risk == 0);
    }

    /// @dev test that transferred tokenId is removed from activeTokenIds if tokenId tokenRisk is zero
    function test_assignEscrowedERC1155AssetRemovesTokenIdFromActiveTokenIdsIfTokenRiskIsZero()
        public
    {
        bytes32 tokenRiskSlot = keccak256(
            abi.encode(
                tokenId, // id of token
                keccak256(
                    abi.encode(
                        COLLECTION, // address of collection
                        uint256(Storage.STORAGE_SLOT) + 16 // tokenRisk mapping storage slot
                    )
                )
            )
        );

        //overwrite storage
        vm.store(
            address(perpetualMint),
            tokenRiskSlot,
            bytes32(uint256(riskThree))
        );

        perpetualMint.exposed_assignEscrowedERC1155Asset(
            depositorTwo,
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
}
