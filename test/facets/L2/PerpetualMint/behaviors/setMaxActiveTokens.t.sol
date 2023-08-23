// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";
import { Guards } from "../../../../../contracts/facets/L2/common/Guards.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";

/// @title PerpetualMint_setMaxActiveTokens
/// @dev PerpetualMint test contract for testing expected behavior of the setMaxActiveTokens function
contract PerpetualMint_setMaxActiveTokens is PerpetualMintTest, L2ForkTest {
    address nonOwner = address(100);
    uint256 maxActiveTokens = 5;

    /// @dev tests the setting of a new maxActiveTokens amount
    function testFuzz_setMaxActiveTokens(uint256 amount) public {
        perpetualMint.setMaxActiveTokens(amount);

        assert(amount == _maxActiveTokens(address(perpetualMint)));
    }

    /// @dev tests that setMaxActiveTokens emits MaxActiveTokensSet event
    function test_setMaxActiveTokensEmitsMaxActiveTokensSetEvent() public {
        vm.expectEmit();
        emit Guards.MaxActiveTokensSet(maxActiveTokens);

        perpetualMint.setMaxActiveTokens(maxActiveTokens);
    }

    /// @dev tests that setMaxActiveTokens reverts when the caller is not the owner
    function test_setMaxActiveTokensRevertsWhen_CallerIsNotOwner() public {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);
        vm.prank(nonOwner);
        perpetualMint.setMaxActiveTokens(maxActiveTokens);
    }
}
