// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";

/// @title PerpetualMint_reactivateERC721Assets
/// @dev PerpetualMint test contract for testing expected behavior of the reactivateERC721Assets function
contract PerpetualMint_reactivateERC721Assets is
    IPerpetualMintInternal,
    PerpetualMintTest,
    L2ForkTest
{
    uint256 internal constant COLLECTION_EARNINGS = 1 ether;
    uint256 internal constant FAILING_RISK = 10000000000000;
    uint256 internal constant NEW_RISK = 10000;

    address internal constant COLLECTION = BORED_APE_YACHT_CLUB;
    address internal constant NON_OWNER = address(4);
    uint256 internal BAYC_ID;
    uint256 internal RISK;

    uint256[] tokenIds;
    uint256[] risks;

    // grab BAYC collection earnings storage slot
    bytes32 internal collectionEarningsStorageSlot =
        keccak256(
            abi.encode(
                COLLECTION, // the ERC721 collection
                uint256(Storage.STORAGE_SLOT) + 9 // the collectionEarnings storage slot
            )
        );

    function setUp() public override {
        super.setUp();

        BAYC_ID = BORED_APE_YACHT_CLUB_TOKEN_ID_ONE;
        RISK = riskOne;

        depositBoredApeYachtClubAssetsMock();

        //overwrite storage
        vm.store(
            address(perpetualMint),
            collectionEarningsStorageSlot,
            bytes32(COLLECTION_EARNINGS)
        );

        tokenIds.push(BAYC_ID);

        risks.push(RISK);

        uint256 totalRisk = _totalRisk(address(perpetualMint), COLLECTION);

        uint256 totalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        assert(totalDepositorRisk != 0);
        assert(totalRisk != 0);

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

        vm.prank(depositorOne);
        perpetualMint.idleERC721Tokens(COLLECTION, tokenIds);

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

    /// @dev tests that upon reactivating ERC721 tokens, the depositor earnings are updated and the
    /// base multiplier and lastCollectionEarnings are updated
    function test_reactivateERC721AssetsUpdatesDepositorEarningsWhenTotalDepositorRiskIsZero()
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
        uint256 oldBaseMultiplier = _baseMultiplier(
            address(perpetualMint),
            COLLECTION
        );
        uint256 baseMultiplier = oldBaseMultiplier +
            (currentEarnings - lastEarnings) /
            _totalRisk(address(perpetualMint), COLLECTION);

        vm.prank(depositorOne);
        perpetualMint.reactivateERC721Assets(COLLECTION, risks, tokenIds);

        assert(
            baseMultiplier ==
                _baseMultiplier(address(perpetualMint), COLLECTION)
        );

        assert(
            currentEarnings ==
                _lastCollectionEarnings(address(perpetualMint), COLLECTION)
        );
    }

    /// @dev tests that upon reactivating ERC721 tokens, the total risk of the ERC721 collection increases by
    /// the sum of reactivated token risks
    function test_reactivateERC721AssetsIncreasesTotalRiskBySumOfReactivatedTokenRisks()
        public
    {
        uint256 oldTotalRisk = _totalRisk(address(perpetualMint), COLLECTION);

        uint256 expectedTotalRiskChange;

        for (uint256 i; i < risks.length; ++i) {
            expectedTotalRiskChange += risks[i];
        }

        vm.prank(depositorOne);
        perpetualMint.reactivateERC721Assets(COLLECTION, risks, tokenIds);

        uint256 newTotalRisk = _totalRisk(address(perpetualMint), COLLECTION);

        assert(newTotalRisk - oldTotalRisk == expectedTotalRiskChange);
    }

    /// @dev tests that upon reactivating ERC721 tokens, the token ids are added to the active token ids of
    /// of the ERC721 collection
    function test_reactivateERC721AssetsAddsDepositorOneBAYCIdsToActiveTokenIds()
        public
    {
        vm.prank(depositorOne);
        perpetualMint.reactivateERC721Assets(COLLECTION, risks, tokenIds);

        uint256[] memory activeTokenIds = _activeTokenIds(
            address(perpetualMint),
            COLLECTION
        );

        for (uint256 i; i < activeTokenIds.length; ++i) {
            for (uint256 j; j < tokenIds.length; ++j) {
                if (activeTokenIds[i] != depositorTwoBAYCIds[j]) {
                    assert(activeTokenIds[i] == tokenIds[j]);
                }
            }
        }
    }

    /// @dev tests that upon reactivating ERC721 tokens the total active tokens of an ERC721 collection are increased
    /// by the number of reactivated tokens
    function test_reactivateERC712TokensIncreasesTotalActiveTokens() public {
        uint256 oldActiveTokens = _totalActiveTokens(
            address(perpetualMint),
            COLLECTION
        );

        vm.prank(depositorOne);
        perpetualMint.reactivateERC721Assets(COLLECTION, risks, tokenIds);

        uint256 newActiveTokens = _totalActiveTokens(
            address(perpetualMint),
            COLLECTION
        );

        assert(newActiveTokens - oldActiveTokens == tokenIds.length);
    }

    /// @dev tests that upon reactivating ERC721 tokens the active tokens of a depositor of the ERC721 collection
    /// are increased by the amount of tokens reactivated
    function test_reactivateERC721AssetsIncreasesActiveTokensOfDepositor()
        public
    {
        uint256 oldActiveTokens = _activeTokens(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        vm.prank(depositorOne);
        perpetualMint.reactivateERC721Assets(COLLECTION, risks, tokenIds);

        uint256 newActiveTokens = _activeTokens(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        assert(newActiveTokens - oldActiveTokens == tokenIds.length);
    }

    /// @dev tests that reactivating ERC721 tokens decreases the inactive tokens of the depositor of that ERC721 collection
    /// by the amount of tokens reactivated
    function test_reactivateERC721AssetsDecreasesInactiveTokensOfDepositor()
        public
    {
        uint256 oldInactiveTokens = _inactiveTokens(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        vm.prank(depositorOne);
        perpetualMint.reactivateERC721Assets(COLLECTION, risks, tokenIds);

        uint256 newInactiveTokens = _inactiveTokens(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        assert(oldInactiveTokens - newInactiveTokens == tokenIds.length);
    }

    /// @dev tests that upon reactivating ERC721 tokens, the total depositor risk for that ERC721 collection
    /// increases by the sum of the reactivated token risks
    function test_reactivateERC721AssetsIncreasesTotalDepositorRiskBySumOfReactivatedTokenRisks()
        public
    {
        uint256 oldRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        uint256 expectedTotalTokenRiskChange;

        for (uint256 i; i < risks.length; ++i) {
            expectedTotalTokenRiskChange += risks[i];
        }

        vm.prank(depositorOne);
        perpetualMint.reactivateERC721Assets(COLLECTION, risks, tokenIds);

        uint256 newRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        assert(newRisk - oldRisk == expectedTotalTokenRiskChange);
    }

    /// @dev tests that upon reactivating ERC721 tokens the depositor token risk of each ERC721 token is set correctly
    function test_reactivateERC721AssetsSetsDepositorTokenRiskOfEachToken()
        public
    {
        vm.prank(depositorOne);
        perpetualMint.reactivateERC721Assets(COLLECTION, risks, tokenIds);

        for (uint256 i; i < risks.length; ++i) {
            assert(
                risks[i] ==
                    _tokenRisk(address(perpetualMint), COLLECTION, tokenIds[i])
            );
        }
    }

    /// @dev tests that upon reactivating ERC721 tokens the risk of each ERC721 token is set correctly
    function test_reactivateERC721AssetsSetsTokenRiskOfEachToken() public {
        vm.prank(depositorOne);
        perpetualMint.reactivateERC721Assets(COLLECTION, risks, tokenIds);

        for (uint256 i; i < risks.length; ++i) {
            assert(
                risks[i] ==
                    _tokenRisk(address(perpetualMint), COLLECTION, tokenIds[i])
            );
        }
    }

    /// @dev tests that a caller who is not the escrowedERC721Owner for each tokenId cannot call reactivateERC721Assets
    function test_reactivateERC721AssetsRevertsWhen_CallerIsNotTheEscrowedERC721OwnerOfEachTokenId()
        public
    {
        vm.expectRevert(IPerpetualMintInternal.OnlyEscrowedTokenOwner.selector);

        vm.prank(NON_OWNER);
        perpetualMint.reactivateERC721Assets(COLLECTION, risks, tokenIds);
    }

    /// @dev test that reactivateERC721Assets reverts if the collection is an ERC1155 collection
    function test_reactivateERC721AssetsRevertsWhen_CollectionIsERC1155()
        public
    {
        vm.expectRevert(IPerpetualMintInternal.CollectionTypeMismatch.selector);

        vm.prank(depositorOne);
        perpetualMint.reactivateERC721Assets(PARALLEL_ALPHA, risks, tokenIds);
    }

    /// @dev test that reactivateERC721Assets reverts if the risk to be set is larger than the BASIS
    function test_reactivateERC721AssetsRevertsWhen_RiskExceedsBasis() public {
        risks[0] = FAILING_RISK;

        vm.expectRevert(IPerpetualMintInternal.BasisExceeded.selector);

        vm.prank(depositorOne);
        perpetualMint.reactivateERC721Assets(COLLECTION, risks, tokenIds);
    }

    /// @dev test that reactivateERC721Assets reverts if the risk to be set is 0
    function test_reactivateERC721AssetsRevertsWhen_RiskIsSetToZero() public {
        risks[0] = 0;

        vm.expectRevert(IPerpetualMintInternal.TokenRiskMustBeNonZero.selector);

        vm.prank(depositorOne);
        perpetualMint.reactivateERC721Assets(COLLECTION, risks, tokenIds);
    }

    /// @dev test that reactivateERC721Assets reverts if the risk array and tokenIds array differ in length
    function test_reactivateERC721AssetsRevertsWhen_TokenIdsAndRisksArrayLengthsMismatch()
        public
    {
        risks.push(NEW_RISK);

        vm.expectRevert(IPerpetualMintInternal.ArrayLengthMismatch.selector);

        vm.prank(depositorOne);
        perpetualMint.reactivateERC721Assets(COLLECTION, risks, tokenIds);
    }

    /// @dev test that reactivateERC721Assets reverts if the token is already active
    function test_reactivateERC721AssetsRevertsWhen_TokenIsAlreadyActive()
        public
    {
        vm.startPrank(depositorOne);
        perpetualMint.reactivateERC721Assets(COLLECTION, risks, tokenIds);

        vm.expectRevert(IPerpetualMintInternal.TokenAlreadyActive.selector);

        perpetualMint.reactivateERC721Assets(COLLECTION, risks, tokenIds);
    }
}
