// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

import { PerpetualMintTest_Base } from "../PerpetualMint.t.sol";
import { TokenTest } from "../../../Token/Token.t.sol";
import { BaseForkTest } from "../../../../BaseForkTest.t.sol";
import { CoreTest } from "../../../../diamonds/Core.t.sol";
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

    /// @dev collection to test
    address internal constant COLLECTION = BORED_APE_YACHT_CLUB;

    /// @dev overrides the receive function to accept ETH
    receive() external payable override(CoreTest, TokenProxyTest) {}

    /// @dev Sets up the test case environment.
    function setUp() public override(PerpetualMintTest_Base, TokenTest) {
        PerpetualMintTest_Base.setUp();
        TokenTest.setUp();

        perpetualMint.setMintToken(address(token));

        token.addMintingContract(address(perpetualMint));

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

        // calculate and store the mint fulfillment block number using the configured vrf min # of confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            TEST_VRF_NUMBER_OF_CONFIRMATIONS;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        uint8 numberOfRandomWordsRequested = uint8(TEST_MINT_ATTEMPTS * 2); // 2 words per mint attempt

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
            perpetualMint.exposed_pendingRequestsAt(COLLECTION, 0) ==
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

        perpetualMint.exposed_pendingRequestsAt(COLLECTION, 1);
    }

    /// @dev Tests fulfillRandomWords functionality when mint is paid in $MINT.
    function testFuzz_fulfillRandomWordsWithMint(uint256 randomness) external {
        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // attempt to mint using $MINT
        vm.prank(minter);
        perpetualMint.attemptBatchMintWithMint(COLLECTION, TEST_MINT_ATTEMPTS);

        // calculate and store the mint fulfillment block number using the configured vrf min # of confirmations
        uint256 mintFulfillmentBlockNumber = mintBlockNumber +
            TEST_VRF_NUMBER_OF_CONFIRMATIONS;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        uint8 numberOfRandomWordsRequested = uint8(TEST_MINT_ATTEMPTS * 2); // 2 words per mint attempt

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
            perpetualMint.exposed_pendingRequestsAt(COLLECTION, 0) ==
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

        perpetualMint.exposed_pendingRequestsAt(COLLECTION, 1);
    }

    /// @dev Tests that fulfillRandomWords (when paid in ETH) can currently handle the max limit of 127 attempted mints per tx.
    function testFuzz_fulfillRandomWordsWithETHCanHandleMaximum127MintAttempts(
        uint256 randomness
    ) external {
        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // specify the current max number of words
        uint8 currentMaxNumWords = type(uint8).max;

        uint32 MAXIMUM_MINT_ATTEMPTS = currentMaxNumWords / 2;

        // attempt to mint with ETH
        vm.prank(minter);
        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * MAXIMUM_MINT_ATTEMPTS
        }(COLLECTION, MAXIMUM_MINT_ATTEMPTS);

        vm.expectRevert();

        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * (MAXIMUM_MINT_ATTEMPTS + 1)
        }(COLLECTION, MAXIMUM_MINT_ATTEMPTS + 1);

        uint8 numberOfRandomWordsRequested = uint8(MAXIMUM_MINT_ATTEMPTS * 2); // 2 words per mint attempt

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

    /// @dev Tests that fulfillRandomWords (when paid in $MINT) can currently handle the max limit of 127 attempted mints per tx.
    function testFuzz_fulfillRandomWordsWithMintCanHandleMaximum127MintAttempts(
        uint256 randomness
    ) external {
        // store current block number to use as the mint block number
        uint256 mintBlockNumber = block.number;

        // specify the current max number of words
        uint8 currentMaxNumWords = type(uint8).max;

        uint32 MAXIMUM_MINT_ATTEMPTS = currentMaxNumWords / 2;

        // attempt to mint with $MINT
        vm.prank(minter);
        perpetualMint.attemptBatchMintWithMint(
            COLLECTION,
            MAXIMUM_MINT_ATTEMPTS
        );

        vm.expectRevert();

        vm.prank(minter);
        perpetualMint.attemptBatchMintWithMint(
            COLLECTION,
            MAXIMUM_MINT_ATTEMPTS + 1
        );

        uint8 numberOfRandomWordsRequested = uint8(MAXIMUM_MINT_ATTEMPTS * 2); // 2 words per mint attempt

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
