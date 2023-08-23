// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";
import { PausableStorage } from "@solidstate/contracts/security/pausable/PausableStorage.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";

/// @dev PerpetualMint_unpause
/// @dev PerpetualMint test contract for testing expected behavior of the unpause function
contract PerpetualMint_unpause is IPerpetualMintInternal, PerpetualMintTest {
    address internal NON_OWNER = address(100);

    function setUp() public override {
        super.setUp();
    }

    /// @dev tests that paused state is set to true
    function test_unpauseSetsPausedStateToFalse() public {
        perpetualMint.pause();
        assertEq(
            1,
            uint256(
                vm.load(address(perpetualMint), PausableStorage.STORAGE_SLOT)
            )
        );

        perpetualMint.unpause();
        assertEq(
            0,
            uint256(
                vm.load(address(perpetualMint), PausableStorage.STORAGE_SLOT)
            )
        );
    }

    /// @dev tests that call will revert if called by non-owner
    function test_pauseRevertsWhen_CalledByNonOwner() public {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);
        vm.prank(NON_OWNER);
        perpetualMint.unpause();
    }
}
