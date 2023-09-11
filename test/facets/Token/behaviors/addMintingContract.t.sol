// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import { TokenTest } from "../Token.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { ITokenInternal } from "../../../../contracts/facets/Token/ITokenInternal.sol";

/// @title Token_addMintingContract
/// @dev Token test contract for testing expected addMintingContract behavior. Tested on an Arbitrum fork.
contract Token_addMintingContract is ArbForkTest, TokenTest, ITokenInternal {
    /// @dev sets up the testing environment
    function setUp() public override {
        super.setUp();

        // remove MINTER from minting contracts
        token.removeMintingContract(MINTER);
    }

    /// @dev ensures a minting contract is added
    function test_addMintingContractAddsAccountToMintingContracts() public {
        address[] memory oldMintingContracts = token.mintingContracts();

        token.addMintingContract(MINTER);

        address[] memory newMintingContracts = token.mintingContracts();

        // check no additional contract has been added
        assert(newMintingContracts.length - oldMintingContracts.length == 1);
    }

    /// @dev ensures adding a minting contract emits an event
    function test_addMintingContractsEmitsMintingContractAddedEvent() public {
        vm.expectEmit();
        emit ITokenInternal.MintingContractAdded(MINTER);

        token.addMintingContract(MINTER);
    }

    /// @dev ensures adding a minting contract reverts when owner is not caller
    function test_addMintingContractRevertsWhen_CallerIsNotOwner() public {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(TOKEN_NON_OWNER);
        token.addMintingContract(MINTER);
    }
}
