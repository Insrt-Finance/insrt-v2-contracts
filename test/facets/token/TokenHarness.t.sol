// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

import { ITokenHarness } from "./ITokenHarness.sol";
import { TokenStorage as Storage } from "../../../contracts/facets/token/Storage.sol";
import { Token } from "../../../contracts/facets/token/Token.sol";

/// @title TokenHarness
/// @dev exposes internal Token internal functions for testing
contract TokenHarness is Token, ITokenHarness {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @inheritdoc ITokenHarness
    function exposed_accrueTokens(address account) external {
        _accrueTokens(Storage.layout(), account);
    }

    /// @inheritdoc ITokenHarness
    function mock_addMintingContract(address account) external {
        Storage.layout().mintingContracts.add(account);
    }

    /// @inheritdoc ITokenHarness
    function accountOffset(
        address account
    ) external view returns (uint256 offset) {
        offset = Storage.layout().accountOffset[account];
    }

    /// @inheritdoc ITokenHarness
    function distributionSupply() external view returns (uint256 supply) {
        supply = Storage.layout().distributionSupply;
    }

    /// @inheritdoc ITokenHarness
    function globalRatio() external view returns (uint256 ratio) {
        ratio = Storage.layout().globalRatio;
    }
}
