// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { PerpetualMintTest } from "../../../facets/PerpetualMint/PerpetualMint.t.sol";
import { IGuardsInternal } from "../../../../contracts/common/IGuardsInternal.sol";

/// @title GuardsInternal_enforceBasis
/// @dev GuardsInternal test contract for testing expected behavior of the _enforceBasis function
/// @dev Uses PerpetualMintTest to expose and test the _enforceBasis function
contract GuardsInternal_enforceBasis is PerpetualMintTest {
    /// @dev tests that values cannot exceed the BASIS
    function testFuzz_enforceBasis(uint32 value) external {
        // _enforceBasis should revert if value exceeds BASIS
        if (value > perpetualMint.BASIS()) {
            vm.expectRevert(IGuardsInternal.BasisExceeded.selector);

            perpetualMint.exposed_enforceBasis(value);
        } else {
            // _enforceBasis should not revert if value does not exceed BASIS
            perpetualMint.exposed_enforceBasis(value);
        }
    }
}
