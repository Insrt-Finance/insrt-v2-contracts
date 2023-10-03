// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { PerpetualMintTest } from "../../PerpetualMint/PerpetualMint.t.sol";
import { TokenTest } from "../../Token/Token.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { CoreTest } from "../../../diamonds/Core.t.sol";
import { TokenProxyTest } from "../../../diamonds/TokenProxy.t.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

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

    uint256 internal constant MINTER_AIRDROP_AMOUNT = (AIRDROP_AMOUNT * 4) / 10;
    uint256 internal constant RECEIVER_ONE_AIRDROP_AMOUNT =
        (AIRDROP_AMOUNT * 5) / 10;
    uint256 internal constant RECEIVER_TWO_AIRDROP_AMOUNT =
        (AIRDROP_AMOUNT * 1) / 10;
    uint256 internal AMOUNT_TO_MINTER;

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

        AMOUNT_TO_MINTER = MINT_AMOUNT - DISTRIBUTION_AMOUNT;
    }

    /// @dev tests that airdropping does not break distribution accounting  when its the first set of actions
    /// taken by the token contract
    /// the sequence of actions following the airdrop is:
    /// - mint MINT_AMOUNT for MINTER
    /// - mint MINT_AMOUNT for RECEIVER_ONE
    /// - burn RECEIVER_TWO_AIRDROP_AMOUNT from RECEIVER_TWO
    /// - claim for RECEIVER_TWO
    /// - burn (RECEIVER_TWO_AIRDROP_AMOUNT * DISTRIBUTION_AMOUNT) / (MINTER_AIRDROP_AMOUNT + AMOUNT_TO_MINTER + RECEIVER_TWO_AIRDROP_AMOUNT) from RECEIVER_TWO
    /// - mint MINT_AMOUNT for MINTER
    /// throughout these actions, the total eligible tokens are checked to be as expected
    function test_airdropPriorToAnyMinting() public {
        uint256 ethRequired = AIRDROP_AMOUNT / ETH_TO_MINT_RATIO;

        perpetualMint.mintAirdrop{ value: ethRequired }(AIRDROP_AMOUNT);

        address[] memory accounts = new address[](3);
        uint256[] memory amounts = new uint256[](3);

        accounts[0] = MINTER;
        accounts[1] = RECEIVER_ONE;
        accounts[2] = RECEIVER_TWO;

        amounts[0] = MINTER_AIRDROP_AMOUNT;
        amounts[1] = RECEIVER_ONE_AIRDROP_AMOUNT;
        amounts[2] = RECEIVER_TWO_AIRDROP_AMOUNT;

        uint256 oldMinterBalance = token.balanceOf(MINTER);
        uint256 oldReceiverOneBalance = token.balanceOf(RECEIVER_ONE);
        uint256 oldReceiverTwoBalance = token.balanceOf(RECEIVER_TWO);

        token.disperseTokens(accounts, amounts);

        uint256 newMinterBalance = token.balanceOf(MINTER);
        uint256 newReceiverOneBalance = token.balanceOf(RECEIVER_ONE);
        uint256 newReceiverTwoBalance = token.balanceOf(RECEIVER_TWO);

        assert(newMinterBalance - oldMinterBalance == MINTER_AIRDROP_AMOUNT);
        assert(
            newReceiverOneBalance - oldReceiverOneBalance ==
                RECEIVER_ONE_AIRDROP_AMOUNT
        );
        assert(
            newReceiverTwoBalance - oldReceiverTwoBalance ==
                RECEIVER_TWO_AIRDROP_AMOUNT
        );

        // mint for MINTER
        vm.prank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        // since MINTER is minting they are not eligible to any of the DISTRIBUTION_AMOUNT
        // with RECEIVER_ONE/TWO being eligible to 5/6 and 1/6 of the DISTRIBUTION_AMOUNT respectively,
        // since their only balance is the amount they have been airdropped:
        // RECEIVER_ONE balance: RECEIVER_ONE_AIDROP_AMOUNT
        // RECEIVER_TWO balance: RECEIVER_TWO_AIDROP_AMOUNT
        // ± 1 error range due to rounding
        assert(
            MINTER_AIRDROP_AMOUNT + AMOUNT_TO_MINTER + 1 >=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );
        assert(
            RECEIVER_ONE_AIRDROP_AMOUNT + ((DISTRIBUTION_AMOUNT * 5) / 6) + 1 >=
                token.balanceOf(RECEIVER_ONE) +
                    token.claimableTokens(RECEIVER_ONE)
        );
        assert(
            RECEIVER_TWO_AIRDROP_AMOUNT + ((DISTRIBUTION_AMOUNT * 1) / 6) + 1 >=
                token.balanceOf(RECEIVER_TWO) +
                    token.claimableTokens(RECEIVER_TWO)
        );

        // mint for RECEIVER_ONE
        vm.prank(MINTER);
        token.mint(RECEIVER_ONE, MINT_AMOUNT);

        // second holder (RECEIVER_ONE) should be entitled to whatever they were entitled to previously
        // and the minted amount minus whatever amount is kept for distribution
        assert(
            RECEIVER_ONE_AIRDROP_AMOUNT +
                (((DISTRIBUTION_AMOUNT) * 5) / 6) +
                AMOUNT_TO_MINTER +
                1 >=
                token.balanceOf(RECEIVER_ONE) +
                    token.claimableTokens(RECEIVER_ONE)
        );

        // the total token balance of the other two holders is:
        // (MINTER_AIRDROP_AMOUNT + AMOUNT_TO_MINTER + RECEIVER_TWO_AIRDROP_AMOUNT)
        // therefore, from the new DISTRIBUTION_AMOUNT MINTER is entitled to:
        // (MINTER_AIRDROP_AMOUNT + AMOUNT_TO_MINTER) * DISTRIBUTION_AMOUNT / (MINTER_AIRDROP_AMOUNT + AMOUNT_TO_MINTER + RECEIVER_TWO_AIRDROP_AMOUNT)
        // and RECEIVER_TWO is entitled to:
        // RECEIVER_TWO_AIRDROP_AMOUNT * DISTRIBUTION_AMOUNT / (MINTER_AIRDROP_AMOUNT + AMOUNT_TO_MINTER + RECEIVER_TWO_AIRDROP_AMOUNT)
        assert(
            MINTER_AIRDROP_AMOUNT +
                AMOUNT_TO_MINTER +
                ((MINTER_AIRDROP_AMOUNT + AMOUNT_TO_MINTER) *
                    DISTRIBUTION_AMOUNT) /
                (MINTER_AIRDROP_AMOUNT +
                    AMOUNT_TO_MINTER +
                    RECEIVER_TWO_AIRDROP_AMOUNT) +
                1 >=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        assert(
            RECEIVER_TWO_AIRDROP_AMOUNT +
                ((DISTRIBUTION_AMOUNT) / 6) +
                (RECEIVER_TWO_AIRDROP_AMOUNT * DISTRIBUTION_AMOUNT) /
                (MINTER_AIRDROP_AMOUNT +
                    AMOUNT_TO_MINTER +
                    RECEIVER_TWO_AIRDROP_AMOUNT) +
                1 >=
                token.balanceOf(RECEIVER_TWO) +
                    token.claimableTokens(RECEIVER_TWO)
        );

        // burn some of RECEIVER_TWO tokens
        vm.prank(MINTER);
        token.burn(RECEIVER_TWO, RECEIVER_TWO_AIRDROP_AMOUNT);

        // claim for RECEIVER_TWO
        vm.prank(RECEIVER_TWO);
        token.claim();

        assert(
            ((DISTRIBUTION_AMOUNT) / 6) +
                (RECEIVER_TWO_AIRDROP_AMOUNT * DISTRIBUTION_AMOUNT) /
                (MINTER_AIRDROP_AMOUNT +
                    AMOUNT_TO_MINTER +
                    RECEIVER_TWO_AIRDROP_AMOUNT) ==
                token.balanceOf(RECEIVER_TWO)
        );

        // burn some of RECEIVER_TWO tokens
        vm.prank(MINTER);
        token.burn(
            RECEIVER_TWO,
            (RECEIVER_TWO_AIRDROP_AMOUNT * DISTRIBUTION_AMOUNT) /
                (MINTER_AIRDROP_AMOUNT +
                    AMOUNT_TO_MINTER +
                    RECEIVER_TWO_AIRDROP_AMOUNT)
        );

        assert(((DISTRIBUTION_AMOUNT) / 6) == token.balanceOf(RECEIVER_TWO));

        // mint some tokens for MINTER
        vm.prank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        // MINTER should be entitled to whatever they were entitled to previously
        // and the minted amount minus whatever amount is kept for distribution
        assert(
            MINTER_AIRDROP_AMOUNT +
                2 *
                AMOUNT_TO_MINTER +
                ((MINTER_AIRDROP_AMOUNT + AMOUNT_TO_MINTER) *
                    DISTRIBUTION_AMOUNT) /
                (MINTER_AIRDROP_AMOUNT +
                    AMOUNT_TO_MINTER +
                    RECEIVER_TWO_AIRDROP_AMOUNT) +
                1 >=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        // the total token balance of the other two holders is:
        //  ((DISTRIBUTION_AMOUNT) / 6) +  RECEIVER_ONE_AIRDROP_AMOUNT + AMOUNT_TO_MINTER
        // therefore, from the new DISTRIBUTION_AMOUNT RECEIVER_ONE is entitled to:
        // (RECEIVER_ONE_AIRDROP_AMOUNT + AMOUNT_TO_MINTER) * DISTRIBUTION_AMOUNT  / (((DISTRIBUTION_AMOUNT) / 6) +  RECEIVER_ONE_AIRDROP_AMOUNT + AMOUNT_TO_MINTER)
        // and RECEIVER_TWO is entitled to:
        // ((DISTRIBUTION_AMOUNT) / 6) * DISTRIBUTION_AMOUNT / (((DISTRIBUTION_AMOUNT) / 6) +  RECEIVER_ONE_AIRDROP_AMOUNT + AMOUNT_TO_MINTER)
        assert(
            RECEIVER_ONE_AIRDROP_AMOUNT +
                (((DISTRIBUTION_AMOUNT) * 5) / 6) +
                AMOUNT_TO_MINTER +
                ((RECEIVER_ONE_AIRDROP_AMOUNT + AMOUNT_TO_MINTER) *
                    DISTRIBUTION_AMOUNT) /
                (((DISTRIBUTION_AMOUNT) / 6) +
                    RECEIVER_ONE_AIRDROP_AMOUNT +
                    AMOUNT_TO_MINTER) +
                1 >=
                token.balanceOf(RECEIVER_ONE) +
                    token.claimableTokens(RECEIVER_ONE)
        );

        assert(
            ((DISTRIBUTION_AMOUNT) / 6) +
                (((DISTRIBUTION_AMOUNT) / 6) * DISTRIBUTION_AMOUNT) /
                (((DISTRIBUTION_AMOUNT) / 6) +
                    RECEIVER_ONE_AIRDROP_AMOUNT +
                    AMOUNT_TO_MINTER) +
                1 >=
                token.balanceOf(RECEIVER_TWO) +
                    token.claimableTokens(RECEIVER_TWO)
        );
    }

    /// @dev tests that airdropping does not break distribution accounting regardless of when its called
    /// the sequence of actions in the test case are:
    /// - airdrop
    /// - mint MINT_AMOUNT for MINTER
    /// - airdrop
    /// - mint MINT_AMOUNT for MINTER
    /// - claim for RECEIVER_ONE
    /// - mint MINT_AMOUNT for RECEIVER_ONE
    /// throughout these actions, the total eligible tokens are checked to be as expected
    function test_airdropThroughoutMinting() public {
        uint256 ethRequired = AIRDROP_AMOUNT / ETH_TO_MINT_RATIO;

        // perform first aidrop
        perpetualMint.mintAirdrop{ value: ethRequired }(AIRDROP_AMOUNT);

        address[] memory accounts = new address[](3);
        uint256[] memory amounts = new uint256[](3);

        accounts[0] = MINTER;
        accounts[1] = RECEIVER_ONE;
        accounts[2] = RECEIVER_TWO;

        amounts[0] = MINTER_AIRDROP_AMOUNT;
        amounts[1] = RECEIVER_ONE_AIRDROP_AMOUNT;
        amounts[2] = RECEIVER_TWO_AIRDROP_AMOUNT;

        uint256 oldMinterBalance = token.balanceOf(MINTER);
        uint256 oldReceiverOneBalance = token.balanceOf(RECEIVER_ONE);
        uint256 oldReceiverTwoBalance = token.balanceOf(RECEIVER_TWO);

        token.disperseTokens(accounts, amounts);

        uint256 newMinterBalance = token.balanceOf(MINTER);
        uint256 newReceiverOneBalance = token.balanceOf(RECEIVER_ONE);
        uint256 newReceiverTwoBalance = token.balanceOf(RECEIVER_TWO);

        assert(newMinterBalance - oldMinterBalance == MINTER_AIRDROP_AMOUNT);
        assert(
            newReceiverOneBalance - oldReceiverOneBalance ==
                RECEIVER_ONE_AIRDROP_AMOUNT
        );
        assert(
            newReceiverTwoBalance - oldReceiverTwoBalance ==
                RECEIVER_TWO_AIRDROP_AMOUNT
        );

        // mint for MINTER
        vm.prank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        // since MINTER is minting they are not eligible to any of the DISTRIBUTION_AMOUNT
        // with RECEIVER_ONE/TWO being eligible to 5/6 and 1/6 of the DISTRIBUTION_AMOUNT respectively,
        // since their only balance is the amount they have been airdropped:
        // RECEIVER_ONE balance: RECEIVER_ONE_AIDROP_AMOUNT
        // RECEIVER_TWO balance: RECEIVER_TWO_AIDROP_AMOUNT
        // ± 1 error range due to rounding
        assert(
            MINTER_AIRDROP_AMOUNT + AMOUNT_TO_MINTER + 1 >=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );
        assert(
            RECEIVER_ONE_AIRDROP_AMOUNT + ((DISTRIBUTION_AMOUNT * 5) / 6) + 1 >=
                token.balanceOf(RECEIVER_ONE) +
                    token.claimableTokens(RECEIVER_ONE)
        );
        assert(
            RECEIVER_TWO_AIRDROP_AMOUNT + ((DISTRIBUTION_AMOUNT * 1) / 6) + 1 >=
                token.balanceOf(RECEIVER_TWO) +
                    token.claimableTokens(RECEIVER_TWO)
        );

        // perform second aidrop
        perpetualMint.mintAirdrop{ value: ethRequired }(AIRDROP_AMOUNT);

        oldMinterBalance = token.balanceOf(MINTER);
        oldReceiverOneBalance = token.balanceOf(RECEIVER_ONE);
        oldReceiverTwoBalance = token.balanceOf(RECEIVER_TWO);

        token.disperseTokens(accounts, amounts);

        newMinterBalance = token.balanceOf(MINTER);
        newReceiverOneBalance = token.balanceOf(RECEIVER_ONE);
        newReceiverTwoBalance = token.balanceOf(RECEIVER_TWO);

        assert(newMinterBalance - oldMinterBalance == MINTER_AIRDROP_AMOUNT);
        assert(
            newReceiverOneBalance - oldReceiverOneBalance ==
                RECEIVER_ONE_AIRDROP_AMOUNT
        );
        assert(
            newReceiverTwoBalance - oldReceiverTwoBalance ==
                RECEIVER_TWO_AIRDROP_AMOUNT
        );

        // mint for MINTER
        vm.prank(MINTER);
        token.mint(MINTER, MINT_AMOUNT);

        // since MINTER is minting they are not eligible to any of the DISTRIBUTION_AMOUNT
        // with RECEIVER_ONE/TWO being eligible to 5/6 and 1/6 of the DISTRIBUTION_AMOUNT respectively,
        // since their only balance is the amount they have been airdropped:
        // RECEIVER_ONE balance: 2 * RECEIVER_ONE_AIDROP_AMOUNT
        // RECEIVER_TWO balance: 2 * RECEIVER_TWO_AIDROP_AMOUNT
        // ± 1 error range due to rounding
        assert(
            2 * MINTER_AIRDROP_AMOUNT + 2 * AMOUNT_TO_MINTER + 1 >=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );

        assert(
            2 *
                RECEIVER_ONE_AIRDROP_AMOUNT +
                2 *
                ((DISTRIBUTION_AMOUNT * 5) / 6) +
                1 >=
                token.balanceOf(RECEIVER_ONE) +
                    token.claimableTokens(RECEIVER_ONE)
        );
        assert(
            2 *
                RECEIVER_TWO_AIRDROP_AMOUNT +
                2 *
                ((DISTRIBUTION_AMOUNT * 1) / 6) +
                1 >=
                token.balanceOf(RECEIVER_TWO) +
                    token.claimableTokens(RECEIVER_TWO)
        );

        // RECEIVER_ONE claims all tokens
        vm.prank(RECEIVER_ONE);
        token.claim();

        assert(
            token.balanceOf(RECEIVER_ONE) >=
                2 *
                    RECEIVER_ONE_AIRDROP_AMOUNT +
                    2 *
                    ((DISTRIBUTION_AMOUNT * 5) / 6)
        );

        // mint for RECEIVER_ONE
        vm.prank(MINTER);
        token.mint(RECEIVER_ONE, MINT_AMOUNT);

        // since RECEIVER_ONE is minting they are not eligible to any of the DISTRIBUTION_AMOUNT
        // with MINTER and RECEIVER_TWO being eligible for the following share of DISTRIBUTION_AMOUNT:
        // MINTER: (2 * MINTER_AIRDROP_AMOUNT + 2 * AMOUNT_TO_MINTER ) / (2 * MINTER_AIRDROP_AMOUNT + 2 * AMOUNT_TO_MINTER +  2 * RECEIVER_TWO_AIRDROP_AMOUNT)
        // RECEIVER_TWO: (2 * RECEIVER_TWO_AIRDROP_AMOUNT) / (2 * MINTER_AIRDROP_AMOUNT + 2 * AMOUNT_TO_MINTER +  2 * RECEIVER_TWO_AIRDROP_AMOUNT)
        // since their respective balances are:
        // MINTER balance: (2 * MINTER_AIRDROP_AMOUNT + 2 * AMOUNT_TO_MINTER )
        // RECEIVER_TWO balance: (2 * RECEIVER_TWO_AIRDROP_AMOUNT)
        // ± 1 error range due to rounding
        assert(
            2 *
                RECEIVER_ONE_AIRDROP_AMOUNT +
                2 *
                ((DISTRIBUTION_AMOUNT * 5) / 6) +
                AMOUNT_TO_MINTER +
                1 >=
                token.balanceOf(RECEIVER_ONE) +
                    token.claimableTokens(RECEIVER_ONE)
        );

        assert(
            ((2 * MINTER_AIRDROP_AMOUNT + 2 * AMOUNT_TO_MINTER)) +
                ((2 * MINTER_AIRDROP_AMOUNT + 2 * AMOUNT_TO_MINTER) *
                    DISTRIBUTION_AMOUNT) /
                (2 *
                    MINTER_AIRDROP_AMOUNT +
                    2 *
                    AMOUNT_TO_MINTER +
                    2 *
                    RECEIVER_TWO_AIRDROP_AMOUNT) +
                1 >=
                token.balanceOf(MINTER) + token.claimableTokens(MINTER)
        );
        assert(
            2 *
                RECEIVER_TWO_AIRDROP_AMOUNT +
                2 *
                ((DISTRIBUTION_AMOUNT * 1) / 6) +
                ((2 * RECEIVER_TWO_AIRDROP_AMOUNT) * DISTRIBUTION_AMOUNT) /
                (2 *
                    MINTER_AIRDROP_AMOUNT +
                    2 *
                    AMOUNT_TO_MINTER +
                    2 *
                    RECEIVER_TWO_AIRDROP_AMOUNT) +
                1 >=
                token.balanceOf(RECEIVER_TWO) +
                    token.claimableTokens(RECEIVER_TWO)
        );
    }
}
