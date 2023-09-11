// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

import { ITokenHarness } from "./ITokenHarness.sol";
import { TokenStorage as Storage } from "../../../contracts/facets/Token/Storage.sol";
import { Token } from "../../../contracts/facets/Token/Token.sol";

/// @title TokenHarness
/// @dev exposes internal Token internal functions for testing
contract TokenHarness is Token, ITokenHarness {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @inheritdoc ITokenHarness
    function exposed_accrueTokens(address account) external {
        _accrueTokens(Storage.layout(), account);
    }

    /// @inheritdoc ITokenHarness
    function exposed_beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) external {
        _beforeTokenTransfer(from, to, amount);
    }
}
