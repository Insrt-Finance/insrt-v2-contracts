// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

/// @title IPerpetualMint
/// @dev interface to PerpetualMint facet
interface IPerpetualMint {
    /// @notice calculates the available earnings for the msg.sender across all collections
    /// @return allEarnings amount of available earnings across all collections
    function allAvailableEarnings() external view returns (uint256 allEarnings);

    /// @notice attempts a mint for the msg.sender from a collection
    /// @param collection address of collection for mint attempt
    function attemptMint(address collection) external;

    /// @notice calculates the available earnings for the msg.sender for a given collection
    /// @param collection address of collection
    /// @return earnings amount of available earnings
    function availableEarnings(
        address collection
    ) external view returns (uint256 earnings);

    /// @notice calculations the weighted collection-wide risk of a collection
    /// @param collection address of collection
    /// @return risk value of collection-wide risk
    function averageCollectionRisk(
        address collection
    ) external view returns (uint128 risk);

    /// @notice claims all earnings across collections of the msg.sender
    function claimAllEarnings() external;

    /// @notice claims all earnings of a collection for the msg.sender
    /// @param collection address of collection
    function claimEarnings(address collection) external;

    /// @notice set the mint price for a given collection
    /// @param collection address of collection
    /// @param price mint price of the collection
    function setCollectionMintPrice(address collection, uint256 price) external;

    /// @notice sets the type of a collection
    /// @param collection address of collection
    /// @param isERC721 bool indicating whether collection is ERC721 or ERC1155
    function setCollectionType(address collection, bool isERC721) external;

    /// @notice updates the risk associated with an escrowed token
    /// @param collection address of token collection
    /// @param tokenId id of token
    /// @param risk risk value
    function updateTokenRisk(
        address collection,
        uint256 tokenId,
        uint64 risk
    ) external;
}
