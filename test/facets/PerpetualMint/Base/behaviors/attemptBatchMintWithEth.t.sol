// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnable } from "@solidstate/contracts/access/ownable/IOwnable.sol";
import { IPausableInternal } from "@solidstate/contracts/security/pausable/IPausableInternal.sol";

import { PerpetualMintTestBase } from "../PerpetualMint.t.sol";
import { BaseForkTest } from "../../../../BaseForkTest.t.sol";
import { IDepositContract } from "../../../../interfaces/IDepositContract.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";
import { ISupraRouterContract } from "../../../../../contracts/facets/PerpetualMint/Base/ISupraRouterContract.sol";

/// @title PerpetualMint_attemptBatchMintWithEthBase
/// @dev PerpetualMint test contract for testing expected attemptBatchMintWithEth behavior. Tested on a Base fork.
contract PerpetualMint_attemptBatchMintWithEthBase is
    BaseForkTest,
    IPerpetualMintInternal,
    PerpetualMintTestBase
{
    IDepositContract private supraVRFDepositContract;

    ISupraRouterContract private supraRouterContract;

    uint32 internal constant TEST_MINT_ATTEMPTS = 3;

    uint32 internal constant ZERO_MINT_ATTEMPTS = 0;

    /// @dev collection to test
    address COLLECTION = BORED_APE_YACHT_CLUB;

    address supraVRFDepositContractOwner;

    /// @dev Sets up the test case environment.
    function setUp() public override {
        super.setUp();

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

    /// @dev Tests attemptBatchMintWithEth functionality.
    function test_attemptBatchMintWithEth() external {
        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(preMintAccruedConsolationFees == 0);

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(preMintAccruedMintEarnings == 0);

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        assert(address(perpetualMint).balance == 0);

        vm.prank(minter);
        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(COLLECTION, TEST_MINT_ATTEMPTS);

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                (((MINT_PRICE * TEST_MINT_ATTEMPTS) *
                    perpetualMint.consolationFeeBP()) / perpetualMint.BASIS())
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(
            postMintAccruedProtocolFees ==
                (((MINT_PRICE * TEST_MINT_ATTEMPTS) *
                    perpetualMint.mintFeeBP()) / perpetualMint.BASIS())
        );

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(
            postMintAccruedMintEarnings ==
                (MINT_PRICE * TEST_MINT_ATTEMPTS) -
                    postMintAccruedConsolationFees -
                    postMintAccruedProtocolFees
        );

        assert(
            address(perpetualMint).balance ==
                postMintAccruedConsolationFees +
                    postMintAccruedMintEarnings +
                    postMintAccruedProtocolFees
        );
    }

    /// @dev Tests that attemptBatchMintWithEth functionality reverts when attempting to mint with an incorrect msg value amount.
    function test_attemptBatchMintWithEthRevertsWhen_AttemptingToMintWithIncorrectMsgValue()
        external
    {
        vm.expectRevert(IPerpetualMintInternal.IncorrectETHReceived.selector);

        perpetualMint.attemptBatchMintWithEth(COLLECTION, TEST_MINT_ATTEMPTS);
    }

    /// @dev Tests that attemptBatchMintWithEth functionality reverts when attempting zero mints.
    function test_attemptBatchMintWithEthRevertsWhen_AttemptingZeroMints()
        external
    {
        vm.expectRevert(IPerpetualMintInternal.InvalidNumberOfMints.selector);

        perpetualMint.attemptBatchMintWithEth(COLLECTION, ZERO_MINT_ATTEMPTS);
    }

    /// @dev Tests that attemptBatchMintWithEth functionality reverts when the contract is paused.
    function test_attemptBatchMintWithEthRevertsWhen_PausedStateIsTrue()
        external
    {
        perpetualMint.pause();
        vm.expectRevert(IPausableInternal.Pausable__Paused.selector);

        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(COLLECTION, TEST_MINT_ATTEMPTS);
    }

    /// @dev Helper function to activate Supra VRF by adding the contract and client to the Supra VRF Deposit Contract whitelist and depositing funds.
    function _activateVRF() private {
        vm.prank(supraVRFDepositContractOwner);
        supraVRFDepositContract.addClientToWhitelist(address(this), true);

        supraVRFDepositContract.addContractToWhitelist(address(perpetualMint));

        supraVRFDepositContract.depositFundClient{ value: 10 ether }();
    }
}
