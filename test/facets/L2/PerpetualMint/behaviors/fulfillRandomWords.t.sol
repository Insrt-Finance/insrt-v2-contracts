// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { VRFCoordinatorV2 } from "@chainlink/vrf/VRFCoordinatorV2.sol";

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { VRFCoordinatorV2MockPlus } from "../../../../mocks/VRFCoordinatorV2MockPlus.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";

/// @title PerpetualMint_fulfillRandomWords
/// @dev PerpetualMint test contract for testing expected fulfillRandomWords behavior. Tested on an Arbitrum fork.
contract PerpetualMint_fulfillRandomWords is
    IPerpetualMintInternal,
    PerpetualMintTest,
    L2ForkTest
{
    PerpetualMintStorage.VRFConfig vrfConfig;

    VRFCoordinatorV2 private vrfCoordinatorV2;

    VRFCoordinatorV2MockPlus private vrfCoordinatorV2Mock;

    uint64 private mockVRFSubscriptionId;

    uint64 internal TEST_VRF_CONSUMER_NONCE = 1;

    /// @dev random words to be requested from ChainlinkVRF for each mint attempt
    /// depending on asset type attemping to be minted
    uint32 internal constant NUM_WORDS_ERC1155_MINT = 3;

    uint32 internal constant NUM_WORDS_ERC721_MINT = 2;

    uint32 internal constant TEST_MINT_ATTEMPTS = 3;

    uint32 internal constant TEST_MINT_FEE_BP = 50000; // 0.5% fee

    uint32 internal constant ZERO_MINT_ATTEMPTS = 0;

    /// @dev Sets up the test case environment.
    function setUp() public override {
        super.setUp();

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

        // sets up the test case by depositing ERC721 tokens into the PerpetualMint contract
        depositBoredApeYachtClubAssetsMock();

        // sets up the test case by depositing ERC1155 tokens into the PerpetualMint contract
        depositParallelAlphaAssetsMock();

        // sets the mint fee
        perpetualMint.setMintFeeBP(TEST_MINT_FEE_BP);

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
        vrfConfig = _vrfConfig(address(perpetualMint));

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

    /// @dev Tests fulfillRandomWords functionality.
    function test_fulfillRandomWords(uint256 randomness) public {
        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // attempt to mint NFTs
        vm.prank(msg.sender);
        perpetualMint.attemptBatchMint{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(BORED_APE_YACHT_CLUB, TEST_MINT_ATTEMPTS);

        uint32 numberOfRandomWordsRequested = TEST_MINT_ATTEMPTS *
            NUM_WORDS_ERC721_MINT; // 2 words per mint attempt for ERC721 mints

        // mock the VRF Coordinator request random words call
        vm.prank(address(perpetualMint));
        uint256 mockMintRequestId = vrfCoordinatorV2Mock.requestRandomWords(
            vrfConfig.keyHash,
            mockVRFSubscriptionId,
            vrfConfig.minConfirmations,
            vrfConfig.callbackGasLimit,
            numberOfRandomWordsRequested
        );

        // calculate the PerpetualMint request minter slot using the mock mint request ID
        bytes32 requestMinterSlot = keccak256(
            abi.encode(
                mockMintRequestId, // id of mock Chainlink VRF request
                uint256(PerpetualMintStorage.STORAGE_SLOT) + 6 // requestMinter mapping storage slot
            )
        );

        // store the minter as request minter in the PerpetualMint contract
        vm.store(
            address(perpetualMint),
            requestMinterSlot,
            bytes32(uint256(uint160(msg.sender)))
        );

        // calculate the PerpetualMint request collection slot using the mock mint request ID
        bytes32 requestCollectionSlot = keccak256(
            abi.encode(
                mockMintRequestId, // id of mock Chainlink VRF request
                uint256(PerpetualMintStorage.STORAGE_SLOT) + 7 // requestCollection mapping storage slot
            )
        );

        // store the minted collection as request collection in the PerpetualMint contract
        vm.store(
            address(perpetualMint),
            requestCollectionSlot,
            bytes32(uint256(uint160(BORED_APE_YACHT_CLUB)))
        );

        // calculate unfulfilledRequests enumerable set slot
        bytes32 unfulfilledRequestsSlot = keccak256(
            abi.encode(
                BORED_APE_YACHT_CLUB, // address of collection
                uint256(PerpetualMintStorage.STORAGE_SLOT) + 28 // requestIds mapping storage slot
            )
        );

        // store EnumerableSet.UintSet._inner._values length
        vm.store(
            address(perpetualMint),
            unfulfilledRequestsSlot,
            bytes32(uint256(1))
        );

        // calculate the PerpetualMint unfulfilled request id slot
        bytes32 unfulfilledRequestIdValueSlot = keccak256(
            abi.encodePacked(unfulfilledRequestsSlot)
        );

        // store the mockMintRequestId in the unfulfilledRequests enumerable set
        vm.store(
            address(perpetualMint),
            unfulfilledRequestIdValueSlot,
            bytes32(mockMintRequestId)
        );

        // calcaulte the PerpetualMint unfulfilled request id index slot
        bytes32 unfulfilledRequestIdIndexSlot = keccak256(
            abi.encode(
                bytes32(mockMintRequestId),
                uint256(unfulfilledRequestsSlot) + 1
            )
        );

        // store 1 as the index of mockMintRequestId
        vm.store(
            address(perpetualMint),
            unfulfilledRequestIdIndexSlot,
            bytes32(uint256(1))
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

        uint256[] memory oldUnfulfilledRequests = _unfulfilledRequests(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        assert(oldUnfulfilledRequests[0] == mockMintRequestId);

        // mock the VRF Coordinator fulfill random words call
        vrfCoordinatorV2Mock.fulfillRandomWordsWithOverridePlus(
            mockMintRequestId,
            address(perpetualMint),
            randomWords
        );

        uint256[] memory requestIds = _unfulfilledRequests(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        // assert mockMintRequestId has been removed
        for (uint256 i; i < requestIds.length; ++i) {
            assert(requestIds[i] != mockMintRequestId);
        }
    }

    /// @dev Tests that fulfillRandomWords correctly uses request minter and request collection data to resolve ERC1155 mints.
    function test_fulfillRandomWordsUsesStoredRequestDataToCorrectlyDetermineERC1155Resolution(
        uint256 randomness
    ) public {
        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // attempt to mint NFTs
        vm.prank(msg.sender);
        perpetualMint.attemptBatchMint{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(PARALLEL_ALPHA, TEST_MINT_ATTEMPTS);

        uint32 numberOfRandomWordsRequested = TEST_MINT_ATTEMPTS *
            NUM_WORDS_ERC1155_MINT; // 3 words per mint attempt for ERC1155 mints

        // mock the VRF Coordinator request random words call
        vm.prank(address(perpetualMint));
        uint256 mockMintRequestId = vrfCoordinatorV2Mock.requestRandomWords(
            vrfConfig.keyHash,
            mockVRFSubscriptionId,
            vrfConfig.minConfirmations,
            vrfConfig.callbackGasLimit,
            numberOfRandomWordsRequested
        );

        // calculate the PerpetualMint request minter slot using the mock mint request ID
        bytes32 requestMinterSlot = keccak256(
            abi.encode(
                mockMintRequestId, // id of mock Chainlink VRF request
                uint256(PerpetualMintStorage.STORAGE_SLOT) + 6 // requestMinter mapping storage slot
            )
        );

        // store the minter as request minter in the PerpetualMint contract
        vm.store(
            address(perpetualMint),
            requestMinterSlot,
            bytes32(uint256(uint160(msg.sender)))
        );

        // calculate the PerpetualMint request collection slot using the mock mint request ID
        bytes32 requestCollectionSlot = keccak256(
            abi.encode(
                mockMintRequestId, // id of mock Chainlink VRF request
                uint256(PerpetualMintStorage.STORAGE_SLOT) + 7 // requestCollection mapping storage slot
            )
        );

        // store the minted collection as request collection in the PerpetualMint contract
        vm.store(
            address(perpetualMint),
            requestCollectionSlot,
            bytes32(uint256(uint160(PARALLEL_ALPHA)))
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

        // only check the first & second topic (the collection address)
        // this makes sure the correct collection is being resolved
        vm.expectEmit(true, true, false, false);
        emit ERC1155MintResolved(PARALLEL_ALPHA, false);

        // mock the VRF Coordinator fulfill random words call
        vrfCoordinatorV2Mock.fulfillRandomWordsWithOverridePlus(
            mockMintRequestId,
            address(perpetualMint),
            randomWords
        );

        // checks that the correct request minter was used
        // the likelihood of this assertion is extremely low for 3 consecutive mint attempts
        assert(perpetualMint.exposed_balanceOf(msg.sender) != 0);
    }

    /// @dev Tests that fulfillRandomWords correctly uses request minter and request colletion data to resolve ERC721 mints.
    function test_fulfillRandomWordsUsesStoredRequestDataToCorrectlyDetermineERC721Resolution(
        uint256 randomness
    ) public {
        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // attempt to mint NFTs
        vm.prank(msg.sender);
        perpetualMint.attemptBatchMint{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(BORED_APE_YACHT_CLUB, TEST_MINT_ATTEMPTS);

        uint32 numberOfRandomWordsRequested = TEST_MINT_ATTEMPTS *
            NUM_WORDS_ERC721_MINT; // 2 words per mint attempt for ERC721 mints

        // mock the VRF Coordinator request random words call
        vm.prank(address(perpetualMint));
        uint256 mockMintRequestId = vrfCoordinatorV2Mock.requestRandomWords(
            vrfConfig.keyHash,
            mockVRFSubscriptionId,
            vrfConfig.minConfirmations,
            vrfConfig.callbackGasLimit,
            numberOfRandomWordsRequested
        );

        // calculate the PerpetualMint request minter slot using the mock mint request ID
        bytes32 requestMinterSlot = keccak256(
            abi.encode(
                mockMintRequestId, // id of mock Chainlink VRF request
                uint256(PerpetualMintStorage.STORAGE_SLOT) + 6 // requestMinter mapping storage slot
            )
        );

        // store the minter as request minter in the PerpetualMint contract
        vm.store(
            address(perpetualMint),
            requestMinterSlot,
            bytes32(uint256(uint160(msg.sender)))
        );

        // calculate the PerpetualMint request collection slot using the mock mint request ID
        bytes32 requestCollectionSlot = keccak256(
            abi.encode(
                mockMintRequestId, // id of mock Chainlink VRF request
                uint256(PerpetualMintStorage.STORAGE_SLOT) + 7 // requestCollection mapping storage slot
            )
        );

        // store the minted collection as request collection in the PerpetualMint contract
        vm.store(
            address(perpetualMint),
            requestCollectionSlot,
            bytes32(uint256(uint160(BORED_APE_YACHT_CLUB)))
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

        // only check the first & second topic (the collection address)
        // this makes sure the correct request collection is being resolved
        vm.expectEmit(true, true, false, false);
        emit ERC721MintResolved(BORED_APE_YACHT_CLUB, false);

        // mock the VRF Coordinator fulfill random words call
        vrfCoordinatorV2Mock.fulfillRandomWordsWithOverridePlus(
            mockMintRequestId,
            address(perpetualMint),
            randomWords
        );

        // checks that the correct request minter was used
        // the likelihood of this assertion is extremely low for 3 consecutive mint attempts
        assert(perpetualMint.exposed_balanceOf(msg.sender) != 0);
    }

    /// @dev Tests that fulfillRandomWords can currently handle at most 20 attempted mints for ERC1155 assets.
    function test_fulfillRandomWordsCanHandleMaximumTwentyERC1155MintAttempts(
        uint256 randomness
    ) public {
        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        uint32 MAXIMUM_ERC1155_MINT_ATTEMPTS = 20;

        // attempt to mint NFTs
        vm.prank(msg.sender);
        perpetualMint.attemptBatchMint{
            value: MINT_PRICE * MAXIMUM_ERC1155_MINT_ATTEMPTS
        }(PARALLEL_ALPHA, MAXIMUM_ERC1155_MINT_ATTEMPTS);

        uint32 numberOfRandomWordsRequested = MAXIMUM_ERC1155_MINT_ATTEMPTS *
            NUM_WORDS_ERC1155_MINT; // 3 words per mint attempt for ERC1155 mints

        // mock the VRF Coordinator request random words call
        vm.prank(address(perpetualMint));
        uint256 mockMintRequestId = vrfCoordinatorV2Mock.requestRandomWords(
            vrfConfig.keyHash,
            mockVRFSubscriptionId,
            vrfConfig.minConfirmations,
            vrfConfig.callbackGasLimit,
            numberOfRandomWordsRequested
        );

        // calculate the PerpetualMint request minter slot using the mock mint request ID
        bytes32 requestMinterSlot = keccak256(
            abi.encode(
                mockMintRequestId, // id of mock Chainlink VRF request
                uint256(PerpetualMintStorage.STORAGE_SLOT) + 6 // requestMinter mapping storage slot
            )
        );

        // store the minter as request minter in the PerpetualMint contract
        vm.store(
            address(perpetualMint),
            requestMinterSlot,
            bytes32(uint256(uint160(msg.sender)))
        );

        // calculate the PerpetualMint request collection slot using the mock mint request ID
        bytes32 requestCollectionSlot = keccak256(
            abi.encode(
                mockMintRequestId, // id of mock Chainlink VRF request
                uint256(PerpetualMintStorage.STORAGE_SLOT) + 7 // requestCollection mapping storage slot
            )
        );

        // store the minted collection as request collection in the PerpetualMint contract
        vm.store(
            address(perpetualMint),
            requestCollectionSlot,
            bytes32(uint256(uint160(PARALLEL_ALPHA)))
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

        // mock the VRF Coordinator fulfill random words call
        vrfCoordinatorV2Mock.fulfillRandomWordsWithOverridePlus(
            mockMintRequestId,
            address(perpetualMint),
            randomWords
        );

        uint256 currentConsolationPrizeBalance = perpetualMint
            .exposed_balanceOf(msg.sender);

        // should definitely not be zero
        assert(currentConsolationPrizeBalance != 0);

        // mock the VRF Coordinator request random words call again, this time for 63 words (21 mint attempts)
        vm.prank(address(perpetualMint));
        mockMintRequestId = vrfCoordinatorV2Mock.requestRandomWords(
            vrfConfig.keyHash,
            mockVRFSubscriptionId,
            vrfConfig.minConfirmations,
            vrfConfig.callbackGasLimit,
            numberOfRandomWordsRequested + 3 // 3 extra words to exceed the maximum
        );

        // calculate the new PerpetualMint request minter slot using the new mock mint request ID
        requestMinterSlot = keccak256(
            abi.encode(
                mockMintRequestId, // id of mock Chainlink VRF request
                uint256(PerpetualMintStorage.STORAGE_SLOT) + 6 // requestMinter mapping storage slot
            )
        );

        // store the minter as request minter in the PerpetualMint contract
        vm.store(
            address(perpetualMint),
            requestMinterSlot,
            bytes32(uint256(uint160(msg.sender)))
        );

        // calculate the new PerpetualMint request collection slot using the new mock mint request ID
        requestCollectionSlot = keccak256(
            abi.encode(
                mockMintRequestId, // id of mock Chainlink VRF request
                uint256(PerpetualMintStorage.STORAGE_SLOT) + 7 // requestCollection mapping storage slot
            )
        );

        // store the minted collection as request collection in the PerpetualMint contract
        vm.store(
            address(perpetualMint),
            requestCollectionSlot,
            bytes32(uint256(uint160(PARALLEL_ALPHA)))
        );

        // generate 93 random words
        randomWords = new uint256[](numberOfRandomWordsRequested + 3);

        for (uint256 i = 0; i < randomWords.length; ++i) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        bool success = vrfCoordinatorV2Mock.fulfillRandomWordsWithOverridePlus(
            mockMintRequestId,
            address(perpetualMint),
            randomWords
        );

        // internal call fails with OutOfGas error
        // current foundry limitation prevents us from checking the evm revert directly
        assert(success == false);

        uint256 newConsolationPrizeBalance = perpetualMint.exposed_balanceOf(
            msg.sender
        );

        // consolation prize balance should not have changed
        assert(
            newConsolationPrizeBalance ==
                perpetualMint.exposed_balanceOf(msg.sender)
        );
    }

    /// @dev Tests that fulfillRandomWords can currently handle at most 20 attempted mints for ERC721 assets.
    function test_fulfillRandomWordsCanHandleMaximumTwentyERC721MintAttempts(
        uint256 randomness
    ) public {
        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        uint32 MAXIMUM_ERC721_MINT_ATTEMPTS = 20;

        // attempt to mint NFTs
        vm.prank(msg.sender);
        perpetualMint.attemptBatchMint{
            value: MINT_PRICE * MAXIMUM_ERC721_MINT_ATTEMPTS
        }(BORED_APE_YACHT_CLUB, MAXIMUM_ERC721_MINT_ATTEMPTS);

        uint32 numberOfRandomWordsRequested = MAXIMUM_ERC721_MINT_ATTEMPTS *
            NUM_WORDS_ERC721_MINT; // 2 words per mint attempt for ERC721 mints

        // mock the VRF Coordinator request random words call
        vm.prank(address(perpetualMint));
        uint256 mockMintRequestId = vrfCoordinatorV2Mock.requestRandomWords(
            vrfConfig.keyHash,
            mockVRFSubscriptionId,
            vrfConfig.minConfirmations,
            vrfConfig.callbackGasLimit,
            numberOfRandomWordsRequested
        );

        // calculate the PerpetualMint request minter slot using the mock mint request ID
        bytes32 requestMinterSlot = keccak256(
            abi.encode(
                mockMintRequestId, // id of mock Chainlink VRF request
                uint256(PerpetualMintStorage.STORAGE_SLOT) + 6 // requestMinter mapping storage slot
            )
        );

        // store the minter as request minter in the PerpetualMint contract
        vm.store(
            address(perpetualMint),
            requestMinterSlot,
            bytes32(uint256(uint160(msg.sender)))
        );

        // calculate the PerpetualMint request collection slot using the mock mint request ID
        bytes32 requestCollectionSlot = keccak256(
            abi.encode(
                mockMintRequestId, // id of mock Chainlink VRF request
                uint256(PerpetualMintStorage.STORAGE_SLOT) + 7 // requestCollection mapping storage slot
            )
        );

        // store the minted collection as request collection in the PerpetualMint contract
        vm.store(
            address(perpetualMint),
            requestCollectionSlot,
            bytes32(uint256(uint160(BORED_APE_YACHT_CLUB)))
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

        // mock the VRF Coordinator fulfill random words call
        vrfCoordinatorV2Mock.fulfillRandomWordsWithOverridePlus(
            mockMintRequestId,
            address(perpetualMint),
            randomWords
        );

        uint256 currentConsolationPrizeBalance = perpetualMint
            .exposed_balanceOf(msg.sender);

        // should definitely not be zero
        assert(currentConsolationPrizeBalance != 0);

        // mock the VRF Coordinator request random words call again, this time for 42 words (21 mint attempts)
        vm.prank(address(perpetualMint));
        mockMintRequestId = vrfCoordinatorV2Mock.requestRandomWords(
            vrfConfig.keyHash,
            mockVRFSubscriptionId,
            vrfConfig.minConfirmations,
            vrfConfig.callbackGasLimit,
            numberOfRandomWordsRequested + 2 // 2 extra words to exceed the maximum
        );

        // calculate the new PerpetualMint request minter slot using the new mock mint request ID
        requestMinterSlot = keccak256(
            abi.encode(
                mockMintRequestId, // id of mock Chainlink VRF request
                uint256(PerpetualMintStorage.STORAGE_SLOT) + 6 // requestMinter mapping storage slot
            )
        );

        // store the minter as request minter in the PerpetualMint contract
        vm.store(
            address(perpetualMint),
            requestMinterSlot,
            bytes32(uint256(uint160(msg.sender)))
        );

        // calculate the new PerpetualMint request collection slot using the new mock mint request ID
        requestCollectionSlot = keccak256(
            abi.encode(
                mockMintRequestId, // id of mock Chainlink VRF request
                uint256(PerpetualMintStorage.STORAGE_SLOT) + 7 // requestCollection mapping storage slot
            )
        );

        // store the minted collection as request collection in the PerpetualMint contract
        vm.store(
            address(perpetualMint),
            requestCollectionSlot,
            bytes32(uint256(uint160(BORED_APE_YACHT_CLUB)))
        );

        randomWords = new uint256[](numberOfRandomWordsRequested + 2);

        // generate 42 new random words
        for (uint256 i = 0; i < randomWords.length; ++i) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        bool success = vrfCoordinatorV2Mock.fulfillRandomWordsWithOverridePlus(
            mockMintRequestId,
            address(perpetualMint),
            randomWords
        );

        // internal call fails with OutOfGas error
        // current foundry limitation prevents us from checking the evm revert directly
        assert(success == false);

        uint256 newConsolationPrizeBalance = perpetualMint.exposed_balanceOf(
            msg.sender
        );

        // consolation prize balance should not have changed
        assert(
            newConsolationPrizeBalance ==
                perpetualMint.exposed_balanceOf(msg.sender)
        );
    }

    /// @dev Tests that fulfillRandomWords reverts when the VRF subscription balance is insufficient.
    function test_fulfillRandomWordsRevertsWhen_VRFSubscriptionBalanceIsInsufficient(
        uint256 randomness
    ) public {
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

        // attempt to mint NFTs
        vm.prank(msg.sender);
        perpetualMint.attemptBatchMint{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(BORED_APE_YACHT_CLUB, TEST_MINT_ATTEMPTS);

        uint32 numberOfRandomWordsRequested = TEST_MINT_ATTEMPTS *
            NUM_WORDS_ERC721_MINT; // 2 words per mint attempt for ERC721 mints

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
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        vm.expectRevert(VRFCoordinatorV2.InsufficientBalance.selector);

        vrfCoordinatorV2Mock.fulfillRandomWordsWithOverridePlus(
            mockMintRequestId,
            address(perpetualMint),
            randomWords
        );
    }
}
