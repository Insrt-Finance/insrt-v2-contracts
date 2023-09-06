// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { TokenTest } from "../Token.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { ITokenInternal } from "../../../../contracts/facets/token/ITokenInternal.sol";

/// @title Token_setDistributionFractionBP
/// @dev Token test contract for testing expected setDistributionFractionBP behavior. Tested on an Arbitrum fork.
contract Token_setDistributionFractionBP is
    ArbForkTest,
    TokenTest,
    ITokenInternal
{
    uint32 internal constant NEW_VALUE = 10;

    /// @dev sets up the testing environment
    function setUp() public override {
        super.setUp();
    }

    /// @dev ensures setDistributionFractionBP sets a new value for distributionFeeBP
    function test_setDistributionFractionBPSetsNewDistributionFeeBPValue()
        public
    {
        token.setDistributionFractionBP(NEW_VALUE);

        assert(token.distributionFractionBP() == NEW_VALUE);
    }

    /// @dev ensures setDistributionFractionBP emits an event
    function test_setDistributionFractionBPEmitsDistributionFractionSetEvent()
        public
    {
        vm.expectEmit();
        emit ITokenInternal.DistributionFractionSet(NEW_VALUE);

        token.setDistributionFractionBP(NEW_VALUE);
    }

    /// @dev ensures setDistributionFractionB{} reverts when owner is not caller
    function test_setDistributionFractionBPRevertsWhen_CallerIsNotOwner()
        public
    {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(NON_OWNER);
        token.setDistributionFractionBP(NEW_VALUE);
    }
}
