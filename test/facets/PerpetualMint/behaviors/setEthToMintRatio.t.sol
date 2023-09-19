// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_setEthToMintRatio
/// @dev PerpetualMint test contract for testing expected behavior of the setEthToMintRatio function
contract PerpetualMint_setEthToMintRatio is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    /// @dev new ETH:$MINT ratio to test, 1 ETH = 100,000 $MINT
    uint32 newEthToMintRatio = 100000;

    /// @dev tests the setting of a new ETH to $MINT ratio
    function testFuzz_setEthToMintRatio(uint32 _newEthToMintRatio) external {
        assert(
            perpetualMint.defaultEthToMintRatio() ==
                perpetualMint.ethToMintRatio()
        );

        perpetualMint.setEthToMintRatio(_newEthToMintRatio);

        if (_newEthToMintRatio == 0) {
            /// @dev if the new ETH to $MINT ratio is 0, the ETH to $MINT ratio should be set to the default ratio
            assert(
                perpetualMint.defaultEthToMintRatio() ==
                    perpetualMint.ethToMintRatio()
            );
        } else {
            assert(_newEthToMintRatio == perpetualMint.ethToMintRatio());
        }
    }

    /// @dev tests for the EthToMintRatioSet event emission after a new EthToMint ratio is set
    function test_setEthToMintRatioEmitsEthToMintRatioSetEvent() external {
        vm.expectEmit();
        emit EthToMintRatioSet(newEthToMintRatio);

        perpetualMint.setEthToMintRatio(newEthToMintRatio);
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setEthToMintRatioRevertsWhen_CallerIsNotOwner() external {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.setEthToMintRatio(newEthToMintRatio);
    }
}
