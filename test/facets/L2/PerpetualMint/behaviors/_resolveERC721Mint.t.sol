// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";

/// @dev PerpetualMint_resolveERC721Mint
/// @dev PerpetualMint test contract for testing expected behavior of the _resolveERC721Mint function
contract PerpetualMint_resolveERC721Mint is
    IPerpetualMintInternal,
    PerpetualMintTest,
    L2ForkTest
{
    uint256 internal constant COLLECTION_EARNINGS = 1 ether;

    /// @dev mimics random values sent by Chainlink VRF
    uint256[] randomWords;

    // grab BAYC collection earnings storage slot
    bytes32 internal constant collectionEarningsStorageSlot =
        keccak256(
            abi.encode(
                BORED_APE_YACHT_CLUB, // the ERC721 collection
                uint256(Storage.STORAGE_SLOT) + 9 // the collectionEarnings storage slot
            )
        );

    /// @dev values of random numbers which will lead to a successful mint and token one being selected
    uint256 internal constant winValue = 500;
    uint256 internal constant tokenOneSelectValue = 300;

    /// @dev expected value of won token ID
    uint256 internal expectedTokenId;

    /// @dev depositor deductions of depositor matching expectedTokenId (depositorOne) prior to minting
    uint256 internal oldDepositorDeductions;

    /// @dev address of depositor matching expectedTokenId (depositorOne) prior to minting
    address internal oldOwner;

    /// @dev total risk of ERC721 collection (BAYC) prior to minting
    uint256 internal totalRisk;

    /// @dev total depositor collection risk of depositor matching expectedTokenId (depositorOne) prior to minting
    uint256 internal totalDepositorRisk;

    /// @dev sets up the context for _resolveERC721Mint tests
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
        totalRisk = _totalRisk(address(perpetualMint), BORED_APE_YACHT_CLUB);
        oldOwner = _escrowedERC721Owner(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB,
            expectedTokenId
        );
        totalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            oldOwner,
            BORED_APE_YACHT_CLUB
        );
        oldDepositorDeductions = _depositorDeductions(
            address(perpetualMint),
            oldOwner,
            BORED_APE_YACHT_CLUB
        );
    }

    /// @dev tests that _resolveERC721Mint works with many random values
    function testFuzz_resolveERC721Mint(
        uint256 valueOne,
        uint256 valueTwo
    ) public {
        randomWords.push(valueOne);
        randomWords.push(valueTwo);

        vm.prank(minter);
        perpetualMint.exposed_resolveERC721Mint(
            minter,
            BORED_APE_YACHT_CLUB,
            randomWords
        );
    }

    /// @dev tests that the number of inactive tokens for the minter is incremented after win
    function test_resolveERC721MintWinIncrementsInactiveTokensOfWinner()
        public
    {
        uint256 oldInactiveTokens = _inactiveTokens(
            address(perpetualMint),
            address(minter),
            BORED_APE_YACHT_CLUB
        );

        vm.prank(minter);
        perpetualMint.exposed_resolveERC721Mint(
            minter,
            BORED_APE_YACHT_CLUB,
            randomWords
        );

        assert(
            _inactiveTokens(
                address(perpetualMint),
                address(minter),
                BORED_APE_YACHT_CLUB
            ) -
                oldInactiveTokens ==
                1
        );
    }

    /// @dev tests that the number of active tokens is decremented for the old owner after win
    function test_resolveERC721MintDecrementsActiveTokensOfOldOwner() public {
        uint256 oldActiveTokens = _activeTokens(
            address(perpetualMint),
            oldOwner,
            BORED_APE_YACHT_CLUB
        );

        vm.prank(minter);
        perpetualMint.exposed_resolveERC721Mint(
            minter,
            BORED_APE_YACHT_CLUB,
            randomWords
        );

        assert(
            oldActiveTokens -
                _activeTokens(
                    address(perpetualMint),
                    oldOwner,
                    BORED_APE_YACHT_CLUB
                ) ==
                1
        );
    }

    /// @dev tests that the new owner is the minter after a win
    /// @dev simultaneously tests token selection
    function test_resolveERC721MintWinEscrowedERC721OwnerIsMinter() public {
        vm.prank(minter);
        perpetualMint.exposed_resolveERC721Mint(
            minter,
            BORED_APE_YACHT_CLUB,
            randomWords
        );

        assert(
            address(minter) ==
                _escrowedERC721Owner(
                    address(perpetualMint),
                    BORED_APE_YACHT_CLUB,
                    expectedTokenId
                )
        );
    }

    /// @dev tests that depositor earnings of old owner are updated correclty after win
    function test_resolveERC721MintWinUpdateDepositorEarningsOfOldOwner()
        public
    {
        assert(totalDepositorRisk != 0);
        assert(totalRisk != 0);

        vm.prank(minter);
        perpetualMint.exposed_resolveERC721Mint(
            minter,
            BORED_APE_YACHT_CLUB,
            randomWords
        );

        uint256 newDepositorDeductions = _depositorDeductions(
            address(perpetualMint),
            oldOwner,
            BORED_APE_YACHT_CLUB
        );

        uint256 expectedEarnings = (COLLECTION_EARNINGS * totalDepositorRisk) /
            totalRisk -
            oldDepositorDeductions;

        assert(
            expectedEarnings ==
                _depositorEarnings(
                    address(perpetualMint),
                    oldOwner,
                    BORED_APE_YACHT_CLUB
                )
        );

        assert(newDepositorDeductions == expectedEarnings);
    }

    /// @dev tests that the depositor earnings of the minter are updated correctly after when, when a minter
    /// has no previous deposits
    function test_resolveERC721MintWinUpdateDepositorEarningsOfMinterWhenMinterHasNoDeposits()
        public
    {
        vm.prank(minter); //has zero risk since they have not deposited
        perpetualMint.exposed_resolveERC721Mint(
            minter,
            BORED_APE_YACHT_CLUB,
            randomWords
        );

        assert(
            _depositorDeductions(
                address(perpetualMint),
                address(minter),
                BORED_APE_YACHT_CLUB
            ) ==
                _collectionEarnings(
                    address(perpetualMint),
                    BORED_APE_YACHT_CLUB
                )
        );
    }

    /// @dev tests that the depositor earnings of the minter are updated correctly after when, when a minter
    /// has previous deposits
    function test_resolveERC721MintWinUpdateDepositorEarningsOfMinterWhenMinterHasPreviousDeposits()
        public
    {
        vm.prank(depositorTwo);
        perpetualMint.exposed_resolveERC721Mint(
            depositorTwo,
            BORED_APE_YACHT_CLUB,
            randomWords
        );

        uint256 expectedEarnings = (COLLECTION_EARNINGS * riskTwo) /
            totalRisk -
            oldDepositorDeductions;

        //previous earnings are not accounted for because there are none from the setup
        assert(
            expectedEarnings ==
                _depositorEarnings(
                    address(perpetualMint),
                    depositorTwo,
                    BORED_APE_YACHT_CLUB
                )
        );

        assert(
            expectedEarnings ==
                _depositorDeductions(
                    address(perpetualMint),
                    depositorTwo,
                    BORED_APE_YACHT_CLUB
                )
        );
    }

    /// @dev tests that the won token risk is deleted after a win
    function test_resolveERC721MintWinDeletesWonTokenRisk() public {
        vm.prank(minter);
        perpetualMint.exposed_resolveERC721Mint(
            minter,
            BORED_APE_YACHT_CLUB,
            randomWords
        );

        assert(
            _tokenRisk(
                address(perpetualMint),
                BORED_APE_YACHT_CLUB,
                BORED_APE_YACHT_CLUB_TOKEN_ID_ONE
            ) == 0
        );
    }

    /// @dev tests that the total active tokens value of the collection being minted
    /// is decremented
    function test_resolveERC721MintWinDecrementsTotalActiveTokensOfCollection()
        public
    {
        uint256 oldActiveTokens = _totalActiveTokens(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        vm.prank(minter);
        perpetualMint.exposed_resolveERC721Mint(
            minter,
            BORED_APE_YACHT_CLUB,
            randomWords
        );

        uint256 newActiveTokens = _totalActiveTokens(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );
        assert(oldActiveTokens - 1 == newActiveTokens);
    }

    /// @dev tests that the total depositor risk of the old token owner is decreased
    /// by the token risk of the won token
    function test_resolveERC721MintWinReducesTotalDepositorRiskOfOldOwnerByWonTokenRisk()
        public
    {
        uint256 tokenRisk = _tokenRisk(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB,
            expectedTokenId
        );

        vm.prank(minter);
        perpetualMint.exposed_resolveERC721Mint(
            minter,
            BORED_APE_YACHT_CLUB,
            randomWords
        );

        uint256 newDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        assert(totalDepositorRisk - tokenRisk == newDepositorRisk);
    }

    /// @dev tests that the ERC721MintResolved event is emitted
    function test_resolveERC721TokenMintEmitsERC721MintResolved() public {
        vm.expectEmit();
        emit ERC721MintResolved(BORED_APE_YACHT_CLUB, true);

        vm.prank(minter);
        perpetualMint.exposed_resolveERC721Mint(
            minter,
            BORED_APE_YACHT_CLUB,
            randomWords
        );
    }

    /// @dev tests that the won token id is removed from active token ids after win
    function test_resolveERC721MintWinWonTokenRemovedFromActiveTokenIds()
        public
    {
        uint256[] memory oldActiveTokenIds = _activeTokenIds(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        vm.prank(minter);
        perpetualMint.exposed_resolveERC721Mint(
            minter,
            BORED_APE_YACHT_CLUB,
            randomWords
        );

        uint256[] memory newActiveTokenIds = _activeTokenIds(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        assert(newActiveTokenIds.length + 1 == oldActiveTokenIds.length);

        for (uint i; i < newActiveTokenIds.length; ++i) {
            assert(newActiveTokenIds[i] != expectedTokenId);
        }
    }
}
