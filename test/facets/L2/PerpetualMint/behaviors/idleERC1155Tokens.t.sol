// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";

/// @title PerpetualMint_idle1155Tokens
/// @dev PerpetualMint test contract for testing expected behavior of the idleERC721Tokens function
contract PerpetualMint_idleERC1155Tokens is
    IPerpetualMintInternal,
    PerpetualMintTest,
    L2ForkTest
{
    uint256 internal constant COLLECTION_EARNINGS = 1 ether;
    address internal constant NON_OWNER = address(4);
    uint256 internal PARALLEL_ALPHA_ID;
    uint256[] tokenIds;
    uint256[] amounts;

    // declare collection context for the test cases
    // as PARALLEL_ALPHA collection
    address internal constant COLLECTION = PARALLEL_ALPHA;

    // grab PARALLEL_ALPHA collection earnings storage slot
    bytes32 internal collectionEarningsStorageSlot =
        keccak256(
            abi.encode(
                COLLECTION, // the ERC1155 collection
                uint256(Storage.STORAGE_SLOT) + 9 // the collectionEarnings storage slot
            )
        );

    function setUp() public override {
        super.setUp();

        PARALLEL_ALPHA_ID = PARALLEL_ALPHA_TOKEN_ID_ONE;

        depositParallelAlphaAssetsMock();

        //overwrite storage
        vm.store(
            address(perpetualMint),
            collectionEarningsStorageSlot,
            bytes32(COLLECTION_EARNINGS)
        );

        tokenIds.push(PARALLEL_ALPHA_ID);
        amounts.push(
            _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                COLLECTION,
                PARALLEL_ALPHA_ID
            ) / 2
        );
    }

    /// @dev tests that upon idling ERC1155 tokens, the depositor earnings are updated and the depositor
    /// deductions set equal to the depositor earnings
    function test_idleERC1155TokensUpdatesDepositorEarningsWhenTotalDepositorRiskIsNonZero()
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
            depositorOne,
            COLLECTION
        );
        uint256 totalDepositorRisk = _totalDepositorRisk(
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

        assert(totalDepositorRisk != 0);
        assert(_totalRisk(address(perpetualMint), COLLECTION) != 0);

        vm.prank(depositorOne);
        perpetualMint.idleERC1155Tokens(COLLECTION, tokenIds, amounts);

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

    /// @dev tests that when idling ERC1155 tokens the token risk changes by
    /// the amount of active tokens of the depositor multiplied by the old token risk
    function test_idleERC1155TokensDecreasesTokenRiskByRiskChange() public {
        uint256 oldParallelAlphaTokenRisk = _tokenRisk(
            address(perpetualMint),
            COLLECTION,
            PARALLEL_ALPHA_ID
        );

        uint256 totalRiskChange;

        for (uint256 i; i < tokenIds.length; ++i) {
            totalRiskChange +=
                _depositorTokenRisk(
                    address(perpetualMint),
                    depositorOne,
                    COLLECTION,
                    tokenIds[i]
                ) *
                uint256(amounts[i]);
        }

        vm.prank(depositorOne);
        perpetualMint.idleERC1155Tokens(COLLECTION, tokenIds, amounts);

        uint256 newParallelAlphaTokenRisk = _tokenRisk(
            address(perpetualMint),
            COLLECTION,
            PARALLEL_ALPHA_ID
        );

        assert(
            oldParallelAlphaTokenRisk - newParallelAlphaTokenRisk ==
                totalRiskChange
        );
    }

    /// @dev tests that when idling ERC1155 tokens the total risk changes by
    /// the amount of active tokens of the depositor multiplied by the old token risk
    function test_idleERC1155TokensDecreasesTotalRiskByRiskChange() public {
        uint256 oldTotalRisk = _totalRisk(address(perpetualMint), COLLECTION);

        uint256 totalRiskChange;

        for (uint256 i; i < tokenIds.length; ++i) {
            totalRiskChange +=
                _depositorTokenRisk(
                    address(perpetualMint),
                    depositorOne,
                    COLLECTION,
                    tokenIds[i]
                ) *
                uint256(amounts[i]);
        }

        vm.prank(depositorOne);
        perpetualMint.idleERC1155Tokens(COLLECTION, tokenIds, amounts);

        uint256 newTotalRisk = _totalRisk(address(perpetualMint), COLLECTION);

        assert(oldTotalRisk - newTotalRisk == totalRiskChange);
    }

    /// @dev tests that when idling ERC1155 tokens the total active tokens of the ERC1155 collections is
    /// decreased by the sum of amounts to be idled
    function test_idleERC1155TokensDecreasesTotalActiveTokensOfERC1155CollectionBySumOfAmountsToBeIdled()
        public
    {
        uint256 oldTotalActiveTokens = uint256(
            _totalActiveTokens(address(perpetualMint), COLLECTION)
        );

        uint256 idledTokenSum;

        for (uint256 i; i < tokenIds.length; ++i) {
            idledTokenSum += amounts[i];
        }

        vm.prank(depositorOne);
        perpetualMint.idleERC1155Tokens(COLLECTION, tokenIds, amounts);

        uint256 newTotalActiveTokens = uint256(
            _totalActiveTokens(address(perpetualMint), COLLECTION)
        );

        assert(oldTotalActiveTokens - newTotalActiveTokens == idledTokenSum);
    }

    /// @dev tests that when idling tokens of an ERC1155 collection the total depositor risk is decreased by the sum of
    /// the amounts of tokens to be idled multiplied by the difference between the previous and new risks
    /// across tokenIds
    function test_idleERC1155TokensDecreasesTotalDepositorRiskByRiskChange()
        public
    {
        uint256 expectedRiskChange;
        for (uint256 i; i < tokenIds.length; ++i) {
            expectedRiskChange +=
                _depositorTokenRisk(
                    address(perpetualMint),
                    depositorOne,
                    COLLECTION,
                    tokenIds[i]
                ) *
                uint256(amounts[i]);
        }

        uint256 oldDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        vm.prank(depositorOne);
        perpetualMint.idleERC1155Tokens(COLLECTION, tokenIds, amounts);

        uint256 newDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        assert(oldDepositorRisk - newDepositorRisk == expectedRiskChange);
    }

    /// @dev tests that when idling tokens of an ERC1155 collection if the amount of tokens idled for a tokenId is equal
    /// to activeERC1155Tokens of the depositor, then the token risk is set to zero for that token
    function test_idleERC1155TokensSetsDepositorTokenRiskOfEachTokenIdToZeroIfIdledAmountIsActiveTokenAmount()
        public
    {
        for (uint256 i; i < tokenIds.length; ++i) {
            amounts[i] = _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                COLLECTION,
                tokenIds[i]
            );
        }

        vm.prank(depositorOne);
        perpetualMint.idleERC1155Tokens(COLLECTION, tokenIds, amounts);

        for (uint256 i; i < tokenIds.length; ++i) {
            assert(
                0 ==
                    _depositorTokenRisk(
                        address(perpetualMint),
                        depositorOne,
                        COLLECTION,
                        tokenIds[i]
                    )
            );
        }
    }

    /// @dev tests that when idling tokens of an ERC1155 collection the depositor active tokens are decreased by
    /// the idled token amount for each tokenId
    function test_idleERC1155TokensDecreasesActiveERC1155TokensOfDepositorByAmountForEachTokenId()
        public
    {
        uint256[] memory oldActiveTokens = new uint256[](tokenIds.length);

        for (uint256 i; i < tokenIds.length; ++i) {
            oldActiveTokens[i] = _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                COLLECTION,
                tokenIds[i]
            );
        }

        vm.prank(depositorOne);
        perpetualMint.idleERC1155Tokens(COLLECTION, tokenIds, amounts);

        for (uint256 i; i < tokenIds.length; ++i) {
            assert(
                oldActiveTokens[i] -
                    _activeERC1155Tokens(
                        address(perpetualMint),
                        depositorOne,
                        COLLECTION,
                        tokenIds[i]
                    ) ==
                    amounts[i]
            );
        }
    }

    /// @dev tests that when idling ERC1155 tokens the depositor inactive tokens is increased
    /// by the amount of tokens to be idled for each tokenId
    function test_idleERC1155TokensIncreasesDepositorInactiveTokensByIdledAmountForEachTokenId()
        public
    {
        uint256[] memory oldInactiveTokens = new uint256[](tokenIds.length);

        for (uint256 i; i < tokenIds.length; ++i) {
            oldInactiveTokens[i] = _inactiveERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                COLLECTION,
                tokenIds[i]
            );
        }

        vm.prank(depositorOne);
        perpetualMint.idleERC1155Tokens(COLLECTION, tokenIds, amounts);

        for (uint256 i; i < tokenIds.length; ++i) {
            assert(
                amounts[i] ==
                    _inactiveERC1155Tokens(
                        address(perpetualMint),
                        depositorOne,
                        COLLECTION,
                        tokenIds[i]
                    ) -
                        oldInactiveTokens[i]
            );
        }
    }

    /// @dev tests that when idling ERC1155 tokens the depositor is removed from the
    /// active ERC1155 owners EnumerableSet for each tokenId if the amount of idled tokens is
    /// equal to the amount of active ERC1155 tokens
    function test_idleERC1155TokensRemovesDepositorFromActiveERC1155OwnersForEachTokenId()
        public
    {
        for (uint256 i; i < tokenIds.length; ++i) {
            amounts[i] = _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                COLLECTION,
                tokenIds[i]
            );
        }

        vm.prank(depositorOne);
        perpetualMint.idleERC1155Tokens(COLLECTION, tokenIds, amounts);

        for (uint256 i; i < tokenIds.length; ++i) {
            address[] memory activeOwners = _activeERC1155Owners(
                address(perpetualMint),
                COLLECTION,
                tokenIds[i]
            );

            for (uint256 j; j < activeOwners.length; ++j) {
                assert(activeOwners[i] != depositorOne);
            }
        }
    }

    /// @dev tests that when idling ERC1155 tokens the token id is removed from the
    /// active token id mapping for each tokenId if the new token risk for the token id is zero
    function test_idleERC1155TokensRemovesTokenIdFromActiveTokenIdsForEachTokenIdWhenTokenRiskIsZero()
        public
    {
        // idle all ERC1155 tokens
        amounts[0] = _activeERC1155Tokens(
            address(perpetualMint),
            depositorOne,
            COLLECTION,
            PARALLEL_ALPHA_TOKEN_ID_ONE
        );

        tokenIds.push(PARALLEL_ALPHA_TOKEN_ID_TWO);

        amounts.push(
            _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                COLLECTION,
                PARALLEL_ALPHA_TOKEN_ID_TWO
            )
        );

        vm.prank(depositorOne);
        perpetualMint.idleERC1155Tokens(COLLECTION, tokenIds, amounts);

        amounts = [
            _activeERC1155Tokens(
                address(perpetualMint),
                depositorTwo,
                COLLECTION,
                PARALLEL_ALPHA_TOKEN_ID_ONE
            )
        ];
        tokenIds = [PARALLEL_ALPHA_TOKEN_ID_ONE];

        vm.prank(depositorTwo);
        perpetualMint.idleERC1155Tokens(COLLECTION, tokenIds, amounts);

        for (uint256 i; i < tokenIds.length; ++i) {
            uint256[] memory activeTokenIds = _activeTokenIds(
                address(perpetualMint),
                COLLECTION
            );

            for (uint256 j; j < activeTokenIds.length; ++j) {
                assert(activeTokenIds[j] != tokenIds[i]);
            }
        }
    }

    /// @dev tests that the call reverts when the collection passed in is not an ERC1155 collection
    function test_idleERC1155TokensRevertsWhen_CollectionIsNotERC1155() public {
        vm.expectRevert(IPerpetualMintInternal.CollectionTypeMismatch.selector);
        vm.prank(depositorOne);
        perpetualMint.idleERC1155Tokens(
            BORED_APE_YACHT_CLUB,
            tokenIds,
            amounts
        );
    }

    /// @dev tests that an address not belonging to escrowedERC1155TokenOwners for each token id
    /// cannot call idleERC1155Tokens
    function test_idleERC1155TokensRevertsWhen_CallerIsNotContainedInEscrowedERC1155OwnersOfEachTokenId()
        public
    {
        vm.expectRevert(IPerpetualMintInternal.OnlyEscrowedTokenOwner.selector);
        vm.prank(NON_OWNER);
        perpetualMint.idleERC1155Tokens(COLLECTION, tokenIds, amounts);
    }
}
