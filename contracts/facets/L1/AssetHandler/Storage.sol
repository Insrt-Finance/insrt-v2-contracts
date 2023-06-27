// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

/// @title L1AssetHandlerStorage
/// @dev Defines storage layout for the L1AssetHandler facet.
library L1AssetHandlerStorage {
    struct Layout {
        /// TODO: Add storage variables here, or remove this contract.
        uint8 DUMMY_PLACEHOLDER;
    }

    // The slot in contract storage where data will be stored. Used to avoid collisions with other variables.
    bytes32 internal constant STORAGE_SLOT =
        keccak256("insrt.contracts.storage.L1AssetHandler");

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
