// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";

/// @title PerpetualMint_idleERC721Tokens
/// @dev PerpetualMint test contract for testing expected behavior of the idleERC721Tokens function
contract PerpetualMint_idleERC721Tokens is
    IPerpetualMintInternal,
    PerpetualMintTest,
    L2ForkTest
{
    uint256 internal constant COLLECTION_EARNINGS = 1 ether;
    address internal constant NON_OWNER = address(4);
    uint256 internal BAYC_ID;
    uint256[] tokenIds;

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

        BAYC_ID = boredApeYachtClubTokenIds[0];

        depositBoredApeYachtClubAssetsMock();

        //overwrite storage
        vm.store(
            address(perpetualMint),
            collectionEarningsStorageSlot,
            bytes32(COLLECTION_EARNINGS)
        );

        tokenIds.push(BAYC_ID);
    }

    /// @dev tests that upon idling ERC721 tokens, the depositor earnings are updated and the depositor
    /// deductions set equal to the depositor earnings
    function test_idleERC721TokensUpdatesDepositorEarningsWhenTotalDepositorRiskIsNonZero()
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
        perpetualMint.idleERC721Tokens(BORED_APE_YACHT_CLUB, tokenIds);

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

    /// @dev tests that upon idling ERC721 tokens the total risk of the ERC721 collection decreases by sum of
    /// previous token risks
    function test_idleERC721TokensDecreasesTotalRiskBySumOfOldTokenRisks()
        public
    {
        uint64 oldTotalRisk = _totalRisk(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        uint256 idsLength = tokenIds.length;
        uint64 expectedTotalRiskChange;

        for (uint256 i; i < idsLength; ++i) {
            expectedTotalRiskChange += _tokenRisk(
                address(perpetualMint),
                BORED_APE_YACHT_CLUB,
                tokenIds[i]
            );
        }

        vm.prank(depositorOne);
        perpetualMint.idleERC721Tokens(BORED_APE_YACHT_CLUB, tokenIds);

        uint64 newTotalRisk = _totalRisk(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        assert(oldTotalRisk - newTotalRisk == expectedTotalRiskChange);
    }

    /// @dev tests that upon idling ERC721 tokens the token ids are removed from the active token ids of
    /// of the ERC721 collection
    function test_idleERC721TokensRemovesTokenIdsFromActivetokenIds() public {
        vm.prank(depositorOne);
        perpetualMint.idleERC721Tokens(BORED_APE_YACHT_CLUB, tokenIds);

        uint256[] memory activeTokenIds = _activeTokenIds(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        for (uint256 i; i < activeTokenIds.length; ++i) {
            for (uint256 j; j < tokenIds.length; ++j) {
                assert(activeTokenIds[i] != tokenIds[j]);
            }
        }
    }

    /// @dev tests that upon idling ERC721 tokens the total active tokens of an ERC721 collection are decreased
    /// by the number of idled tokens
    function test_idleERC712TokensDecreasesTotalActiveTokens() public {
        uint256 oldActiveTokens = _totalActiveTokens(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        vm.prank(depositorOne);
        perpetualMint.idleERC721Tokens(BORED_APE_YACHT_CLUB, tokenIds);

        uint256 newActiveTokens = _totalActiveTokens(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        assert(oldActiveTokens - newActiveTokens == tokenIds.length);
    }

    /// @dev tests that upon idling ERC721 tokens the active tokens of a depositor of the ERC721 collection
    /// are decreased by the amount of tokens idled
    function test_idleERC721TokensDecreasesActiveTokensOfDepositor() public {
        uint64 oldActiveTokens = _activeTokens(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        vm.prank(depositorOne);
        perpetualMint.idleERC721Tokens(BORED_APE_YACHT_CLUB, tokenIds);

        uint64 newActiveTokens = _activeTokens(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        assert(oldActiveTokens - newActiveTokens == tokenIds.length);
    }

    /// @dev tests that idling ERC721 tokens increases the inactive tokens of the depositor of that ERC721 collection
    /// by the amount of tokens idled
    function test_idleERC721TokensIncreasesInactiveTokensOfDepositor() public {
        uint64 oldInactiveTokens = _inactiveTokens(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        vm.prank(depositorOne);
        perpetualMint.idleERC721Tokens(BORED_APE_YACHT_CLUB, tokenIds);

        uint64 newInactiveTokens = _inactiveTokens(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        assert(newInactiveTokens - oldInactiveTokens == tokenIds.length);
    }

    /// @dev tests that upon idling ERC721 tokens the total depositor risk for that ERC721 collection
    /// decreases by the sum of old token risks of idled ERC721 tokens
    function test_idleERC721TokensDecreasesTotalDepositorRiskByOldTotalTokenRisk()
        public
    {
        uint64 oldRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        uint64 oldTotalTokenRisk;

        for (uint256 i; i < tokenIds.length; ++i) {
            oldTotalTokenRisk += _tokenRisk(
                address(perpetualMint),
                BORED_APE_YACHT_CLUB,
                tokenIds[i]
            );
        }

        vm.prank(depositorOne);
        perpetualMint.idleERC721Tokens(BORED_APE_YACHT_CLUB, tokenIds);

        uint64 newRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        assert(oldRisk - newRisk == oldTotalTokenRisk);
    }

    /// @dev tests that upon idling ERC721 tokens the risk of each ERC721 token is deleted
    function test_idleERC721TokensSetsTokenRiskOfEachTokenToZero() public {
        vm.prank(depositorOne);
        perpetualMint.idleERC721Tokens(BORED_APE_YACHT_CLUB, tokenIds);

        for (uint256 i; i < tokenIds.length; ++i) {
            assert(
                0 ==
                    _tokenRisk(
                        address(perpetualMint),
                        BORED_APE_YACHT_CLUB,
                        tokenIds[i]
                    )
            );
        }
    }

    /// @dev tests that a caller who is not the escrowedERC721Owner for each tokenId cannot call idleERC721Tokens
    function test_idleERC721TokensRevertsWhen_CallerIsNotTheEscrowedERC721OwnerOfEachTokenId()
        public
    {
        vm.expectRevert(IPerpetualMintInternal.OnlyEscrowedTokenOwner.selector);
        vm.prank(NON_OWNER);
        perpetualMint.idleERC721Tokens(BORED_APE_YACHT_CLUB, tokenIds);
    }
}
