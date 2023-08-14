// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IPerpetualMintHarness } from "./IPerpetualMintHarness.sol";
import { VRFConsumerBaseV2Mock } from "../../../mocks/VRFConsumerBaseV2Mock.sol";
import { PerpetualMint } from "../../../../contracts/facets/L2/PerpetualMint/PerpetualMint.sol";
import { PerpetualMintStorage as Storage } from "../../../../contracts/facets/L2/PerpetualMint/Storage.sol";

/// @title PerpetualMintHarness
/// @dev exposes internal PerpetualMint internal functions for testing
contract PerpetualMintHarness is
    IPerpetualMintHarness,
    PerpetualMint,
    VRFConsumerBaseV2Mock
{
    constructor(address vrf) PerpetualMint(vrf) {}

    /// @dev exposes _assignEscrowedERC1155Asset method
    function exposed_assignEscrowedERC1155Asset(
        address originalOwner,
        address newOwner,
        address collection,
        uint256 tokenId
    ) external {
        Storage.Layout storage l = Storage.layout();

        _assignEscrowedERC1155Asset(
            l,
            originalOwner,
            newOwner,
            collection,
            tokenId
        );
    }

    /// @dev IPerpetualMintHarness
    function exposed_balanceOf(
        address account
    ) external view returns (uint256 balance) {
        balance = _balanceOf(account);
    }

    /// @dev exposes _normalizeValue method
    function exposed_normalizeValue(
        uint256 value,
        uint256 basis
    ) external pure returns (uint256 normalizedValue) {
        normalizedValue = _normalizeValue(value, basis);
    }

    /// @dev exposes _resolve1155Mints method
    function exposed_resolveERC1155Mints(
        address account,
        address collection,
        uint256[] memory randomWords
    ) external {
        Storage.Layout storage l = Storage.layout();

        _resolveERC1155Mints(l, account, collection, randomWords);
    }

    /// @dev exposes _resolveERC721Mints method
    function exposed_resolveERC721Mints(
        address account,
        address collection,
        uint256[] memory randomWords
    ) external {
        Storage.Layout storage l = Storage.layout();

        _resolveERC721Mints(l, account, collection, randomWords);
    }

    /// @dev exposis _selectERC1155Owner
    function exposed_selectERC1155Owner(
        address collection,
        uint256 tokenId,
        uint256 randomValue
    ) external view returns (address owner) {
        Storage.Layout storage l = Storage.layout();

        owner = _selectERC1155Owner(l, collection, tokenId, randomValue);
    }

    /// @dev exposes _selectToken method
    function exposed_selectToken(
        address collection,
        uint256 randomValue
    ) external view returns (uint256 tokenId) {
        Storage.Layout storage l = Storage.layout();

        tokenId = _selectToken(l, collection, randomValue);
    }

    /// @dev exposes _updateDepositorEarnings method
    function exposed_updateDepositorEarnings(
        address depositor,
        address collection
    ) external {
        Storage.Layout storage l = Storage.layout();

        _updateDepositorEarnings(l, depositor, collection);
    }
}
