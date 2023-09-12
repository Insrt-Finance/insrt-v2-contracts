// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

/// @title TokenStorage
/// @dev defines storage layout for the Token facet
library TokenStorage {
    struct Layout {
        /// @dev ratio of distributionSupply to totalSupply
        uint256 globalRatio;
        /// @dev number of tokens held for distribution to token holders
        uint256 distributionSupply;
        /// @dev fraction of tokens to be reserved for distribution to token holders in basis points
        uint32 distributionFractionBP;
        /// @dev last ratio an account had when one of their actions led to a change in the
        /// reservedSupply
        mapping(address account => uint256 ratio) accountOffset;
        /// @dev amount of tokens accrued as a result of distribution to token holders
        mapping(address account => uint256 amount) accruedTokens;
        /// @dev set of contracts which are allowed to call the mint function
        EnumerableSet.AddressSet mintingContracts;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("insrt.contracts.storage.MintToken");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
