// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import { ExecutorStorage } from './ExecutorStorage.sol';

abstract contract ExecutorInternal {
    /**
     * @notice emitted when an account is set as the executor
     */
    event ExecutorSet(address account);

    /**
     * @notice sets an account to be the executor
     * @param account address to set as executor
     */
    function _setExecutor(address account) internal {
        ExecutorStorage.layout().executor = account;

        emit ExecutorSet(account);
    }

    /**
     * @notice returns executor address
     * @return executor address of executor
     */
    function _executor() internal view returns (address executor) {
        executor = ExecutorStorage.layout().executor;
    }
}