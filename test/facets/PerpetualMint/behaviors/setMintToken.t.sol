// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_setMintToken
/// @dev PerpetualMint test contract for testing expected behavior of the setMintToken function
contract PerpetualMint_setMintToken is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    /// @dev new mint token address to test
    address testMintToken = address(1234);

    function setUp() public override {
        super.setUp();
    }

    /// @dev tests the setting of a new mint token address
    function testFuzz_setMintToken(address _newMintToken) external {
        // it is assumed we will never set mintToken to a zero address
        if (_newMintToken != address(0)) {
            assert(perpetualMint.mintToken() == address(0));

            perpetualMint.setMintToken(_newMintToken);

            assert(_newMintToken == perpetualMint.mintToken());
        }
    }

    /// @dev tests for the MintTokenSet event emission after a new MintToken is set
    function test_setMintTokenEmitsMintTokenSetEvent() external {
        vm.expectEmit();
        emit MintTokenSet(testMintToken);

        perpetualMint.setMintToken(testMintToken);
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setMintTokenRevertsWhen_CallerIsNotOwner() external {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.setMintToken(testMintToken);
    }
}
