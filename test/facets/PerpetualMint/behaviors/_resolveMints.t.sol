// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { TokenTest } from "../../Token/Token.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { CoreTest } from "../../../diamonds/Core.t.sol";
import { TokenProxyTest } from "../../../diamonds/TokenProxy.t.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_resolveMints
/// @dev PerpetualMint test contract for testing expected behavior of the _resolveMints function
contract PerpetualMint_resolveMints is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest,
    TokenTest
{
    /// @dev mimics random values sent by Chainlink VRF
    uint256[] randomWords;

    /// @dev collection to test
    address COLLECTION = BORED_APE_YACHT_CLUB;

    /// @dev overrides the receive function to accept ETH
    receive() external payable override(CoreTest, TokenProxyTest) {}

    /// @dev sets up the context for the test cases
    function setUp() public override(PerpetualMintTest, TokenTest) {
        PerpetualMintTest.setUp();
        TokenTest.setUp();

        perpetualMint.setMintToken(address(token));

        token.addMintingContract(address(perpetualMint));
    }

    /// @dev tests that _resolveMints distributes a token receipt to the minter on successful mints
    function test_resolveMintsDistributesWinningReceipts() external {
        // expected winning mint resolutions
        randomWords.push(1);
        randomWords.push(2);
        randomWords.push(3);
        randomWords.push(4);

        uint256 tokenIdForCollection = uint256(bytes32(abi.encode(COLLECTION)));

        // assert that the minter currently has no token receipts
        assert(
            perpetualMint.exposed_balanceOf(minter, tokenIdForCollection) == 0
        );

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMints(minter, COLLECTION, randomWords);

        // check that minter received a token receipt for each won mint
        assert(
            perpetualMint.exposed_balanceOf(minter, tokenIdForCollection) == 2
        );
    }

    /// @dev tests that the MintResolved event is emitted when successfully resolving a mint
    function test_resolveMintsEmitsMintResolved() external {
        // expected winning mint resolution
        randomWords.push(1);
        randomWords.push(2);

        vm.expectEmit();
        emit MintResult(minter, COLLECTION, 1, 0, 1);

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMints(minter, COLLECTION, randomWords);
    }

    /// @dev tests that _resolveMints reverts when random words are unmatched
    function test_resolveMintsRevertsWhen_RandomWordsAreUnmatched() public {
        // unmatched expected winning mint resolution
        randomWords.push(1);

        vm.expectRevert(IPerpetualMintInternal.UnmatchedRandomWords.selector);

        vm.startPrank(address(perpetualMint));
        perpetualMint.exposed_resolveMints(minter, COLLECTION, randomWords);

        // add additional unmatched extra words to cause unmatched random words revert
        randomWords.push(2);
        randomWords.push(3);

        vm.expectRevert(IPerpetualMintInternal.UnmatchedRandomWords.selector);

        perpetualMint.exposed_resolveMints(minter, COLLECTION, randomWords);
    }

    /// @dev tests that _resolveMints works with many random values
    function testFuzz_resolveMints(
        uint256 valueOne,
        uint256 valueTwo
    ) external {
        randomWords.push(valueOne);
        randomWords.push(valueTwo);

        vm.prank(address(perpetualMint));
        perpetualMint.exposed_resolveMints(minter, COLLECTION, randomWords);
    }
}
