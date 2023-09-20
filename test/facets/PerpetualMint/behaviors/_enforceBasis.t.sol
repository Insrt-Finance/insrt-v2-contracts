// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IGuardsInternal } from "../../../../contracts/common/IGuardsInternal.sol";

/// @title PerpetualMint_enforceBasis
/// @dev PerpetualMint test contract for testing expected behavior of the _enforceBasis function
contract PerpetualMint_enforceBasis is ArbForkTest, PerpetualMintTest {
    /// @dev tests that risk values cannot exceed the BASIS
    function testFuzz_enforceBasis(uint32 risk) external {
        // _enforceBasis should revert if risk exceeds BASIS
        if (risk > perpetualMint.BASIS()) {
            vm.expectRevert(IGuardsInternal.BasisExceeded.selector);

            perpetualMint.exposed_enforceBasis(risk);
        } else {
            // _enforceBasis should not revert if risk does not exceed BASIS
            perpetualMint.exposed_enforceBasis(risk);
        }
    }
}
