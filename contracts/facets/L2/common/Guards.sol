// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

/// @title Guards Library
/// @dev defines storage layout for guards and the guards themselves
library Guards {
    /// @dev thrown when attempting to increase activeTokens of a collectino past the maxActiveTokens amount
    error MaxActiveTokensExceeded();

    /// @dev emitted when a new value for maxActiveTokens is set
    /// @param maxActiveTokens new maxActiveTokens value
    event MaxActiveTokensSet(uint256 maxActiveTokens);

    struct Layout {
        /// @dev maximum amount of active tokens allowed per collection
        uint256 maxActiveTokens;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("insrt.contracts.storage.Guards");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @dev enforces the maximum active token limit on an amount of tokens
    /// @param tokens amount to check
    function enforceMaxActiveTokens(uint256 tokens) internal view {
        if (tokens > layout().maxActiveTokens) {
            revert MaxActiveTokensExceeded();
        }
    }

    /// @dev sets a new value for maxActiveTokens
    /// @param maxActiveTokens new maxActiveTokens value
    function setMaxActiveTokens(uint256 maxActiveTokens) internal {
        layout().maxActiveTokens = maxActiveTokens;
        emit MaxActiveTokensSet(maxActiveTokens);
    }
}
