// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

/// @title L2AssetHandlerStorage
/// @dev Defines storage layout for the L2AssetHandler facet.
library L2AssetHandlerStorage {
    struct Layout {
        /// @dev Mapping of depositor address to collection address to tokenId to amount for ERC1155 assets.
        /// Represents the amount of each specific ERC1155 token that each depositor has deposited.
        mapping(address depositor => mapping(address collection => mapping(uint256 tokenId => uint256 amount))) erc1155Deposits;
        /// @dev Mapping of depositor address to collection address to tokenId to deposited check for ERC721 assets.
        /// Represents the specific ERC721 tokens that each depositor has deposited.
        mapping(address depositor => mapping(address collection => mapping(uint256 tokenIds => bool deposited))) erc721Deposits;
    }

    // The slot in contract storage where data will be stored. Used to avoid collisions with other variables.
    bytes32 internal constant STORAGE_SLOT =
        keccak256("insrt.contracts.storage.L2AssetHandler");

    /// @dev Returns the storage layout.
    /// @return l The storage layout.
    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        // Inline assembly used to directly load the value of the storage slot into the returned struct.
        assembly {
            l.slot := slot
        }
    }
}
