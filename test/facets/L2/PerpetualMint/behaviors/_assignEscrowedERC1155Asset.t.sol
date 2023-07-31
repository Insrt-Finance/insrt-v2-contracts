// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";

/// @title PerpetualMint_assignEscrowedERC1155Asset
/// @dev PerpetualMint test contract for testing expected behavior of the assignEscrowedERC1155 function
contract PerpetualMint_assignEscrowedERC1155Asset is
    IPerpetualMintInternal,
    PerpetualMintTest,
    L2ForkTest
{
    /// @dev tokenId of ERC1155 asset to be transferred
    uint256 tokenId;

    /// @dev risk of token set by depositor prior to transfer
    uint64 tokenRisk;
    /// @dev activeERC1155Tokens storage slot
    bytes32 slot;

    /// @dev set up the context for testing
    function setUp() public override {
        super.setUp();

        depositParallelAlphaAssetsMock();

        // instantiate variables used in testing
        tokenId = parallelAlphaTokenIds[0];
        tokenRisk = _depositorTokenRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA,
            tokenId
        );

        // grab slot of activeERC1155Tokens
        slot = keccak256(
            abi.encode(
                tokenId, // id of token
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

        //overwrite storage to set activeERC1155 tokens to 1 for testing
        vm.store(address(perpetualMint), slot, bytes32(uint256(1)));
    }

    /// @dev test that activeTokens of 'from' are decremented after asset assignment
    function test_assignEscrowedERC1155AssetDecrementsFromActiveTokens()
        public
    {
        uint256 oldActiveTokens = _activeERC1155Tokens(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA,
            tokenId
        );

        perpetualMint.exposed_assignEscrowedERC1155Asset(
            depositorOne,
            minter,
            PARALLEL_ALPHA,
            tokenId,
            tokenRisk
        );

        uint256 newActiveTokens = _activeERC1155Tokens(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA,
            tokenId
        );

        assert(oldActiveTokens - newActiveTokens == 1);
    }

    /// @dev test that inactiveTokens of 'to' address are increment after asset assignment
    function test_assignEscrowedERC1155AssetIncrementsToInactiveTokens()
        public
    {
        uint256 oldInactiveTokens = _inactiveERC1155Tokens(
            address(perpetualMint),
            minter,
            PARALLEL_ALPHA,
            tokenId
        );

        perpetualMint.exposed_assignEscrowedERC1155Asset(
            depositorOne,
            minter,
            PARALLEL_ALPHA,
            tokenId,
            tokenRisk
        );

        uint256 newInactiveTokens = _inactiveERC1155Tokens(
            address(perpetualMint),
            minter,
            PARALLEL_ALPHA,
            tokenId
        );

        assert(newInactiveTokens - oldInactiveTokens == 1);
    }

    /// @dev test that totalActiveTokens are decremented after asset assignment
    function test_assignEscrowedERC1155AssetDecrementsTotalAciveTokens()
        public
    {
        uint256 oldActiveTokens = _totalActiveTokens(
            address(perpetualMint),
            PARALLEL_ALPHA
        );

        perpetualMint.exposed_assignEscrowedERC1155Asset(
            depositorOne,
            minter,
            PARALLEL_ALPHA,
            tokenId,
            tokenRisk
        );

        uint256 newActiveTokens = _totalActiveTokens(
            address(perpetualMint),
            PARALLEL_ALPHA
        );

        assert(oldActiveTokens - newActiveTokens == 1);
    }

    /// @dev test that totalRisk is decremented after by risk of assigned token
    function test_assignEscrowedERC1155AssetDecreasesTotalRiskByTokenRisk()
        public
    {
        uint256 oldTotalRisk = _totalRisk(
            address(perpetualMint),
            PARALLEL_ALPHA
        );

        perpetualMint.exposed_assignEscrowedERC1155Asset(
            depositorOne,
            minter,
            PARALLEL_ALPHA,
            tokenId,
            tokenRisk
        );

        uint256 newTotalRisk = _totalRisk(
            address(perpetualMint),
            PARALLEL_ALPHA
        );

        assert(oldTotalRisk - newTotalRisk == tokenRisk);
    }

    /// @dev test that tokenRisk of tokenId is decreased by the 'from' address depositorTokenRisk
    function test_assignEscrowedERC1155AssetDecreasesTokenRiskByFromTokenRisk()
        public
    {
        uint256 oldTokenRisk = _tokenRisk(
            address(perpetualMint),
            PARALLEL_ALPHA,
            tokenId
        );

        perpetualMint.exposed_assignEscrowedERC1155Asset(
            depositorOne,
            minter,
            PARALLEL_ALPHA,
            tokenId,
            tokenRisk
        );

        uint256 newTokenRisk = _tokenRisk(
            address(perpetualMint),
            PARALLEL_ALPHA,
            tokenId
        );

        assert(oldTokenRisk - newTokenRisk == tokenRisk);
    }

    /// @dev test that 'from' totalDepositorRisk is decreased by the 'from' address depositorTokenRisk
    function test_assignEscrowedERC1155AssetDecreasesTotalDepositorRiskByTokenRisk()
        public
    {
        uint256 oldDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        perpetualMint.exposed_assignEscrowedERC1155Asset(
            depositorOne,
            minter,
            PARALLEL_ALPHA,
            tokenId,
            tokenRisk
        );

        uint256 newDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        assert(oldDepositorRisk - newDepositorRisk == tokenRisk);
    }

    /// @dev test that 'from' address is removed to activeERC1155Owners if 'from' activeERC1155Tokens is zero
    function test_assignEscrowedERC1155AssetRemovesFromFromActiveERC1155OwnersIfFromActiveERC1155TokensIsZero()
        public
    {
        perpetualMint.exposed_assignEscrowedERC1155Asset(
            depositorTwo,
            minter,
            PARALLEL_ALPHA,
            tokenId,
            tokenRisk
        );

        address[] memory owners = _activeERC1155Owners(
            address(perpetualMint),
            PARALLEL_ALPHA,
            tokenId
        );

        for (uint i; i < owners.length; ++i) {
            assert(owners[i] != depositorTwo);
        }
    }

    /// @dev test that 'from' address is depositTokenRisk is deleted if 'from' activeERC1155 tokens are zero
    function test_assignEscrowedERC1155AssetDeletesFromDepositorTokenRiskIfFromActiveERC1155TokensIsZero()
        public
    {
        perpetualMint.exposed_assignEscrowedERC1155Asset(
            depositorTwo,
            minter,
            PARALLEL_ALPHA,
            tokenId,
            tokenRisk
        );

        uint256 risk = _depositorTokenRisk(
            address(perpetualMint),
            depositorTwo,
            PARALLEL_ALPHA,
            tokenId
        );

        assert(risk == 0);
    }

    /// @dev test that transferred tokenId is removed from activeTokenIds if tokenId tokenRisk is zero
    function test_assignEscrowedERC1155AssetRemovesTokenIdFromActiveTokenIdsIfTokenRiskIsZero()
        public
    {
        bytes32 tokenRiskSlot = keccak256(
            abi.encode(
                tokenId, // id of token
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

        perpetualMint.exposed_assignEscrowedERC1155Asset(
            depositorTwo,
            minter,
            PARALLEL_ALPHA,
            tokenId,
            tokenRisk
        );

        uint256[] memory tokenIds = _activeTokenIds(
            address(perpetualMint),
            PARALLEL_ALPHA
        );

        for (uint i; i < tokenIds.length; ++i) {
            assert(tokenIds[i] != tokenId);
        }
    }
}
