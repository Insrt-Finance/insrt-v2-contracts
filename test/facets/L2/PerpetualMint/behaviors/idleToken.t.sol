// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";

/// @title PerpetualMint_updateTokenRisk
/// @dev PerpetualMint test contract for testing expected behavior of the idleToken function
contract PerpetualMint_idleToken is
    IPerpetualMintInternal,
    PerpetualMintTest,
    L2ForkTest
{
    uint256 internal constant COLLECTION_EARNINGS = 1 ether;
    address internal constant NON_OWNER = address(4);
    uint256 internal PARALLEL_ALPHA_ID;
    uint256 internal BAYC_ID;

    // grab BAYC collection earnings storage slot
    bytes32 internal collectionEarningsStorageSlot =
        keccak256(
            abi.encode(
                BORED_APE_YACHT_CLUB, // the ERC721 collection
                uint256(Storage.STORAGE_SLOT) + 7 // the risk storage slot
            )
        );

    function setUp() public override {
        super.setUp();

        PARALLEL_ALPHA_ID = parallelAlphaTokenIds[0];
        BAYC_ID = boredApeYachtClubTokenIds[0];

        depositBoredApeYachtClubAssetsMock();
        depositParallelAlphaAssetsMock();

        //overwrite storage
        vm.store(
            address(perpetualMint),
            collectionEarningsStorageSlot,
            bytes32(COLLECTION_EARNINGS)
        );
    }

    /// @dev tests that upon idling a token, the depositor earnings are udpated and the depositor
    /// deductions set equal to the depositor earnings
    function test_idleTokenUpdatesDepositorEarningsWhenTotalDepositorRiskIsNonZero()
        public
    {
        uint64 totalRisk = _totalRisk(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );
        uint64 totalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );
        uint256 collectionEarnings = _collectionEarnings(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );
        uint256 oldDepositorDeductions = _depositorDeductions(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        assert(totalDepositorRisk != 0);
        assert(totalRisk != 0);

        vm.prank(depositorOne);
        perpetualMint.idleToken(BORED_APE_YACHT_CLUB, BAYC_ID);

        uint256 newDepositorDeductions = _depositorDeductions(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        uint256 expectedEarnings = (collectionEarnings * totalDepositorRisk) /
            totalRisk -
            oldDepositorDeductions;

        assert(
            expectedEarnings ==
                _depositorEarnings(
                    address(perpetualMint),
                    depositorOne,
                    BORED_APE_YACHT_CLUB
                )
        );

        assert(newDepositorDeductions == expectedEarnings);
    }

    /// @dev tests that upon idling token the total risk of the ERC721 collection decreases by previous
    /// token risk
    function test_idleTokenReducesTotalRiskByPreviousRiskWhenCollectionIsERC721()
        public
    {
        uint64 oldTotalRisk = _totalRisk(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        uint64 oldTokenRisk = _tokenRisk(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB,
            BAYC_ID
        );

        vm.prank(depositorOne);
        perpetualMint.idleToken(BORED_APE_YACHT_CLUB, BAYC_ID);

        uint64 newTotalRisk = _totalRisk(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        assert(oldTotalRisk - newTotalRisk == oldTokenRisk);
    }

    /// @dev tests that upon idling token the token is removed from the active token ids of
    /// of the ERC721 collection
    function test_idleTokenRemovesTokenIdFromERC721CollectionActivetokenIds()
        public
    {
        vm.prank(depositorOne);
        perpetualMint.idleToken(BORED_APE_YACHT_CLUB, BAYC_ID);

        uint256[] memory activeTokenIds = _activeTokenIds(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        for (uint256 i; i < activeTokenIds.length; ++i) {
            assert(activeTokenIds[i] != BAYC_ID);
        }
    }

    /// @dev tests that upon idling token the total active tokens of an ERC721 collection are decremented
    function test_idleTokenDecremetsTotalActiveTokensOfERC721Collection()
        public
    {
        uint256 oldActiveTokens = _totalActiveTokens(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        vm.prank(depositorOne);
        perpetualMint.idleToken(BORED_APE_YACHT_CLUB, BAYC_ID);

        uint256 newActiveTokens = _totalActiveTokens(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        assert(oldActiveTokens - newActiveTokens == 1);
    }

    /// @dev tests that upon idling token the active tokens of a depositor of the ERC721 collection
    /// are decremented
    function test_idleTokenDecrementsActiveTokensOfDepositorOfERC721Collection()
        public
    {
        uint64 oldActiveTokens = _activeTokens(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        vm.prank(depositorOne);
        perpetualMint.idleToken(BORED_APE_YACHT_CLUB, BAYC_ID);

        uint64 newActiveTokens = _activeTokens(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        assert(oldActiveTokens - newActiveTokens == 1);
    }

    /// @dev tests that idling a token increments the inactive tokens of the depositor of that ERC721 collection
    function test_idleTokenIncrementsInactiveTokensOfDepositorOfERC721Collection()
        public
    {
        uint64 oldInactiveTokens = _inactiveTokens(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        vm.prank(depositorOne);
        perpetualMint.idleToken(BORED_APE_YACHT_CLUB, BAYC_ID);

        uint64 newInactiveTokens = _inactiveTokens(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        assert(newInactiveTokens - oldInactiveTokens == 1);
    }

    /// @dev tests that upon idling token the total depositor risk for that ERC721 collection
    /// decreases by the old token risk
    function test_idleTokenDecreasesTotalDepositorRiskOfERC721CollectionByOldTokenRisk()
        public
    {
        uint64 oldRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );
        uint64 oldTokenRisk = _tokenRisk(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB,
            BAYC_ID
        );

        vm.prank(depositorOne);
        perpetualMint.idleToken(BORED_APE_YACHT_CLUB, BAYC_ID);

        uint64 newRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        assert(oldRisk - newRisk == oldTokenRisk);
    }

    /// @dev tests that upon idling token the risk of the ERC721 token is deleted
    function test_idleTokenDeletesTokenRiskOfERc721CollectionOfToken() public {
        vm.prank(depositorOne);
        perpetualMint.idleToken(BORED_APE_YACHT_CLUB, BAYC_ID);

        assert(
            0 ==
                _tokenRisk(
                    address(perpetualMint),
                    BORED_APE_YACHT_CLUB,
                    BAYC_ID
                )
        );
    }

    /// @dev tests that when idling an ERC1155 token the total risk changes by
    /// the amount of active tokens of the depositor multiplied by the old token risk
    function test_idleTokenDecreasesTotalRiskByRiskChange() public {
        uint256 oldTotalRisk = _totalRisk(
            address(perpetualMint),
            PARALLEL_ALPHA
        );

        uint64 oldTokenRisk = _depositorTokenRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID
        );

        uint256 oldActiveTokens = _activeERC1155Tokens(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID
        );

        uint64 riskChange = oldTokenRisk * uint64(oldActiveTokens);

        vm.prank(depositorOne);
        perpetualMint.idleToken(PARALLEL_ALPHA, PARALLEL_ALPHA_ID);

        uint256 newTotalRisk = _totalRisk(
            address(perpetualMint),
            PARALLEL_ALPHA
        );

        assert(oldTotalRisk - newTotalRisk == riskChange);
    }

    /// @dev tests that when idling an ERC1155 token the total active tokens of the ERC1155 collections is
    /// decreased by the previous active tokens of the depositor
    function test_idleTokenDecreasesTotalActiveTokensOfERC1155CollectionByOldActiveTokensOfDepositorOfERC1155Collection()
        public
    {
        uint64 oldTotalActiveTokens = uint64(
            _totalActiveTokens(address(perpetualMint), PARALLEL_ALPHA)
        );

        uint256 oldActiveTokens = _activeERC1155Tokens(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID
        );

        vm.prank(depositorOne);
        perpetualMint.idleToken(PARALLEL_ALPHA, PARALLEL_ALPHA_ID);

        uint64 newTotalActiveTokens = uint64(
            _totalActiveTokens(address(perpetualMint), PARALLEL_ALPHA)
        );

        assert(oldTotalActiveTokens - newTotalActiveTokens == oldActiveTokens);
    }

    /// @dev tests that when idling a token of an ERC1155 to zero the total depositor risk is decreased by
    /// the amount of active tokens of the depositor multiplied by the difference between the previous and new risks
    function test_idleTokenDecreasesTotalDepositorRiskOfERC1155CollectionByRiskChange()
        public
    {
        uint64 oldRisk = _depositorTokenRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID
        );

        uint256 oldActiveTokens = _activeERC1155Tokens(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID
        );

        uint64 oldDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        vm.prank(depositorOne);
        perpetualMint.idleToken(PARALLEL_ALPHA, PARALLEL_ALPHA_ID);

        uint64 newDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        assert(
            oldDepositorRisk - newDepositorRisk ==
                uint64(oldActiveTokens) * oldRisk
        );
    }

    /// @dev tests that when idling a token of an ERC1155 to zero the depositor token risk is deleted
    function test_idleTokenDeletesDepositorTokenRiskOfERC1155Collection()
        public
    {
        vm.prank(depositorOne);
        perpetualMint.idleToken(PARALLEL_ALPHA, PARALLEL_ALPHA_ID);

        assert(
            0 ==
                _depositorTokenRisk(
                    address(perpetualMint),
                    depositorOne,
                    PARALLEL_ALPHA,
                    PARALLEL_ALPHA_ID
                )
        );
    }

    /// @dev tests that when idling a token of an ERC1155 to zero the depositor active tokens deleted
    function test_idleTokenDeletesActiveERC1155TokensOfDepositorOfERC1155Collection()
        public
    {
        vm.prank(depositorOne);
        perpetualMint.idleToken(PARALLEL_ALPHA, PARALLEL_ALPHA_ID);

        assert(
            0 ==
                _activeERC1155Tokens(
                    address(perpetualMint),
                    depositorOne,
                    PARALLEL_ALPHA,
                    PARALLEL_ALPHA_ID
                )
        );
    }

    /// @dev tests that when idling a token of an ERC1155 to zero the depositor inactive tokens is increased
    /// by the amount of previously active ERC1155 tokens of that depositor
    function test_idleTokenIncreasesDepositorInactiveTokensOfERC1155CollectionByPreviousActiveTokens()
        public
    {
        uint256 oldActiveTokens = _activeERC1155Tokens(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID
        );
        vm.prank(depositorOne);
        perpetualMint.idleToken(PARALLEL_ALPHA, PARALLEL_ALPHA_ID);

        uint256 newInactiveTokens = _inactiveERC1155Tokens(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID
        );
        assert(newInactiveTokens == oldActiveTokens);
    }

    /// @dev tests that when idling a token of an ERC1155 token to zero the depositor is removed from the
    /// active ERC1155 owners EnumerableSet
    function test_idletokenRemovesDepositorFromActiveERC1155OwnersOfERC1155Collection()
        public
    {
        vm.prank(depositorOne);
        perpetualMint.idleToken(PARALLEL_ALPHA, PARALLEL_ALPHA_ID);

        address[] memory activeOwners = _activeERC1155Owners(
            address(perpetualMint),
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID
        );

        for (uint256 i; i < activeOwners.length; ++i) {
            assert(activeOwners[i] != depositorOne);
        }
    }
}
