// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";

/// @title PerpetualMint_reactivateERC1155Assets
/// @dev PerpetualMint test contract for testing expected behavior of the reactivateERC1155Assets function
contract PerpetualMint_reactivateERC1155Assets is
    IPerpetualMintInternal,
    PerpetualMintTest,
    L2ForkTest
{
    uint256 internal constant COLLECTION_EARNINGS = 1 ether;
    uint256 internal constant FAILING_RISK = 10000000000000;
    uint256 internal constant NEW_RISK = 10000;
    address internal constant NON_OWNER = address(4);
    uint256 internal PARALLEL_ALPHA_ID;

    uint256[] tokenIds;
    uint256[] amounts;
    uint256[] risks;

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

        depositParallelAlphaAssetsMock();

        // overwrite storage
        vm.store(
            address(perpetualMint),
            collectionEarningsStorageSlot,
            bytes32(COLLECTION_EARNINGS)
        );

        tokenIds.push(PARALLEL_ALPHA_TOKEN_ID_ONE);
        tokenIds.push(PARALLEL_ALPHA_TOKEN_ID_TWO);

        amounts.push(
            _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                PARALLEL_ALPHA_TOKEN_ID_ONE
            )
        );
        amounts.push(
            _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                PARALLEL_ALPHA_TOKEN_ID_TWO
            )
        );

        risks.push(NEW_RISK);
        risks.push(NEW_RISK);

        uint256 totalRisk = _totalRisk(address(perpetualMint), PARALLEL_ALPHA);

        uint256 totalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        uint256 collectionEarnings = _collectionEarnings(
            address(perpetualMint),
            PARALLEL_ALPHA
        );

        uint256 oldDepositorDeductions = _multiplierOffset(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        assert(totalDepositorRisk != 0);
        assert(totalRisk != 0);

        vm.prank(depositorOne);
        perpetualMint.idleERC1155Tokens(PARALLEL_ALPHA, tokenIds, amounts);

        uint256 newDepositorDeductions = _multiplierOffset(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        uint256 newTotalDepositorRisk = _totalDepositorRisk(
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
        assert(newTotalDepositorRisk == 0);
    }

    /// @dev tests that upon reactivating ERC1155 tokens, the depositor earnings are updated and the depositor
    /// deductions set equal to the depositor earnings
    function test_reactivateERC1155AssetsUpdatesDepositorEarningsWhenTotalDepositorRiskIsZero()
        public
    {
        uint256 totalRisk = _totalRisk(address(perpetualMint), PARALLEL_ALPHA);

        uint256 totalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        uint256 collectionEarnings = _collectionEarnings(
            address(perpetualMint),
            PARALLEL_ALPHA
        );

        uint256 oldDepositorDeductions = _multiplierOffset(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        vm.prank(depositorOne);
        perpetualMint.reactivateERC1155Assets(
            PARALLEL_ALPHA,
            risks,
            tokenIds,
            amounts
        );

        uint256 newDepositorDeductions = _multiplierOffset(
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

    /// @dev tests that when reactivating ERC1155 tokens the total risk changes by
    /// the amount of reactivated tokens of the depositor multiplied by the new token risks
    function test_reactivateERC1155AssetsIncreasesTotalRiskByRiskChange()
        public
    {
        uint256 oldTotalRisk = _totalRisk(
            address(perpetualMint),
            PARALLEL_ALPHA
        );

        uint256 totalRiskChange;

        for (uint256 i; i < risks.length; ++i) {
            totalRiskChange += risks[i] * amounts[i];
        }

        vm.prank(depositorOne);
        perpetualMint.reactivateERC1155Assets(
            PARALLEL_ALPHA,
            risks,
            tokenIds,
            amounts
        );

        uint256 newTotalRisk = _totalRisk(
            address(perpetualMint),
            PARALLEL_ALPHA
        );

        assert(newTotalRisk - oldTotalRisk == totalRiskChange);
    }

    /// @dev tests that when reactivating ERC1155 tokens the total active tokens of the ERC1155 collections is
    /// increased by the sum of amounts to be reactivated
    function test_reactivateERC1155AssetsIncreasesTotalActiveTokensOfERC1155CollectionBySumOfAmountsToBeReactivated()
        public
    {
        uint256 oldTotalActiveTokens = _totalActiveTokens(
            address(perpetualMint),
            PARALLEL_ALPHA
        );

        uint256 reactivatedTokenSum;

        for (uint256 i; i < tokenIds.length; ++i) {
            reactivatedTokenSum += amounts[i];
        }

        vm.prank(depositorOne);
        perpetualMint.reactivateERC1155Assets(
            PARALLEL_ALPHA,
            risks,
            tokenIds,
            amounts
        );

        uint256 newTotalActiveTokens = _totalActiveTokens(
            address(perpetualMint),
            PARALLEL_ALPHA
        );

        assert(
            newTotalActiveTokens - oldTotalActiveTokens == reactivatedTokenSum
        );
    }

    /// @dev tests that when reactivating tokens of an ERC1155 collection the total depositor risk is increased by the sum of
    /// the amounts of tokens to be reactivated multiplied by the difference between the previous and new risks
    /// across tokenIds
    function test_reactivateERC1155AssetsIncreasesTotalDepositorRiskByRiskChange()
        public
    {
        uint256 expectedRiskChange;
        for (uint256 i; i < risks.length; ++i) {
            expectedRiskChange += risks[i] * amounts[i];
        }

        uint256 oldDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        vm.prank(depositorOne);
        perpetualMint.reactivateERC1155Assets(
            PARALLEL_ALPHA,
            risks,
            tokenIds,
            amounts
        );

        uint256 newDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        assert(newDepositorRisk - oldDepositorRisk == expectedRiskChange);
    }

    /// @dev tests that when reactivating tokens of an ERC1155 collection if the amount of activeERC1155Tokens for a given tokenId
    /// of the depositor is zero, then the token risk is set to risks given for that token
    function test_reactivateERC1155AssetsSetsDepositorTokenRiskOfEachTokenIdIfActiveAmountIsZeroForEachTokenId()
        public
    {
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

        vm.prank(depositorOne);
        perpetualMint.reactivateERC1155Assets(
            PARALLEL_ALPHA,
            risks,
            tokenIds,
            amounts
        );

        for (uint256 i; i < tokenIds.length; ++i) {
            assert(
                risks[i] ==
                    _depositorTokenRisk(
                        address(perpetualMint),
                        depositorOne,
                        PARALLEL_ALPHA,
                        tokenIds[i]
                    )
            );
        }
    }

    /// @dev tests that when reactivating tokens of an ERC1155 collection the depositor inactive tokens are decreased by
    /// the reactivated token amount for each tokenId
    function test_reactivateERC1155AssetsDecreasesInactiveERC1155TokensOfDepositorByAmountForEachTokenId()
        public
    {
        uint256[] memory oldActiveTokens = new uint256[](tokenIds.length);

        for (uint256 i; i < tokenIds.length; ++i) {
            oldActiveTokens[i] = _inactiveERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                tokenIds[i]
            );
        }

        vm.prank(depositorOne);
        perpetualMint.reactivateERC1155Assets(
            PARALLEL_ALPHA,
            risks,
            tokenIds,
            amounts
        );

        for (uint256 i; i < tokenIds.length; ++i) {
            assert(
                oldActiveTokens[i] -
                    _inactiveERC1155Tokens(
                        address(perpetualMint),
                        depositorOne,
                        PARALLEL_ALPHA,
                        tokenIds[i]
                    ) ==
                    amounts[i]
            );
        }
    }

    /// @dev tests that when reactivating ERC1155 tokens the depositor active tokens is increased
    /// by the amount of tokens to be reactivated for each tokenId
    function test_reactivateERC1155AssetsIncreasesDepositorActiveTokensByReactivatedAmountForEachTokenId()
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
        perpetualMint.reactivateERC1155Assets(
            PARALLEL_ALPHA,
            risks,
            tokenIds,
            amounts
        );

        for (uint256 i; i < tokenIds.length; ++i) {
            assert(
                amounts[i] ==
                    _activeERC1155Tokens(
                        address(perpetualMint),
                        depositorOne,
                        PARALLEL_ALPHA,
                        tokenIds[i]
                    ) -
                        oldActiveTokens[i]
            );
        }
    }

    /// @dev tests that when reactivating ERC1155 tokens the depositor is added to the
    /// active ERC1155 owners EnumerableSet for each tokenId if the amount of active tokens was zero
    function test_reactivateERC1155AssetsAddsDepositorToActiveERC1155OwnersForEachTokenId()
        public
    {
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

            address[] memory activeOwners = _activeERC1155Owners(
                address(perpetualMint),
                PARALLEL_ALPHA,
                tokenIds[i]
            );

            for (uint256 j; j < activeOwners.length; ++j) {
                assert(activeOwners[j] != depositorOne);
            }
        }

        vm.prank(depositorOne);
        perpetualMint.reactivateERC1155Assets(
            PARALLEL_ALPHA,
            risks,
            tokenIds,
            amounts
        );

        for (uint256 i; i < tokenIds.length; ++i) {
            address[] memory activeOwners = _activeERC1155Owners(
                address(perpetualMint),
                PARALLEL_ALPHA,
                tokenIds[i]
            );

            bool depositorFound = false;

            for (uint256 j; j < activeOwners.length; ++j) {
                if (activeOwners[j] == depositorOne) {
                    depositorFound = true;
                }
            }

            assert(depositorFound);
        }
    }

    /// @dev tests that an address not belonging to escrowedERC1155TokenOwners for each token id
    /// cannot call reactivateERC1155Assets
    function test_reactivateERC1155AssetsRevertsWhen_CallerIsNotContainedInEscrowedERC1155OwnersOfEachTokenId()
        public
    {
        vm.expectRevert(IPerpetualMintInternal.OnlyEscrowedTokenOwner.selector);

        vm.prank(NON_OWNER);
        perpetualMint.reactivateERC1155Assets(
            PARALLEL_ALPHA,
            risks,
            tokenIds,
            amounts
        );
    }

    /// @dev test that reactivateERC1155Assets reverts if the caller does not belong to the escrowed1155Owners EnumerableSet
    function test_reactivateERC1155AssetsRevertsWhen_CollectionIsERC1155AndCallerIsNotInEscrowedERC1155Owners()
        public
    {
        amounts[0] = 0;

        vm.expectRevert(IPerpetualMintInternal.OnlyEscrowedTokenOwner.selector);

        vm.prank(NON_OWNER);
        perpetualMint.reactivateERC1155Assets(
            PARALLEL_ALPHA,
            risks,
            tokenIds,
            amounts
        );
    }

    /// @dev test that reactivateERC1155Assets reverts if the collection is an ERC721 collection
    function test_reactivateERC1155AssetsTokenRisksRevertsWhen_CollectionIsERC721()
        public
    {
        vm.expectRevert(IPerpetualMintInternal.CollectionTypeMismatch.selector);

        vm.prank(depositorOne);
        perpetualMint.reactivateERC1155Assets(
            BORED_APE_YACHT_CLUB,
            risks,
            tokenIds,
            amounts
        );
    }

    /// @dev test that reactivateERC1155Assets reverts if the risk to be set is larger than the BASIS
    function test_reactivateERC1155AssetsRevertsWhen_RiskExceedsBasis() public {
        risks[0] = FAILING_RISK;

        vm.expectRevert(IPerpetualMintInternal.BasisExceeded.selector);

        vm.prank(depositorOne);
        perpetualMint.reactivateERC1155Assets(
            PARALLEL_ALPHA,
            risks,
            tokenIds,
            amounts
        );
    }

    /// @dev test that reactivateERC1155Assets reverts if the risk to be set is 0
    function test_reactivateERC1155AssetsRevertsWhen_RiskIsSetToZero() public {
        risks[0] = 0;

        vm.expectRevert(IPerpetualMintInternal.TokenRiskMustBeNonZero.selector);

        vm.prank(depositorOne);
        perpetualMint.reactivateERC1155Assets(
            PARALLEL_ALPHA,
            risks,
            tokenIds,
            amounts
        );
    }

    /// @dev test that reactivateERC1155Assets reverts if the risk array and tokenIds array differ in length
    function test_reactivateERC1155AssetsRevertsWhen_TokenIdsAndRisksArrayLengthsMismatch()
        public
    {
        risks.push(NEW_RISK);

        vm.expectRevert(IPerpetualMintInternal.ArrayLengthMismatch.selector);

        vm.prank(depositorOne);
        perpetualMint.reactivateERC1155Assets(
            PARALLEL_ALPHA,
            risks,
            tokenIds,
            amounts
        );
    }
}
