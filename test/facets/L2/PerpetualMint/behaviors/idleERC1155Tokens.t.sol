// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";

/// @title PerpetualMint_updateTokenRisk
/// @dev PerpetualMint test contract for testing expected behavior of the idleERC721Tokens function
contract PerpetualMint_idleERC721Tokens is
    IPerpetualMintInternal,
    PerpetualMintTest,
    L2ForkTest
{
    uint256 internal constant COLLECTION_EARNINGS = 1 ether;
    address internal constant NON_OWNER = address(4);
    uint256 internal PARALLEL_ALPHA_ID;
    uint256[] tokenIds;

    // grab PARALLEL_ALPHA collection earnings storage slot
    bytes32 internal collectionEarningsStorageSlot =
        keccak256(
            abi.encode(
                PARALLEL_ALPHA, // the ERC1155 collection
                uint256(Storage.STORAGE_SLOT) + 7 // the risk storage slot
            )
        );

    function setUp() public override {
        super.setUp();

        PARALLEL_ALPHA_ID = parallelAlphaTokenIds[0];

        depositParallelAlphaAssetsMock();

        //overwrite storage
        vm.store(
            address(perpetualMint),
            collectionEarningsStorageSlot,
            bytes32(COLLECTION_EARNINGS)
        );

        tokenIds.push(PARALLEL_ALPHA_ID);
    }

    /// @dev tests that upon idling ERC1155 tokens, the depositor earnings are udpated and the depositor
    /// deductions set equal to the depositor earnings
    function test_idleERC1155TokensUpdatesDepositorEarningsWhenTotalDepositorRiskIsNonZero()
        public
    {
        uint64 totalRisk = _totalRisk(address(perpetualMint), PARALLEL_ALPHA);
        uint64 totalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );
        uint256 collectionEarnings = _collectionEarnings(
            address(perpetualMint),
            PARALLEL_ALPHA
        );
        uint256 oldDepositorDeductions = _depositorDeductions(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        assert(totalDepositorRisk != 0);
        assert(totalRisk != 0);

        vm.prank(depositorOne);
        perpetualMint.idleERC1155Tokens(PARALLEL_ALPHA, tokenIds);

        uint256 newDepositorDeductions = _depositorDeductions(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        uint256 expectedEarnings = (collectionEarnings * totalDepositorRisk) /
            totalRisk -
            oldDepositorDeductions;

        assert(
            expectedEarnings ==
                _depositorEarnings(
                    address(perpetualMint),
                    depositorOne,
                    PARALLEL_ALPHA
                )
        );

        assert(newDepositorDeductions == expectedEarnings);
    }

    /// @dev tests that when idling ERC1155 tokens the total risk changes by
    /// the amount of active tokens of the depositor multiplied by the old token risk
    function test_idleERC1155TokensDecreasesTotalRiskByRiskChange() public {
        uint256 oldTotalRisk = _totalRisk(
            address(perpetualMint),
            PARALLEL_ALPHA
        );

        uint64 totalRiskChange;

        for (uint256 i; i < tokenIds.length; ++i) {
            totalRiskChange +=
                _depositorTokenRisk(
                    address(perpetualMint),
                    depositorOne,
                    PARALLEL_ALPHA,
                    tokenIds[i]
                ) *
                uint64(
                    _activeERC1155Tokens(
                        address(perpetualMint),
                        depositorOne,
                        PARALLEL_ALPHA,
                        tokenIds[i]
                    )
                );
        }

        vm.prank(depositorOne);
        perpetualMint.idleERC1155Tokens(PARALLEL_ALPHA, tokenIds);

        uint256 newTotalRisk = _totalRisk(
            address(perpetualMint),
            PARALLEL_ALPHA
        );

        assert(oldTotalRisk - newTotalRisk == totalRiskChange);
    }

    /// @dev tests that when idling ERC1155 tokens the total active tokens of the ERC1155 collections is
    /// decreased by the previous active tokens of each of the tokenIds for the depositor
    function test_idleERC1155TokensDecreasesTotalActiveTokensOfERC1155CollectionByOldActiveTokensAcrossTokenIds()
        public
    {
        uint64 oldTotalActiveTokens = uint64(
            _totalActiveTokens(address(perpetualMint), PARALLEL_ALPHA)
        );

        uint256 oldActiveTokensSum;

        for (uint256 i; i < tokenIds.length; ++i) {
            oldActiveTokensSum += _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                tokenIds[i]
            );
        }

        vm.prank(depositorOne);
        perpetualMint.idleERC1155Tokens(PARALLEL_ALPHA, tokenIds);

        uint64 newTotalActiveTokens = uint64(
            _totalActiveTokens(address(perpetualMint), PARALLEL_ALPHA)
        );

        assert(
            oldTotalActiveTokens - newTotalActiveTokens == oldActiveTokensSum
        );
    }

    /// @dev tests that when idling tokens of an ERC1155 collection the total depositor risk is decreased by the sum of
    /// the amount of active tokens of the depositor multiplied by the difference between the previous and new risks
    /// across tokenIds
    function test_idleERC1155TokensDecreasesTotalDepositorRiskByRiskChange()
        public
    {
        uint64 expectedRiskChange;
        for (uint256 i; i < tokenIds.length; ++i) {
            expectedRiskChange +=
                _depositorTokenRisk(
                    address(perpetualMint),
                    depositorOne,
                    PARALLEL_ALPHA,
                    tokenIds[i]
                ) *
                uint64(
                    _activeERC1155Tokens(
                        address(perpetualMint),
                        depositorOne,
                        PARALLEL_ALPHA,
                        tokenIds[i]
                    )
                );
        }

        uint64 oldDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        vm.prank(depositorOne);
        perpetualMint.idleERC1155Tokens(PARALLEL_ALPHA, tokenIds);

        uint64 newDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        assert(oldDepositorRisk - newDepositorRisk == expectedRiskChange);
    }

    /// @dev tests that when idling tokens of an ERC1155 collection the depositor token risk is set to
    /// zero for each token
    function test_idleERC1155TokensSetsDepositorTokenRiskOfEachTokenIdToZero()
        public
    {
        vm.prank(depositorOne);
        perpetualMint.idleERC1155Tokens(PARALLEL_ALPHA, tokenIds);

        for (uint256 i; i < tokenIds.length; ++i) {
            assert(
                0 ==
                    _depositorTokenRisk(
                        address(perpetualMint),
                        depositorOne,
                        PARALLEL_ALPHA,
                        tokenIds[i]
                    )
            );
        }
    }

    /// @dev tests that when idling tokens of an ERC1155 collection the depositor active tokens are set to
    /// zero for each tokenId
    function test_idleERC1155TokensSetsActiveERC1155TokensOfDepositorToZeroForEachTokenId()
        public
    {
        vm.prank(depositorOne);
        perpetualMint.idleERC1155Tokens(PARALLEL_ALPHA, tokenIds);

        for (uint256 i; i < tokenIds.length; ++i) {
            assert(
                0 ==
                    _activeERC1155Tokens(
                        address(perpetualMint),
                        depositorOne,
                        PARALLEL_ALPHA,
                        tokenIds[i]
                    )
            );
        }
    }

    /// @dev tests that when idling ERC1155 tokens the depositor inactive tokens is increased
    /// by the amount of previously active ERC1155 tokens of that depositor for each tokenId
    function test_idleERC1155TokensIncreasesDepositorInactiveTokensByPreviousActiveTokensForEachTokenId()
        public
    {
        uint256[] memory oldActiveTokens = new uint256[](tokenIds.length);

        for (uint256 i; i < tokenIds.length; ++i) {
            oldActiveTokens[i] = _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                tokenIds[i]
            );
        }

        vm.prank(depositorOne);
        perpetualMint.idleERC1155Tokens(PARALLEL_ALPHA, tokenIds);

        for (uint256 i; i < tokenIds.length; ++i) {
            assert(
                oldActiveTokens[i] ==
                    _inactiveERC1155Tokens(
                        address(perpetualMint),
                        depositorOne,
                        PARALLEL_ALPHA,
                        tokenIds[i]
                    )
            );
        }
    }

    /// @dev tests that when idling ERC1155 tokens the depositor is removed from the
    /// active ERC1155 owners EnumerableSet for each tokenId
    function test_idleERC1155TokensRemovesDepositorFromActiveERC1155OwnersForEachTokenId()
        public
    {
        vm.prank(depositorOne);
        perpetualMint.idleERC1155Tokens(PARALLEL_ALPHA, tokenIds);

        for (uint256 i; i < tokenIds.length; ++i) {
            address[] memory activeOwners = _activeERC1155Owners(
                address(perpetualMint),
                PARALLEL_ALPHA,
                tokenIds[i]
            );

            for (uint256 j; j < activeOwners.length; ++j) {
                assert(activeOwners[i] != depositorOne);
            }
        }
    }

    /// @dev tests that an address not belonging to escrowedERC1155TokenOwners for each token id
    /// cannot call idleERC1155Tokens
    function test_idleERC1155TokensRevertsWhen_CallerIsNotContainedInEscrowedERC1155OwnersOfEachTokenId()
        public
    {
        vm.expectRevert(IPerpetualMintInternal.OnlyEscrowedTokenOwner.selector);
        vm.prank(NON_OWNER);
        perpetualMint.idleERC1155Tokens(PARALLEL_ALPHA, tokenIds);
    }
}