// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

/// @title IPerpetualMintHarness
/// @dev Interface for PerpetualMintHarness contract
interface IPerpetualMintHarness {
    /// @dev exposes _assignEscrowedERC1155Asset method
    function exposed_assignEscrowedERC1155Asset(
        address from,
        address to,
        address collection,
        uint256 tokenId,
        uint256 tokenRisk
    ) external;

    /// @dev exposes _normalizeValue
    function exposed_normalizeValue(
        uint256 value,
        uint256 basis
    ) external pure returns (uint256 normalizedValue);

    /// @dev exposes _resolveERC1155Mint
    function exposed_resolveERC1155Mint(
        address account,
        address collection,
        uint256[] memory randomWords
    ) external;

    /// @dev exposes _resolveERC721Mint
    function exposed_resolveERC721Mint(
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
