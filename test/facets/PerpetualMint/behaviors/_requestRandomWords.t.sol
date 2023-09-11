// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { VRFCoordinatorV2 } from "@chainlink/vrf/VRFCoordinatorV2.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { IVRFCoordinatorV2Events } from "../../../interfaces/IVRFCoordinatorV2Events.sol";
import { VRFConfig } from "../../../../contracts/facets/PerpetualMint/Storage.sol";

/// @title PerpetualMint_requestRandomWords
/// @dev PerpetualMint test contract for testing expected behavior of the _requestRandomWords function
contract PerpetualMint_requestRandomWords is
    ArbForkTest,
    IVRFCoordinatorV2Events,
    PerpetualMintTest
{
    /// @dev test number of random words to request, current ratio of random words to mint attempts is 1:1
    uint32 internal constant TEST_NUM_WORDS = 3;

    /// @dev activation nonce for the Chainlink VRF Coordinator
    uint64 internal TEST_VRF_CONSUMER_NONCE = 1;

    /// @dev collection to test
    address COLLECTION = BORED_APE_YACHT_CLUB;

    /// @dev Tests that _requestRandomWords functionality emits a RandomWordsRequested event when successfully requesting random words.
    function test_requestRandomWordsEmitsMessageSent() external {
        _activateVRFConsumer();

        VRFConfig memory vrfConfig = perpetualMint.vrfConfig();

        // calculate the mint request pre-seed
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

        // calculate the mint request ID
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
            TEST_NUM_WORDS,
            address(perpetualMint)
        );

        perpetualMint.exposed_requestRandomWords(
            minter,
            COLLECTION,
            TEST_NUM_WORDS
        );
    }

    function test_requestRandomWordsPaidInEth() external {
        _activateVRFConsumer();

        // assert that this will be the first request added to pendingRequests
        assert(perpetualMint.exposed_pendingRequestsLength(COLLECTION) == 0);

        perpetualMint.exposed_requestRandomWords(
            minter,
            COLLECTION,
            TEST_NUM_WORDS
        );

        // this call succeeds only if the request was added to pendingRequests
        uint256 requestId = perpetualMint.exposed_pendingRequestsAt(
            COLLECTION,
            0
        );

        (address requestMinter, address requestCollection) = perpetualMint
            .exposed_requests(requestId);

        assert(requestCollection == COLLECTION);

        assert(requestMinter == minter);
    }

    function test_requestRandomWordsPaidInMint() external {
        _activateVRFConsumer();

        // assert that this will be the first request added to pendingRequests
        assert(perpetualMint.exposed_pendingRequestsLength(COLLECTION) == 0);

        perpetualMint.exposed_requestRandomWords(
            minter,
            COLLECTION,
            TEST_NUM_WORDS
        );

        // this call succeeds only if the request was added to pendingRequests
        uint256 requestId = perpetualMint.exposed_pendingRequestsAt(
            COLLECTION,
            0
        );

        (address requestMinter, address requestCollection) = perpetualMint
            .exposed_requests(requestId);

        assert(requestCollection == COLLECTION);

        assert(requestMinter == minter);
    }

    /// @dev Tests that _requestRandomWords functionality reverts when more than the current max number of words (500) is requested.
    function test_requestRandomWordsRevertsWhen_MoreThanMaxNumberOfWordsRequested()
        external
    {
        _activateVRFConsumer();

        // grab the current max number of words
        uint32 currentMaxNumWords = VRFCoordinatorV2(
            this.perpetualMintHelper().VRF_COORDINATOR()
        ).MAX_NUM_WORDS();

        // check that the current max number of words is 500
        assert(currentMaxNumWords == 500);

        vm.expectRevert(
            abi.encodeWithSelector(
                VRFCoordinatorV2.NumWordsTooBig.selector,
                currentMaxNumWords + 1,
                currentMaxNumWords
            )
        );

        perpetualMint.exposed_requestRandomWords(
            minter,
            COLLECTION,
            ++currentMaxNumWords
        );
    }

    /// @dev Tests that _requestRandomWords functionality reverts when the VRF consumer is not set.
    function test_requestRandomWordsRevertsWhen_VRFConsumerIsNotSet() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                VRFCoordinatorV2.InvalidConsumer.selector,
                TEST_VRF_SUBSCRIPTION_ID,
                address(perpetualMint)
            )
        );

        perpetualMint.exposed_requestRandomWords(
            minter,
            COLLECTION,
            TEST_NUM_WORDS
        );
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
