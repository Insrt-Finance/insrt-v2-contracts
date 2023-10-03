// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";
import { IERC20BaseInternal } from "@solidstate/contracts/token/ERC20/base/IERC20BaseInternal.sol";

import { TokenTest } from "../Token.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { ITokenInternal } from "../../../../contracts/facets/Token/ITokenInternal.sol";

/// @title Token_airdropMint
/// @dev Token test contract for testing expected airdropMint behavior. Tested on an Arbitrum fork.
contract Token_airdropMint is ArbForkTest, TokenTest {
    /// @dev amount of $MINT to airdrop
    uint256 internal constant AIRDROP_MINT_AMOUNT = 10 ether;

    /// @dev tests airdropMint successfully mints tokens to token contract
    function test_airdropMint() external {
        vm.prank(MINTER);
        token.airdropMint(AIRDROP_MINT_AMOUNT);

        // assert that the token contract has minted all minted tokens
        assert(token.balanceOf(address(token)) == AIRDROP_MINT_AMOUNT);
    }

    /// @dev tests that airdropMint keeps the globalRatio and distributionSupply the same
    function test_airdropMintKeepsGlobalRatioDistributionSupplySame() external {
        vm.prank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        uint256 oldGlobalRatio = token.globalRatio();
        uint256 oldDistributionSupply = token.distributionSupply();

        vm.prank(MINTER);
        token.airdropMint(AIRDROP_MINT_AMOUNT);

        uint256 newGlobalRatio = token.globalRatio();
        uint256 newDistributionSupply = token.distributionSupply();

        assert(oldGlobalRatio == newGlobalRatio);
        assert(oldDistributionSupply == newDistributionSupply);
    }

    /// @dev tests that airdropMint increases airdropSupply by airdropAmount
    function test_airdropMintIncreasesAirdropSupply() external {
        uint256 oldAirdropSupply = token.airdropSupply();

        vm.prank(MINTER);
        token.airdropMint(AIRDROP_MINT_AMOUNT);

        uint256 newAirdropSupply = token.airdropSupply();

        assert(newAirdropSupply - oldAirdropSupply == AIRDROP_MINT_AMOUNT);
    }

    /// @dev tests that disepseTokens reverts when called by non-mintingContract
    function test_airdropMintRevertsWhen_CallerIsNotMintingContract() external {
        vm.expectRevert(ITokenInternal.NotMintingContract.selector);

        vm.prank(TOKEN_NON_OWNER);
        token.airdropMint(AIRDROP_MINT_AMOUNT);
    }
}
