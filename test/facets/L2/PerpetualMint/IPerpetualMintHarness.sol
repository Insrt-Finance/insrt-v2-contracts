// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

/// @title IPerpetualMintHarness
/// @dev Interface for PerpetualMintHarness contract
interface IPerpetualMintHarness {
    /// @dev exposes _assignEscrowedERC1155Asset method
    function exposed_assignEscrowedERC1155Asset(
        address originalOwner,
        address newOwner,
        address collection,
        uint256 tokenId
    ) external;

    /// @dev exposes _balanceOf method
    function exposed_balanceOf(
        address account
    ) external view returns (uint256 balance);

    /// @dev exposes _normalizeValue
    function exposed_normalizeValue(
        uint256 value,
        uint256 basis
    ) external pure returns (uint256 normalizedValue);

    /// @dev exposes _resolveERC1155Mints
    function exposed_resolveERC1155Mints(
        address account,
        address collection,
        uint256[] memory randomWords
    ) external;

    /// @dev exposes _resolveERC721Mints
    function exposed_resolveERC721Mints(
        address account,
        address collection,
        uint256[] memory randomWords
    ) external;

    /// @dev exposes _selectERC1155Owner
    function exposed_selectERC1155Owner(
        address collection,
        uint256 tokenId,
        uint256 randomValue
    ) external view returns (address owner);

    /// @dev exposes _selectToken
    function exposed_selectToken(
        address collection,
        uint256 randomValue
    ) external view returns (uint256 tokenId);

    /// @dev exposes _updateDepositorEarnings
    function exposed_updateDepositorEarnings(
        address depositor,
        address collection
    ) external;
}
