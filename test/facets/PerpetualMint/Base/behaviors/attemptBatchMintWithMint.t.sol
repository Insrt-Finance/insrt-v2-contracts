// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnable } from "@solidstate/contracts/access/ownable/IOwnable.sol";
import { IPausableInternal } from "@solidstate/contracts/security/pausable/IPausableInternal.sol";

import { PerpetualMintTestBase } from "../PerpetualMint.t.sol";
import { TokenTest } from "../../../Token/Token.t.sol";
import { BaseForkTest } from "../../../../BaseForkTest.t.sol";
import { CoreTest } from "../../../../diamonds/Core.t.sol";
import { TokenProxyTest } from "../../../../diamonds/TokenProxy.t.sol";
import { IDepositContract } from "../../../../interfaces/IDepositContract.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";
import { ISupraRouterContract } from "../../../../../contracts/facets/PerpetualMint/Base/ISupraRouterContract.sol";

/// @title PerpetualMint_attemptBatchMintWithMintBase
/// @dev PerpetualMint test contract for testing expected attemptBatchMintWithMint behavior. Tested on a Base fork.
contract PerpetualMint_attemptBatchMintWithMintBase is
    BaseForkTest,
    IPerpetualMintInternal,
    PerpetualMintTestBase,
    TokenTest
{
    IDepositContract private supraVRFDepositContract;

    ISupraRouterContract private supraRouterContract;

    uint32 internal constant TEST_MINT_ATTEMPTS = 3;

    uint32 internal constant ZERO_MINT_ATTEMPTS = 0;

    /// @dev collection to test
    address COLLECTION = BORED_APE_YACHT_CLUB;

    address supraVRFDepositContractOwner;

    /// @dev overrides the receive function to accept ETH
    receive() external payable override(CoreTest, TokenProxyTest) {}

    /// @dev sets up the context for the test cases
    function setUp() public override(PerpetualMintTestBase, TokenTest) {
        PerpetualMintTestBase.setUp();
        TokenTest.setUp();

        perpetualMint.setMintToken(address(token));

        perpetualMint.setConsolationFees(100 ether);

        token.addMintingContract(address(perpetualMint));

        // mint a bunch of tokens to minter
        vm.prank(MINTER);
        token.mint(minter, MINT_AMOUNT * 1e10);

        supraRouterContract = ISupraRouterContract(
            this.perpetualMintHelper().VRF_ROUTER()
        );

        supraVRFDepositContract = IDepositContract(
            supraRouterContract._depositContract()
        );

        supraVRFDepositContractOwner = IOwnable(
            address(supraVRFDepositContract)
        ).owner();

        _activateVRF();
    }

    /// @dev Tests attemptBatchMintWithMint functionality.
    function test_attemptBatchMintWithMint() external {
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
        perpetualMint.attemptBatchMintWithMint(COLLECTION, TEST_MINT_ATTEMPTS);

        uint256 expectedEthRequired = MINT_PRICE * TEST_MINT_ATTEMPTS;

        uint256 expectedConsolationFee = (expectedEthRequired *
            perpetualMint.consolationFeeBP()) / perpetualMint.BASIS();

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                preMintAccruedConsolationFees -
                    (expectedEthRequired - expectedConsolationFee)
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        uint256 expectedMintFee = (expectedEthRequired *
            perpetualMint.mintFeeBP()) / perpetualMint.BASIS();

        assert(postMintAccruedProtocolFees == expectedMintFee);

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(
            postMintAccruedMintEarnings ==
                expectedEthRequired - expectedConsolationFee - expectedMintFee
        );

        uint256 postMintTokenBalance = token.balanceOf(minter);

        uint256 expectedMintTokenBurned = expectedEthRequired *
            perpetualMint.ethToMintRatio();

        assert(
            postMintTokenBalance ==
                preMintTokenBalance - expectedMintTokenBurned
        );
    }

    /// @dev Tests that attemptBatchMintWithMint functionality reverts when attempting zero mints.
    function test_attemptBatchMintWithMintRevertsWhen_AttemptingZeroMints()
        external
    {
        vm.expectRevert(IPerpetualMintInternal.InvalidNumberOfMints.selector);

        perpetualMint.attemptBatchMintWithMint(COLLECTION, ZERO_MINT_ATTEMPTS);
    }

    /// @dev Tests that attemptBatchMintWithMint functionality reverts when the contract is paused.
    function test_attemptBatchMintWithMintRevertsWhen_PausedStateIsTrue()
        external
    {
        perpetualMint.pause();
        vm.expectRevert(IPausableInternal.Pausable__Paused.selector);

        perpetualMint.attemptBatchMintWithMint(COLLECTION, TEST_MINT_ATTEMPTS);
    }

    function _activateVRF() private {
        vm.prank(supraVRFDepositContractOwner);
        supraVRFDepositContract.addClientToWhitelist(address(this), true);

        supraVRFDepositContract.addContractToWhitelist(address(perpetualMint));

        supraVRFDepositContract.depositFundClient{ value: 10 ether }();
    }
}
