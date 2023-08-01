// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";

/// @title PerpetualMint_resolveERC1155Mint
/// @dev PerpetualMint test contract for testing expected behavior of the _resolveERC1155Mint function
contract PerpetualMint_resolveERC1155Mint is
    IPerpetualMintInternal,
    PerpetualMintTest,
    L2ForkTest
{
    uint256 internal constant COLLECTION_EARNINGS = 1 ether;
    uint256[] randomWords;

    // grab PARALLEL_ALPHA collection earnings storage slot
    bytes32 internal collectionEarningsStorageSlot =
        keccak256(
            abi.encode(
                PARALLEL_ALPHA, // the ERC721 collection
                uint256(Storage.STORAGE_SLOT) + 9 // the risk storage slot
            )
        );

    /// @dev value of roll which will lead to a successful mint and token one being selected from depositor one
    uint256 internal constant tokenOneDepositorOneSelectValue =
        (uint256(((uint128(90) << 64) | uint128(uint64(90)))) << 128) |
            uint256(uint128(90));

    // expected value of won token ID
    uint256 internal expectedTokenId;

    /// @dev depositor deductions of depositor matching expectedTokenId (depositorOne) prior to minting
    uint256 internal oldDepositorDeductions;

    /// @dev address of depositor matching expectedTokenId (depositorOne) prior to minting
    address internal oldOwner;

    /// @dev total risk of ERC1155 collection (PARALLEL_ALPHA) prior to minting
    uint64 internal totalRisk;

    /// @dev risk of token set by depositor
    uint64 internal tokenRisk;

    /// @dev total depositor collection risk of depositor matching expectedTokenId (depositorOne) prior to minting
    uint64 internal totalDepositorRisk;

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
        randomWords.push(tokenOneDepositorOneSelectValue);
        totalRisk = _totalRisk(address(perpetualMint), PARALLEL_ALPHA);
        oldOwner = depositorOne;
        totalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            oldOwner,
            PARALLEL_ALPHA
        );
        oldDepositorDeductions = _depositorDeductions(
            address(perpetualMint),
            oldOwner,
            PARALLEL_ALPHA
        );
        tokenRisk = riskThree;
    }

    /// @dev tests that _resolveERC1155Mint works with many random values
    function testFuzz_resolveERC1155Mint(uint256 randomValue) public {
        randomWords.push(randomValue);

        vm.prank(minter);
        perpetualMint.exposed_resolveERC1155Mint(
            minter,
            PARALLEL_ALPHA,
            randomWords
        );
    }

    /// @dev tests that after a successful mint the minter is one of the owners of the tokenId
    /// @dev tests token selection && owner selection simultaneously via expectedTokenId
    /// and checking decrement of depositorOne activeERC1155Tokens
    function test_resolveERC1155MintWinOwnerIsMinter() public {
        randomWords.push(tokenOneDepositorOneSelectValue);

        vm.prank(minter);
        perpetualMint.exposed_resolveERC1155Mint(
            minter,
            PARALLEL_ALPHA,
            randomWords
        );

        assert(
            _inactiveERC1155Tokens(
                address(perpetualMint),
                minter,
                PARALLEL_ALPHA,
                expectedTokenId
            ) == 1
        );
        assert(
            _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                expectedTokenId
            ) == parallelAlphaTokenAmount - 1
        );
    }

    /// @dev tests that depositEarnings are updated correctly when depositor has no risk, after a win
    function test_resolveERC1155MintWinUpdateDepositorEarningsForMinterWhenMinterHasNoRisk()
        public
    {
        randomWords.push(tokenOneDepositorOneSelectValue);

        vm.prank(minter);
        perpetualMint.exposed_resolveERC1155Mint(
            minter,
            PARALLEL_ALPHA,
            randomWords
        );

        assert(
            _depositorDeductions(
                address(perpetualMint),
                minter,
                PARALLEL_ALPHA
            ) == COLLECTION_EARNINGS
        );
    }

    /// @dev tests that depositEarnings are updated correctly when minter has risk, after a win
    function test_resolveERC1155MintWinUpdateDepositorEarningsForMinterWhenMinterHasRisk()
        public
    {
        randomWords.push(tokenOneDepositorOneSelectValue);

        vm.prank(depositorTwo);
        perpetualMint.exposed_resolveERC1155Mint(
            depositorTwo,
            PARALLEL_ALPHA,
            randomWords
        );

        uint256 newDepositorDeductions = _depositorDeductions(
            address(perpetualMint),
            oldOwner,
            PARALLEL_ALPHA
        );

        uint256 expectedEarnings = (COLLECTION_EARNINGS * totalDepositorRisk) /
            totalRisk -
            oldDepositorDeductions;

        assert(
            expectedEarnings ==
                _depositorEarnings(
                    address(perpetualMint),
                    oldOwner,
                    PARALLEL_ALPHA
                )
        );

        assert(newDepositorDeductions == expectedEarnings);
    }

    /// @dev tests that depositorEarnings of depositor are updated correctly after a succesful mint
    function test_resolveERC1155MintWinUpdateDepositorEarningsOfDepositor()
        public
    {
        randomWords.push(tokenOneDepositorOneSelectValue);

        assert(totalDepositorRisk != 0);
        assert(totalRisk != 0);

        vm.prank(minter);
        perpetualMint.exposed_resolveERC1155Mint(
            minter,
            PARALLEL_ALPHA,
            randomWords
        );

        uint256 newDepositorDeductions = _depositorDeductions(
            address(perpetualMint),
            oldOwner,
            PARALLEL_ALPHA
        );

        uint256 expectedEarnings = (COLLECTION_EARNINGS * totalDepositorRisk) /
            totalRisk -
            oldDepositorDeductions;

        assert(
            expectedEarnings ==
                _depositorEarnings(
                    address(perpetualMint),
                    oldOwner,
                    PARALLEL_ALPHA
                )
        );

        assert(newDepositorDeductions == expectedEarnings);
    }

    /// @dev test that activeTokens of depositor are decremented after successful mint
    function test_resolveERC1155MintDecrementsDepositorActiveTokens() public {
        randomWords.push(tokenOneDepositorOneSelectValue);
        uint256 oldActiveTokens = _activeERC1155Tokens(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA,
            expectedTokenId
        );

        vm.prank(minter);
        perpetualMint.exposed_resolveERC1155Mint(
            minter,
            PARALLEL_ALPHA,
            randomWords
        );

        uint256 newActiveTokens = _activeERC1155Tokens(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA,
            expectedTokenId
        );

        assert(oldActiveTokens - newActiveTokens == 1);
    }

    /// @dev test that inactiveTokens of minter address are increment after successful mint
    function test_resolveERC1155MintIncrementsMinterInactiveTokens() public {
        randomWords.push(tokenOneDepositorOneSelectValue);
        uint256 oldInactiveTokens = _inactiveERC1155Tokens(
            address(perpetualMint),
            minter,
            PARALLEL_ALPHA,
            expectedTokenId
        );

        vm.prank(minter);
        perpetualMint.exposed_resolveERC1155Mint(
            minter,
            PARALLEL_ALPHA,
            randomWords
        );

        uint256 newInactiveTokens = _inactiveERC1155Tokens(
            address(perpetualMint),
            minter,
            PARALLEL_ALPHA,
            expectedTokenId
        );

        assert(newInactiveTokens - oldInactiveTokens == 1);
    }

    /// @dev test that totalActiveTokens are decremented after successful mint
    function test_resolveERC1155MintDecrementsTotalAciveTokens() public {
        randomWords.push(tokenOneDepositorOneSelectValue);
        uint256 oldActiveTokens = _totalActiveTokens(
            address(perpetualMint),
            PARALLEL_ALPHA
        );

        vm.prank(minter);
        perpetualMint.exposed_resolveERC1155Mint(
            minter,
            PARALLEL_ALPHA,
            randomWords
        );

        uint256 newActiveTokens = _totalActiveTokens(
            address(perpetualMint),
            PARALLEL_ALPHA
        );

        assert(oldActiveTokens - newActiveTokens == 1);
    }

    /// @dev test that totalRisk is decremented after by tokenRisk after successful mint
    function test_resolveERC1155MintDecreasesTotalRiskByTokenRisk() public {
        randomWords.push(tokenOneDepositorOneSelectValue);
        uint256 oldTotalRisk = _totalRisk(
            address(perpetualMint),
            PARALLEL_ALPHA
        );

        vm.prank(minter);
        perpetualMint.exposed_resolveERC1155Mint(
            minter,
            PARALLEL_ALPHA,
            randomWords
        );

        uint256 newTotalRisk = _totalRisk(
            address(perpetualMint),
            PARALLEL_ALPHA
        );

        assert(oldTotalRisk - newTotalRisk == tokenRisk);
    }

    /// @dev test that tokenRisk of tokenId is decreased by the depositor depositorTokenRisk after successful mint
    function test_resolveERC1155MintDecreasesTokenRiskByDepositorTokenRisk()
        public
    {
        randomWords.push(tokenOneDepositorOneSelectValue);
        uint256 oldTokenRisk = _tokenRisk(
            address(perpetualMint),
            PARALLEL_ALPHA,
            expectedTokenId
        );

        vm.prank(minter);
        perpetualMint.exposed_resolveERC1155Mint(
            minter,
            PARALLEL_ALPHA,
            randomWords
        );

        uint256 newTokenRisk = _tokenRisk(
            address(perpetualMint),
            PARALLEL_ALPHA,
            expectedTokenId
        );

        assert(oldTokenRisk - newTokenRisk == tokenRisk);
    }

    /// @dev test that depositor totalDepositorRisk is decreased by the depositorTokenRisk after successful mint
    function test_resolveERC1155MintDecreasesTotalDepositorRiskByTokenRisk()
        public
    {
        randomWords.push(tokenOneDepositorOneSelectValue);
        uint256 oldDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        vm.prank(minter);
        perpetualMint.exposed_resolveERC1155Mint(
            minter,
            PARALLEL_ALPHA,
            randomWords
        );

        uint256 newDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        assert(oldDepositorRisk - newDepositorRisk == tokenRisk);
    }

    /// @dev test that depositor address is removed from activeERC1155Owners if depositor activeERC1155Tokens is zero
    function test_resolveERC1155MintRemovesDepositorFromActiveERC1155OwnersIfDepositorActiveERC1155TokensIsZero()
        public
    {
        randomWords.push(tokenOneDepositorOneSelectValue);

        // grab slot of activeERC1155Tokens
        bytes32 depositorOneSlot = keccak256(
            abi.encode(
                expectedTokenId, // id of token
                keccak256(
                    abi.encode(
                        PARALLEL_ALPHA, // address of collection
                        keccak256(
                            abi.encode(
                                depositorOne, // address of depositor
                                uint256(Storage.STORAGE_SLOT) + 23 // activeERC1155Tokens mapping storage slot
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
                        PARALLEL_ALPHA, // address of collection
                        keccak256(
                            abi.encode(
                                depositorTwo, // address of depositor
                                uint256(Storage.STORAGE_SLOT) + 23 // activeERC1155Tokens mapping storage slot
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
                        PARALLEL_ALPHA, // address of collection
                        uint256(Storage.STORAGE_SLOT) + 14 // tokenRisk mapping storage slot
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
        perpetualMint.exposed_resolveERC1155Mint(
            minter,
            PARALLEL_ALPHA,
            randomWords
        );

        address[] memory owners = _activeERC1155Owners(
            address(perpetualMint),
            PARALLEL_ALPHA,
            expectedTokenId
        );

        for (uint i; i < owners.length; ++i) {
            assert(owners[i] != depositorOne);
        }
    }

    /// @dev test that depostior depositorTokenRisk is deleted if despositor activeERC1155 tokens are zero
    function test_resolveERC1155MintDeletesDepositorTokenRiskIfDepositorActiveERC1155TokensIsZero()
        public
    {
        randomWords.push(tokenOneDepositorOneSelectValue);

        // grab slot of activeERC1155Tokens
        bytes32 depositorOneSlot = keccak256(
            abi.encode(
                expectedTokenId, // id of token
                keccak256(
                    abi.encode(
                        PARALLEL_ALPHA, // address of collection
                        keccak256(
                            abi.encode(
                                depositorOne, // address of depositor
                                uint256(Storage.STORAGE_SLOT) + 23 // activeERC1155Tokens mapping storage slot
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
                        PARALLEL_ALPHA, // address of collection
                        keccak256(
                            abi.encode(
                                depositorTwo, // address of depositor
                                uint256(Storage.STORAGE_SLOT) + 23 // activeERC1155Tokens mapping storage slot
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
                        PARALLEL_ALPHA, // address of collection
                        uint256(Storage.STORAGE_SLOT) + 14 // tokenRisk mapping storage slot
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
        perpetualMint.exposed_resolveERC1155Mint(
            minter,
            PARALLEL_ALPHA,
            randomWords
        );

        uint256 risk = _depositorTokenRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA,
            expectedTokenId
        );

        assert(risk == 0);
    }

    /// @dev test that tokenId is removed from activeTokenIds if tokenId tokenRisk is zero after successful mint
    function test_assignEscrowedERC1155RemovesTokenIdFromActiveTokenIdsIfTokenRiskIsZero()
        public
    {
        bytes32 tokenRiskSlot = keccak256(
            abi.encode(
                expectedTokenId, // id of token
                keccak256(
                    abi.encode(
                        PARALLEL_ALPHA, // address of collection
                        uint256(Storage.STORAGE_SLOT) + 14 // tokenRisk mapping storage slot
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
        perpetualMint.exposed_resolveERC1155Mint(
            minter,
            PARALLEL_ALPHA,
            randomWords
        );

        uint256[] memory tokenIds = _activeTokenIds(
            address(perpetualMint),
            PARALLEL_ALPHA
        );

        for (uint i; i < tokenIds.length; ++i) {
            assert(tokenIds[i] != expectedTokenId);
        }
    }
}
