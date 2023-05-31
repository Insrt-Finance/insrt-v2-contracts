// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import {OwnableInternal} from "@solidstate-solidity/access/ownable/OwnableInternal.sol";

import {Errors} from "./Errors.sol";
import {ExecutorInternal} from "./ExecutorInternal.sol";

abstract contract AccessControl is OwnableInternal, ExecutorInternal {
    /**
     * @notice reverts if msg.sender is not procol owner
     */
    modifier onlyProtocolOwner() {
        _onlyProtocolOwner(msg.sender);
        _;
    }

    /**
     * @notice reverts if msg.sender is not executor
     */
    modifier onlyExecutor() {
        _onlyExecutor(msg.sender);
        _;
    }

    /**
     * @notice returns the protocol owner
     * @return address of the protocol owner
     */
    function _protocolOwner() internal view returns (address) {
        return _transitiveOwner();
    }

    /**
     * @notice check if an account is the protocol owner, reverts if not
     * @param account to check
     */
    function _onlyProtocolOwner(address account) internal view {
        if (account != _protocolOwner()) {
            revert Errors.INLP__NotProtocolOwner();
        }
    }

    /**
     * @notice check if an account is the executor, reverts if not
     * @param account to check
     */
    function _onlyExecutor(address account) internal view {
        if (account != _executor()) {
            revert Errors.INLP__NotExecutor();
        }
    }
}
