// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IGuardsInternal } from "../../../../contracts/common/IGuardsInternal.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_setMintForEthConsolationFeeBP
/// @dev PerpetualMint test contract for testing expected behavior of the setMintForEthConsolationFeeBP function
contract PerpetualMint_setMintForEthConsolationFeeBP is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    /// @dev new mint for ETH consolation fee basis points to test, 1.0%
    uint32 newMintForEthConsolationFeeBP = 10000000;

    function setUp() public override {
        super.setUp();

        // set ETH consolation fee basis points to 0.5%
        perpetualMint.setMintForEthConsolationFeeBP(
            TEST_MINT_FOR_ETH_CONSOLATION_FEE_BP
        );
    }

    /// @dev tests the setting of a new ETH consolation fee basis points
    function testFuzz_setMintForEthConsolationFeeBP(
        uint32 _newMintForEthConsolationFeeBP
    ) external {
        // it is assumed we will never set mintForEthConsolationFeeBP to 0
        if (_newMintForEthConsolationFeeBP != 0) {
            assert(
                perpetualMint.mintForEthConsolationFeeBP() ==
                    TEST_MINT_FOR_ETH_CONSOLATION_FEE_BP
            );

            // if the new ETH consolation fee BP is greater than the basis, the function should revert
            if (_newMintForEthConsolationFeeBP > perpetualMint.BASIS()) {
                vm.expectRevert(IGuardsInternal.BasisExceeded.selector);
            }

            perpetualMint.setMintForEthConsolationFeeBP(
                _newMintForEthConsolationFeeBP
            );

            // if the new ETH consolation fee BP was greater than the basis, the function should have reverted
            // and the ETH consolation fee BP should not have been updated
            if (_newMintForEthConsolationFeeBP > perpetualMint.BASIS()) {
                assert(
                    perpetualMint.mintForEthConsolationFeeBP() ==
                        TEST_MINT_FOR_ETH_CONSOLATION_FEE_BP
                );
            } else {
                assert(
                    perpetualMint.mintForEthConsolationFeeBP() ==
                        _newMintForEthConsolationFeeBP
                );
            }
        }
    }

    /// @dev tests for the MintForEthConsolationFeeSet event emission after a new ETH consolation fee is set
    function test_setMintForEthConsolationFeeBPEmitsMintForEthConsolationFeeSetEvent()
        external
    {
        vm.expectEmit();
        emit MintForEthConsolationFeeSet(newMintForEthConsolationFeeBP);

        perpetualMint.setMintForEthConsolationFeeBP(
            newMintForEthConsolationFeeBP
        );
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setMintForEthConsolationFeeBPRevertsWhen_CallerIsNotOwner()
        external
    {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.setMintForEthConsolationFeeBP(
            newMintForEthConsolationFeeBP
        );
    }
}
