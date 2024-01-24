// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @dev DataTypes.sol defines the enum data types used in the Blast yield contract

/// @dev GasMode defines the gas mode options for the Blast yield contract
enum GasMode {
    VOID,
    CLAIMABLE
}

/// @dev YieldMode defines the yield mode options for the Blast yield contract
enum YieldMode {
    AUTOMATIC,
    VOID,
    CLAIMABLE
}
