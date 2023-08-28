// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_setMaxActiveTokensLimit
/// @dev PerpetualMint test contract for testing expected behavior of the setMaxActiveTokensLimit function
contract PerpetualMint_setMaxActiveTokensLimit is
    PerpetualMintTest,
    L2ForkTest,
    IPerpetualMintInternal
{
    address nonOwner = address(100);
    uint256 maxActiveTokens = 5;

    /// @dev tests the setting of a new maxActiveTokens amount
    function testFuzz_setMaxActiveTokensLimit(uint256 amount) public {
        perpetualMint.setMaxActiveTokensLimit(amount);

        assert(amount == _maxActiveTokens(address(perpetualMint)));
    }

    /// @dev tests that setMaxActiveTokensLimit emits MaxActiveTokensSet event
    function test_setMaxActiveTokensLimitEmitsMaxActiveTokensSetEvent() public {
        vm.expectEmit();
        emit MaxActiveTokensLimitSet(maxActiveTokens);

        perpetualMint.setMaxActiveTokensLimit(maxActiveTokens);
    }

    /// @dev tests that setMaxActiveTokensLimit reverts when the caller is not the owner
    function test_setMaxActiveTokensLimitRevertsWhen_CallerIsNotOwner() public {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);
        vm.prank(nonOwner);
        perpetualMint.setMaxActiveTokensLimit(maxActiveTokens);
    }
}
