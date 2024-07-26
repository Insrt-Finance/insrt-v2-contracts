// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "forge-std/Test.sol";

import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

import { PerpetualMintTest_InsrtVRFCoordinator } from "../PerpetualMint.t.sol";
import { ArbForkTest } from "../../ArbForkTest.t.sol";
import { CoreTest } from "../../diamonds/Core/Core.t.sol";
import { TokenProxyTest } from "../../diamonds/TokenProxy.t.sol";
import { TokenTest } from "../../facets/Token/Token.t.sol";
import { IPerpetualMintInternal } from "../../../contracts/facets/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage, VRFConfig } from "../../../contracts/facets/PerpetualMint/Storage.sol";
import { RequestCommitment } from "../../../contracts/vrf/Insrt/DataTypes.sol";
import { IInsrtVRFCoordinator } from "../../../contracts/vrf/Insrt/IInsrtVRFCoordinator.sol";
import { IInsrtVRFCoordinatorInternal } from "../../../contracts/vrf/Insrt/IInsrtVRFCoordinatorInternal.sol";

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

        uint32 numberOfRandomWordsRequested = 2; // 2 words per mint for collection attempt per request

        uint256 requestPreSeed;
        uint256 requestId;

        uint256[] memory requestIds = new uint256[](TEST_MINT_ATTEMPTS);

        for (uint256 i; i < TEST_MINT_ATTEMPTS; ++i) {
            requestPreSeed = uint256(
                keccak256(
                    abi.encode(
                        vrfConfig.keyHash,
                        address(perpetualMint),
                        vrfConfig.subscriptionId,
                        2 + i
                    )
                )
            );

            requestId = uint256(
                keccak256(abi.encode(vrfConfig.keyHash, requestPreSeed))
            );

            requestIds[i] = requestId;

            assert(
                perpetualMint.exposed_pendingRequestsAt(
                    MINT_FOR_COLLECTION_ADDRESS,
                    i
                ) == requestId
            );
        }

        // calculate and store the mint fulfillment block number using vrf config min confirmations
        uint64 mintFulfillmentBlockNumber = mintBlockNumber +
            vrfConfig.minConfirmations;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        // mock the VRF Coordinator fulfill random words call for all requests
        for (uint256 i; i < TEST_MINT_ATTEMPTS; ++i) {
            vm.prank(msg.sender);
            insrtVRFCoordinator.fulfillRandomWords(
                requestIds[i],
                randomness,
                RequestCommitment(
                    mintBlockNumber,
                    vrfConfig.subscriptionId,
                    vrfConfig.callbackGasLimit,
                    numberOfRandomWordsRequested,
                    address(perpetualMint)
                )
            );
        }

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

        uint32 numberOfRandomWordsRequested = 1; // 1 word per mint for $MINT attempt per request

        uint256 requestPreSeed;
        uint256 requestId;

        uint256[] memory requestIds = new uint256[](TEST_MINT_ATTEMPTS);

        for (uint256 i; i < TEST_MINT_ATTEMPTS; ++i) {
            requestPreSeed = uint256(
                keccak256(
                    abi.encode(
                        vrfConfig.keyHash,
                        address(perpetualMint),
                        vrfConfig.subscriptionId,
                        2 + i
                    )
                )
            );

            requestId = uint256(
                keccak256(abi.encode(vrfConfig.keyHash, requestPreSeed))
            );

            requestIds[i] = requestId;

            assert(
                perpetualMint.exposed_pendingRequestsAt(
                    MINT_FOR_MINT_ADDRESS,
                    i
                ) == requestId
            );
        }

        // calculate and store the mint fulfillment block number using vrf config min confirmations
        uint64 mintFulfillmentBlockNumber = mintBlockNumber +
            vrfConfig.minConfirmations;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        // mock the VRF Coordinator fulfill random words call for all requests
        for (uint256 i; i < TEST_MINT_ATTEMPTS; ++i) {
            vm.prank(msg.sender);
            insrtVRFCoordinator.fulfillRandomWords(
                requestIds[i],
                randomness,
                RequestCommitment(
                    mintBlockNumber,
                    vrfConfig.subscriptionId,
                    vrfConfig.callbackGasLimit,
                    numberOfRandomWordsRequested,
                    address(perpetualMint)
                )
            );
        }

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

        uint32 numberOfRandomWordsRequested = 2; // 2 words per mint for collection attempt per request

        uint256 requestPreSeed;
        uint256 requestId;

        uint256[] memory requestIds = new uint256[](TEST_MINT_ATTEMPTS);

        for (uint256 i; i < TEST_MINT_ATTEMPTS; ++i) {
            requestPreSeed = uint256(
                keccak256(
                    abi.encode(
                        vrfConfig.keyHash,
                        address(perpetualMint),
                        vrfConfig.subscriptionId,
                        2 + i
                    )
                )
            );

            requestId = uint256(
                keccak256(abi.encode(vrfConfig.keyHash, requestPreSeed))
            );

            requestIds[i] = requestId;

            assert(
                perpetualMint.exposed_pendingRequestsAt(
                    MINT_FOR_COLLECTION_ADDRESS,
                    i
                ) == requestId
            );
        }

        // calculate and store the mint fulfillment block number using vrf config min confirmations
        uint64 mintFulfillmentBlockNumber = mintBlockNumber +
            vrfConfig.minConfirmations;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        // mock the VRF Coordinator fulfill random words call for all requests
        for (uint256 i; i < TEST_MINT_ATTEMPTS; ++i) {
            vm.prank(msg.sender);
            insrtVRFCoordinator.fulfillRandomWords(
                requestIds[i],
                randomness,
                RequestCommitment(
                    mintBlockNumber,
                    vrfConfig.subscriptionId,
                    vrfConfig.callbackGasLimit,
                    numberOfRandomWordsRequested,
                    address(perpetualMint)
                )
            );
        }

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

        uint32 numberOfRandomWordsRequested = 1; // 1 word per mint for $MINT attempt per request

        uint256 requestPreSeed;
        uint256 requestId;

        uint256[] memory requestIds = new uint256[](TEST_MINT_ATTEMPTS);

        for (uint256 i; i < TEST_MINT_ATTEMPTS; ++i) {
            requestPreSeed = uint256(
                keccak256(
                    abi.encode(
                        vrfConfig.keyHash,
                        address(perpetualMint),
                        vrfConfig.subscriptionId,
                        2 + i
                    )
                )
            );

            requestId = uint256(
                keccak256(abi.encode(vrfConfig.keyHash, requestPreSeed))
            );

            requestIds[i] = requestId;

            assert(
                perpetualMint.exposed_pendingRequestsAt(
                    MINT_FOR_MINT_ADDRESS,
                    i
                ) == requestId
            );
        }

        // calculate and store the mint fulfillment block number using vrf config min confirmations
        uint64 mintFulfillmentBlockNumber = mintBlockNumber +
            vrfConfig.minConfirmations;

        // roll forward to the mint fulfillment block number
        vm.roll(mintFulfillmentBlockNumber);

        // mock the VRF Coordinator fulfill random words call for all requests
        for (uint256 i; i < TEST_MINT_ATTEMPTS; ++i) {
            vm.prank(msg.sender);
            insrtVRFCoordinator.fulfillRandomWords(
                requestIds[i],
                randomness,
                RequestCommitment(
                    mintBlockNumber,
                    vrfConfig.subscriptionId,
                    vrfConfig.callbackGasLimit,
                    numberOfRandomWordsRequested,
                    address(perpetualMint)
                )
            );
        }

        // we expect the next call to fail to assert the mock mint request has been fulfilled
        vm.expectRevert(EnumerableSet.EnumerableSet__IndexOutOfBounds.selector);

        perpetualMint.exposed_pendingRequestsAt(MINT_FOR_MINT_ADDRESS, 0);
    }
}
