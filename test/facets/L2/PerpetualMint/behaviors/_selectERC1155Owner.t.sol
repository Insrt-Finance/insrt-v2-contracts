// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { L1ForkTest } from "../../../../L1ForkTest.t.sol";

/// @title PerpetualMint_selectERC1155Owner
/// @dev PerpetualMint test contract for testing expected behavior of the selectERC1155Owner function
contract PerpetualMint_selectERC1155Owner is
    IPerpetualMintInternal,
    PerpetualMintTest,
    L1ForkTest
{
    function setUp() public override {
        super.setUp();

        depositBongBearsAssetsMock();
    }

    /// @dev tests selecting an ERC1155 owner after an ERC1155 asset has been won
    function testFuzz_selectERC1155Owner(
        uint8 tokenSelector,
        uint64 randomOwnerValue
    ) public view {
        // select a random token
        uint8 pickingNumber = tokenSelector % 2;
        uint256 selectedTokenId = pickingNumber == 0
            ? bongBearTokenIds[0]
            : bongBearTokenIds[1];

        //identfiy the expected owner as per the setup since each token only has one owner
        address expectedOwner = selectedTokenId == bongBearTokenIds[0]
            ? depositorOne
            : depositorTwo;

        assert(
            perpetualMint.exposed_selectERC1155Owner(
                BONG_BEARS,
                selectedTokenId,
                randomOwnerValue
            ) == expectedOwner
        );
    }
}
