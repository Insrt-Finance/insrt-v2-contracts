// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import {EnumerableSet} from "@solidstate-solidity/data/EnumerableSet.sol";
import {IERC721} from "@solidstate-solidity/interfaces/IERC721.sol";
import {ERC1155BaseInternal} from "@solidstate-solidity/token/ERC1155/base/ERC1155BaseInternal.sol";
import {ERC20BaseInternal} from "@solidstate-solidity/token/ERC20/base/ERC20BaseInternal.sol";

import {Errors} from "./Errors.sol";
import {IPoolExecutionInternal} from "./IPoolExecutionInternal.sol";
import {PoolStorage as s} from "./PoolStorage.sol";

/**
 * @notice Insrt Finance internal execution logic for asset exchanges
 */
abstract contract PoolExecutionInternal is IPoolExecutionInternal, ERC1155BaseInternal, ERC20BaseInternal {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @notice accepts a supported ERC721 token in exchange for a combination of shards and/or INLP tokens
     * @param account address depositing ERC721 token
     * @param collection address of ERC721 collection
     * @param tokenId id of ERC721 token
     * @param shardAmount amount of shards to mint to account
     * @param remainingShards amount of shards remaining from tokenShards of collection after accounting
     * for both INLP and shards minted to account
     * @param lpAmount amount of INLP tokens to mint to account
     */
    function _swapNFTForShards(
        address account,
        address collection,
        uint256 tokenId,
        uint16 shardAmount,
        uint16 remainingShards,
        uint256 lpAmount
    ) internal {
        _enforceCollectionWhitelist(collection);
        _enforceCollectionShardLimit(collection, shardAmount);

        s.Layout storage l = s.layout();

        IERC721(collection).transferFrom(account, address(this), tokenId);

        l.unclaimedShards[collection] += remainingShards;
        l.poolAssets[collection].add(tokenId);

        _mint(account, l.collectionShardId[collection], shardAmount, "0x");

        if (lpAmount > 0) {
            _mint(account, lpAmount);
        }

        emit TokenDeposit(collection, tokenId);
    }

    /**
     * @notice burns shards in exchange for an ERC721 token owned by INLP
     * @param account address of shard owner
     * @param collection address of ERC721 collection
     * @param tokenId id of ERC721 token
     */
    function _swapShardsForNFT(address account, address collection, uint256 tokenId) internal {
        _enforceCollectionWhitelist(collection);

        s.Layout storage l = s.layout();

        _burn(account, l.collectionShardId[collection], l.tokenShards[collection]);

        IERC721(collection).transferFrom(address(this), account, tokenId);

        l.poolAssets[collection].remove(tokenId);

        emit TokenRedemption(collection, tokenId);
    }

    /**
     * @notice burns INLP in exchange for an ERC721 token owned by INLP
     * @param account address of INLP owner
     * @param collection address of ERC721 collection
     * @param tokenId id of ERC721 token
     * @param lpAmount amount of INLP tokens to burn from account
     */
    function _swapINLPForNFT(address account, address collection, uint256 tokenId, uint256 lpAmount) internal {
        _enforceCollectionWhitelist(collection);

        _burn(account, lpAmount);
        IERC721(collection).transferFrom(address(this), account, tokenId);

        emit TokenRedemption(collection, tokenId);
    }

    /**
     * @notice burns INLP tokens in exchange for shards of a given collection
     * @param account address of INLP owner and shard receiver
     * @param collection address of underlying ERC721 collection of shards
     * @param lpAmount amount of INLP to burn
     * @param shardAmount amount of shards to receive
     */
    function _swapINLPforShards(address account, address collection, uint256 lpAmount, uint256 shardAmount) internal {
        _enforceCollectionWhitelist(collection);
        _enforceSufficientUnclaimedShards(collection, shardAmount);

        s.Layout storage l = s.layout();

        _burn(account, lpAmount);
        _mint(account, l.collectionShardId[collection], shardAmount, "0x");

        l.unclaimedShards[collection] -= shardAmount;

        emit INLPSwap(shardAmount);
    }

    /**
     * @notice burns shards of a given collection in exchange for INLP tokens
     * @param account address of shard owner and INLP receiver
     * @param collection address of underlying ERC721 collection of shards
     * @param lpAmount amount of INLP to receive
     * @param shardAmount amount of shards to burn
     */
    function _swapShardsForINLP(address account, address collection, uint256 shardAmount, uint256 lpAmount) internal {
        _enforceCollectionWhitelist(collection);

        s.Layout storage l = s.layout();

        _burn(account, l.collectionShardId[collection], shardAmount);
        _mint(account, lpAmount);

        emit ShardSwap(lpAmount);
    }

    /**
     * @notice checks whether a collection is whitelisted, reverts if not
     * @param collection address of ERC721 collection
     */
    function _enforceCollectionWhitelist(address collection) internal view {
        if (!s.layout().whitelistedCollections.contains(collection)) {
            revert Errors.INLP__OnlyWhitelistedCollections();
        }
    }

    /**
     * @notice checks if an amount is less than the shard limit for a token in a supported ERC721 collection,
     * reverts if not
     * @param collection address of ERC721 collection
     * @param amount amount to check
     */
    function _enforceCollectionShardLimit(address collection, uint256 amount) internal view {
        if (s.layout().tokenShards[collection] < amount) {
            revert Errors.INLP__ShardsPerTokenExceeded();
        }
    }

    /**
     * @notice checks if sufficient shards are available for a given collection given an amount of shards to be claimed,
     * reverts if not
     * @param collection address of ERC721 collection underyling shards
     * @param amount claim amount
     */
    function _enforceSufficientUnclaimedShards(address collection, uint256 amount) internal view {
        if (s.layout().unclaimedShards[collection] < amount) {
            revert Errors.INLP__InsufficientUnclaimedShards();
        }
    }
}
