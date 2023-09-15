// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";
import { IERC1155BaseInternal } from "@solidstate/contracts/token/ERC1155/base/IERC1155BaseInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_cancelClaim
/// @dev PerpetualMint test contract for testing expected cancelClaim behavior. Tested on an Arbitrum fork.
contract PerpetualMint_cancelClaim is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    /// @dev test collection prize address
    address internal testCollection = address(0xdeadbeef);

    /// @dev test collection prize address encoded as uint256
    uint256 internal testTokenId = uint256(bytes32(abi.encode(testCollection)));

    /// @dev sets up the context for the test cases
    function setUp() public override {
        super.setUp();

        vm.prank(address(perpetualMint));
        perpetualMint.mintReceipts(testCollection, 1);
    }

    /// @dev Tests cancelClaim functionality.
    function test_cancelClaim() external {
        uint256 preCancelClaimerReceiptBalance = perpetualMint
            .exposed_balanceOf(minter, testTokenId);

        uint256 preCancelProtocolReceiptBalance = perpetualMint
            .exposed_balanceOf(address(perpetualMint), testTokenId);

        perpetualMint.cancelClaim(minter, testTokenId);

        uint256 postCancelClaimerReceiptBalance = perpetualMint
            .exposed_balanceOf(minter, testTokenId);

        assert(
            postCancelClaimerReceiptBalance ==
                preCancelClaimerReceiptBalance + 1
        );

        uint256 postCancelProtocolReceiptBalance = perpetualMint
            .exposed_balanceOf(address(perpetualMint), testTokenId);

        assert(
            postCancelProtocolReceiptBalance ==
                preCancelProtocolReceiptBalance - 1
        );
    }

    /// @dev Tests cancelClaim emits ClaimCancelled event.
    function test_cancelClaimEmitsClaimCancelled() external {
        vm.expectEmit();

        emit IPerpetualMintInternal.ClaimCancelled(minter, testCollection);

        perpetualMint.cancelClaim(minter, testTokenId);
    }

    /// @dev Tests cancelClaim reverts when called by non-owner.
    function test_cancelClaimRevertsWhen_CalledByNonOwner() external {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.cancelClaim(minter, testTokenId);
    }

    /// @dev Tests cancelClaim reverts when protocol balance is insufficient.
    function test_cancelClaimRevertsWhen_ProtocolBalanceInsufficient()
        external
    {
        vm.expectRevert(
            IERC1155BaseInternal.ERC1155Base__TransferExceedsBalance.selector
        );

        perpetualMint.cancelClaim(minter, ++testTokenId); // increment testTokenId to ensure balance is insufficient
    }
}
