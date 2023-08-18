// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";

/// @dev PerpetualMint_resolveERC721Mints
/// @dev PerpetualMint test contract for testing expected behavior of the _resolveERC721Mints function
contract PerpetualMint_resolveERC721Mints is
    IPerpetualMintInternal,
    PerpetualMintTest,
    L2ForkTest
{
    uint256 internal constant COLLECTION_EARNINGS = 1 ether;

    /// @dev mimics random values sent by Chainlink VRF
    uint256[] randomWords;

    /// @dev values of random numbers which will lead to a successful mint and token one being selected
    uint256 internal constant winValue = 500;
    uint256 internal constant tokenOneSelectValue = 300;

    address constant COLLECTION = BORED_APE_YACHT_CLUB;

    /// @dev expected value of won token ID
    uint256 internal expectedTokenId;

    /// @dev address of depositor matching expectedTokenId (depositorOne) prior to minting
    address internal oldOwner;

    /// @dev total risk of ERC721 collection (BAYC) prior to minting
    uint256 internal totalRisk;

    /// @dev total depositor collection risk of depositor matching expectedTokenId (depositorOne) prior to minting
    uint256 internal totalDepositorRisk;

    // grab BAYC collection earnings storage slot
    bytes32 internal constant collectionEarningsStorageSlot =
        keccak256(
            abi.encode(
                COLLECTION, // the ERC721 collection
                uint256(Storage.STORAGE_SLOT) + 9 // the collectionEarnings storage slot
            )
        );

    /// @dev sets up the context for _resolveERC721Mints tests
    function setUp() public override {
        super.setUp();

        vm.store( // overwrite storage
            address(perpetualMint),
            collectionEarningsStorageSlot,
            bytes32(COLLECTION_EARNINGS)
        );

        depositBoredApeYachtClubAssetsMock(); // deposit BAYC assets

        randomWords.push(winValue); // add token one win roll
        randomWords.push(tokenOneSelectValue);

        // set all common variables by reading directly from storage
        expectedTokenId = BORED_APE_YACHT_CLUB_TOKEN_ID_ONE;
        totalRisk = _totalRisk(address(perpetualMint), COLLECTION);
        oldOwner = _escrowedERC721Owner(
            address(perpetualMint),
            COLLECTION,
            expectedTokenId
        );
        totalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            oldOwner,
            COLLECTION
        );
    }

    /// @dev tests that _resolveERC721Mints works with many random values
    function testFuzz_resolveERC721Mints(
        uint256 valueOne,
        uint256 valueTwo
    ) public {
        randomWords.push(valueOne);
        randomWords.push(valueTwo);

        vm.prank(minter);
        perpetualMint.exposed_resolveERC721Mints(
            minter,
            COLLECTION,
            randomWords
        );
    }

    /// @dev tests that the number of inactive tokens for the minter is incremented after win
    function test_resolveERC721MintsWinIncrementsInactiveTokensOfWinner()
        public
    {
        uint256 oldInactiveTokens = _inactiveTokens(
            address(perpetualMint),
            address(minter),
            COLLECTION
        );

        vm.prank(minter);
        perpetualMint.exposed_resolveERC721Mints(
            minter,
            COLLECTION,
            randomWords
        );

        assert(
            _inactiveTokens(
                address(perpetualMint),
                address(minter),
                COLLECTION
            ) -
                oldInactiveTokens ==
                1
        );
    }

    /// @dev tests that the number of active tokens is decremented for the old owner after win
    function test_resolveERC721MintsDecrementsActiveTokensOfOldOwner() public {
        uint256 oldActiveTokens = _activeTokens(
            address(perpetualMint),
            oldOwner,
            COLLECTION
        );

        vm.prank(minter);
        perpetualMint.exposed_resolveERC721Mints(
            minter,
            COLLECTION,
            randomWords
        );

        assert(
            oldActiveTokens -
                _activeTokens(address(perpetualMint), oldOwner, COLLECTION) ==
                1
        );
    }

    /// @dev tests that the new owner is the minter after a win
    /// @dev simultaneously tests token selection
    function test_resolveERC721MintsWinEscrowedERC721OwnerIsMinter() public {
        vm.prank(minter);
        perpetualMint.exposed_resolveERC721Mints(
            minter,
            COLLECTION,
            randomWords
        );

        assert(
            address(minter) ==
                _escrowedERC721Owner(
                    address(perpetualMint),
                    COLLECTION,
                    expectedTokenId
                )
        );
    }

    /// @dev tests that depositor earnings of old owner are updated correclty after win
    function test_resolveERC721MintsWinUpdateDepositorEarningsOfOldOwner()
        public
    {
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
            oldOwner,
            COLLECTION
        );
        uint256 multiplierOffset = _multiplierOffset(
            address(perpetualMint),
            oldOwner,
            COLLECTION
        );

        uint256 expectedEarnings = (baseMultiplier - multiplierOffset) *
            totalDepositorRisk;

        vm.prank(minter);
        perpetualMint.exposed_resolveERC721Mints(
            minter,
            COLLECTION,
            randomWords
        );

        assert(
            expectedEarnings + oldDepositorEarnings ==
                _depositorEarnings(address(perpetualMint), oldOwner, COLLECTION)
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

    /// @dev tests that the depositor earnings of the minter are updated correctly after when, when a minter
    /// has no previous deposits
    function test_resolveERC721MintsWinUpdateDepositorEarningsOfMinterWhenMinterHasNoDeposits()
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

        vm.prank(minter); //has zero risk since they have not deposited
        perpetualMint.exposed_resolveERC721Mints(
            minter,
            COLLECTION,
            randomWords
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

    /// @dev tests that the depositor earnings of the minter are updated correctly after when, when a minter
    /// has previous deposits
    function test_resolveERC721MintsWinUpdateDepositorEarningsOfMinterWhenMinterHasPreviousDeposits()
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

        uint256 multiplierOffset = _multiplierOffset(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        uint256 expectedEarnings = (baseMultiplier - multiplierOffset) *
            totalDepositorRisk;

        vm.prank(depositorTwo);
        perpetualMint.exposed_resolveERC721Mints(
            depositorTwo,
            COLLECTION,
            randomWords
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

    /// @dev tests that the won token risk is deleted after a win
    function test_resolveERC721MintsWinDeletesWonTokenRisk() public {
        vm.prank(minter);
        perpetualMint.exposed_resolveERC721Mints(
            minter,
            COLLECTION,
            randomWords
        );

        assert(
            _tokenRisk(address(perpetualMint), COLLECTION, expectedTokenId) == 0
        );
    }

    /// @dev tests that the total active tokens value of the collection being minted
    /// is decremented
    function test_resolveERC721MintsWinDecrementsTotalActiveTokensOfCollection()
        public
    {
        uint256 oldActiveTokens = _totalActiveTokens(
            address(perpetualMint),
            COLLECTION
        );

        vm.prank(minter);
        perpetualMint.exposed_resolveERC721Mints(
            minter,
            COLLECTION,
            randomWords
        );

        uint256 newActiveTokens = _totalActiveTokens(
            address(perpetualMint),
            COLLECTION
        );
        assert(oldActiveTokens - 1 == newActiveTokens);
    }

    /// @dev tests that the total depositor risk of the old token owner is decreased
    /// by the token risk of the won token
    function test_resolveERC721MintsWinReducesTotalDepositorRiskOfOldOwnerByWonTokenRisk()
        public
    {
        uint256 tokenRisk = _tokenRisk(
            address(perpetualMint),
            COLLECTION,
            expectedTokenId
        );

        vm.prank(minter);
        perpetualMint.exposed_resolveERC721Mints(
            minter,
            COLLECTION,
            randomWords
        );

        uint256 newDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        assert(totalDepositorRisk - tokenRisk == newDepositorRisk);
    }

    /// @dev tests that the ERC721MintResolved event is emitted
    function test_resolveERC721TokenMintEmitsERC721MintResolved() public {
        vm.expectEmit();
        emit ERC721MintResolved(COLLECTION, true);

        vm.prank(minter);
        perpetualMint.exposed_resolveERC721Mints(
            minter,
            COLLECTION,
            randomWords
        );
    }

    /// @dev tests that the won token id is removed from active token ids after win
    function test_resolveERC721MintsWinWonTokenRemovedFromActiveTokenIds()
        public
    {
        uint256[] memory oldActiveTokenIds = _activeTokenIds(
            address(perpetualMint),
            COLLECTION
        );

        vm.prank(minter);
        perpetualMint.exposed_resolveERC721Mints(
            minter,
            COLLECTION,
            randomWords
        );

        uint256[] memory newActiveTokenIds = _activeTokenIds(
            address(perpetualMint),
            COLLECTION
        );

        assert(newActiveTokenIds.length + 1 == oldActiveTokenIds.length);

        for (uint i; i < newActiveTokenIds.length; ++i) {
            assert(newActiveTokenIds[i] != expectedTokenId);
        }
    }

    /// @dev tests that _resolveERC721Mints reverts when random words are unmatched
    function test_resolveERC721MintsRevertsWhen_RandomWordsAreUnmatched()
        public
    {
        // remove one word to cause unmatched random words revert
        randomWords.pop();

        vm.expectRevert(IPerpetualMintInternal.UnmatchedRandomWords.selector);

        vm.startPrank(minter);
        perpetualMint.exposed_resolveERC721Mints(
            minter,
            COLLECTION,
            randomWords
        );

        // add extra word to cause unmatched random words revert
        randomWords.push(1);
        randomWords.push(2);

        vm.expectRevert(IPerpetualMintInternal.UnmatchedRandomWords.selector);
        perpetualMint.exposed_resolveERC721Mints(
            minter,
            COLLECTION,
            randomWords
        );
    }
}
