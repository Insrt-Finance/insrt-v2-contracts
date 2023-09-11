// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";

/// @dev PerpetualMint_claimMintEarnings
/// @dev PerpetualMint test contract for testing expected behavior of the claimMintEarnings function
contract PerpetualMint_claimMintEarnings is ArbForkTest, PerpetualMintTest {
    uint32 internal constant unsuccessfulMintAttempts = 10;

    /// @dev collection to test
    address internal constant COLLECTION = BORED_APE_YACHT_CLUB;

    /// @dev sets up the context for the test cases
    function setUp() public override {
        super.setUp();

        // mocks unsuccessful mint attempts as a method to increase fees & earnings
        mock_unsuccessfulMintWithEthAttempts(
            COLLECTION,
            unsuccessfulMintAttempts
        );

        // ensure contract has enough ETH to send to claimer
        vm.deal(address(perpetualMint), 50 ether);
    }

    /// @dev Tests claimMintEarnings functionality.
    function test_claimMintEarnings() external {
        uint256 preClaimedMintEarnings = perpetualMint.accruedMintEarnings();

        uint256 preClaimedOwnerEthBalance = address(this).balance;

        perpetualMint.claimMintEarnings();

        uint256 postClaimedMintEarnings = perpetualMint.accruedMintEarnings();

        // mintEarnings should be zero after claiming
        assert(postClaimedMintEarnings == 0);

        uint256 postClaimedOwnerEthBalance = address(this).balance;

        // owner's ETH balance should increase by the amount of claimed mintEarnings
        assert(
            postClaimedOwnerEthBalance ==
                preClaimedOwnerEthBalance + preClaimedMintEarnings
        );
    }

    /// @dev tests that claimMintEarnings will revert if called by non-owner
    function test_claimMintEarningsRevertsWhen_CalledByNonOwner() external {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.claimMintEarnings();
    }
}
