// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { PerpetualMint } from "../../../../contracts/facets/L2/PerpetualMint/PerpetualMint.sol";
import { IPerpetualMintHarness } from "./IPerpetualMintHarness.sol";

/// @title PerpetualMintHarness
/// @dev exposes internal PerpetualMint internal functions for testing
contract PerpetualMintHarness is IPerpetualMintHarness, PerpetualMint {
    constructor(address vrf) PerpetualMint(vrf) {}

    /// @dev exposes _assignEscrowedERC1155Asset method
    function exposed_assignEscrowedERC1155Asset(
        address from,
        address to,
        address collection,
        uint256 tokenId,
        uint256 tokenRisk
    ) external {
        _assignEscrowedERC1155Asset(from, to, collection, tokenId, tokenRisk);
    }

    /// @dev exposes _normalizeValue method
    function exposed_normalizeValue(
        uint256 value,
        uint256 basis
    ) external pure returns (uint256 normalizedValue) {
        normalizedValue = _normalizeValue(value, basis);
    }

    /// @dev exposes _resolve1155Mint method
    function exposed_resolveERC1155Mint(
        address account,
        address collection,
        uint256[] memory randomWords
    ) external {
        _resolveERC1155Mint(account, collection, randomWords);
    }

    /// @dev exposes _resolveERC721Mint method
    function exposed_resolveERC721Mint(
        address account,
        address collection,
        uint256[] memory randomWords
    ) external {
        _resolveERC721Mint(account, collection, randomWords);
    }

    /// @dev exposis _selectERC1155Owner
    function exposed_selectERC1155Owner(
        address collection,
        uint256 tokenId,
        uint256 randomValue
    ) external view returns (address owner) {
        owner = _selectERC1155Owner(collection, tokenId, randomValue);
    }

    /// @dev exposes _selectToken method
    function exposed_selectToken(
        address collection,
        uint256 randomValue
    ) external view returns (uint256 tokenId) {
        tokenId = _selectToken(collection, randomValue);
    }

    /// @dev exposes _updateDepositorEarnings method
    function exposed_updateDepositorEarnings(
        address depositor,
        address collection
    ) external {
        _updateDepositorEarnings(depositor, collection);
    }
}
