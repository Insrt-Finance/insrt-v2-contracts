// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

/// @title L2AssetHandlerStorage
/// @dev Defines storage layout for the L2AssetHandler facet.
library L2AssetHandlerStorage {
    struct Layout {
        /// @dev The LayerZero proprietary chain ID of the destination blockchain.
        /// LayerZero uses this ID to route the staked assets to the correct destination.
        /// This is not the same as the destination blockchain's actual chain ID.
        uint16 DESTINATION_LAYER_ZERO_CHAIN_ID;
        /// @dev Mapping of staker address to collection address to tokenId to amount for ERC1155 assets.
        /// Represents the amount of each specific ERC1155 token that each staker has staked.
        mapping(address staker => mapping(address collection => mapping(uint256 tokenId => uint256 amount))) stakedERC1155Assets;
        /// @dev Mapping of staker address to collection address to a set of tokenIds for ERC721 assets.
        /// Represents the specific ERC721 tokens that each staker has staked.
        mapping(address staker => mapping(address collection => EnumerableSet.UintSet tokenIds)) stakedERC721Assets;
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
