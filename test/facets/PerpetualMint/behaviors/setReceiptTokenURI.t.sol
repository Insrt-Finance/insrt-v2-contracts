// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";
import { UintUtils } from "@solidstate/contracts/utils/UintUtils.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";

/// @title PerpetualMint_setReceiptTokenURI
/// @dev PerpetualMint test contract for testing expected behavior of the setReceiptTokenURI function
contract PerpetualMint_setReceiptTokenURI is ArbForkTest, PerpetualMintTest {
    using UintUtils for uint256;

    /// @dev test collection address
    address COLLECTION = BORED_APE_YACHT_CLUB;

    /// @notice test token URI
    string internal constant testTokenURI = "https://test.com/";

    /// @dev test collection address encoded as uint256
    uint256 internal testTokenId = uint256(bytes32(abi.encode(COLLECTION)));

    function setUp() public override {
        super.setUp();
    }

    /// @dev tests the setting of a new receipt token URI
    function test_setReceiptTokenURI() external {
        // assert that the token URI is empty
        // direct string comparison is not supported so we use pack & use keccak256 to compare
        assert(
            keccak256(abi.encodePacked(perpetualMint.uri(testTokenId))) ==
                keccak256(abi.encodePacked(""))
        );

        perpetualMint.setReceiptTokenURI(testTokenId, testTokenURI);

        // assert that the token URI is now set to the new value
        assert(
            keccak256(abi.encodePacked(perpetualMint.uri(testTokenId))) ==
                keccak256(
                    abi.encodePacked(string(abi.encodePacked(testTokenURI)))
                )
        );

        // assert that other token URIs are still empty
        assert(
            keccak256(abi.encodePacked(perpetualMint.uri(++testTokenId))) ==
                keccak256(abi.encodePacked(""))
        );
    }

    /// @dev tests for the revert case when the caller is not the owner
    function test_setReceiptTokenURIRevertsWhen_CallerIsNotOwner() external {
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);

        vm.prank(PERPETUAL_MINT_NON_OWNER);
        perpetualMint.setReceiptTokenURI(testTokenId, testTokenURI);
    }
}
