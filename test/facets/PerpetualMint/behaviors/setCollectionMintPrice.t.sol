// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_setCollectionMintPrice
/// @dev PerpetualMint test contract for testing expected behavior of the setCollectionMintPrice function
contract PerpetualMint_setCollectionMintPrice is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    /// @dev new mint price to test
    uint256 newMintPrice = 0.6 ether;

    /// @dev collection to test
    address COLLECTION = BORED_APE_YACHT_CLUB;

    /// @dev tests the setting of a new collection mint price
    function testFuzz_setCollectionMintPrice(uint256 _newMintPrice) external {
        assert(MINT_PRICE == perpetualMint.collectionMintPrice(COLLECTION));

        perpetualMint.setCollectionMintPrice(COLLECTION, _newMintPrice);

        if (_newMintPrice == 0) {
            /// @dev if the new mint price is 0, the mint price should be set to the default mint price
            assert(
                perpetualMint.defaultCollectionMintPrice() ==
                    perpetualMint.collectionMintPrice(COLLECTION)
            );
        } else {
            assert(
                _newMintPrice == perpetualMint.collectionMintPrice(COLLECTION)
            );
        }
    }

    /// @dev tests for the MintPriceSet event emission after a new collection mint price is set
    function test_setCollectionMintPriceEmitsMintPriceSetEvent() external {
        vm.expectEmit();
        emit MintPriceSet(COLLECTION, newMintPrice);

        perpetualMint.setCollectionMintPrice(COLLECTION, newMintPrice);
    }

    /// @dev tests that setCollectionPrice updates the mint price for a collection when there is no specific price set (collection mint price is the default price)
    function test_setCollectionMintPriceUpdatesPriceFromDefaultPrice()
        external
    {
        perpetualMint.setCollectionMintPrice(COLLECTION, 0);

        /// @dev if the new price is 0, the mint price should be set to the default mint price
        assert(
            perpetualMint.defaultCollectionMintPrice() ==
                perpetualMint.collectionMintPrice(COLLECTION)
        );

        perpetualMint.setCollectionMintPrice(COLLECTION, newMintPrice);

        assert(newMintPrice == perpetualMint.collectionMintPrice(COLLECTION));
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setCollectionMintPriceRevertsWhen_CallerIsNotOwner()
        external
    {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.setCollectionMintPrice(COLLECTION, newMintPrice);
    }
}
