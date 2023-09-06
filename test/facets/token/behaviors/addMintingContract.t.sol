// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { TokenTest } from "../Token.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { ITokenInternal } from "../../../../contracts/facets/token/ITokenInternal.sol";

/// @title Token_addMintingContract
/// @dev Token test contract for testing expected addMintingContract behavior. Tested on an Arbitrum fork.
contract Token_addMintingContract is ArbForkTest, TokenTest, ITokenInternal {
    // address of WETH on Arbitrum
    address internal constant WETH =
        address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

    /// @dev sets up the testing environment
    function setUp() public override {
        super.setUp();
    }

    /// @dev ensures a minting contract is added if account being added is a contract
    function test_addMintingContractAddsAccountToMintingContractsIfAccountIsContract()
        public
    {
        address[] memory oldMintingContracts = token.mintingContracts();

        token.addMintingContract(WETH);

        address[] memory newMintingContracts = token.mintingContracts();

        // check one additional contract has been added
        assert(newMintingContracts.length - oldMintingContracts.length == 1);
    }

    /// @dev ensures a minting contract is not added if account being added is not a contract
    function test_addMintingContractDoesNotAddaAccountToMintingContractsIfAccountIsNotContract()
        public
    {
        address[] memory oldMintingContracts = token.mintingContracts();

        token.addMintingContract(MINTER);

        address[] memory newMintingContracts = token.mintingContracts();

        // check no additional contract has been added
        assert(newMintingContracts.length - oldMintingContracts.length == 0);
    }

    /// @dev ensures adding a minting contract emits an event
    function test_addMintingContractsEmitsMintingContractAddedEvent() public {
        vm.expectEmit();
        emit ITokenInternal.MintingContractAdded(WETH);

        token.addMintingContract(WETH);
    }

    /// @dev ensures adding a minting contract reverts when owner is not caller
    function test_addMintingContractRevertsWhen_CallerIsNotOwner() public {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(NON_OWNER);
        token.addMintingContract(WETH);
    }
}
