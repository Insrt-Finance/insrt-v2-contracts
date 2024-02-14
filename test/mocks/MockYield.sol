// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title MockYield
/// @notice Mock Blast-specific Yield contract to be used in Blast-specific tests.
contract MockYield {
    mapping(address contractAddress => uint8 mode) internal configurations;

    function claim(
        address,
        address recipientOfYield,
        uint256 desiredAmount
    ) external returns (uint256 claimedAmount) {
        (bool success, ) = recipientOfYield.call{ value: desiredAmount }("");

        require(success, "");

        claimedAmount = desiredAmount;
    }

    function configure(
        address contractAddress,
        uint8 mode
    ) external returns (uint256) {
        configurations[contractAddress] = mode;

        return 0;
    }

    function getClaimableAmount(
        address
    ) external view returns (uint256 claimableAmount) {
        claimableAmount = address(this).balance;
    }

    function getConfiguration(
        address contractAddress
    ) external view returns (uint8 mode) {
        mode = configurations[contractAddress];
    }
}
