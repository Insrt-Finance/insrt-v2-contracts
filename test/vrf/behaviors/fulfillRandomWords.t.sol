// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "forge-std/Test.sol";

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

import { PerpetualMintTest_InsrtVRFCoordinator } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../ArbForkTest.t.sol";
import { CoreTest } from "../../diamonds/Core.t.sol";
import { TokenProxyTest } from "../../diamonds/TokenProxy.t.sol";
import { TokenTest } from "../../facets/Token/Token.t.sol";
import { IPerpetualMintInternal } from "../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage, VRFConfig } from "../../../contracts/facets/PerpetualMint/Storage.sol";
import { RequestCommitment } from "../../../contracts/vrf/DataTypes.sol";
import { IInsrtVRFCoordinator } from "../../../contracts/vrf/IInsrtVRFCoordinator.sol";
import { IInsrtVRFCoordinatorInternal } from "../../../contracts/vrf/IInsrtVRFCoordinatorInternal.sol";

/// @title PerpetualMint_fulfillRandomWords_InsrtVRFCoordinator
/// @dev PerpetualMint test contract for testing expected fulfillRandomWords behavior when using the Insrt VRF Coordinator. Tested on an Arbitrum fork.
contract PerpetualMint_fulfillRandomWords_InsrtVRFCoordinator is
    ArbForkTest,
    IPerpetualMintInternal,
    PerpetualMintTest_InsrtVRFCoordinator,
    TokenTest
{
    VRFConfig vrfConfig;

    IInsrtVRFCoordinator private insrtVRFCoordinator;

    uint32 internal constant TEST_MINT_ATTEMPTS = 3;

    uint32 internal constant ZERO_MINT_ATTEMPTS = 0;

    uint256 internal MINT_FOR_MINT_PRICE;

    /// @dev address to test when minting for collections
    address internal constant MINT_FOR_COLLECTION_ADDRESS =
        BORED_APE_YACHT_CLUB;

    /// @dev address to test when minting for $MINT, currently treated as address(0)
    address internal constant MINT_FOR_MINT_ADDRESS = address(0);

    /// @dev overrides the receive function to accept ETH
    receive() external payable override(CoreTest, TokenProxyTest) {}

    /// @dev Sets up the test case environment.
    function setUp()
        public
        override(PerpetualMintTest_InsrtVRFCoordinator, TokenTest)
    {
        PerpetualMintTest_InsrtVRFCoordinator.setUp();
        TokenTest.setUp();

        perpetualMint.setMintToken(address(token));

        token.addMintingContract(address(perpetualMint));

        insrtVRFCoordinator = IInsrtVRFCoordinator(
            this.perpetualMintHelper().VRF_COORDINATOR()
        );

        vm.prank(address(this.perpetualMintHelper()));
        insrtVRFCoordinator.addFulfiller(msg.sender);

        // store the VRF config
        vrfConfig = perpetualMint.vrfConfig();

        perpetualMint.setConsolationFees(10000 ether);

        // mint a bunch of tokens to minter
        vm.prank(MINTER);
        token.mint(minter, MINT_AMOUNT * 1e10);

        // make sure minter has enough ETH to mint a bunch of times
        vm.deal(minter, 1000000 ether);

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
        uint64 mintBlockNumber = uint64(block.number);

        // attempt to mint for a collection using ETH
        vm.prank(minter);
        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * TEST_MINT_ATTEMPTS
        }(MINT_FOR_COLLECTION_ADDRESS, NO_REFERRER, TEST_MINT_ATTEMPTS);

        uint32 numberOfRandomWordsRequested = TEST_MINT_ATTEMPTS * 2; // 2 words per mint for collection attempt

        uint256 requestPreSeed = uint256(
            keccak256(
                abi.encode(
                    vrfConfig.keyHash,
                    address(perpetualMint),
                    vrfConfig.subscriptionId,
                    2
                )
            )
        );

        uint256 requestId = uint256(
            keccak256(abi.encode(vrfConfig.keyHash, requestPreSeed))
        );

        // calculate and store the mint fulfillment block number using vrf config min confirmations
        uint64 mintFulfillmentBlockNumber = mintBlockNumber +
            vrfConfig.minConfirmations;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        assert(
            perpetualMint.exposed_pendingRequestsAt(
                MINT_FOR_COLLECTION_ADDRESS,
                0
            ) == requestId
        );

        // mock the VRF Coordinator fulfill random words call
        vm.prank(msg.sender);
        insrtVRFCoordinator.fulfillRandomWords(
            requestId,
            randomness,
            RequestCommitment(
                mintBlockNumber,
                vrfConfig.subscriptionId,
                vrfConfig.callbackGasLimit,
                numberOfRandomWordsRequested,
                address(perpetualMint)
            )
        );

        // we expect the next call to fail to assert the mock mint request has been fulfilled
        vm.expectRevert(EnumerableSet.EnumerableSet__IndexOutOfBounds.selector);

        perpetualMint.exposed_pendingRequestsAt(MINT_FOR_COLLECTION_ADDRESS, 0);
    }

    /// @dev Tests fulfillRandomWords functionality when mint for $MINT is paid in ETH.
    function testFuzz_fulfillRandomWordsMintForMintWithEth(
        uint256 randomness
    ) external {
        // store current block number to use as the mint block number
        uint64 mintBlockNumber = uint64(block.number);

        // attempt to mint for $MINT using ETH
        vm.prank(minter);
        perpetualMint.attemptBatchMintForMintWithEth{
            value: MINT_FOR_MINT_PRICE * TEST_MINT_ATTEMPTS
        }(NO_REFERRER, TEST_MINT_ATTEMPTS);

        uint32 numberOfRandomWordsRequested = TEST_MINT_ATTEMPTS * 1; // 1 word per mint for $MINT attempt

        uint256 requestPreSeed = uint256(
            keccak256(
                abi.encode(
                    vrfConfig.keyHash,
                    address(perpetualMint),
                    vrfConfig.subscriptionId,
                    2
                )
            )
        );

        uint256 requestId = uint256(
            keccak256(abi.encode(vrfConfig.keyHash, requestPreSeed))
        );

        // calculate and store the mint fulfillment block number using vrf config min confirmations
        uint64 mintFulfillmentBlockNumber = mintBlockNumber +
            vrfConfig.minConfirmations;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        assert(
            perpetualMint.exposed_pendingRequestsAt(MINT_FOR_MINT_ADDRESS, 0) ==
                requestId
        );

        // mock the VRF Coordinator fulfill random words call
        vm.prank(msg.sender);
        insrtVRFCoordinator.fulfillRandomWords(
            requestId,
            randomness,
            RequestCommitment(
                mintBlockNumber,
                vrfConfig.subscriptionId,
                vrfConfig.callbackGasLimit,
                numberOfRandomWordsRequested,
                address(perpetualMint)
            )
        );

        // we expect the next call to fail to assert the mock mint request has been fulfilled
        vm.expectRevert(EnumerableSet.EnumerableSet__IndexOutOfBounds.selector);

        perpetualMint.exposed_pendingRequestsAt(MINT_FOR_MINT_ADDRESS, 0);
    }

    /// @dev Tests fulfillRandomWords functionality when mint for collection is paid in $MINT.
    function testFuzz_fulfillRandomWordsMintForCollectionWithMint(
        uint256 randomness
    ) external {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        // store current block number to use as the mint block number
        uint64 mintBlockNumber = uint64(block.number);

        // attempt to mint for collection using $MINT
        vm.prank(minter);
        perpetualMint.attemptBatchMintWithMint(
            MINT_FOR_COLLECTION_ADDRESS,
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_ATTEMPTS
        );

        uint32 numberOfRandomWordsRequested = TEST_MINT_ATTEMPTS * 2; // 2 words per mint for collection attempt

        uint256 requestPreSeed = uint256(
            keccak256(
                abi.encode(
                    vrfConfig.keyHash,
                    address(perpetualMint),
                    vrfConfig.subscriptionId,
                    2
                )
            )
        );

        uint256 requestId = uint256(
            keccak256(abi.encode(vrfConfig.keyHash, requestPreSeed))
        );

        // calculate and store the mint fulfillment block number using vrf config min confirmations
        uint64 mintFulfillmentBlockNumber = mintBlockNumber +
            vrfConfig.minConfirmations;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        assert(
            perpetualMint.exposed_pendingRequestsAt(
                MINT_FOR_COLLECTION_ADDRESS,
                0
            ) == requestId
        );

        // mock the VRF Coordinator fulfill random words call
        vm.prank(msg.sender);
        insrtVRFCoordinator.fulfillRandomWords(
            requestId,
            randomness,
            RequestCommitment(
                mintBlockNumber,
                vrfConfig.subscriptionId,
                vrfConfig.callbackGasLimit,
                numberOfRandomWordsRequested,
                address(perpetualMint)
            )
        );

        // we expect the next call to fail to assert the mock mint request has been fulfilled
        vm.expectRevert(EnumerableSet.EnumerableSet__IndexOutOfBounds.selector);

        perpetualMint.exposed_pendingRequestsAt(MINT_FOR_COLLECTION_ADDRESS, 0);
    }

    /// @dev Tests fulfillRandomWords functionality when mint for $MINT is paid in $MINT.
    function testFuzz_fulfillRandomWordsMintForMintWithMint(
        uint256 randomness
    ) external {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        // store current block number to use as the mint block number
        uint64 mintBlockNumber = uint64(block.number);

        // attempt to mint for $MINT using $MINT
        vm.prank(minter);
        perpetualMint.attemptBatchMintForMintWithMint(
            NO_REFERRER,
            MINT_PRICE * currentEthToMintRatio,
            TEST_MINT_ATTEMPTS
        );

        uint32 numberOfRandomWordsRequested = TEST_MINT_ATTEMPTS * 1; // 1 word per mint for $MINT attempt

        uint256 requestPreSeed = uint256(
            keccak256(
                abi.encode(
                    vrfConfig.keyHash,
                    address(perpetualMint),
                    vrfConfig.subscriptionId,
                    2
                )
            )
        );

        uint256 requestId = uint256(
            keccak256(abi.encode(vrfConfig.keyHash, requestPreSeed))
        );

        // calculate and store the mint fulfillment block number using vrf config min confirmations
        uint64 mintFulfillmentBlockNumber = mintBlockNumber +
            vrfConfig.minConfirmations;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        assert(
            perpetualMint.exposed_pendingRequestsAt(MINT_FOR_MINT_ADDRESS, 0) ==
                requestId
        );

        // mock the VRF Coordinator fulfill random words call
        vm.prank(msg.sender);
        insrtVRFCoordinator.fulfillRandomWords(
            requestId,
            randomness,
            RequestCommitment(
                mintBlockNumber,
                vrfConfig.subscriptionId,
                vrfConfig.callbackGasLimit,
                numberOfRandomWordsRequested,
                address(perpetualMint)
            )
        );

        // we expect the next call to fail to assert the mock mint request has been fulfilled
        vm.expectRevert(EnumerableSet.EnumerableSet__IndexOutOfBounds.selector);

        perpetualMint.exposed_pendingRequestsAt(MINT_FOR_MINT_ADDRESS, 0);
    }

    /// @dev Tests that fulfillRandomWords (when minting for a collection paid in ETH) can currently handle the max limit of (type(uint16).max) attempted mints per tx.
    function testFuzz_fulfillRandomWordsMintForCollectionWithETHCanHandleMaximumUint16MintAttempts(
        uint256 randomness
    ) external {
        // store current block number to use as the mint block number
        uint64 mintBlockNumber = uint64(block.number);

        // grab the current max number of words
        uint32 currentMaxNumWords = IInsrtVRFCoordinator(
            this.perpetualMintHelper().VRF_COORDINATOR()
        ).MAX_NUM_WORDS();

        // check that the current max number of words is type(uint16).max
        assert(currentMaxNumWords == type(uint16).max);

        // account for integer division by subtracting by 1 on mints for collection
        --currentMaxNumWords;

        uint32 MAXIMUM_MINT_ATTEMPTS = currentMaxNumWords / 2;

        // attempt to mint for collection with ETH
        vm.prank(minter);
        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * MAXIMUM_MINT_ATTEMPTS
        }(MINT_FOR_COLLECTION_ADDRESS, NO_REFERRER, MAXIMUM_MINT_ATTEMPTS);

        vm.expectRevert(
            abi.encodeWithSelector(
                IInsrtVRFCoordinatorInternal.NumWordsTooBig.selector,
                // account for integer division
                currentMaxNumWords + 2,
                currentMaxNumWords + 1
            )
        );

        perpetualMint.attemptBatchMintWithEth{
            value: MINT_PRICE * (MAXIMUM_MINT_ATTEMPTS + 1)
        }(MINT_FOR_COLLECTION_ADDRESS, NO_REFERRER, MAXIMUM_MINT_ATTEMPTS + 1);

        uint32 numberOfRandomWordsRequested = currentMaxNumWords; // 2 words per mint for collection attempt

        uint256 requestPreSeed = uint256(
            keccak256(
                abi.encode(
                    vrfConfig.keyHash,
                    address(perpetualMint),
                    vrfConfig.subscriptionId,
                    2
                )
            )
        );

        uint256 requestId = uint256(
            keccak256(abi.encode(vrfConfig.keyHash, requestPreSeed))
        );

        // calculate and store the mint fulfillment block number using vrf config min confirmations
        uint96 mintFulfillmentBlockNumber = mintBlockNumber +
            vrfConfig.minConfirmations;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        // mock the VRF Coordinator fulfill random words call
        vm.prank(msg.sender);
        uint96 payment = insrtVRFCoordinator.fulfillRandomWords(
            requestId,
            randomness,
            RequestCommitment(
                mintBlockNumber,
                vrfConfig.subscriptionId,
                vrfConfig.callbackGasLimit,
                numberOfRandomWordsRequested,
                address(perpetualMint)
            )
        );

        assert(payment == 0); // call succeeded and payment is 0
    }

    /// @dev Tests that fulfillRandomWords (when minting for $MINT paid in ETH) can currently handle the max limit of (type(uint16).max)  attempted mints per tx.
    function testFuzz_fulfillRandomWordsMintForMintWithETHCanHandleMaximum500MintAttempts(
        uint256 randomness
    ) external {
        // store current block number to use as the mint block number
        uint64 mintBlockNumber = uint64(block.number);

        // grab the current max number of words
        uint32 currentMaxNumWords = IInsrtVRFCoordinator(
            this.perpetualMintHelper().VRF_COORDINATOR()
        ).MAX_NUM_WORDS();

        // check that the current max number of words is type(uint16).max
        assert(currentMaxNumWords == type(uint16).max);

        uint32 MAXIMUM_MINT_ATTEMPTS = currentMaxNumWords;

        // attempt to mint for $MINT with ETH
        vm.prank(minter);
        perpetualMint.attemptBatchMintForMintWithEth{
            value: MINT_FOR_MINT_PRICE * MAXIMUM_MINT_ATTEMPTS
        }(NO_REFERRER, MAXIMUM_MINT_ATTEMPTS);

        vm.expectRevert(
            abi.encodeWithSelector(
                IInsrtVRFCoordinatorInternal.NumWordsTooBig.selector,
                currentMaxNumWords + 1,
                currentMaxNumWords
            )
        );

        perpetualMint.attemptBatchMintForMintWithEth{
            value: MINT_FOR_MINT_PRICE * (MAXIMUM_MINT_ATTEMPTS + 1)
        }(NO_REFERRER, MAXIMUM_MINT_ATTEMPTS + 1);

        uint32 numberOfRandomWordsRequested = currentMaxNumWords; // 1 word per mint for $MINT attempt

        uint256 requestPreSeed = uint256(
            keccak256(
                abi.encode(
                    vrfConfig.keyHash,
                    address(perpetualMint),
                    vrfConfig.subscriptionId,
                    2
                )
            )
        );

        uint256 requestId = uint256(
            keccak256(abi.encode(vrfConfig.keyHash, requestPreSeed))
        );

        // calculate and store the mint fulfillment block number using vrf config min confirmations
        uint96 mintFulfillmentBlockNumber = mintBlockNumber +
            vrfConfig.minConfirmations;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        // mock the VRF Coordinator fulfill random words call
        vm.prank(msg.sender);
        uint96 payment = insrtVRFCoordinator.fulfillRandomWords(
            requestId,
            randomness,
            RequestCommitment(
                mintBlockNumber,
                vrfConfig.subscriptionId,
                vrfConfig.callbackGasLimit,
                numberOfRandomWordsRequested,
                address(perpetualMint)
            )
        );

        assert(payment == 0); // call succeeded and payment is 0
    }

    /// @dev Tests that fulfillRandomWords (when minting for a collection paid in $MINT) can currently handle the max limit of (type(uint16).max) attempted mints per tx.
    function testFuzz_fulfillRandomWordsMintForCollectionWithMintCanHandleMaximumUint16MintAttempts(
        uint256 randomness
    ) external {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        // store current block number to use as the mint block number
        uint64 mintBlockNumber = uint64(block.number);

        // grab the current max number of words
        uint32 currentMaxNumWords = IInsrtVRFCoordinator(
            this.perpetualMintHelper().VRF_COORDINATOR()
        ).MAX_NUM_WORDS();

        // check that the current max number of words is type(uint16).max
        assert(currentMaxNumWords == type(uint16).max);

        // account for integer division by subtracting by 1 on mints for collection
        --currentMaxNumWords;

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
                IInsrtVRFCoordinatorInternal.NumWordsTooBig.selector,
                // account for integer division
                currentMaxNumWords + 2,
                currentMaxNumWords + 1
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

        uint256 requestPreSeed = uint256(
            keccak256(
                abi.encode(
                    vrfConfig.keyHash,
                    address(perpetualMint),
                    vrfConfig.subscriptionId,
                    2
                )
            )
        );

        uint256 requestId = uint256(
            keccak256(abi.encode(vrfConfig.keyHash, requestPreSeed))
        );

        // calculate and store the mint fulfillment block number using vrf config min confirmations
        uint96 mintFulfillmentBlockNumber = mintBlockNumber +
            vrfConfig.minConfirmations;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        // mock the VRF Coordinator fulfill random words call
        vm.prank(msg.sender);
        uint96 payment = insrtVRFCoordinator.fulfillRandomWords(
            requestId,
            randomness,
            RequestCommitment(
                mintBlockNumber,
                vrfConfig.subscriptionId,
                vrfConfig.callbackGasLimit,
                numberOfRandomWordsRequested,
                address(perpetualMint)
            )
        );

        assert(payment == 0); // call succeeded and payment is 0
    }

    /// @dev Tests that fulfillRandomWords (when minting for $MINT paid in $MINT) can currently handle the max limit of (type(uint16).max) attempted mints per tx.
    function testFuzz_fulfillRandomWordsMintForMintWithMintCanHandleMaximum500MintAttempts(
        uint256 randomness
    ) external {
        uint256 currentEthToMintRatio = perpetualMint.ethToMintRatio();

        // store current block number to use as the mint block number
        uint64 mintBlockNumber = uint64(block.number);

        // grab the current max number of words
        uint32 currentMaxNumWords = IInsrtVRFCoordinator(
            this.perpetualMintHelper().VRF_COORDINATOR()
        ).MAX_NUM_WORDS();

        // check that the current max number of words is type(uint16).max
        assert(currentMaxNumWords == type(uint16).max);

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
                IInsrtVRFCoordinatorInternal.NumWordsTooBig.selector,
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

        uint256 requestPreSeed = uint256(
            keccak256(
                abi.encode(
                    vrfConfig.keyHash,
                    address(perpetualMint),
                    vrfConfig.subscriptionId,
                    2
                )
            )
        );

        uint256 requestId = uint256(
            keccak256(abi.encode(vrfConfig.keyHash, requestPreSeed))
        );

        // calculate and store the mint fulfillment block number using vrf config min confirmations
        uint96 mintFulfillmentBlockNumber = mintBlockNumber +
            vrfConfig.minConfirmations;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        // mock the VRF Coordinator fulfill random words call
        vm.prank(msg.sender);
        uint96 payment = insrtVRFCoordinator.fulfillRandomWords(
            requestId,
            randomness,
            RequestCommitment(
                mintBlockNumber,
                vrfConfig.subscriptionId,
                vrfConfig.callbackGasLimit,
                numberOfRandomWordsRequested,
                address(perpetualMint)
            )
        );

        assert(payment == 0); // call succeeded and payment is 0
    }
}
