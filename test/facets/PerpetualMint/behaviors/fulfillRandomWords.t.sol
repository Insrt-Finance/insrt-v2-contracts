// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "forge-std/Test.sol";

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { TokenTest } from "../../Token/Token.t.sol";
import { ArbForkTest } from "../../../ArbForkTest.t.sol";
import { CoreTest } from "../../../diamonds/Core/Core.t.sol";
import { TokenProxyTest } from "../../../diamonds/TokenProxy.t.sol";
import { IVRFCoordinatorV2 } from "../../../interfaces/IVRFCoordinatorV2.sol";
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

    IVRFCoordinatorV2 private vrfCoordinatorV2;

    VRFCoordinatorV2MockPlus private vrfCoordinatorV2Mock;

    uint64 private mockVRFSubscriptionId;

    uint64 internal TEST_VRF_CONSUMER_NONCE = 1;

    uint32 internal constant TEST_MINT_ATTEMPTS = 3;

    uint32 internal constant ZERO_MINT_ATTEMPTS = 0;

    uint256 internal MINT_FOR_MINT_PRICE;

    /// @dev address to test when minting for collections
    address internal constant MINT_FOR_COLLECTION_ADDRESS =
        BORED_APE_YACHT_CLUB;

    /// @dev address to test when minting for $MINT
    address internal constant MINT_FOR_MINT_ADDRESS =
        MINT_TOKEN_COLLECTION_ADDRESS;

    /// @dev overrides the receive function to accept ETH
    receive() external payable override(CoreTest, TokenProxyTest) {}

    /// @dev Sets up the test case environment.
    function setUp() public override(PerpetualMintTest, TokenTest) {
        PerpetualMintTest.setUp();
        TokenTest.setUp();

        perpetualMint.setMintToken(address(token));

        token.addMintingContract(address(perpetualMint));

        vrfCoordinatorV2 = IVRFCoordinatorV2(
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

        perpetualMint.setMintEarnings(30_000 ether);

        // mint a bunch of tokens to minter
        vm.prank(MINTER);
        token.mint(minter, MINT_AMOUNT * 1e10);

        // get the mint price for $MINT
        MINT_FOR_MINT_PRICE = perpetualMint.collectionMintPrice(
            MINT_FOR_MINT_ADDRESS
        );
    }

    /// @dev Tests fulfillRandomWords functionality when mint for collection is paid in ETH.
    function testFuzz_fulfillRandomWordsMintForCollectionWithEth(
        uint256 randomness
    ) external {
        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // attempt to mint for a collection using ETH
        vm.prank(minter);
        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(MINT_FOR_COLLECTION_ADDRESS, NO_REFERRER, TEST_MINT_ATTEMPTS);

        uint32 numberOfRandomWordsRequested = TEST_MINT_ATTEMPTS * 2; // 2 words per mint for collection attempt

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
        perpetualMint.exposed_pendingRequestsAdd(
            MINT_FOR_COLLECTION_ADDRESS,
            mockMintRequestId
        );

        // add the mock mint request data
        perpetualMint.setRequests(
            mockMintRequestId,
            minter,
            MINT_FOR_COLLECTION_ADDRESS,
            TEST_MINT_EARNINGS_FEE_PER_SPIN,
            TEST_ADJUSTMENT_FACTOR,
            TEST_MINT_FOR_COLLECTION_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
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
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        assert(
            perpetualMint.exposed_pendingRequestsAt(
                MINT_FOR_COLLECTION_ADDRESS,
                1
            ) == mockMintRequestId
        );

        // mock the VRF Coordinator fulfill random words call
        vrfCoordinatorV2Mock.fulfillRandomWordsWithOverridePlus(
            mockMintRequestId,
            address(perpetualMint),
            randomWords
        );

        // we expect the next call to fail to assert the mock mint request has been fulfilled
        vm.expectRevert(EnumerableSet.EnumerableSet__IndexOutOfBounds.selector);

        perpetualMint.exposed_pendingRequestsAt(MINT_FOR_COLLECTION_ADDRESS, 1);
    }

    /// @dev Tests fulfillRandomWords functionality when mint for ETH is paid in ETH.
    function testFuzz_fulfillRandomWordsMintForEthWithEth(
        uint256 randomness
    ) external {
        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // attempt to mint for ETH
        vm.prank(minter);
        perpetualMint.attemptBatchMintForEthWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(
            NO_REFERRER,
            TEST_MINT_ATTEMPTS,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );

        uint32 numberOfRandomWordsRequested = TEST_MINT_ATTEMPTS * 2; // 2 words per mint for ETH attempt

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
        perpetualMint.exposed_pendingRequestsAdd(
            ETH_COLLECTION_ADDRESS,
            mockMintRequestId
        );

        // add the mock mint request data
        perpetualMint.setRequests(
            mockMintRequestId,
            minter,
            ETH_COLLECTION_ADDRESS,
            TEST_MINT_EARNINGS_FEE_PER_SPIN,
            TEST_ADJUSTMENT_FACTOR,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
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
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        assert(
            perpetualMint.exposed_pendingRequestsAt(
                ETH_COLLECTION_ADDRESS,
                1
            ) == mockMintRequestId
        );

        // mock the VRF Coordinator fulfill random words call
        vrfCoordinatorV2Mock.fulfillRandomWordsWithOverridePlus(
            mockMintRequestId,
            address(perpetualMint),
            randomWords
        );

        // we expect the next call to fail to assert the mock mint request has been fulfilled
        vm.expectRevert(EnumerableSet.EnumerableSet__IndexOutOfBounds.selector);

        perpetualMint.exposed_pendingRequestsAt(ETH_COLLECTION_ADDRESS, 1);
    }

    /// @dev Tests fulfillRandomWords functionality when mint for ETH is paid in $MINT.
    function testFuzz_fulfillRandomWordsMintForEthWithMint(
        uint256 randomness
    ) external {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // attempt to mint for ETH using $MINT
        vm.prank(minter);
        perpetualMint.attemptBatchMintForEthWithMint(
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_ATTEMPTS,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );

        uint32 numberOfRandomWordsRequested = TEST_MINT_ATTEMPTS * 2; // 2 words per mint for ETH attempt

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
        perpetualMint.exposed_pendingRequestsAdd(
            ETH_COLLECTION_ADDRESS,
            mockMintRequestId
        );

        // add the mock mint request data
        perpetualMint.setRequests(
            mockMintRequestId,
            minter,
            ETH_COLLECTION_ADDRESS,
            TEST_MINT_EARNINGS_FEE_PER_SPIN,
            TEST_ADJUSTMENT_FACTOR,
            TEST_MINT_FOR_COLLECTION_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
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
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        assert(
            perpetualMint.exposed_pendingRequestsAt(
                ETH_COLLECTION_ADDRESS,
                1
            ) == mockMintRequestId
        );

        // mock the VRF Coordinator fulfill random words call
        vrfCoordinatorV2Mock.fulfillRandomWordsWithOverridePlus(
            mockMintRequestId,
            address(perpetualMint),
            randomWords
        );

        // we expect the next call to fail to assert the mock mint request has been fulfilled
        vm.expectRevert(EnumerableSet.EnumerableSet__IndexOutOfBounds.selector);

        perpetualMint.exposed_pendingRequestsAt(ETH_COLLECTION_ADDRESS, 1);
    }

    /// @dev Tests fulfillRandomWords functionality when mint for $MINT is paid in ETH.
    function testFuzz_fulfillRandomWordsMintForMintWithEth(
        uint256 randomness
    ) external {
        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // attempt to mint for $MINT using ETH
        vm.prank(minter);
        perpetualMint.attemptBatchMintForMintWithEth{
            value: MINT_FOR_MINT_PRICE * TEST_MINT_ATTEMPTS
        }(NO_REFERRER, TEST_MINT_ATTEMPTS);

        uint32 numberOfRandomWordsRequested = TEST_MINT_ATTEMPTS * 1; // 1 word per mint for $MINT attempt

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
        perpetualMint.exposed_pendingRequestsAdd(
            MINT_FOR_MINT_ADDRESS,
            mockMintRequestId
        );

        // add the mock mint request data
        perpetualMint.setRequests(
            mockMintRequestId,
            minter,
            MINT_FOR_MINT_ADDRESS,
            TEST_MINT_EARNINGS_FEE_PER_SPIN,
            TEST_ADJUSTMENT_FACTOR,
            TEST_MINT_FOR_MINT_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
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
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        assert(
            perpetualMint.exposed_pendingRequestsAt(MINT_FOR_MINT_ADDRESS, 1) ==
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

        perpetualMint.exposed_pendingRequestsAt(MINT_FOR_MINT_ADDRESS, 1);
    }

    /// @dev Tests fulfillRandomWords functionality when mint for collection is paid in $MINT.
    function testFuzz_fulfillRandomWordsMintForCollectionWithMint(
        uint256 randomness
    ) external {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // attempt to mint for collection using $MINT
        vm.prank(minter);
        perpetualMint.attemptBatchMintWithMint(
            MINT_FOR_COLLECTION_ADDRESS,
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_ATTEMPTS
        );

        uint32 numberOfRandomWordsRequested = TEST_MINT_ATTEMPTS * 2; // 2 words per mint for collection attempt

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
        perpetualMint.exposed_pendingRequestsAdd(
            MINT_FOR_COLLECTION_ADDRESS,
            mockMintRequestId
        );

        // add the mock mint request data
        perpetualMint.setRequests(
            mockMintRequestId,
            minter,
            MINT_FOR_COLLECTION_ADDRESS,
            TEST_MINT_EARNINGS_FEE_PER_SPIN,
            TEST_ADJUSTMENT_FACTOR,
            TEST_MINT_FOR_COLLECTION_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
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
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        assert(
            perpetualMint.exposed_pendingRequestsAt(
                MINT_FOR_COLLECTION_ADDRESS,
                1
            ) == mockMintRequestId
        );

        // mock the VRF Coordinator fulfill random words call
        vrfCoordinatorV2Mock.fulfillRandomWordsWithOverridePlus(
            mockMintRequestId,
            address(perpetualMint),
            randomWords
        );

        // we expect the next call to fail to assert the mock mint request has been fulfilled
        vm.expectRevert(EnumerableSet.EnumerableSet__IndexOutOfBounds.selector);

        perpetualMint.exposed_pendingRequestsAt(MINT_FOR_COLLECTION_ADDRESS, 1);
    }

    /// @dev Tests fulfillRandomWords functionality when mint for $MINT is paid in $MINT.
    function testFuzz_fulfillRandomWordsMintForMintWithMint(
        uint256 randomness
    ) external {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // attempt to mint for $MINT using $MINT
        vm.prank(minter);
        perpetualMint.attemptBatchMintForMintWithMint(
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_ATTEMPTS
        );

        uint32 numberOfRandomWordsRequested = TEST_MINT_ATTEMPTS * 1; // 1 word per mint for $MINT attempt

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
        perpetualMint.exposed_pendingRequestsAdd(
            MINT_FOR_MINT_ADDRESS,
            mockMintRequestId
        );

        // add the mock mint request data
        perpetualMint.setRequests(
            mockMintRequestId,
            minter,
            MINT_FOR_MINT_ADDRESS,
            TEST_MINT_EARNINGS_FEE_PER_SPIN,
            TEST_ADJUSTMENT_FACTOR,
            TEST_MINT_FOR_MINT_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
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
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        assert(
            perpetualMint.exposed_pendingRequestsAt(MINT_FOR_MINT_ADDRESS, 1) ==
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

        perpetualMint.exposed_pendingRequestsAt(MINT_FOR_MINT_ADDRESS, 1);
    }

    /// @dev Tests that fulfillRandomWords (when minting for a collection paid in ETH) can currently handle the max limit of 250 attempted mints per tx.
    function testFuzz_fulfillRandomWordsMintForCollectionWithETHCanHandleMaximum250MintAttempts(
        uint256 randomness
    ) external {
        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // grab the current max number of words
        uint32 currentMaxNumWords = IVRFCoordinatorV2(
            this.perpetualMintHelper().VRF_COORDINATOR()
        ).MAX_NUM_WORDS();

        // check that the current max number of words is 500
        assert(currentMaxNumWords == 500);

        uint32 MAXIMUM_MINT_ATTEMPTS = currentMaxNumWords / 2;

        // attempt to mint for collection with ETH
        vm.prank(minter);
        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * MAXIMUM_MINT_ATTEMPTS
        }(MINT_FOR_COLLECTION_ADDRESS, NO_REFERRER, MAXIMUM_MINT_ATTEMPTS);

        vm.expectRevert(
            abi.encodeWithSelector(
                IVRFCoordinatorV2.NumWordsTooBig.selector,
                currentMaxNumWords + 2,
                currentMaxNumWords
            )
        );
        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * (MAXIMUM_MINT_ATTEMPTS + 1)
        }(MINT_FOR_COLLECTION_ADDRESS, NO_REFERRER, MAXIMUM_MINT_ATTEMPTS + 1);

        uint32 numberOfRandomWordsRequested = currentMaxNumWords; // 2 words per mint for collection attempt

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
        perpetualMint.exposed_pendingRequestsAdd(
            MINT_FOR_COLLECTION_ADDRESS,
            mockMintRequestId
        );

        // add the mock mint request data
        perpetualMint.setRequests(
            mockMintRequestId,
            minter,
            MINT_FOR_COLLECTION_ADDRESS,
            TEST_MINT_EARNINGS_FEE_PER_SPIN,
            TEST_ADJUSTMENT_FACTOR,
            TEST_MINT_FOR_COLLECTION_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
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

    /// @dev Tests that fulfillRandomWords (when minting for ETH paid in ETH) can currently handle the max limit of 250 attempted mints per tx.
    function testFuzz_fulfillRandomWordsMintForEthWithEthCanHandleMaximum250MintAttempts(
        uint256 randomness
    ) external {
        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // grab the current max number of words
        uint32 currentMaxNumWords = IVRFCoordinatorV2(
            this.perpetualMintHelper().VRF_COORDINATOR()
        ).MAX_NUM_WORDS();

        // check that the current max number of words is 500
        assert(currentMaxNumWords == 500);

        uint32 MAXIMUM_MINT_ATTEMPTS = currentMaxNumWords / 2;

        // attempt to mint for ETH
        vm.prank(minter);
        perpetualMint.attemptBatchMintForEthWithEth{
            value: MINT_PRICE * MAXIMUM_MINT_ATTEMPTS
        }(
            NO_REFERRER,
            MAXIMUM_MINT_ATTEMPTS,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                IVRFCoordinatorV2.NumWordsTooBig.selector,
                currentMaxNumWords + 2,
                currentMaxNumWords
            )
        );
        perpetualMint.attemptBatchMintForEthWithEth{
            value: MINT_PRICE * (MAXIMUM_MINT_ATTEMPTS + 1)
        }(
            NO_REFERRER,
            MAXIMUM_MINT_ATTEMPTS + 1,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );

        uint32 numberOfRandomWordsRequested = currentMaxNumWords; // 2 words per mint for ETH attempt

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
        perpetualMint.exposed_pendingRequestsAdd(
            ETH_COLLECTION_ADDRESS,
            mockMintRequestId
        );

        // add the mock mint request data
        perpetualMint.setRequests(
            mockMintRequestId,
            minter,
            ETH_COLLECTION_ADDRESS,
            TEST_MINT_EARNINGS_FEE_PER_SPIN,
            TEST_ADJUSTMENT_FACTOR,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
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

    /// @dev Tests that fulfillRandomWords (when minting for ETH paid in $MINT) can currently handle the max limit of 250 attempted mints per tx.
    function testFuzz_fulfillRandomWordsMintForETHWithMintCanHandleMaximum250MintAttempts(
        uint256 randomness
    ) external {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // grab the current max number of words
        uint32 currentMaxNumWords = IVRFCoordinatorV2(
            this.perpetualMintHelper().VRF_COORDINATOR()
        ).MAX_NUM_WORDS();

        // check that the current max number of words is 500
        assert(currentMaxNumWords == 500);

        uint32 MAXIMUM_MINT_ATTEMPTS = currentMaxNumWords / 2;

        // attempt to mint for ETH with $MINT
        vm.prank(minter);
        perpetualMint.attemptBatchMintForEthWithMint(
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            MAXIMUM_MINT_ATTEMPTS,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                IVRFCoordinatorV2.NumWordsTooBig.selector,
                currentMaxNumWords + 2,
                currentMaxNumWords
            )
        );

        vm.prank(minter);
        perpetualMint.attemptBatchMintForEthWithMint(
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            MAXIMUM_MINT_ATTEMPTS + 1,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );

        uint32 numberOfRandomWordsRequested = currentMaxNumWords; // 2 words per mint for ETH attempt

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
        perpetualMint.exposed_pendingRequestsAdd(
            MINT_FOR_COLLECTION_ADDRESS,
            mockMintRequestId
        );

        // add the mock mint request data
        perpetualMint.setRequests(
            mockMintRequestId,
            minter,
            MINT_FOR_COLLECTION_ADDRESS,
            TEST_MINT_EARNINGS_FEE_PER_SPIN,
            TEST_ADJUSTMENT_FACTOR,
            TEST_MINT_FOR_COLLECTION_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
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

    /// @dev Tests that fulfillRandomWords (when minting for $MINT paid in ETH) can currently handle the max limit of 500 attempted mints per tx.
    function testFuzz_fulfillRandomWordsMintForMintWithETHCanHandleMaximum500MintAttempts(
        uint256 randomness
    ) external {
        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // grab the current max number of words
        uint32 currentMaxNumWords = IVRFCoordinatorV2(
            this.perpetualMintHelper().VRF_COORDINATOR()
        ).MAX_NUM_WORDS();

        // check that the current max number of words is 500
        assert(currentMaxNumWords == 500);

        uint32 MAXIMUM_MINT_ATTEMPTS = currentMaxNumWords;

        // attempt to mint for $MINT with ETH
        vm.prank(minter);
        perpetualMint.attemptBatchMintForMintWithEth{
            value: MINT_FOR_MINT_PRICE * MAXIMUM_MINT_ATTEMPTS
        }(NO_REFERRER, MAXIMUM_MINT_ATTEMPTS);

        vm.expectRevert(
            abi.encodeWithSelector(
                IVRFCoordinatorV2.NumWordsTooBig.selector,
                currentMaxNumWords + 1,
                currentMaxNumWords
            )
        );
        perpetualMint.attemptBatchMintForMintWithEth{
            value: MINT_FOR_MINT_PRICE * (MAXIMUM_MINT_ATTEMPTS + 1)
        }(NO_REFERRER, MAXIMUM_MINT_ATTEMPTS + 1);

        uint32 numberOfRandomWordsRequested = currentMaxNumWords; // 1 word per mint for $MINT attempt

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
        perpetualMint.exposed_pendingRequestsAdd(
            MINT_FOR_MINT_ADDRESS,
            mockMintRequestId
        );

        // add the mock mint request data
        perpetualMint.setRequests(
            mockMintRequestId,
            minter,
            MINT_FOR_MINT_ADDRESS,
            TEST_MINT_EARNINGS_FEE_PER_SPIN,
            TEST_ADJUSTMENT_FACTOR,
            TEST_MINT_FOR_MINT_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
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

    /// @dev Tests that fulfillRandomWords (when minting for a collection paid in $MINT) can currently handle the max limit of 250 attempted mints per tx.
    function testFuzz_fulfillRandomWordsMintForCollectionWithMintCanHandleMaximum250MintAttempts(
        uint256 randomness
    ) external {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // grab the current max number of words
        uint32 currentMaxNumWords = IVRFCoordinatorV2(
            this.perpetualMintHelper().VRF_COORDINATOR()
        ).MAX_NUM_WORDS();

        // check that the current max number of words is 500
        assert(currentMaxNumWords == 500);

        uint32 MAXIMUM_MINT_ATTEMPTS = currentMaxNumWords / 2;

        // attempt to mint for collection with $MINT
        vm.prank(minter);
        perpetualMint.attemptBatchMintWithMint(
            MINT_FOR_COLLECTION_ADDRESS,
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            MAXIMUM_MINT_ATTEMPTS
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                IVRFCoordinatorV2.NumWordsTooBig.selector,
                currentMaxNumWords + 2,
                currentMaxNumWords
            )
        );

        vm.prank(minter);
        perpetualMint.attemptBatchMintWithMint(
            MINT_FOR_COLLECTION_ADDRESS,
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            MAXIMUM_MINT_ATTEMPTS + 1
        );

        uint32 numberOfRandomWordsRequested = currentMaxNumWords; // 2 words per mint for collection attempt

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
        perpetualMint.exposed_pendingRequestsAdd(
            MINT_FOR_COLLECTION_ADDRESS,
            mockMintRequestId
        );

        // add the mock mint request data
        perpetualMint.setRequests(
            mockMintRequestId,
            minter,
            MINT_FOR_COLLECTION_ADDRESS,
            TEST_MINT_EARNINGS_FEE_PER_SPIN,
            TEST_ADJUSTMENT_FACTOR,
            TEST_MINT_FOR_COLLECTION_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
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

    /// @dev Tests that fulfillRandomWords (when minting for $MINT paid in $MINT) can currently handle the max limit of 500 attempted mints per tx.
    function testFuzz_fulfillRandomWordsMintForMintWithMintCanHandleMaximum500MintAttempts(
        uint256 randomness
    ) external {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // grab the current max number of words
        uint32 currentMaxNumWords = IVRFCoordinatorV2(
            this.perpetualMintHelper().VRF_COORDINATOR()
        ).MAX_NUM_WORDS();

        // check that the current max number of words is 500
        assert(currentMaxNumWords == 500);

        uint32 MAXIMUM_MINT_ATTEMPTS = currentMaxNumWords;

        // attempt to mint for $MINT with $MINT
        vm.prank(minter);
        perpetualMint.attemptBatchMintForMintWithMint(
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            MAXIMUM_MINT_ATTEMPTS
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                IVRFCoordinatorV2.NumWordsTooBig.selector,
                currentMaxNumWords + 1,
                currentMaxNumWords
            )
        );

        vm.prank(minter);
        perpetualMint.attemptBatchMintForMintWithMint(
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            MAXIMUM_MINT_ATTEMPTS + 1
        );

        uint32 numberOfRandomWordsRequested = currentMaxNumWords; // 1 word per mint for $MINT attempt

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
        perpetualMint.exposed_pendingRequestsAdd(
            MINT_FOR_MINT_ADDRESS,
            mockMintRequestId
        );

        // add the mock mint request data
        perpetualMint.setRequests(
            mockMintRequestId,
            minter,
            MINT_FOR_MINT_ADDRESS,
            TEST_MINT_EARNINGS_FEE_PER_SPIN,
            TEST_ADJUSTMENT_FACTOR,
            TEST_MINT_FOR_MINT_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
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
        }(MINT_FOR_COLLECTION_ADDRESS, NO_REFERRER, TEST_MINT_ATTEMPTS);

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

        vm.expectRevert(IVRFCoordinatorV2.InsufficientBalance.selector);

        vrfCoordinatorV2Mock.fulfillRandomWordsWithOverridePlus(
            mockMintRequestId,
            address(perpetualMint),
            randomWords
        );
    }
}
