// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { TokenTest } from "../../Token/Token.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { CoreTest } from "../../../diamonds/Core.t.sol";
import { TokenProxyTest } from "../../../diamonds/TokenProxy.t.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_redeem
/// @dev PerpetualMint test contract for testing expected redeem behavior. Tested on an Arbitrum fork.
contract PerpetualMint_redeem is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest,
    TokenTest
{
    /// @dev overrides the receive function to accept ETH
    receive() external payable override(CoreTest, TokenProxyTest) {}

    /// @dev sets up the context for the test cases
    function setUp() public override(PerpetualMintTest, TokenTest) {
        PerpetualMintTest.setUp();
        TokenTest.setUp();

        perpetualMint.setMintToken(address(token));

        vm.deal(address(perpetualMint), 100 ether);

        perpetualMint.setMintEarnings(100 ether);

        token.addMintingContract(address(perpetualMint));

        // mint tokens to minter
        vm.prank(MINTER);
        token.mint(minter, MINT_AMOUNT);
    }

    /// @dev Tests redeem functionality.
    /// Tests up to type(uint64).max redemption amount.
    function testFuzz_redeem(uint64 redemptionAmount) external {
        uint256 preRedeemAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        uint256 preRedeemProtocolEtherBalance = address(perpetualMint).balance;

        uint256 preRedeemTokenBalance = token.balanceOf(minter);

        vm.prank(minter);
        perpetualMint.redeem(redemptionAmount);

        uint256 expectedEthRedeemed = (uint256(redemptionAmount) *
            (perpetualMint.exposed_basis() - perpetualMint.redemptionFeeBP())) /
            (perpetualMint.exposed_basis() * perpetualMint.ethToMintRatio());

        uint256 postRedeemAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(
            postRedeemAccruedMintEarnings ==
                preRedeemAccruedMintEarnings - expectedEthRedeemed
        );

        uint256 postRedeemProtocolEtherBalance = address(perpetualMint).balance;

        assert(
            postRedeemProtocolEtherBalance ==
                preRedeemProtocolEtherBalance - expectedEthRedeemed
        );

        uint256 postRedeemTokenBalance = token.balanceOf(minter);

        assert(
            postRedeemTokenBalance == preRedeemTokenBalance - redemptionAmount
        );
    }
}
