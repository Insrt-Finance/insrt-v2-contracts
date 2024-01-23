// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { PerpetualMintTest_InsrtVRFCoordinator } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../ArbForkTest.t.sol";
import { VRFConfig } from "../../../contracts/facets/PerpetualMint/Storage.sol";
import { IInsrtVRFCoordinator } from "../../../contracts/vrf/Insrt/IInsrtVRFCoordinator.sol";
import { IInsrtVRFCoordinatorInternal } from "../../../contracts/vrf/Insrt/IInsrtVRFCoordinatorInternal.sol";

/// @title PerpetualMint_requestRandomWords_InsrtVRFCoordinator
/// @dev PerpetualMint test contract for testing expected behavior of the _requestRandomWords function when using the Insrt VRF Coordinator.
/// Tested on an Arbitrum fork.
contract PerpetualMint_requestRandomWords_InsrtVRFCoordinator is
    ArbForkTest,
    IInsrtVRFCoordinatorInternal,
    PerpetualMintTest_InsrtVRFCoordinator
{
    /// @dev test number of random words to request, current ratio of random words to mint attempts is 2:1
    uint32 internal constant TEST_NUM_WORDS = 2;

    uint64 internal TEST_VRF_CONSUMER_NONCE = 1;

    /// @dev test VRF subscription balance threshold, 400 LINK, 1e18
    uint96 internal TEST_VRF_SUBSCRIPTION_THRESHOLD = 400 ether;

    /// @dev collection to test
    address COLLECTION = BORED_APE_YACHT_CLUB;

    function setUp() public override {
        super.setUp();
    }

    /// @dev Tests that _requestRandomWords functionality emits a RandomWordsRequested event when successfully requesting random words.
    function test_requestRandomWordsEmitsRandomWordsRequested() external {
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
            TEST_ADJUSTMENT_FACTOR,
            TEST_NUM_WORDS
        );
    }

    /// @dev Tests that _requestRandomWords functionality updates pendingRequests appropriately.
    function test_requestRandomWordsUpdatesPendingRequests() external {
        // assert that this will be the first request added to pendingRequests
        assert(perpetualMint.exposed_pendingRequestsLength(COLLECTION) == 0);

        perpetualMint.exposed_requestRandomWords(
            minter,
            COLLECTION,
            TEST_ADJUSTMENT_FACTOR,
            TEST_NUM_WORDS
        );

        // this call succeeds only if the request was added to pendingRequests
        uint256 requestId = perpetualMint.exposed_pendingRequestsAt(
            COLLECTION,
            0
        );

        (
            address requestMinter,
            address requestCollection,
            uint256 mintPriceAdjustmentFactor
        ) = perpetualMint.exposed_requests(requestId);

        assert(requestCollection == COLLECTION);

        assert(requestMinter == minter);

        assert(mintPriceAdjustmentFactor == TEST_ADJUSTMENT_FACTOR);
    }

    /// @dev Tests that _requestRandomWords functionality reverts when more than the current max number of words (type(uint16).max) is requested.
    function test_requestRandomWordsRevertsWhen_MoreThanMaxNumberOfWordsRequested()
        external
    {
        // grab the current max number of words
        uint32 currentMaxNumWords = IInsrtVRFCoordinator(
            this.perpetualMintHelper().VRF_COORDINATOR()
        ).MAX_NUM_WORDS();

        // check that the current max number of words is type(uint16).max
        assert(currentMaxNumWords == type(uint16).max);

        vm.expectRevert(
            abi.encodeWithSelector(
                IInsrtVRFCoordinatorInternal.NumWordsTooBig.selector,
                currentMaxNumWords + 1,
                currentMaxNumWords
            )
        );

        perpetualMint.exposed_requestRandomWords(
            minter,
            COLLECTION,
            TEST_ADJUSTMENT_FACTOR,
            ++currentMaxNumWords
        );
    }

    /// @dev Tests that _requestRandomWords functionality reverts when the VRF consumer is not set.
    function test_requestRandomWordsRevertsWhen_VRFConsumerIsNotSet() external {
        address vrfCoordinator = this.perpetualMintHelper().VRF_COORDINATOR();

        vm.prank(address(this.perpetualMintHelper()));
        IInsrtVRFCoordinator(vrfCoordinator).removeConsumer(
            TEST_VRF_SUBSCRIPTION_ID,
            address(perpetualMint)
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                IInsrtVRFCoordinatorInternal.InvalidConsumer.selector,
                TEST_VRF_SUBSCRIPTION_ID,
                address(perpetualMint)
            )
        );

        perpetualMint.exposed_requestRandomWords(
            minter,
            COLLECTION,
            TEST_ADJUSTMENT_FACTOR,
            TEST_NUM_WORDS
        );
    }
}
