// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { PerpetualMintStorage as Storage } from "./Storage.sol";

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
    ) external view returns (uint256 risk);

    /// @notice claims all earnings across collections of the msg.sender
    function claimAllEarnings() external;

    /// @notice claims all earnings of a collection for the msg.sender
    /// @param collection address of collection
    function claimEarnings(address collection) external;

    /// @notice returns owner of escrowed ERC721 token
    /// @param collection address of collection
    /// @param tokenId id of token
    /// @return owner address of token owner
    function escrowedERC721TokenOwner(
        address collection,
        uint256 tokenId
    ) external view returns (address owner);

    /// @notice sets the token risk of a set of ERC1155 tokens to zero thereby making them idle - still escrowed
    /// by the PerpetualMint contracts but not actively accruing earnings nor incurring risk from mint attemps
    /// @param collection address of ERC1155 collection
    /// @param tokenIds ids of token of collection
    /// @param amounts amount of each tokenId to idle
    function idleERC1155Tokens(
        address collection,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external;

    /// @notice sets the token risk of a set of ERC721 tokens to zero thereby making them idle - still escrowed
    /// by the PerpetualMint contracts but not actively accruing earnings nor incurring risk from mint attemps
    /// @param collection address of ERC721 collection
    /// @param tokenIds ids of token of collection
    function idleERC721Tokens(
        address collection,
        uint256[] calldata tokenIds
    ) external;

    /// @notice Used to reactivate idled ERC1155 tokens.
    /// @dev Reactivates a set of idled ERC1155 tokens by setting their risks to the given values.
    /// @param collection The address of the collection.
    /// @param risks The new risk settings for the tokens.
    /// @param tokenIds An array of token ids to reactivate.
    /// @param amounts An array of amounts to reactivate.
    /// @notice The length of the `risks`, `tokenIds` and `amounts` arrays should be the same.
    function reactivateERC1155Assets(
        address collection,
        uint256[] calldata risks,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external;

    /// @notice Used to reactivate idled ERC721 tokens.
    /// @dev Reactivates a set of idled ERC721 tokens by setting their risks to the given values.
    /// @param collection The address of the collection.
    /// @param risks The new risk settings for the tokens.
    /// @param tokenIds An array of token ids to reactivate.
    /// @notice The length of the `risks` and `tokenIds` arrays should be the same.
    function reactivateERC721Assets(
        address collection,
        uint256[] calldata risks,
        uint256[] calldata tokenIds
    ) external;

    /// @notice set the mint price for a given collection
    /// @param collection address of collection
    /// @param price mint price of the collection
    function setCollectionMintPrice(address collection, uint256 price) external;

    /// @notice sets the Chainlink VRF config
    /// @param config VRFConfig struct holding all related data to ChainlinkVRF setup
    function setVRFConfig(Storage.VRFConfig calldata config) external;

    /// @notice updates the risk associated with escrowed ERC1155 tokens of a depositor
    /// @param collection address of token collection
    /// @param tokenIds array of token ids
    /// @param amounts amount of inactive tokens to activate for each tokenId
    /// @param risks array of new risk values for token ids
    function updateERC1155TokenRisks(
        address collection,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256[] calldata risks
    ) external;

    /// @notice updates the risk associated with an escrowed ERC721 tokens of a depositor
    /// @param collection address of token collection
    /// @param tokenIds array of token ids
    /// @param risks array of new risk values for token ids
    function updateERC721TokenRisks(
        address collection,
        uint256[] calldata tokenIds,
        uint256[] calldata risks
    ) external;
}
