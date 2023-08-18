// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";

/// @title PerpetualMint_resolveERC1155Mints
/// @dev PerpetualMint test contract for testing expected behavior of the _resolveERC1155Mints function
contract PerpetualMint_resolveERC1155Mints is
    IPerpetualMintInternal,
    PerpetualMintTest,
    L2ForkTest
{
    uint256 internal constant COLLECTION_EARNINGS = 1 ether;
    uint256[] randomWords;

    // declare collection context for the test cases
    // as PARALLEL_ALPHA collection
    address internal constant COLLECTION = PARALLEL_ALPHA;

    // grab COLLECTION collection earnings storage slot
    bytes32 internal collectionEarningsStorageSlot =
        keccak256(
            abi.encode(
                COLLECTION, // the ERC721 collection
                uint256(Storage.STORAGE_SLOT) + 9 // the collectionEarnings storage slot
            )
        );

    /// @dev value of random values which will lead to a successful mint and token one being selected from depositor one
    uint256 internal constant winValue = 90;
    uint256 internal constant tokenOneSelectValue = 90;
    uint256 internal constant depositorOneSelectValue = 90;

    // expected value of won token ID
    uint256 internal expectedTokenId;

    /// @dev depositor deductions of depositor matching expectedTokenId (depositorOne) prior to minting
    uint256 internal oldDepositorDeductions;

    /// @dev address of depositor matching expectedTokenId (depositorOne) prior to minting
    address internal oldOwner;

    /// @dev total risk of ERC1155 collection (COLLECTION) prior to minting
    uint256 internal totalRisk;

    /// @dev risk of token set by depositor
    uint256 internal tokenRisk;

    /// @dev total depositor collection risk of depositor matching expectedTokenId (depositorOne) prior to minting
    uint256 internal totalDepositorRisk;

    function setUp() public override {
        super.setUp();

        depositParallelAlphaAssetsMock();

        //overwrite storage
        vm.store(
            address(perpetualMint),
            collectionEarningsStorageSlot,
            bytes32(COLLECTION_EARNINGS)
        );

        expectedTokenId = PARALLEL_ALPHA_TOKEN_ID_ONE;

        randomWords.push(winValue);
        randomWords.push(tokenOneSelectValue);
        randomWords.push(depositorOneSelectValue);

        totalRisk = _totalRisk(address(perpetualMint), COLLECTION);
        oldOwner = depositorOne;
        totalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            oldOwner,
            COLLECTION
        );
        oldDepositorDeductions = _multiplierOffset(
            address(perpetualMint),
            oldOwner,
            COLLECTION
        );
        tokenRisk = riskThree;
    }

    /// @dev tests that _resolveERC1155Mints works with many random values
    function testFuzz_resolveERC1155Mints(
        uint256 valueOne,
        uint256 valueTwo,
        uint256 valueThree
    ) public {
        randomWords[0] = valueOne;
        randomWords[1] = valueTwo;
        randomWords[2] = valueThree;

        vm.prank(minter);
        perpetualMint.exposed_resolveERC1155Mints(
            minter,
            COLLECTION,
            randomWords
        );
    }

    /// @dev tests that after a successful mint the minter is one of the owners of the tokenId
    /// @dev tests token selection && owner selection simultaneously via expectedTokenId
    /// and checking decrement of depositorOne activeERC1155Tokens
    function test_resolveERC1155MintsWinOwnerIsMinter() public {
        vm.prank(minter);
        perpetualMint.exposed_resolveERC1155Mints(
            minter,
            COLLECTION,
            randomWords
        );

        assert(
            _inactiveERC1155Tokens(
                address(perpetualMint),
                minter,
                COLLECTION,
                expectedTokenId
            ) == 1
        );
        assert(
            _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                COLLECTION,
                expectedTokenId
            ) == parallelAlphaTokenAmount - 1
        );
    }

    /// @dev ensures that baseMultiplier and lastCollectionEarnings are updated when minter has no risk
    /// and wins the mint
    function test_resolveERC1155MintWinUpdateDepositorEarningsForMinterWhenMinterHasNoRisk()
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

        vm.prank(minter);
        perpetualMint.exposed_resolveERC1155Mints(
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

    /// @dev tests that depositEarnings are updated correctly when minter has risk, after a win
    function test_resolveERC1155MintsWinUpdateDepositorEarningsForMinterWhenMinterHasRisk()
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
        totalDepositorRisk = _totalDepositorRisk(
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

        vm.prank(depositorTwo);
        perpetualMint.exposed_resolveERC1155Mints(
            depositorTwo,
            COLLECTION,
            randomWords
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

    /// @dev tests that depositorEarnings of depositor are updated correctly after a succesful mint
    function test_resolveERC1155MintsWinUpdateDepositorEarningsOfDepositor()
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
            depositorOne,
            COLLECTION
        );
        totalDepositorRisk = _totalDepositorRisk(
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

        vm.prank(minter);
        perpetualMint.exposed_resolveERC1155Mints(
            minter,
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

    /// @dev test that activeTokens of depositor are decremented after successful mint
    function test_resolveERC1155MintsDecrementsDepositorActiveTokens() public {
        uint256 oldActiveTokens = _activeERC1155Tokens(
            address(perpetualMint),
            depositorOne,
            COLLECTION,
            expectedTokenId
        );

        vm.prank(minter);
        perpetualMint.exposed_resolveERC1155Mints(
            minter,
            COLLECTION,
            randomWords
        );

        uint256 newActiveTokens = _activeERC1155Tokens(
            address(perpetualMint),
            depositorOne,
            COLLECTION,
            expectedTokenId
        );

        assert(oldActiveTokens - newActiveTokens == 1);
    }

    /// @dev test that inactiveTokens of minter address are increment after successful mint
    function test_resolveERC1155MintsIncrementsMinterInactiveTokens() public {
        uint256 oldInactiveTokens = _inactiveERC1155Tokens(
            address(perpetualMint),
            minter,
            COLLECTION,
            expectedTokenId
        );

        vm.prank(minter);
        perpetualMint.exposed_resolveERC1155Mints(
            minter,
            COLLECTION,
            randomWords
        );

        uint256 newInactiveTokens = _inactiveERC1155Tokens(
            address(perpetualMint),
            minter,
            COLLECTION,
            expectedTokenId
        );

        assert(newInactiveTokens - oldInactiveTokens == 1);
    }

    /// @dev test that totalActiveTokens are decremented after successful mint
    function test_resolveERC1155MintsDecrementsTotalAciveTokens() public {
        uint256 oldActiveTokens = _totalActiveTokens(
            address(perpetualMint),
            COLLECTION
        );

        vm.prank(minter);
        perpetualMint.exposed_resolveERC1155Mints(
            minter,
            COLLECTION,
            randomWords
        );

        uint256 newActiveTokens = _totalActiveTokens(
            address(perpetualMint),
            COLLECTION
        );

        assert(oldActiveTokens - newActiveTokens == 1);
    }

    /// @dev test that totalRisk is decremented after by tokenRisk after successful mint
    function test_resolveERC1155MintsDecreasesTotalRiskByTokenRisk() public {
        uint256 oldTotalRisk = _totalRisk(address(perpetualMint), COLLECTION);

        vm.prank(minter);
        perpetualMint.exposed_resolveERC1155Mints(
            minter,
            COLLECTION,
            randomWords
        );

        uint256 newTotalRisk = _totalRisk(address(perpetualMint), COLLECTION);

        assert(oldTotalRisk - newTotalRisk == tokenRisk);
    }

    /// @dev test that tokenRisk of tokenId is decreased by the depositor depositorTokenRisk after successful mint
    function test_resolveERC1155MintsDecreasesTokenRiskByDepositorTokenRisk()
        public
    {
        uint256 oldTokenRisk = _tokenRisk(
            address(perpetualMint),
            COLLECTION,
            expectedTokenId
        );

        vm.prank(minter);
        perpetualMint.exposed_resolveERC1155Mints(
            minter,
            COLLECTION,
            randomWords
        );

        uint256 newTokenRisk = _tokenRisk(
            address(perpetualMint),
            COLLECTION,
            expectedTokenId
        );

        assert(oldTokenRisk - newTokenRisk == tokenRisk);
    }

    /// @dev test that depositor totalDepositorRisk is decreased by the depositorTokenRisk after successful mint
    function test_resolveERC1155MintsDecreasesTotalDepositorRiskByTokenRisk()
        public
    {
        uint256 oldDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        vm.prank(minter);
        perpetualMint.exposed_resolveERC1155Mints(
            minter,
            COLLECTION,
            randomWords
        );

        uint256 newDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        assert(oldDepositorRisk - newDepositorRisk == tokenRisk);
    }

    /// @dev test that depositor address is removed from activeERC1155Owners if depositor activeERC1155Tokens is zero
    function test_resolveERC1155MintsRemovesDepositorFromActiveERC1155OwnersIfDepositorActiveERC1155TokensIsZero()
        public
    {
        // grab slot of activeERC1155Tokens
        bytes32 depositorOneSlot = keccak256(
            abi.encode(
                expectedTokenId, // id of token
                keccak256(
                    abi.encode(
                        COLLECTION, // address of collection
                        keccak256(
                            abi.encode(
                                depositorOne, // address of depositor
                                uint256(Storage.STORAGE_SLOT) + 25 // activeERC1155Tokens mapping storage slot
                            )
                        )
                    )
                )
            )
        );

        bytes32 depositorTwoSlot = keccak256(
            abi.encode(
                expectedTokenId, // id of token
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

        bytes32 tokenRiskSlot = keccak256(
            abi.encode(
                expectedTokenId, // id of token
                keccak256(
                    abi.encode(
                        COLLECTION, // address of collection
                        uint256(Storage.STORAGE_SLOT) + 16 // tokenRisk mapping storage slot
                    )
                )
            )
        );

        //overwrite storage to set activeERC1155 tokens to 1 for testing
        vm.store(address(perpetualMint), depositorOneSlot, bytes32(uint256(1)));
        vm.store(address(perpetualMint), depositorTwoSlot, bytes32(uint256(1)));
        vm.store(
            address(perpetualMint),
            tokenRiskSlot,
            bytes32(uint256(2 * riskThree))
        ); // only two active tokens

        vm.prank(minter);
        perpetualMint.exposed_resolveERC1155Mints(
            minter,
            COLLECTION,
            randomWords
        );

        address[] memory owners = _activeERC1155Owners(
            address(perpetualMint),
            COLLECTION,
            expectedTokenId
        );

        for (uint i; i < owners.length; ++i) {
            assert(owners[i] != depositorOne);
        }
    }

    /// @dev test that depostior depositorTokenRisk is deleted if despositor activeERC1155 tokens are zero
    function test_resolveERC1155MintsDeletesDepositorTokenRiskIfDepositorActiveERC1155TokensIsZero()
        public
    {
        // grab slot of activeERC1155Tokens
        bytes32 depositorOneSlot = keccak256(
            abi.encode(
                expectedTokenId, // id of token
                keccak256(
                    abi.encode(
                        COLLECTION, // address of collection
                        keccak256(
                            abi.encode(
                                depositorOne, // address of depositor
                                uint256(Storage.STORAGE_SLOT) + 25 // activeERC1155Tokens mapping storage slot
                            )
                        )
                    )
                )
            )
        );

        bytes32 depositorTwoSlot = keccak256(
            abi.encode(
                expectedTokenId, // id of token
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

        bytes32 tokenRiskSlot = keccak256(
            abi.encode(
                expectedTokenId, // id of token
                keccak256(
                    abi.encode(
                        COLLECTION, // address of collection
                        uint256(Storage.STORAGE_SLOT) + 16 // tokenRisk mapping storage slot
                    )
                )
            )
        );

        //overwrite storage to set activeERC1155 tokens to 1 for testing
        vm.store(address(perpetualMint), depositorOneSlot, bytes32(uint256(1)));
        vm.store(address(perpetualMint), depositorTwoSlot, bytes32(uint256(1)));
        vm.store(
            address(perpetualMint),
            tokenRiskSlot,
            bytes32(uint256(2 * riskThree))
        ); // only two active tokens

        vm.prank(minter);
        perpetualMint.exposed_resolveERC1155Mints(
            minter,
            COLLECTION,
            randomWords
        );

        uint256 risk = _depositorTokenRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION,
            expectedTokenId
        );

        assert(risk == 0);
    }

    /// @dev test that tokenId is removed from activeTokenIds if tokenId tokenRisk is zero after successful mint
    function test_resolveERC1155MintsRemovesTokenIdFromActiveTokenIdsIfTokenRiskIsZero()
        public
    {
        bytes32 tokenRiskSlot = keccak256(
            abi.encode(
                expectedTokenId, // id of token
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

        vm.prank(minter);
        perpetualMint.exposed_resolveERC1155Mints(
            minter,
            COLLECTION,
            randomWords
        );

        uint256[] memory tokenIds = _activeTokenIds(
            address(perpetualMint),
            COLLECTION
        );

        for (uint i; i < tokenIds.length; ++i) {
            assert(tokenIds[i] != expectedTokenId);
        }
    }

    /// @dev tests that _resolveERC1155Mints reverts when random words are unmatched
    function test_resolveERC1155MintsRevertsWhen_RandomWordsAreUnmatched()
        public
    {
        // remove one word to cause unmatched random words revert
        randomWords.pop();

        vm.expectRevert(IPerpetualMintInternal.UnmatchedRandomWords.selector);

        vm.startPrank(minter);
        perpetualMint.exposed_resolveERC1155Mints(
            minter,
            COLLECTION,
            randomWords
        );

        // add extra word to cause unmatched random words revert
        randomWords.push(1);
        randomWords.push(2);

        vm.expectRevert(IPerpetualMintInternal.UnmatchedRandomWords.selector);
        perpetualMint.exposed_resolveERC1155Mints(
            minter,
            COLLECTION,
            randomWords
        );
    }
}
