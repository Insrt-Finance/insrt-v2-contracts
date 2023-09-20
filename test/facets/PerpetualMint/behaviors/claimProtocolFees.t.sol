// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";

/// @dev PerpetualMint_claimProtocolFees
/// @dev PerpetualMint test contract for testing expected behavior of the claimProtocolFees function
contract PerpetualMint_claimProtocolFees is ArbForkTest, PerpetualMintTest {
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

    /// @dev Tests claimProtocolFees functionality.
    function test_claimProtocolFees() external {
        uint256 preClaimedProtocolFees = perpetualMint.accruedProtocolFees();

        uint256 preClaimedOwnerEthBalance = address(this).balance;

        perpetualMint.claimProtocolFees();

        uint256 postClaimedProtocolFees = perpetualMint.accruedProtocolFees();

        // protocolFees should be zero after claiming
        assert(postClaimedProtocolFees == 0);

        uint256 postClaimedOwnerEthBalance = address(this).balance;

        // owner's ETH balance should increase by the amount of claimed protocolFees
        assert(
            postClaimedOwnerEthBalance ==
                preClaimedOwnerEthBalance + preClaimedProtocolFees
        );
    }

    /// @dev tests that claimProtocolFees will revert if called by non-owner
    function test_claimProtocolFeesRevertsWhen_CalledByNonOwner() external {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.claimProtocolFees();
    }
}
