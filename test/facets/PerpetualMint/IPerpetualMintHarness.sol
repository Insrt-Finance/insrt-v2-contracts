// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { VRFConfig } from "../../../contracts/facets/PerpetualMint/Storage.sol";

/// @title IPerpetualMintHarness
/// @dev Interface for PerpetualMintHarness contract
interface IPerpetualMintHarness {
    /// @dev exposes _balanceOf method
    function exposed_balanceOf(
        address account,
        uint256 tokenId
    ) external view returns (uint256 balance);

    /// @dev exposes BASIS
    function exposed_basis() external view returns (uint32 basis);

    /// @dev exposes _enforceBasis
    function exposed_enforceBasis(uint32 risk) external pure;

    /// @dev exposes _enforceNoPendingMints
    function exposed_enforceNoPendingMints(address collection) external view;

    /// @dev exposes _normalizeValue
    function exposed_normalizeValue(
        uint256 value,
        uint32 basis
    ) external pure returns (uint256 normalizedValue);

    /// @dev exposes pendingRequests.add
    function exposed_pendingRequestsAdd(
        address collection,
        uint256 requestId
    ) external;

    /// @dev exposes pendingRequests.at
    function exposed_pendingRequestsAt(
        address collection,
        uint256 index
    ) external view returns (uint256 requestId);

    /// @dev exposes pendingRequests.length
    function exposed_pendingRequestsLength(
        address collection
    ) external view returns (uint256 length);

    /// @dev exposes _requestRandomWords
    function exposed_requestRandomWords(
        address minter,
        address collection,
        uint32 numWords
    ) external;

    /// @dev exposes requests
    function exposed_requests(
        uint256 requestId
    ) external view returns (address minter, address collection);

    /// @dev exposes _resolveMints
    function exposed_resolveMints(
        address minter,
        address collection,
        uint256[] memory randomWords
    ) external;

    /// @dev allows setting accrued consolation fees
    function setConsolationFees(uint256 amount) external;

    /// @dev allows setting accrued mint earnings
    function setMintEarnings(uint256 amount) external;

    /// @dev allows setting accrued protocol fees
    function setProtocolFees(uint256 amount) external;

    /// @dev allows setting request data
    function setRequests(
        uint256 requestId,
        address minter,
        address collection
    ) external;
}
