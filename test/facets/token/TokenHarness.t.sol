// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { ITokenHarness } from "./ITokenHarness.sol";
import { TokenStorage as Storage } from "../../../contracts/facets/token/Storage.sol";
import { Token } from "../../../contracts/facets/token/Token.sol";

/// @title TokenHarness
/// @dev exposes internal Token internal functions for testing
contract TokenHarness is Token, ITokenHarness {
    /// @inheritdoc ITokenHarness
    function exposed_accrueTokens(address account) external {
        _accrueTokens(Storage.layout(), account);
    }
}
