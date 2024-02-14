// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { TokenTest } from "../../Token/Token.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { CoreTest } from "../../../diamonds/Core/Core.t.sol";
import { TokenProxyTest } from "../../../diamonds/TokenProxy.t.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_mintAirdrop
/// @dev PerpetualMint test contract for testing expected mintAirdrop behavior. Tested on an Arbitrum fork.
contract PerpetualMint_mintAirdrop is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest,
    TokenTest
{
    uint256 internal constant AIRDROP_AMOUNT = 100 ether;

    /// @dev overrides the receive function to accept ETH
    receive() external payable override(CoreTest, TokenProxyTest) {}

    /// @dev sets up the context for the test cases
    function setUp() public override(PerpetualMintTest, TokenTest) {
        PerpetualMintTest.setUp();
        TokenTest.setUp();

        perpetualMint.setMintToken(address(token));

        vm.deal(address(perpetualMint), 10000 ether);

        token.addMintingContract(address(perpetualMint));

        // mint tokens to minter
        vm.prank(MINTER);
        token.mint(minter, MINT_AMOUNT);
    }

    /// @dev Tests mintAirdrop functionality mints AIRDROP_AMOUNT of tokens
    function test_mintAirdrop() external {
        uint256 ethRequired = AIRDROP_AMOUNT / perpetualMint.ethToMintRatio();

        uint256 oldBalance = token.balanceOf(address(token));

        perpetualMint.mintAirdrop{ value: ethRequired }(AIRDROP_AMOUNT);

        uint256 newBalance = token.balanceOf(address(token));

        assert(newBalance - oldBalance == AIRDROP_AMOUNT);
    }

    /// @dev tests that mintAirdrop increases consolation fees by ETH needed for airdrop
    function test_mintAirdropIncreasesConsolationFees() external {
        uint256 ethRequired = AIRDROP_AMOUNT / perpetualMint.ethToMintRatio();

        uint256 oldConsolationFees = perpetualMint.accruedConsolationFees();

        perpetualMint.mintAirdrop{ value: ethRequired }(AIRDROP_AMOUNT);

        uint256 newConsolationFees = perpetualMint.accruedConsolationFees();

        assert(newConsolationFees - oldConsolationFees == ethRequired);
    }

    /// @dev tests that mintAirdrop reverts when incorrect amount of ETH is received
    function test_mintAirdropRevertsWhen_IncorrectAmountOfETHIsSent() external {
        uint256 ethRequired = AIRDROP_AMOUNT / perpetualMint.ethToMintRatio();

        vm.expectRevert(IPerpetualMintInternal.IncorrectETHReceived.selector);

        perpetualMint.mintAirdrop{ value: ethRequired - 10 }(AIRDROP_AMOUNT);
    }

    /// @dev tests that mintAirdrop revents when caller is not owner
    function test_mintAirdropRevertsWhen_CallerIsNotOwner() external {
        uint256 ethRequired = AIRDROP_AMOUNT / perpetualMint.ethToMintRatio();

        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.deal(PERPETUAL_MINT_NON_OWNER, 10000 ether);

        vm.startPrank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.mintAirdrop{ value: ethRequired }(AIRDROP_AMOUNT);
    }
}
