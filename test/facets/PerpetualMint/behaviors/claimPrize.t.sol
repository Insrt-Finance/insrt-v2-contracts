// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IERC1155BaseInternal } from "@solidstate/contracts/token/ERC1155/base/IERC1155BaseInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_claimPrize
/// @dev PerpetualMint test contract for testing expected claimPrize behavior. Tested on an Arbitrum fork.
contract PerpetualMint_claimPrize is
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

        vm.prank(minter);
        perpetualMint.mintReceipts(testCollection, 1);
    }

    /// @dev Tests claimPrize functionality.
    function test_claimPrize() external {
        uint256 preClaimClaimerReceiptBalance = perpetualMint.balanceOf(
            minter,
            testTokenId
        );

        uint256 preClaimProtocolReceiptBalance = perpetualMint.balanceOf(
            address(perpetualMint),
            testTokenId
        );

        vm.prank(minter);
        perpetualMint.claimPrize(minter, testTokenId);

        uint256 postClaimClaimerReceiptBalance = perpetualMint.balanceOf(
            minter,
            testTokenId
        );

        assert(
            postClaimClaimerReceiptBalance == preClaimClaimerReceiptBalance - 1
        );

        uint256 postClaimProtocolReceiptBalance = perpetualMint.balanceOf(
            address(perpetualMint),
            testTokenId
        );

        assert(
            postClaimProtocolReceiptBalance ==
                preClaimProtocolReceiptBalance + 1
        );
    }

    /// @dev Tests claimPrize emits PrizeClaimed event.
    function test_claimPrizeEmitsPrizeClaimed() external {
        vm.expectEmit();

        emit IPerpetualMintInternal.PrizeClaimed(
            minter,
            minter,
            testCollection
        );

        vm.prank(minter);
        perpetualMint.claimPrize(minter, testTokenId);
    }

    /// @dev Tests claimPrize reverts when claimer balance is insufficient.
    function test_claimPrizeRevertsWhen_ClaimerBalanceInsufficient() external {
        vm.expectRevert(
            IERC1155BaseInternal.ERC1155Base__TransferExceedsBalance.selector
        );

        vm.prank(minter);
        perpetualMint.claimPrize(minter, ++testTokenId); // increment testTokenId to ensure balance is insufficient
    }
}
