// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

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
    /// @dev value of roll which will lead to depositor one being selected
    uint128 internal constant depositorOneSelectValue = uint64(900);

    function setUp() public override {
        super.setUp();

        depositParallelAlphaAssetsMock();
    }

    /// @dev tests selecting an ERC1155 owner after an ERC1155 asset has been won
    function testFuzz_selectERC1155Owner(uint64 randomOwnerValue) public view {
        uint256 selectedTokenId = parallelAlphaTokenIds[0];

        // make sure random value is within 0 - tokenRisk range
        uint64 normalizedValue = randomOwnerValue %
            _tokenRisk(address(perpetualMint), PARALLEL_ALPHA, selectedTokenId);

        uint64 depositorOneRisk = _depositorTokenRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA,
            selectedTokenId
        );

        // since only two owners, if normalizedValue is larger than the
        // risk of depositorOne, then its depositorTwo who is the expectedOWner
        address expectedOwner = normalizedValue >
            depositorOneRisk * parallelAlphaTokenAmount
            ? depositorTwo
            : depositorOne;

        assert(
            perpetualMint.exposed_selectERC1155Owner(
                PARALLEL_ALPHA,
                selectedTokenId,
                randomOwnerValue
            ) == expectedOwner
        );
    }
}
