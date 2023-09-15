// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IPausableInternal } from "@solidstate/contracts/security/pausable/IPausableInternal.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";

/// @title PerpetualMint_attemptBatchMintWithEth
/// @dev PerpetualMint test contract for testing expected attemptBatchMintWithEth behavior. Tested on an Arbitrum fork.
contract PerpetualMint_attemptBatchMintWithEth is
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

    /// @dev Tests attemptBatchMintWithEth functionality.
    function test_attemptBatchMintWithEth() external {
        uint256 preMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(preMintAccruedConsolationFees == 0);

        uint256 preMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(preMintAccruedMintEarnings == 0);

        uint256 preMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(preMintAccruedProtocolFees == 0);

        assert(address(perpetualMint).balance == 0);

        vm.prank(minter);
        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(COLLECTION, TEST_MINT_ATTEMPTS);

        uint256 postMintAccruedConsolationFees = perpetualMint
            .accruedConsolationFees();

        assert(
            postMintAccruedConsolationFees ==
                (((MINT_PRICE * TEST_MINT_ATTEMPTS) *
                    perpetualMint.consolationFeeBP()) / perpetualMint.BASIS())
        );

        uint256 postMintAccruedProtocolFees = perpetualMint
            .accruedProtocolFees();

        assert(
            postMintAccruedProtocolFees ==
                (((MINT_PRICE * TEST_MINT_ATTEMPTS) *
                    perpetualMint.mintFeeBP()) / perpetualMint.BASIS())
        );

        uint256 postMintAccruedMintEarnings = perpetualMint
            .accruedMintEarnings();

        assert(
            postMintAccruedMintEarnings ==
                (MINT_PRICE * TEST_MINT_ATTEMPTS) -
                    postMintAccruedConsolationFees -
                    postMintAccruedProtocolFees
        );

        assert(
            address(perpetualMint).balance ==
                postMintAccruedConsolationFees +
                    postMintAccruedMintEarnings +
                    postMintAccruedProtocolFees
        );
    }

    /// @dev Tests that attemptBatchMintWithEth functionality reverts when attempting to mint with an incorrect msg value amount.
    function test_attemptBatchMintWithEthRevertsWhen_AttemptingToMintWithIncorrectMsgValue()
        external
    {
        vm.expectRevert(IPerpetualMintInternal.IncorrectETHReceived.selector);

        perpetualMint.attemptBatchMintWithEth(COLLECTION, TEST_MINT_ATTEMPTS);
    }

    /// @dev Tests that attemptBatchMintWithEth functionality reverts when attempting zero mints.
    function test_attemptBatchMintWithEthRevertsWhen_AttemptingZeroMints()
        external
    {
        vm.expectRevert(IPerpetualMintInternal.InvalidNumberOfMints.selector);

        perpetualMint.attemptBatchMintWithEth(COLLECTION, ZERO_MINT_ATTEMPTS);
    }

    /// @dev Tests that attemptBatchMintWithEth functionality reverts when the contract is paused.
    function test_attemptBatchMintWithEthRevertsWhen_PausedStateIsTrue()
        external
    {
        perpetualMint.pause();
        vm.expectRevert(IPausableInternal.Pausable__Paused.selector);

        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(COLLECTION, TEST_MINT_ATTEMPTS);
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
