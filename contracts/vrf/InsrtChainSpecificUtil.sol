// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { ArbSys } from "@chainlink/vendor/@arbitrum/nitro-contracts/src/precompiles/ArbSys.sol";

/// @title InsrtChainSpecificUtil
/// @dev A simplified version of Chainlink's ChainSpecificUtil library.
/// @dev This library is used to abstract out opcodes that behave differently across chains.
library InsrtChainSpecificUtil {
    // ------------ Start Arbitrum Constants ------------

    /// @dev ARBSYS_ADDR is the address of the ArbSys precompile on Arbitrum.
    /// @dev reference: https://github.com/OffchainLabs/nitro/blob/v2.0.14/contracts/src/precompiles/ArbSys.sol#L10
    address private constant ARBSYS_ADDR =
        address(0x0000000000000000000000000000000000000064);

    ArbSys private constant ARBSYS = ArbSys(ARBSYS_ADDR);

    /// @dev Arbitrum Goerli Chain ID
    uint24 private constant ARB_GOERLI_TESTNET_CHAIN_ID = 421613;

    /// @dev Arbitrum Mainnet Chain ID
    uint16 private constant ARB_MAINNET_CHAIN_ID = 42161;

    /// @dev Arbitrum Sepolia Testnet Chain ID
    uint24 private constant ARB_SEPOLIA_TESTNET_CHAIN_ID = 421614;

    // ------------ End Arbitrum Constants ------------

    /// @notice Returns the block number of the current block.
    /// @notice When on a known Arbitrum chain, it uses ArbSys.
    /// @notice Otherwise, it uses the block.number opcode.
    /// @notice Note that the block.number opcode will return the L2 block number on Optimism.
    /// @return blockNumber The block number of the current block.
    function _getBlockNumber() internal view returns (uint64 blockNumber) {
        uint24 chainid = uint24(block.chainid);

        blockNumber = _isArbitrumChainId(chainid)
            ? uint64(ARBSYS.arbBlockNumber())
            : uint64(block.number);
    }

    /// @notice Returns true if and only if the provided chain ID is an Arbitrum chain ID.
    /// @param chainId The chain ID to check.
    /// @return True if the chain ID is an Arbitrum chain ID, otherwise false.
    function _isArbitrumChainId(uint24 chainId) internal pure returns (bool) {
        return
            chainId == ARB_MAINNET_CHAIN_ID ||
            chainId == ARB_GOERLI_TESTNET_CHAIN_ID ||
            chainId == ARB_SEPOLIA_TESTNET_CHAIN_ID;
    }
}
