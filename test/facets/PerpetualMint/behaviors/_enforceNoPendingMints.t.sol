// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_enforceNoPendingMints
/// @dev PerpetualMint test contract for testing expected behavior of the _enforceNoPendingMints function
contract PerpetualMint_enforceNoPendingMints is ArbForkTest, PerpetualMintTest {
    /// @dev collection to test
    address internal constant COLLECTION = BORED_APE_YACHT_CLUB;

    /// @dev tests that when there are pending mint requests, _enforceNoPendingMints reverts
    function test_enforceNoPendingMints() external {
        uint256 pendingMintRequests = perpetualMint
            .exposed_pendingRequestsLength(COLLECTION);

        // assert that there are no pending mint requests
        assert(pendingMintRequests == 0);

        // _enforceNoPendingMints should not revert if there are no pending mint requests
        perpetualMint.exposed_enforceNoPendingMints(COLLECTION);

        // add a dummy pending mint request
        uint256 dummyRequestId = 1;

        perpetualMint.exposed_pendingRequestsAdd(COLLECTION, dummyRequestId);

        // _enforceNoPendingMints should revert if there are pending mint requests
        vm.expectRevert(IPerpetualMintInternal.PendingRequests.selector);

        perpetualMint.exposed_enforceNoPendingMints(COLLECTION);
    }
}
