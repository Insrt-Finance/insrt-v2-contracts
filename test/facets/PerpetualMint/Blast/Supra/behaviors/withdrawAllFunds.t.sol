// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { PerpetualMintTest_SupraBlast } from "../PerpetualMint.t.sol";
import { BlastForkTest } from "../../../../../BlastForkTest.t.sol";
import { IPerpetualMintEmergencyWithdraw } from "../../../../../../contracts/facets/PerpetualMint/IPerpetualMintEmergencyWithdraw.sol";

/// @title PerpetualMint_attemptBatchMintWithMintSupraBlast
/// @dev PerpetualMint_SupraBlast test contract for testing expected attemptBatchMintWithMint behavior. Tested on a Blast fork.
contract PerpetualMint_attemptBatchMintWithMintSupraBlast is
    BlastForkTest,
    PerpetualMintTest_SupraBlast
{
    function setUp() public override(PerpetualMintTest_SupraBlast) {
        PerpetualMintTest_SupraBlast.setUp();

        perpetualMint.setProtocolFees(100 ether);
        perpetualMint.setConsolationFees(100 ether);
        perpetualMint.setMintEarnings(30_000 ether);
    }

    function test_withdrawAllFunds() public {
        assert(perpetualMint.accruedConsolationFees() == 100 ether);
        assert(perpetualMint.accruedMintEarnings() == 30_000 ether);
        assert(perpetualMint.accruedProtocolFees() == 100 ether);

        deal(address(perpetualMint), 100 ether + 100 ether + 30_000 ether);

        uint256 oldBalance = PERPETUAL_MINT_NON_OWNER.balance;

        IPerpetualMintEmergencyWithdraw(address(perpetualMint))
            .withdrawAllFunds(PERPETUAL_MINT_NON_OWNER);

        uint256 newBalance = PERPETUAL_MINT_NON_OWNER.balance;

        assert(perpetualMint.accruedConsolationFees() == 0);
        assert(perpetualMint.accruedMintEarnings() == 0);
        assert(perpetualMint.accruedProtocolFees() == 0);
        assert(newBalance - oldBalance == 100 ether + 100 ether + 30_000 ether);
    }
}
