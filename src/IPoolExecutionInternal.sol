// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

/**
 * @title internal interface to hold events for PoolExecution of INLP
 */
interface IPoolExecutionInternal {
    /**
     * @notice emitted when a supported token is deposited into INLP
     * @param collection address of ERC721 collection
     * @param tokenId id of ERC721 token
     */
    event TokenDeposit(address collection, uint256 tokenId);

    /**
     * @notice emitted when shards or INLP tokens are redeemed for an ERC721 token
     * owned by INLP
     * @param collection address of ERC721 collection
     * @param tokenId id of ERC721 token
     */
    event TokenRedemption(address collection, uint256 tokenId);

    /**
     * @notice emitted when INLP tokens are swapped for shards
     * @param shardAmount amount of shards received
     */
    event INLPSwap(uint256 shardAmount);

    /**
     * @notice emitted when shards are swapped for INLP tokens
     * @param lpAmount amount of INLP received
     */
    event ShardSwap(uint256 lpAmount);

    /**
     * @notice emitted when unclaimed shards are claimed for ETH
     * @param collection address of underlyin ERC721 collection of shards
     * @param amount amount of shards claimed
     */
    event ShardClaim(address collection, uint256 amount);
}
