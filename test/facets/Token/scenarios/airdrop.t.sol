// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { PerpetualMintTest } from "../../PerpetualMint/PerpetualMint.t.sol";
import { TokenTest } from "../../Token/Token.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { CoreTest } from "../../../diamonds/Core.t.sol";
import { TokenProxyTest } from "../../../diamonds/TokenProxy.t.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

import "forge-std/console.sol";

/// @title PerpetualMint_airdrop
/// @dev PerpetualMint test contract for testing expected behavior of the airdrop $MINT scenario
contract PerpetualMint_airdrop is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest,
    TokenTest
{
    uint256 internal constant AIRDROP_AMOUNT = 10000 ether;
    uint256 internal constant ETH_TO_MINT_RATIO = 100 ether;
    address internal constant RECEIVER_ONE = address(1001);
    address internal constant RECEIVER_TWO = address(1002);

    /// @dev overrides the receive function to accept ETH
    receive() external payable override(CoreTest, TokenProxyTest) {}

    /// @dev sets up the context for the test cases
    function setUp() public override(PerpetualMintTest, TokenTest) {
        PerpetualMintTest.setUp();
        TokenTest.setUp();

        perpetualMint.setMintToken(address(token));

        token.addMintingContract(address(perpetualMint));

        address[] memory mintingContracts = token.mintingContracts();

        assert(mintingContracts[0] == MINTER);

        assert(mintingContracts[1] == address(perpetualMint));

        perpetualMint.setEthToMintRatio(ETH_TO_MINT_RATIO);

        assert(perpetualMint.ethToMintRatio() == ETH_TO_MINT_RATIO);
    }

    function test_airdrop() public {
        uint256 ethRequired = AIRDROP_AMOUNT / ETH_TO_MINT_RATIO;
        uint256 minterAmount = (AIRDROP_AMOUNT * 4) / 10;
        uint256 receiverOneAmount = (AIRDROP_AMOUNT * 5) / 10;
        uint256 receiverTwoAmount = (AIRDROP_AMOUNT * 1) / 10;

        perpetualMint.airdropMint{ value: ethRequired }(AIRDROP_AMOUNT);

        address[] memory accounts = new address[](3);
        uint256[] memory amounts = new uint256[](3);

        accounts[0] = MINTER;
        accounts[1] = RECEIVER_ONE;
        accounts[2] = RECEIVER_TWO;

        amounts[0] = minterAmount;
        amounts[1] = receiverOneAmount;
        amounts[2] = receiverTwoAmount;

        uint256 oldMinterBalance = token.balanceOf(MINTER);
        uint256 oldReceiverOneBalance = token.balanceOf(RECEIVER_ONE);
        uint256 oldReceiverTwoBalance = token.balanceOf(RECEIVER_TWO);

        token.disperseTokens(accounts, amounts);

        uint256 newMinterBalance = token.balanceOf(MINTER);
        uint256 newReceiverOneBalance = token.balanceOf(RECEIVER_ONE);
        uint256 newReceiverTwoBalance = token.balanceOf(RECEIVER_TWO);

        assert(newMinterBalance - oldMinterBalance == minterAmount);
        assert(
            newReceiverOneBalance - oldReceiverOneBalance == receiverOneAmount
        );
        assert(
            newReceiverTwoBalance - oldReceiverTwoBalance == receiverTwoAmount
        );

        //mint for MINTER
        vm.prank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        // since MINTER is minting they are not eligible to any of the DISTRIBUTION_AMOUNT
        // with RECEIVER_ONE/TWO being eligible to 5/6 and 1/6 of the DISTRIBUTION_AMOUNT respectively,
        // since they own 5/6 and 1/6 of the (totalSupply - minterBalance)
        // ± 1 error range due to rounding
        assert(
            minterAmount + MINT_AMOUNT - DISTRIBUTION_AMOUNT + 1 >=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );
        assert(
            receiverOneAmount + ((DISTRIBUTION_AMOUNT * 5) / 6) + 1 >=
                token.balanceOf(RECEIVER_ONE) +
                    token.claimableTokens(RECEIVER_ONE)
        );
        assert(
            receiverTwoAmount + ((DISTRIBUTION_AMOUNT * 1) / 6) + 1 >=
                token.balanceOf(RECEIVER_TWO) +
                    token.claimableTokens(RECEIVER_TWO)
        );
    }

    /// @dev ensures that throughout a series of actions the $MINT tokens are distributed correctly
    /// @dev this is a copy of the first test in the mint.t.sol scenario test, to ensure distribution happens correctly
    /// after an airdrop
    /// amongst the participants of the system
    /// the sequence of actions is:
    /// - MINTER mints
    /// - RECEIVER_ONE mints
    /// - RECEIVER_TWO mints
    /// - MINTER claims
    /// - RECEIVER_ONE mints
    /// - MINTER burns
    /// - RECEIVER_TWO mints
    /// each of the actions listed above affect token accruals and future distributions so
    /// after each action, the division of the distributed tokens is checked
    function _accountingOfAccruedTokensWithMultipleReceiversAcrossMultipleActions()
        internal
    {
        // mint for MINTER
        vm.prank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        // since only one holder (MINTER), all of the MINT_AMOUNT should belong to them
        // ± 1 error range due to rounding
        assert(
            MINT_AMOUNT + 1 >=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        assert(
            MINT_AMOUNT - 1 <=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        // mint for RECEIVER_ONE
        vm.prank(MINTER);
        token.mint(RECEIVER_ONE, MINT_AMOUNT);

        // second holder (RECEIVER_ONE) should be entitled to the minted amount minus whatever
        // amount is kept for distribution
        assert(
            MINT_AMOUNT - DISTRIBUTION_AMOUNT ==
                token.balanceOf(RECEIVER_ONE) +
                    token.claimableTokens(RECEIVER_ONE)
        );

        // first holder (MINTER) is entitled to the full amount of RECEIVE_ONE's distributionAmount, so should have
        // their own MINT_AMOUNT + DISTRIBUTION_AMOUNT
        // ± 1 error range due to rounding
        assert(
            MINT_AMOUNT + DISTRIBUTION_AMOUNT + 1 >=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );
        assert(
            MINT_AMOUNT + DISTRIBUTION_AMOUNT - 1 <=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        // mint for RECEIVER_TWO
        vm.prank(MINTER);
        token.mint(RECEIVER_TWO, MINT_AMOUNT);

        // third holder (RECEIVER_TWO) is entitled to the minted amount minus whatever
        // amount is kept for distribution
        assert(
            MINT_AMOUNT - DISTRIBUTION_AMOUNT ==
                token.balanceOf(RECEIVER_TWO) +
                    token.claimableTokens(RECEIVER_TWO)
        );

        // second holder (RECEIVER_ONE) is entitled to 1/2 of the DISTRIBUTION_AMOUNT contributed by RECEIVE_TWO since
        // they own 1/2 of the total supply - distirbution supply
        // ± 1 error range due to rounding
        assert(
            MINT_AMOUNT - (DISTRIBUTION_AMOUNT / 2) + 1 >=
                token.balanceOf(RECEIVER_ONE) +
                    token.claimableTokens(RECEIVER_ONE)
        );
        assert(
            MINT_AMOUNT - (DISTRIBUTION_AMOUNT / 2) - 1 <=
                token.balanceOf(RECEIVER_ONE) +
                    token.claimableTokens(RECEIVER_ONE)
        );

        // first holder (MINTER) is entitled to 1/2 of the DISTRIBUTION_AMOUNT contributed by RECEIVE_TWO since
        // they own 1/2 of the total supply - distirbution supply, as well as what they were entitled previously
        // ± 1 error range due to rounding
        assert(
            MINT_AMOUNT + ((DISTRIBUTION_AMOUNT * 3) / 2) + 1 >=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );
        assert(
            MINT_AMOUNT + ((DISTRIBUTION_AMOUNT * 3) / 2) - 1 <=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        // claim for MINTER
        vm.prank(MINTER);
        token.claim();

        // after MINTER has claimed, the amount they are owed from the distribution supply, which is
        // (DISTRIBUTION_AMOUNT * 3 / 2) should be transferred to them
        assert(
            MINT_AMOUNT + ((DISTRIBUTION_AMOUNT * 3) / 2) + 1 >=
                token.balanceOf(MINTER)
        );
        assert(
            MINT_AMOUNT + ((DISTRIBUTION_AMOUNT * 3) / 2) - 1 <=
                token.balanceOf(MINTER)
        );

        // mint second time for RECEIVER_ONE
        vm.prank(MINTER);
        token.mint(RECEIVER_ONE, MINT_AMOUNT);

        // receiver one is not entitled to any portion of their newly contributed distributionAmount,
        // so their token claims should remain the same, whilst their balance should increase by MINT_AMOUNT - DISTRIBUTION_AMOUNT
        // ± 1 error range due to rounding
        assert(
            2 * MINT_AMOUNT - ((DISTRIBUTION_AMOUNT * 3) / 2) + 1 >=
                token.balanceOf(RECEIVER_ONE) +
                    token.claimableTokens(RECEIVER_ONE)
        );
        assert(
            2 * MINT_AMOUNT - ((DISTRIBUTION_AMOUNT * 3) / 2) - 1 <=
                token.balanceOf(RECEIVER_ONE) +
                    token.claimableTokens(RECEIVER_ONE)
        );

        // MINTER has MINT_AMOUNT + 3 / 2 * DISTRIBUTION_AMOUNT of tokens after the claim, whilst
        // RECEIVER_TWO has MINT_AMOUNT - DISTRIBUTION_AMOUNT of tokens
        // it follows that MINTER is entitled to ( MINT_AMOUNT + 3 / 2 * DISTRIBUTION_AMOUNT) / (2 * MINT_AMOUNT + DISTRIBUTION_AMOUNT / 2)
        // of the new distributionAmount contributed by RECEIVER_ONE
        // ± 1 error range due to rounding
        uint256 minterShareOfFourthMint = ((MINT_AMOUNT +
            (DISTRIBUTION_AMOUNT * 3) /
            2) * DISTRIBUTION_AMOUNT) /
            (2 * MINT_AMOUNT + DISTRIBUTION_AMOUNT / 2);

        assert(
            MINT_AMOUNT +
                ((DISTRIBUTION_AMOUNT * 3) / 2) +
                minterShareOfFourthMint +
                1 >=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );
        assert(
            MINT_AMOUNT +
                ((DISTRIBUTION_AMOUNT * 3) / 2) +
                minterShareOfFourthMint -
                1 <=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        // RECEIVER_TWO has MINT_AMOUNT - DISTRIBUTION_AMOUNT of their mint
        // it follows that RECEIVER_TWO is entitled to ((MINT_AMOUNT - DISTRIBUTION_AMOUNT) * DISTRIBUTION_AMOUNT) / (2 * MINT_AMOUNT + DISTRIBUTION_AMOUNT / 2)
        // of the new distributionAmount contributed by RECEIVER_ONE
        // ± 1 error range due to rounding
        assert(
            MINT_AMOUNT - minterShareOfFourthMint + 1 >=
                token.balanceOf(RECEIVER_TWO) +
                    token.claimableTokens(RECEIVER_TWO)
        );
        assert(
            MINT_AMOUNT - minterShareOfFourthMint - 1 <=
                token.balanceOf(RECEIVER_TWO) +
                    token.claimableTokens(RECEIVER_TWO)
        );

        // burn balance of MINTER tokens
        vm.startPrank(MINTER); //refresh Foundry memory
        token.burn(MINTER, token.balanceOf(MINTER));

        // MINTER should only be entitled to minterShareOfFourthMint since all of their balance
        // was burnt
        assert(
            minterShareOfFourthMint + 1 >=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        assert(
            minterShareOfFourthMint - 1 <=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        // mint to RECEIVER_TWO
        token.mint(RECEIVER_TWO, MINT_AMOUNT);

        // since MINTER burned all of their tokens, they should only be entitled to their previously
        // unclaimed tokens, which is minterShareOfFourthMint
        // ± 1 error range due to rounding
        assert(
            minterShareOfFourthMint + 1 >=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        assert(
            minterShareOfFourthMint - 1 <=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        // since RECEIVER_TWO is not entitled to any of the DISTRIBUTION_AMOUNT contributed by them,
        // RECEIVER_ONE is entitled to all of it
        // RECEIVER_ONE has minted twice, so they have received (MINT_AMOUNT - DISTRIBUTION_AMOUNT) * 2
        // and were entitled to claim DISTRIBUTION_AMOUNT / 2 from the first mint of RECEIVER_TWO
        // therefore the overall balance of RECEIVER_ONE should be
        // 2 * MINT_AMOUNT - 1/2 DISTRIBUTION_AMOUNT
        //  ± 3 error range due to rounding
        assert(
            2 * MINT_AMOUNT - (DISTRIBUTION_AMOUNT / 2) + 3 >=
                token.balanceOf(RECEIVER_ONE) +
                    token.claimableTokens(RECEIVER_ONE)
        );
        assert(
            2 * MINT_AMOUNT - (DISTRIBUTION_AMOUNT / 2) - 3 <=
                token.balanceOf(RECEIVER_ONE) +
                    token.claimableTokens(RECEIVER_ONE)
        );
    }
}
