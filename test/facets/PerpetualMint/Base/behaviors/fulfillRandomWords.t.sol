// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

import { PerpetualMintTest_Base } from "../PerpetualMint.t.sol";
import { TokenTest } from "../../../Token/Token.t.sol";
import { BaseForkTest } from "../../../../BaseForkTest.t.sol";
import { CoreTest } from "../../../../diamonds/Core/Core.t.sol";
import { TokenProxyTest } from "../../../../diamonds/TokenProxy.t.sol";

/// @title PerpetualMint_fulfillRandomWordsBase
/// @dev PerpetualMint_Base test contract for testing expected fulfillRandomWords behavior. Tested on a Base fork.
contract PerpetualMint_fulfillRandomWordsBase is
    BaseForkTest,
    PerpetualMintTest_Base,
    TokenTest
{
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
    function setUp() public override(PerpetualMintTest_Base, TokenTest) {
        PerpetualMintTest_Base.setUp();
        TokenTest.setUp();

        perpetualMint.setMintToken(address(token));

        token.addMintingContract(address(perpetualMint));

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

        // calculate and store the mint fulfillment block number using the configured vrf min # of confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            TEST_VRF_NUMBER_OF_CONFIRMATIONS;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        uint8 numberOfRandomWordsRequested = uint8(TEST_MINT_ATTEMPTS * 2); // 2 words per mint for collection attempt

        // Supra VRF Router nonce storage slot
        bytes32 nonceStorageSlot = bytes32(uint256(3));

        uint256 postRequestNonce = uint256(
            vm.load(address(supraRouterContract), nonceStorageSlot)
        );

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
                0
            ) == postRequestNonce
        );

        // mock the Supra VRF Generator RNG request callback
        vm.prank(supraRouterContract._supraGeneratorContract());
        supraRouterContract.rngCallback(
            postRequestNonce,
            randomWords,
            address(perpetualMint),
            VRF_REQUEST_FUNCTION_SIGNATURE
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

        // calculate and store the mint fulfillment block number using the configured vrf min # of confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            TEST_VRF_NUMBER_OF_CONFIRMATIONS;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        uint8 numberOfRandomWordsRequested = uint8(TEST_MINT_ATTEMPTS * 2); // 2 words per mint for ETH attempt

        // Supra VRF Router nonce storage slot
        bytes32 nonceStorageSlot = bytes32(uint256(3));

        uint256 postRequestNonce = uint256(
            vm.load(address(supraRouterContract), nonceStorageSlot)
        );

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
                0
            ) == postRequestNonce
        );

        // mock the Supra VRF Generator RNG request callback
        vm.prank(supraRouterContract._supraGeneratorContract());
        supraRouterContract.rngCallback(
            postRequestNonce,
            randomWords,
            address(perpetualMint),
            VRF_REQUEST_FUNCTION_SIGNATURE
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

        // calculate and store the mint fulfillment block number using the configured vrf min # of confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            TEST_VRF_NUMBER_OF_CONFIRMATIONS;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        uint8 numberOfRandomWordsRequested = uint8(TEST_MINT_ATTEMPTS * 2); // 2 words per mint for ETH attempt

        // Supra VRF Router nonce storage slot
        bytes32 nonceStorageSlot = bytes32(uint256(3));

        uint256 postRequestNonce = uint256(
            vm.load(address(supraRouterContract), nonceStorageSlot)
        );

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
                0
            ) == postRequestNonce
        );

        // mock the Supra VRF Generator RNG request callback
        vm.prank(supraRouterContract._supraGeneratorContract());
        supraRouterContract.rngCallback(
            postRequestNonce,
            randomWords,
            address(perpetualMint),
            VRF_REQUEST_FUNCTION_SIGNATURE
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

        // calculate and store the mint fulfillment block number using the configured vrf min # of confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            TEST_VRF_NUMBER_OF_CONFIRMATIONS;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        uint8 numberOfRandomWordsRequested = uint8(TEST_MINT_ATTEMPTS * 1); // 1 word per mint for $MINT attempt

        // Supra VRF Router nonce storage slot
        bytes32 nonceStorageSlot = bytes32(uint256(3));

        uint256 postRequestNonce = uint256(
            vm.load(address(supraRouterContract), nonceStorageSlot)
        );

        // setup random words to fulfill the mint request
        uint256[] memory randomWords = new uint256[](
            numberOfRandomWordsRequested
        );

        // generate random words
        for (uint256 i = 0; i < numberOfRandomWordsRequested; ++i) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        assert(
            perpetualMint.exposed_pendingRequestsAt(MINT_FOR_MINT_ADDRESS, 0) ==
                postRequestNonce
        );

        // mock the Supra VRF Generator RNG request callback
        vm.prank(supraRouterContract._supraGeneratorContract());
        supraRouterContract.rngCallback(
            postRequestNonce,
            randomWords,
            address(perpetualMint),
            VRF_REQUEST_FUNCTION_SIGNATURE
        );

        // we expect the next call to fail to assert the mock mint request has been fulfilled
        vm.expectRevert(EnumerableSet.EnumerableSet__IndexOutOfBounds.selector);

        perpetualMint.exposed_pendingRequestsAt(ETH_COLLECTION_ADDRESS, 1);
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

        // calculate and store the mint fulfillment block number using the configured vrf min # of confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            TEST_VRF_NUMBER_OF_CONFIRMATIONS;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        uint8 numberOfRandomWordsRequested = uint8(TEST_MINT_ATTEMPTS * 2); // 2 words per mint for collection attempt

        // Supra VRF Router nonce storage slot
        bytes32 nonceStorageSlot = bytes32(uint256(3));

        uint256 postRequestNonce = uint256(
            vm.load(address(supraRouterContract), nonceStorageSlot)
        );

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
                0
            ) == postRequestNonce
        );

        // mock the Supra VRF Generator RNG request callback
        vm.prank(supraRouterContract._supraGeneratorContract());
        supraRouterContract.rngCallback(
            postRequestNonce,
            randomWords,
            address(perpetualMint),
            VRF_REQUEST_FUNCTION_SIGNATURE
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

        // calculate and store the mint fulfillment block number using the configured vrf min # of confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            TEST_VRF_NUMBER_OF_CONFIRMATIONS;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        uint8 numberOfRandomWordsRequested = uint8(TEST_MINT_ATTEMPTS * 2); // 1 word per mint for $MINT attempt

        // Supra VRF Router nonce storage slot
        bytes32 nonceStorageSlot = bytes32(uint256(3));

        uint256 postRequestNonce = uint256(
            vm.load(address(supraRouterContract), nonceStorageSlot)
        );

        // setup random words to fulfill the mint request
        uint256[] memory randomWords = new uint256[](
            numberOfRandomWordsRequested
        );

        // generate random words
        for (uint256 i = 0; i < numberOfRandomWordsRequested; ++i) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        assert(
            perpetualMint.exposed_pendingRequestsAt(MINT_FOR_MINT_ADDRESS, 0) ==
                postRequestNonce
        );

        // mock the Supra VRF Generator RNG request callback
        vm.prank(supraRouterContract._supraGeneratorContract());
        supraRouterContract.rngCallback(
            postRequestNonce,
            randomWords,
            address(perpetualMint),
            VRF_REQUEST_FUNCTION_SIGNATURE
        );

        // we expect the next call to fail to assert the mock mint request has been fulfilled
        vm.expectRevert(EnumerableSet.EnumerableSet__IndexOutOfBounds.selector);

        perpetualMint.exposed_pendingRequestsAt(MINT_FOR_MINT_ADDRESS, 1);
    }

    /// @dev Tests that fulfillRandomWords (when minting for a collection paid in ETH) can currently handle the max limit of 127 attempted mints per tx.
    function testFuzz_fulfillRandomWordsMintForCollectionWithETHCanHandleMaximum127MintAttempts(
        uint256 randomness
    ) external {
        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // specify the current max number of words
        uint8 currentMaxNumWords = type(uint8).max;

        uint32 MAXIMUM_MINT_ATTEMPTS = currentMaxNumWords / 2;

        // attempt to mint for collection with ETH
        vm.prank(minter);
        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * MAXIMUM_MINT_ATTEMPTS
        }(MINT_FOR_COLLECTION_ADDRESS, NO_REFERRER, MAXIMUM_MINT_ATTEMPTS);

        vm.expectRevert();

        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * (MAXIMUM_MINT_ATTEMPTS + 1)
        }(MINT_FOR_COLLECTION_ADDRESS, NO_REFERRER, MAXIMUM_MINT_ATTEMPTS + 1);

        uint8 numberOfRandomWordsRequested = uint8(MAXIMUM_MINT_ATTEMPTS * 2); // 2 words per mint for collection attempt

        // calculate and store the mint fulfillment block number using the configured vrf min # of confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            TEST_VRF_NUMBER_OF_CONFIRMATIONS;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        // Supra VRF Router nonce storage slot
        bytes32 nonceStorageSlot = bytes32(uint256(3));

        uint256 postRequestNonce = uint256(
            vm.load(address(supraRouterContract), nonceStorageSlot)
        );

        // setup random words to fulfill the mint request
        uint256[] memory randomWords = new uint256[](
            numberOfRandomWordsRequested
        );

        // generate random words
        for (uint256 i = 0; i < numberOfRandomWordsRequested; ++i) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        // mock the Supra VRF Generator RNG request callback
        vm.prank(supraRouterContract._supraGeneratorContract());
        (bool success, ) = supraRouterContract.rngCallback(
            postRequestNonce,
            randomWords,
            address(perpetualMint),
            VRF_REQUEST_FUNCTION_SIGNATURE
        );

        assert(success == true);
    }

    /// @dev Tests that fulfillRandomWords (when minting for ETH paid in ETH) can currently handle the max limit of 127 attempted mints per tx.
    function testFuzz_fulfillRandomWordsMintForEthWithEthCanHandleMaximum127MintAttempts(
        uint256 randomness
    ) external {
        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // specify the current max number of words
        uint8 currentMaxNumWords = type(uint8).max;

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

        vm.expectRevert();

        perpetualMint.attemptBatchMintForEthWithEth{
            value: MINT_PRICE * (MAXIMUM_MINT_ATTEMPTS + 1)
        }(
            NO_REFERRER,
            MAXIMUM_MINT_ATTEMPTS + 1,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );

        uint8 numberOfRandomWordsRequested = uint8(MAXIMUM_MINT_ATTEMPTS * 2); // 2 words per mint for ETH attempt

        // calculate and store the mint fulfillment block number using the configured vrf min # of confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            TEST_VRF_NUMBER_OF_CONFIRMATIONS;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        // Supra VRF Router nonce storage slot
        bytes32 nonceStorageSlot = bytes32(uint256(3));

        uint256 postRequestNonce = uint256(
            vm.load(address(supraRouterContract), nonceStorageSlot)
        );

        // setup random words to fulfill the mint request
        uint256[] memory randomWords = new uint256[](
            numberOfRandomWordsRequested
        );

        // generate random words
        for (uint256 i = 0; i < numberOfRandomWordsRequested; ++i) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        // mock the Supra VRF Generator RNG request callback
        vm.prank(supraRouterContract._supraGeneratorContract());
        (bool success, ) = supraRouterContract.rngCallback(
            postRequestNonce,
            randomWords,
            address(perpetualMint),
            VRF_REQUEST_FUNCTION_SIGNATURE
        );

        assert(success == true);
    }

    /// @dev Tests that fulfillRandomWords (when minting for ETH paid in $MINT) can currently handle the max limit of 127 attempted mints per tx.
    function testFuzz_fulfillRandomWordsMintForEthWithMintCanHandleMaximum127MintAttempts(
        uint256 randomness
    ) external {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // specify the current max number of words
        uint8 currentMaxNumWords = type(uint8).max;

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

        vm.expectRevert();

        vm.prank(minter);
        perpetualMint.attemptBatchMintForEthWithMint(
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            MAXIMUM_MINT_ATTEMPTS + 1,
            TEST_MINT_FOR_ETH_PRIZE_VALUE,
            TEST_RISK_REWARD_RATIO
        );

        uint8 numberOfRandomWordsRequested = uint8(MAXIMUM_MINT_ATTEMPTS * 2); // 2 words per mint for ETH attempt

        // calculate and store the mint fulfillment block number using the configured vrf min # of confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            TEST_VRF_NUMBER_OF_CONFIRMATIONS;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        // Supra VRF Router nonce storage slot
        bytes32 nonceStorageSlot = bytes32(uint256(3));

        uint256 postRequestNonce = uint256(
            vm.load(address(supraRouterContract), nonceStorageSlot)
        );

        // setup random words to fulfill the mint request
        uint256[] memory randomWords = new uint256[](
            numberOfRandomWordsRequested
        );

        // generate random words
        for (uint256 i = 0; i < numberOfRandomWordsRequested; ++i) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        // mock the Supra VRF Generator RNG request callback
        vm.prank(supraRouterContract._supraGeneratorContract());
        (bool success, ) = supraRouterContract.rngCallback(
            postRequestNonce,
            randomWords,
            address(perpetualMint),
            VRF_REQUEST_FUNCTION_SIGNATURE
        );

        assert(success == true);
    }

    /// @dev Tests that fulfillRandomWords (when minting for $MINT paid in ETH) can currently handle the max limit of 255 attempted mints per tx.
    function testFuzz_fulfillRandomWordsMintForMintWithETHCanHandleMaximum255MintAttempts(
        uint256 randomness
    ) external {
        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // specify the current max number of words
        uint8 currentMaxNumWords = type(uint8).max;

        uint32 MAXIMUM_MINT_ATTEMPTS = currentMaxNumWords;

        // attempt to mint for $MINT with ETH
        vm.prank(minter);
        perpetualMint.attemptBatchMintForMintWithEth{
            value: MINT_FOR_MINT_PRICE * MAXIMUM_MINT_ATTEMPTS
        }(NO_REFERRER, MAXIMUM_MINT_ATTEMPTS);

        vm.expectRevert();

        perpetualMint.attemptBatchMintForMintWithEth{
            value: MINT_PRICE * (MAXIMUM_MINT_ATTEMPTS + 1)
        }(NO_REFERRER, MAXIMUM_MINT_ATTEMPTS + 1);

        uint8 numberOfRandomWordsRequested = uint8(MAXIMUM_MINT_ATTEMPTS * 1); // 1 word per mint for $MINT attempt

        // calculate and store the mint fulfillment block number using the configured vrf min # of confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            TEST_VRF_NUMBER_OF_CONFIRMATIONS;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        // Supra VRF Router nonce storage slot
        bytes32 nonceStorageSlot = bytes32(uint256(3));

        uint256 postRequestNonce = uint256(
            vm.load(address(supraRouterContract), nonceStorageSlot)
        );

        // setup random words to fulfill the mint request
        uint256[] memory randomWords = new uint256[](
            numberOfRandomWordsRequested
        );

        // generate random words
        for (uint256 i = 0; i < numberOfRandomWordsRequested; ++i) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        // mock the Supra VRF Generator RNG request callback
        vm.prank(supraRouterContract._supraGeneratorContract());
        (bool success, ) = supraRouterContract.rngCallback(
            postRequestNonce,
            randomWords,
            address(perpetualMint),
            VRF_REQUEST_FUNCTION_SIGNATURE
        );

        assert(success == true);
    }

    /// @dev Tests that fulfillRandomWords (when minting for a collection paid in $MINT) can currently handle the max limit of 127 attempted mints per tx.
    function testFuzz_fulfillRandomWordsMintForCollectionWithMintCanHandleMaximum127MintAttempts(
        uint256 randomness
    ) external {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // specify the current max number of words
        uint8 currentMaxNumWords = type(uint8).max;

        uint32 MAXIMUM_MINT_ATTEMPTS = currentMaxNumWords / 2;

        // attempt to mint for collection with $MINT
        vm.prank(minter);
        perpetualMint.attemptBatchMintWithMint(
            MINT_FOR_COLLECTION_ADDRESS,
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            MAXIMUM_MINT_ATTEMPTS
        );

        vm.expectRevert();

        vm.prank(minter);
        perpetualMint.attemptBatchMintWithMint(
            MINT_FOR_COLLECTION_ADDRESS,
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            MAXIMUM_MINT_ATTEMPTS + 1
        );

        uint8 numberOfRandomWordsRequested = uint8(MAXIMUM_MINT_ATTEMPTS * 2); // 2 words per mint for collection attempt

        // calculate and store the mint fulfillment block number using the configured vrf min # of confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            TEST_VRF_NUMBER_OF_CONFIRMATIONS;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        // Supra VRF Router nonce storage slot
        bytes32 nonceStorageSlot = bytes32(uint256(3));

        uint256 postRequestNonce = uint256(
            vm.load(address(supraRouterContract), nonceStorageSlot)
        );

        // setup random words to fulfill the mint request
        uint256[] memory randomWords = new uint256[](
            numberOfRandomWordsRequested
        );

        // generate random words
        for (uint256 i = 0; i < numberOfRandomWordsRequested; ++i) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        // mock the Supra VRF Generator RNG request callback
        vm.prank(supraRouterContract._supraGeneratorContract());
        (bool success, ) = supraRouterContract.rngCallback(
            postRequestNonce,
            randomWords,
            address(perpetualMint),
            VRF_REQUEST_FUNCTION_SIGNATURE
        );

        assert(success == true);
    }

    /// @dev Tests that fulfillRandomWords (when minting for $MINT paid in $MINT) can currently handle the max limit of 255 attempted mints per tx.
    function testFuzz_fulfillRandomWordsMintForMintWithMintCanHandleMaximum255MintAttempts(
        uint256 randomness
    ) external {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // specify the current max number of words
        uint8 currentMaxNumWords = type(uint8).max;

        uint32 MAXIMUM_MINT_ATTEMPTS = currentMaxNumWords;

        // attempt to mint for $MINT with $MINT
        vm.prank(minter);
        perpetualMint.attemptBatchMintForMintWithMint(
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            MAXIMUM_MINT_ATTEMPTS
        );

        vm.expectRevert();

        vm.prank(minter);
        perpetualMint.attemptBatchMintForMintWithMint(
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            MAXIMUM_MINT_ATTEMPTS + 1
        );

        uint8 numberOfRandomWordsRequested = uint8(MAXIMUM_MINT_ATTEMPTS * 1); // 1 word per mint for $MINT attempt

        // calculate and store the mint fulfillment block number using the configured vrf min # of confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            TEST_VRF_NUMBER_OF_CONFIRMATIONS;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        // Supra VRF Router nonce storage slot
        bytes32 nonceStorageSlot = bytes32(uint256(3));

        uint256 postRequestNonce = uint256(
            vm.load(address(supraRouterContract), nonceStorageSlot)
        );

        // setup random words to fulfill the mint request
        uint256[] memory randomWords = new uint256[](
            numberOfRandomWordsRequested
        );

        // generate random words
        for (uint256 i = 0; i < numberOfRandomWordsRequested; ++i) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        // mock the Supra VRF Generator RNG request callback
        vm.prank(supraRouterContract._supraGeneratorContract());
        (bool success, ) = supraRouterContract.rngCallback(
            postRequestNonce,
            randomWords,
            address(perpetualMint),
            VRF_REQUEST_FUNCTION_SIGNATURE
        );

        assert(success == true);
    }
}
