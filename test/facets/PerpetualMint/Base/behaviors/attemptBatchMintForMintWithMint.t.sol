// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IPausableInternal } from "@solidstate/contracts/security/pausable/IPausableInternal.sol";

import { PerpetualMintTest_Base } from "../PerpetualMint.t.sol";
import { TokenTest } from "../../../Token/Token.t.sol";
import { BaseForkTest } from "../../../../BaseForkTest.t.sol";
import { CoreTest } from "../../../../diamonds/Core.t.sol";
import { TokenProxyTest } from "../../../../diamonds/TokenProxy.t.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_attemptBatchMintForMintWithMintBase
/// @dev PerpetualMint_Base test contract for testing expected attemptBatchMintForMintWithMint behavior. Tested on a Base fork.
contract PerpetualMint_attemptBatchMintForMintWithMintBase is
    BaseForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest_Base,
    TokenTest
{
    uint32 internal constant TEST_MINT_ATTEMPTS = 3;

    uint32 internal constant ZERO_MINT_ATTEMPTS = 0;

    /// @dev for now, mints for $MINT are treated as address(0) collections
    address COLLECTION = address(0);

    /// @dev overrides the receive function to accept ETH
    receive() external payable override(CoreTest, TokenProxyTest) {}

    /// @dev sets up the context for the test cases
    function setUp() public override(PerpetualMintTest_Base, TokenTest) {
        PerpetualMintTest_Base.setUp();
        TokenTest.setUp();

        perpetualMint.setMintToken(address(token));

        perpetualMint.setConsolationFees(100 ether);

        token.addMintingContract(address(perpetualMint));

        // mint a bunch of tokens to minter
        vm.prank(MINTER);
        token.mint(minter, MINT_AMOUNT * 1e10);

        // get the mint price for $MINT
        MINT_PRICE = perpetualMint.collectionMintPrice(COLLECTION);
    }

    /// @dev Tests attemptBatchMintForMintWithMint functionality.
    function test_attemptBatchMintForMintWithMint() external {
        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(preMintAccruedMintEarnings == 0);

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        uint256 preMintTokenBalance = token.balanceOf(minter);

        vm.prank(minter);
        perpetualMint.attemptBatchMintForMintWithMint(TEST_MINT_ATTEMPTS);

        uint256 expectedEthRequired = MINT_PRICE * TEST_MINT_ATTEMPTS;

        uint256 expectedMintTokenConsolationFee = (expectedEthRequired *
            perpetualMint.mintTokenConsolationFeeBP()) / perpetualMint.BASIS();

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                preMintAccruedConsolationFees -
                    (expectedEthRequired - expectedMintTokenConsolationFee)
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        // the difference between the expected ETH required and the $MINT consolation fee is the protocol fee
        uint256 expectedMintFee = expectedEthRequired -
            expectedMintTokenConsolationFee;

        assert(postMintAccruedProtocolFees == expectedMintFee);

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        // asert that depositor earnings have not been updated on mints for $MINT
        assert(postMintAccruedMintEarnings == 0);

        uint256 postMintTokenBalance = token.balanceOf(minter);

        uint256 expectedMintTokenBurned = expectedEthRequired *
            perpetualMint.ethToMintRatio();

        assert(
            postMintTokenBalance ==
                preMintTokenBalance - expectedMintTokenBurned
        );
    }

    /// @dev Tests that attemptBatchMintForMintWithMint functionality reverts when attempting zero mints.
    function test_attemptBatchMintForMintWithMintRevertsWhen_AttemptingZeroMints()
        external
    {
        vm.expectRevert(IPerpetualMintInternal.InvalidNumberOfMints.selector);

        perpetualMint.attemptBatchMintForMintWithMint(ZERO_MINT_ATTEMPTS);
    }

    /// @dev Tests that attemptBatchMintForMintWithMint functionality reverts when the contract is paused.
    function test_attemptBatchMintForMintWithMintRevertsWhen_PausedStateIsTrue()
        external
    {
        perpetualMint.pause();
        vm.expectRevert(IPausableInternal.Pausable__Paused.selector);

        perpetualMint.attemptBatchMintForMintWithMint(TEST_MINT_ATTEMPTS);
    }
}
