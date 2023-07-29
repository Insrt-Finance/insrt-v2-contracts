// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";

/// @title PerpetualMint_setCollectionMintPrice
/// @dev PerpetualMint test contract for testing expected behavior of the setCollectionMintPrice function
contract PerpetualMint_setCollectionMintPrice is
    PerpetualMintTest,
    L2ForkTest,
    IPerpetualMintInternal
{
    address nonOwner = address(5);
    uint256 newPrice = 0.6 ether;

    /// @dev tests the setting of a new collection mint price
    function testFuzz_setCollectionMintPrice(uint256 amount) public {
        assert(
            MINT_PRICE ==
                _collectionMintPrice(
                    address(perpetualMint),
                    BORED_APE_YACHT_CLUB
                )
        );

        perpetualMint.setCollectionMintPrice(BORED_APE_YACHT_CLUB, amount);

        assert(
            amount ==
                _collectionMintPrice(
                    address(perpetualMint),
                    BORED_APE_YACHT_CLUB
                )
        );
    }

    /// @dev tests for the MintPriceSet event emission after a new collection mint price is set
    function test_setCollectionMintPriceEmitsMintPriceSetEvent() public {
        vm.expectEmit();
        emit MintPriceSet(BORED_APE_YACHT_CLUB, newPrice);

        perpetualMint.setCollectionMintPrice(BORED_APE_YACHT_CLUB, newPrice);
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_RevertWhen_CallerIsNotOwner() public {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);
        vm.prank(nonOwner);
        perpetualMint.setCollectionMintPrice(BORED_APE_YACHT_CLUB, newPrice);
    }
}
