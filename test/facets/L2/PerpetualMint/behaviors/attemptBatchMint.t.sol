// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { VRFCoordinatorV2 } from "@chainlink/vrf/VRFCoordinatorV2.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { IVRFCoordinatorV2Events } from "../../../../interfaces/IVRFCoordinatorV2Events.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";

/// @title PerpetualMint_attemptBatchMint
/// @dev PerpetualMint test contract for testing expected attemptBatchMint behavior. Tested on an Arbitrum fork.
contract PerpetualMint_attemptBatchMint is
    IPerpetualMintInternal,
    IVRFCoordinatorV2Events,
    PerpetualMintTest,
    L2ForkTest
{
    // Arbitrum mainnet Chainlink VRF Coordinator address
    address internal constant VRF_COORDINATOR =
        0x41034678D6C633D8a95c75e1138A360a28bA15d1;

    uint64 internal TEST_VRF_CONSUMER_NONCE = 1;

    uint32 internal constant TEST_MINT_ATTEMPTS = 3;

    uint32 internal constant TEST_MINT_FEE_BP = 50000; // 0.5% fee

    uint32 internal constant ZERO_MINT_ATTEMPTS = 0;

    /// @dev Sets up the test case environment.
    function setUp() public override {
        super.setUp();

        // sets up the test case by depositing the ERC721 tokens into the PerpetualMint contract
        depositBoredApeYachtClubAssetsMock();

        // sets the mint fee
        perpetualMint.setMintFeeBP(TEST_MINT_FEE_BP);
    }

    /// @dev Tests attemptBatchMint functionality.
    function test_attemptBatchMint() public {
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
            VRF_COORDINATOR,
            s_consumersStorageSlot,
            bytes32(uint256(TEST_VRF_CONSUMER_NONCE)) // set nonce to 1 to activate the consumer
        );

        uint256 preMintProtocolFees = _protocolFees(address(perpetualMint));

        assert(preMintProtocolFees == 0);

        uint256 preMintCollectionEarnings = _collectionEarnings(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        assert(preMintCollectionEarnings == 0);

        vm.prank(msg.sender);
        perpetualMint.attemptBatchMint{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(BORED_APE_YACHT_CLUB, TEST_MINT_ATTEMPTS);

        uint256 postMintProtocolFees = _protocolFees(address(perpetualMint));

        assert(
            postMintProtocolFees ==
                (((MINT_PRICE * TEST_MINT_ATTEMPTS) *
                    _mintFeeBP(address(perpetualMint))) / BASIS)
        );

        uint256 postMintCollectionEarnings = _collectionEarnings(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        assert(
            postMintCollectionEarnings ==
                (MINT_PRICE * TEST_MINT_ATTEMPTS) - postMintProtocolFees
        );

        PerpetualMintStorage.VRFConfig memory vrfConfig = _vrfConfig(
            address(perpetualMint)
        );

        uint256 mintRequestId = uint256(
            keccak256(
                abi.encode(
                    vrfConfig.keyHash,
                    uint256(
                        keccak256(
                            abi.encode(
                                vrfConfig.keyHash,
                                address(perpetualMint),
                                TEST_VRF_SUBSCRIPTION_ID,
                                ++TEST_VRF_CONSUMER_NONCE
                            )
                        )
                    )
                )
            )
        );

        address minter = _requestMinter(address(perpetualMint), mintRequestId);

        assert(minter == msg.sender);

        address mintAttemptCollection = _requestCollection(
            address(perpetualMint),
            mintRequestId
        );

        assert(mintAttemptCollection == BORED_APE_YACHT_CLUB);
    }

    /// @dev Tests that attemptBatchMint functionality emits a RandomWordsRequested event when successfully attempting to mint.
    function test_attemptBatchMintEmitsMessageSent() public {
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
            VRF_COORDINATOR,
            s_consumersStorageSlot,
            bytes32(uint256(TEST_VRF_CONSUMER_NONCE)) // set nonce to 1 to activate the consumer
        );

        PerpetualMintStorage.VRFConfig memory vrfConfig = _vrfConfig(
            address(perpetualMint)
        );

        uint256 mintRequestPreSeed = uint256(
            keccak256(
                abi.encode(
                    vrfConfig.keyHash,
                    address(perpetualMint),
                    TEST_VRF_SUBSCRIPTION_ID,
                    ++TEST_VRF_CONSUMER_NONCE
                )
            )
        );

        uint256 mintRequestId = uint256(
            keccak256(abi.encode(vrfConfig.keyHash, mintRequestPreSeed))
        );

        vm.expectEmit();
        emit RandomWordsRequested(
            vrfConfig.keyHash,
            mintRequestId,
            mintRequestPreSeed,
            TEST_VRF_SUBSCRIPTION_ID,
            vrfConfig.minConfirmations,
            vrfConfig.callbackGasLimit,
            TEST_MINT_ATTEMPTS * 2, // 2 words per mint attempt for ERC721 mint requests
            address(perpetualMint)
        );

        perpetualMint.attemptBatchMint{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(BORED_APE_YACHT_CLUB, TEST_MINT_ATTEMPTS);
    }

    /// @dev Tests that attemptBatchMint functionality reverts when attempting to mint inactive collections.
    function test_attemptBatchMintRevertsWhen_AttemptingToMintInactiveCollections()
        public
    {
        vm.expectRevert(IPerpetualMintInternal.CollectionNotActive.selector);

        perpetualMint.attemptBatchMint(PARALLEL_ALPHA, TEST_MINT_ATTEMPTS);
    }

    /// @dev Tests that attemptBatchMint functionality reverts when attempting to mint with an incorrect msg value amount.
    function test_attemptBatchMintRevertsWhen_AttemptingToMintWithIncorrectMsgValue()
        public
    {
        vm.expectRevert(IPerpetualMintInternal.IncorrectETHReceived.selector);

        perpetualMint.attemptBatchMint(
            BORED_APE_YACHT_CLUB,
            TEST_MINT_ATTEMPTS
        );
    }

    /// @dev Tests that attemptBatchMint functionality reverts when attempting zero mints.
    function test_attemptBatchMintRevertsWhen_AttemptingZeroMints() public {
        vm.expectRevert(IPerpetualMintInternal.InvalidNumberOfMints.selector);

        perpetualMint.attemptBatchMint(
            BORED_APE_YACHT_CLUB,
            ZERO_MINT_ATTEMPTS
        );
    }

    /// @dev Tests that attemptBatchMint functionality reverts when the VRF consumer is not set.
    function test_attemptBatchMintRevertsWhen_VRFConsumerIsNotSet() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                VRFCoordinatorV2.InvalidConsumer.selector,
                TEST_VRF_SUBSCRIPTION_ID,
                address(perpetualMint)
            )
        );

        perpetualMint.attemptBatchMint{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(BORED_APE_YACHT_CLUB, TEST_MINT_ATTEMPTS);
    }
}
