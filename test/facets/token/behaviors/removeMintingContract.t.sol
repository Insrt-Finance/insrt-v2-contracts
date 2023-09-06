// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { TokenTest } from "../Token.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { ITokenInternal } from "../../../../contracts/facets/token/ITokenInternal.sol";

/// @title Token_removeMintingContract
/// @dev Token test contract for testing expected removeMintingContract behavior. Tested on an Arbitrum fork.
contract Token_removeMintingContract is ArbForkTest, TokenTest, ITokenInternal {
    // address of WETH on Arbitrum
    address internal constant WETH =
        address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

    /// @dev sets up the testing environment
    function setUp() public override {
        super.setUp();
        token.addMintingContract(WETH);

        assert(token.mintingContracts()[1] == WETH);
    }

    /// @dev ensures a minting contract is removed from minting contracts
    function test_removeMintingContractRemovesAccountFromMintingContracts()
        public
    {
        token.removeMintingContract(WETH);

        address[] memory newMintingContracts = token.mintingContracts();

        for (uint256 i; i < newMintingContracts.length; ++i) {
            assert(newMintingContracts[i] != WETH);
        }
    }

    /// @dev ensures removing a minting contract emits an event
    function test_removeMintingContractsEmitsMintingContractRemovedEvent()
        public
    {
        vm.expectEmit();
        emit ITokenInternal.MintingContractRemoved(WETH);

        token.removeMintingContract(WETH);
    }

    /// @dev ensures removing a minting contract reverts when owner is not caller
    function test_removeMintingContractRevertsWhen_CallerIsNotOwner() public {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(NON_OWNER);
        token.removeMintingContract(WETH);
    }
}
