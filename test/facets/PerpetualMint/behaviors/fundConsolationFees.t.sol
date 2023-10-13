// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @dev PerpetualMint_fundConsolationFees
/// @dev PerpetualMint test contract for testing expected behavior of the fundConsolationFees function
contract PerpetualMint_fundConsolationFees is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    /// @dev test funding amount
    uint256 internal constant TEST_FUNDING_AMOUNT = 1 ether;

    /// @dev sets up the context for the test cases
    function setUp() public override {
        super.setUp();
    }

    /// @dev Tests fundConsolationFees functionality.
    function test_fundConsolationFees() external {
        uint256 preFundedConsolationFees = perpetualMint
            .accruedConsolationFees();

        uint256 preFundedFunderEthBalance = address(this).balance;

        perpetualMint.fundConsolationFees{ value: TEST_FUNDING_AMOUNT }();

        uint256 postFundedConsolationFees = perpetualMint
            .accruedConsolationFees();

        // assert that the consolation fees have increased by the funding amount
        assert(
            postFundedConsolationFees ==
                preFundedConsolationFees + TEST_FUNDING_AMOUNT
        );

        uint256 postFundedFunderEthBalance = address(this).balance;

        // assert that the funder's ETH balance has decreased by the funding amount
        assert(
            postFundedFunderEthBalance ==
                preFundedFunderEthBalance - TEST_FUNDING_AMOUNT
        );
    }

    /// @dev Tests fundConsolationFees emits the ConsolationFeesFunded event.
    function test_fundConsolationFeesEmitsConsolationFeesFundedEvent()
        external
    {
        vm.expectEmit();
        emit ConsolationFeesFunded(address(this), TEST_FUNDING_AMOUNT);

        perpetualMint.fundConsolationFees{ value: TEST_FUNDING_AMOUNT }();
    }
}
