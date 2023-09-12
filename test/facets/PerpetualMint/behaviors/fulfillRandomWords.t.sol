// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { VRFCoordinatorV2 } from "@chainlink/vrf/VRFCoordinatorV2.sol";
import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { TokenTest } from "../../Token/Token.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { CoreTest } from "../../../diamonds/Core.t.sol";
import { TokenProxyTest } from "../../../diamonds/TokenProxy.t.sol";
import { VRFCoordinatorV2MockPlus } from "../../../mocks/VRFCoordinatorV2MockPlus.sol";
import { IPerpetualMintInternal } from "../../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage, VRFConfig } from "../../../../contracts/facets/PerpetualMint/Storage.sol";

/// @title PerpetualMint_fulfillRandomWords
/// @dev PerpetualMint test contract for testing expected fulfillRandomWords behavior. Tested on an Arbitrum fork.
contract PerpetualMint_fulfillRandomWords is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest,
    TokenTest
{
    VRFConfig vrfConfig;

    VRFCoordinatorV2 private vrfCoordinatorV2;

    VRFCoordinatorV2MockPlus private vrfCoordinatorV2Mock;

    uint64 private mockVRFSubscriptionId;

    uint64 internal TEST_VRF_CONSUMER_NONCE = 1;

    uint32 internal constant TEST_MINT_ATTEMPTS = 3;

    uint32 internal constant ZERO_MINT_ATTEMPTS = 0;

    /// @dev collection to test
    address internal constant COLLECTION = BORED_APE_YACHT_CLUB;

    /// @dev overrides the receive function to accept ETH
    receive() external payable override(CoreTest, TokenProxyTest) {}

    /// @dev Sets up the test case environment.
    function setUp() public override(PerpetualMintTest, TokenTest) {
        PerpetualMintTest.setUp();
        TokenTest.setUp();

        perpetualMint.setMintToken(address(token));

        token.addMintingContract(address(perpetualMint));

        vrfCoordinatorV2 = VRFCoordinatorV2(
            this.perpetualMintHelper().VRF_COORDINATOR()
        );

        // get current wei per unit link conversion factor for configuring the VRF Coordinator mock
        (, int256 weiPerUnitLink, , , ) = vrfCoordinatorV2
            .LINK_ETH_FEED()
            .latestRoundData();

        vrfCoordinatorV2Mock = new VRFCoordinatorV2MockPlus(
            // set the base fee, scaled by 1e12 (uint32 to uint96)
            uint96(vrfCoordinatorV2.getFeeTier(0)) * 1e12, // arbitrum fee tiers are currently all the same, base fee is currently 0.005 LINK
            // set the gas price in link by dividing the current wei per unit gas (tx.gasprice) by current wei per unit link
            // note: the current L1 gas fee should be added to the tx.gasprice before dividing by wei per unit link.
            // due to outstanding issues with foundry supporting L2 precompiles, this is not currently straightforward to dynamically calculate.
            uint96(tx.gasprice / uint256(weiPerUnitLink))
        );

        // create a mock VRF subscription
        mockVRFSubscriptionId = vrfCoordinatorV2Mock.createSubscription();

        // fund the mock VRF subscription
        vrfCoordinatorV2Mock.fundSubscription(mockVRFSubscriptionId, 100 ether);

        // add the PerpetualMint contract as a consumer on the mock VRF coordinator
        vrfCoordinatorV2Mock.addConsumer(
            mockVRFSubscriptionId,
            address(perpetualMint)
        );

        // store the VRF config
        vrfConfig = perpetualMint.vrfConfig();

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

        perpetualMint.setConsolationFees(100 ether);

        // mint a bunch of tokens to minter
        vm.prank(MINTER);
        token.mint(minter, MINT_AMOUNT * 1e10);
    }

    /// @dev Tests fulfillRandomWords functionality when mint is paid in ETH.
    function testFuzz_fulfillRandomWordsWithEth(uint256 randomness) external {
        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // attempt to mint using ETH
        vm.prank(minter);
        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(COLLECTION, TEST_MINT_ATTEMPTS);

        uint32 numberOfRandomWordsRequested = TEST_MINT_ATTEMPTS * 2; // 2 words per mint attempt

        // mock the VRF Coordinator request random words call
        vm.prank(address(perpetualMint));
        uint256 mockMintRequestId = vrfCoordinatorV2Mock.requestRandomWords(
            vrfConfig.keyHash,
            mockVRFSubscriptionId,
            vrfConfig.minConfirmations,
            vrfConfig.callbackGasLimit,
            numberOfRandomWordsRequested
        );

        // add the mock mint request as a pending request
        perpetualMint.exposed_pendingRequestsAdd(COLLECTION, mockMintRequestId);

        // add the mock mint request data
        perpetualMint.setRequests(mockMintRequestId, minter, COLLECTION);

        // calculate and store the mint fulfillment block number using vrf config min confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            vrfConfig.minConfirmations;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        // setup random words to fulfill the mint request
        uint256[] memory randomWords = new uint256[](
            numberOfRandomWordsRequested
        );

        // generate random words
        for (uint256 i = 0; i < numberOfRandomWordsRequested; ++i) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        assert(
            perpetualMint.exposed_pendingRequestsAt(COLLECTION, 1) ==
                mockMintRequestId
        );

        // mock the VRF Coordinator fulfill random words call
        vrfCoordinatorV2Mock.fulfillRandomWordsWithOverridePlus(
            mockMintRequestId,
            address(perpetualMint),
            randomWords
        );

        // we expect the next call to fail to assert the mock mint request has been fulfilled
        vm.expectRevert(EnumerableSet.EnumerableSet__IndexOutOfBounds.selector);

        perpetualMint.exposed_pendingRequestsAt(COLLECTION, 1);
    }

    /// @dev Tests fulfillRandomWords functionality when mint is paid in $MINT.
    function testFuzz_fulfillRandomWordsWithMint(uint256 randomness) external {
        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // attempt to mint using $MINT
        vm.prank(minter);
        perpetualMint.attemptBatchMintWithMint(COLLECTION, TEST_MINT_ATTEMPTS);

        uint32 numberOfRandomWordsRequested = TEST_MINT_ATTEMPTS * 2; // 2 words per mint attempt

        // mock the VRF Coordinator request random words call
        vm.prank(address(perpetualMint));
        uint256 mockMintRequestId = vrfCoordinatorV2Mock.requestRandomWords(
            vrfConfig.keyHash,
            mockVRFSubscriptionId,
            vrfConfig.minConfirmations,
            vrfConfig.callbackGasLimit,
            numberOfRandomWordsRequested
        );

        // add the mock mint request as a pending request
        perpetualMint.exposed_pendingRequestsAdd(COLLECTION, mockMintRequestId);

        // add the mock mint request data
        perpetualMint.setRequests(mockMintRequestId, minter, COLLECTION);

        // calculate and store the mint fulfillment block number using vrf config min confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            vrfConfig.minConfirmations;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        // setup random words to fulfill the mint request
        uint256[] memory randomWords = new uint256[](
            numberOfRandomWordsRequested
        );

        // generate random words
        for (uint256 i = 0; i < numberOfRandomWordsRequested; ++i) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        assert(
            perpetualMint.exposed_pendingRequestsAt(COLLECTION, 1) ==
                mockMintRequestId
        );

        // mock the VRF Coordinator fulfill random words call
        vrfCoordinatorV2Mock.fulfillRandomWordsWithOverridePlus(
            mockMintRequestId,
            address(perpetualMint),
            randomWords
        );

        // we expect the next call to fail to assert the mock mint request has been fulfilled
        vm.expectRevert(EnumerableSet.EnumerableSet__IndexOutOfBounds.selector);

        perpetualMint.exposed_pendingRequestsAt(COLLECTION, 1);
    }

    /// @dev Tests that fulfillRandomWords (when paid in ETH) can currently handle the max limit of 250 attempted mints per tx.
    function testFuzz_fulfillRandomWordsWithETHCanHandleMaximum250MintAttempts(
        uint256 randomness
    ) external {
        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // grab the current max number of words
        uint32 currentMaxNumWords = VRFCoordinatorV2(
            this.perpetualMintHelper().VRF_COORDINATOR()
        ).MAX_NUM_WORDS();

        // check that the current max number of words is 500
        assert(currentMaxNumWords == 500);

        uint32 MAXIMUM_MINT_ATTEMPTS = currentMaxNumWords / 2;

        // attempt to mint with ETH
        vm.prank(minter);
        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * MAXIMUM_MINT_ATTEMPTS
        }(COLLECTION, MAXIMUM_MINT_ATTEMPTS);

        vm.expectRevert(
            abi.encodeWithSelector(
                VRFCoordinatorV2.NumWordsTooBig.selector,
                currentMaxNumWords + 2,
                currentMaxNumWords
            )
        );
        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * (MAXIMUM_MINT_ATTEMPTS + 1)
        }(COLLECTION, MAXIMUM_MINT_ATTEMPTS + 1);

        uint32 numberOfRandomWordsRequested = currentMaxNumWords; // 2 words per mint attempt

        // mock the VRF Coordinator request random words call
        vm.prank(address(perpetualMint));
        uint256 mockMintRequestId = vrfCoordinatorV2Mock.requestRandomWords(
            vrfConfig.keyHash,
            mockVRFSubscriptionId,
            vrfConfig.minConfirmations,
            vrfConfig.callbackGasLimit,
            numberOfRandomWordsRequested
        );

        // add the mock mint request as a pending request
        perpetualMint.exposed_pendingRequestsAdd(COLLECTION, mockMintRequestId);

        // add the mock mint request data
        perpetualMint.setRequests(mockMintRequestId, minter, COLLECTION);

        // calculate and store the mint fulfillment block number using vrf config min confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            vrfConfig.minConfirmations;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        // setup random words to fulfill the mint request
        uint256[] memory randomWords = new uint256[](
            numberOfRandomWordsRequested
        );

        // generate random words
        for (uint256 i = 1; i < numberOfRandomWordsRequested; ++i) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        // mock the VRF Coordinator fulfill random words call
        bool success = vrfCoordinatorV2Mock.fulfillRandomWordsWithOverridePlus(
            mockMintRequestId,
            address(perpetualMint),
            randomWords
        );

        assert(success == true);
    }

    /// @dev Tests that fulfillRandomWords (when paid in $MINT) can currently handle the max limit of 250 attempted mints per tx.
    function testFuzz_fulfillRandomWordsWithMintCanHandleMaximum250MintAttempts(
        uint256 randomness
    ) external {
        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // grab the current max number of words
        uint32 currentMaxNumWords = VRFCoordinatorV2(
            this.perpetualMintHelper().VRF_COORDINATOR()
        ).MAX_NUM_WORDS();

        // check that the current max number of words is 500
        assert(currentMaxNumWords == 500);

        uint32 MAXIMUM_MINT_ATTEMPTS = currentMaxNumWords / 2;

        // attempt to mint with $MINT
        vm.prank(minter);
        perpetualMint.attemptBatchMintWithMint(
            COLLECTION,
            MAXIMUM_MINT_ATTEMPTS
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                VRFCoordinatorV2.NumWordsTooBig.selector,
                currentMaxNumWords + 2,
                currentMaxNumWords
            )
        );

        vm.prank(minter);
        perpetualMint.attemptBatchMintWithMint(
            COLLECTION,
            MAXIMUM_MINT_ATTEMPTS + 1
        );

        uint32 numberOfRandomWordsRequested = currentMaxNumWords; // 2 words per mint attempt

        // mock the VRF Coordinator request random words call
        vm.prank(address(perpetualMint));
        uint256 mockMintRequestId = vrfCoordinatorV2Mock.requestRandomWords(
            vrfConfig.keyHash,
            mockVRFSubscriptionId,
            vrfConfig.minConfirmations,
            vrfConfig.callbackGasLimit,
            numberOfRandomWordsRequested
        );

        // add the mock mint request as a pending request
        perpetualMint.exposed_pendingRequestsAdd(COLLECTION, mockMintRequestId);

        // add the mock mint request data
        perpetualMint.setRequests(mockMintRequestId, minter, COLLECTION);

        // calculate and store the mint fulfillment block number using vrf config min confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            vrfConfig.minConfirmations;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        // setup random words to fulfill the mint request
        uint256[] memory randomWords = new uint256[](
            numberOfRandomWordsRequested
        );

        // generate random words
        for (uint256 i = 1; i < numberOfRandomWordsRequested; ++i) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        // mock the VRF Coordinator fulfill random words call
        bool success = vrfCoordinatorV2Mock.fulfillRandomWordsWithOverridePlus(
            mockMintRequestId,
            address(perpetualMint),
            randomWords
        );

        assert(success == true);
    }

    /// @dev Tests that fulfillRandomWords reverts when the VRF subscription balance is insufficient.
    function test_fulfillRandomWordsRevertsWhen_VRFSubscriptionBalanceIsInsufficient()
        external
    {
        // create a new mock VRF subscription, but don't fund it
        mockVRFSubscriptionId = vrfCoordinatorV2Mock.createSubscription();

        // add the PerpetualMint contract as a consumer on the mock VRF coordinator for
        // the new mock subscription
        vrfCoordinatorV2Mock.addConsumer(
            mockVRFSubscriptionId,
            address(perpetualMint)
        );

        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // attempt to mint using ETH
        vm.prank(minter);
        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(COLLECTION, TEST_MINT_ATTEMPTS);

        uint32 numberOfRandomWordsRequested = TEST_MINT_ATTEMPTS; // 1 word per mint attempt

        // mock the VRF Coordinator request random words call
        vm.prank(address(perpetualMint));
        uint256 mockMintRequestId = vrfCoordinatorV2Mock.requestRandomWords(
            vrfConfig.keyHash,
            mockVRFSubscriptionId,
            vrfConfig.minConfirmations,
            vrfConfig.callbackGasLimit,
            numberOfRandomWordsRequested
        );

        // calculate and store the mint fulfillment block number using vrf config min confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            vrfConfig.minConfirmations;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        // setup random words to fulfill the mint request
        uint256[] memory randomWords = new uint256[](
            numberOfRandomWordsRequested
        );

        // generate random words
        for (uint256 i = 0; i < numberOfRandomWordsRequested; ++i) {
            randomWords[i] = i;
        }

        vm.expectRevert(VRFCoordinatorV2.InsufficientBalance.selector);

        vrfCoordinatorV2Mock.fulfillRandomWordsWithOverridePlus(
            mockMintRequestId,
            address(perpetualMint),
            randomWords
        );
    }
}
