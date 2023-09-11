// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IPausableInternal } from "@solidstate/contracts/security/pausable/IPausableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_attemptBatchMintWithMint
/// @dev PerpetualMint test contract for testing expected attemptBatchMintWithMint behavior. Tested on an Arbitrum fork.
contract PerpetualMint_attemptBatchMintWithMint is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest
{
    uint64 internal TEST_VRF_CONSUMER_NONCE = 1;

    uint32 internal constant TEST_MINT_ATTEMPTS = 3;

    uint32 internal constant ZERO_MINT_ATTEMPTS = 0;

    /// @dev collection to test
    address COLLECTION = BORED_APE_YACHT_CLUB;

    /// @dev Sets up the test case environment.
    function setUp() public override {
        super.setUp();

        _activateVRFConsumer();
    }

    /// @dev Tests attemptBatchMintWithMint functionality.
    function test_attemptBatchMintWithMint() external {
        // TODO
        vm.skip(true);

        vm.prank(minter);
        perpetualMint.attemptBatchMintWithMint(COLLECTION, TEST_MINT_ATTEMPTS);
    }

    /// @dev Tests that attemptBatchMintWithMint functionality reverts when attempting zero mints.
    function test_attemptBatchMintWithMintRevertsWhen_AttemptingZeroMints()
        external
    {
        vm.expectRevert(IPerpetualMintInternal.InvalidNumberOfMints.selector);

        perpetualMint.attemptBatchMintWithMint(COLLECTION, ZERO_MINT_ATTEMPTS);
    }

    /// @dev Tests that attemptBatchMintWithMint functionality reverts when the contract is paused.
    function test_attemptBatchMintWithMintRevertsWhen_PausedStateIsTrue()
        external
    {
        perpetualMint.pause();
        vm.expectRevert(IPausableInternal.Pausable__Paused.selector);

        perpetualMint.attemptBatchMintWithMint(COLLECTION, TEST_MINT_ATTEMPTS);
    }

    function _activateVRFConsumer() private {
        // grab the Chainlink VRF Coordinator's s_consumers storage slot
        bytes32 s_consumersStorageSlot = keccak256(
            abi.encode(
                TEST_VRF_SUBSCRIPTION_ID, // the test VRF subscription ID
                keccak256(
                    abi.encode(
                        address(perpetualMint), // the consumer contract address
                        2 // the s_consumers storage slot
                    )
                )
            )
        );

        vm.store(
            this.perpetualMintHelper().VRF_COORDINATOR(),
            s_consumersStorageSlot,
            bytes32(uint256(TEST_VRF_CONSUMER_NONCE)) // set nonce to 1 to activate the consumer
        );
    }
}
