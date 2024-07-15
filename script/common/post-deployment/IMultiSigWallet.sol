// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


/**
 * @title IMultiSigWallet
 * @dev MultiSigWallet interface
 * @notice Interface for the MultiSigWallet contract comes from the following version: https://github.com/gnosis/MultiSigWallet 
 */
interface IMultiSigWallet {
    function submitTransaction(address destination, uint value, bytes calldata data) external returns (uint transactionId);
    function confirmTransaction(uint transactionId) external;
}
