// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";

/// @dev PerpetualMint_burnReceipt
/// @dev PerpetualMint test contract for testing expected behavior of the burnReceipt function
contract PerpetualMint_burnReceipt is ArbForkTest, PerpetualMintTest {
    /// @dev test collection prize address
    address internal testCollection = address(0xdeadbeef);

    /// @dev test collection prize address encoded as uint256
    uint256 internal testTokenId = uint256(bytes32(abi.encode(testCollection)));

    /// @dev sets up the context for the test cases
    function setUp() public override {
        super.setUp();

        vm.prank(minter);
        perpetualMint.mintReceipts(testCollection, 1);

        vm.prank(minter);
        perpetualMint.claimPrize(minter, testTokenId);
    }

    /// @dev tests that burnReceipt burns a single receipt of the given token ID from the PerpetualMint contract
    function test_burnReceiptBurnsSingleReceiptOfTokenId() external {
        uint256 oldBalance = perpetualMint.balanceOf(
            address(perpetualMint),
            testTokenId
        );

        perpetualMint.burnReceipt(testTokenId);

        uint256 newBalance = perpetualMint.balanceOf(
            address(perpetualMint),
            testTokenId
        );

        assert(oldBalance - newBalance == 1);
    }

    /// @dev tests that burnReceipt will revert if called by non-owner
    function test_burnReceiptsRevertWhen_CalledByNonOwner() external {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.burnReceipt(testTokenId);
    }
}
