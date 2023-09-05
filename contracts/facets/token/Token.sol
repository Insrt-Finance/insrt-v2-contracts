// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { ERC20BaseInternal } from "@solidstate/contracts/token/ERC20/base/ERC20BaseInternal.sol";
import { SolidStateERC20 } from "@solidstate/contracts/token/ERC20/SolidStateERC20.sol";

import { IToken } from "./IToken.sol";
import { TokenInternal } from "./TokenInternal.sol";

/// @title Token contract
/// @dev contains all externally called functions and necessary override for the Token facet
contract Token is TokenInternal, SolidStateERC20, IToken {
    /// @inheritdoc IToken
    function addMintingContract(address account) external onlyOwner {
        _addMintingContract(account);
    }

    /// @notice overrides _beforeTokenTransfer hook to enforce non-transferability
    /// @param from sender of tokens
    /// @param to receiver of tokens
    /// @param amount quantity of tokens transferred
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20BaseInternal, TokenInternal) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /// @inheritdoc IToken
    function burn(
        address account,
        uint256 amount
    ) external onlyMintingContract {
        _burn(amount, account);
    }

    /// @inheritdoc IToken
    function claim() external {
        _claim(msg.sender);
    }

    /// @inheritdoc IToken
    function mint(
        address account,
        uint256 amount
    ) external onlyMintingContract {
        _mint(amount, account);
    }

    /// @inheritdoc IToken
    function removeMintingContract(address account) external onlyOwner {
        _removeMintingContract(account);
    }

    /// @inheritdoc IToken
    function setDistributionFractionBP(
        uint32 distributionFractionBP
    ) external onlyOwner {
        _setDistributionFractionBP(distributionFractionBP);
    }
}