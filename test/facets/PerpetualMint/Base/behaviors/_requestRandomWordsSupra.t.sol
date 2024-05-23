// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { PerpetualMintTest_Base } from "../PerpetualMint.t.sol";
import { BaseForkTest } from "../../../../BaseForkTest.t.sol";
import { ISupraGeneratorContract } from "../../../../interfaces/ISupraGeneratorContract.sol";
import { ISupraGeneratorContractEvents } from "../../../../interfaces/ISupraGeneratorContractEvents.sol";

/// @title PerpetualMint_requestRandomWordsSupra
/// @dev PerpetualMint_Base test contract for testing expected behavior of the _requestRandomWordsSupra function
contract PerpetualMint_requestRandomWordsSupra is
    BaseForkTest,
    ISupraGeneratorContractEvents,
    PerpetualMintTest_Base
{
    /// @dev test number of random words to request, current ratio of random words to mint attempts is 2:1
    uint8 internal constant TEST_NUM_WORDS = 2;

    /// @dev collection to test
    address COLLECTION = BORED_APE_YACHT_CLUB;

    /// @dev Tests that _requestRandomWordsSupra functionality emits a RequestGenerated event when successfully requesting random words.
    function test_requestRandomWordsSupraEmitsRequestGenerated() external {
        // Supra VRF Router nonce storage slot
        bytes32 nonceStorageSlot = bytes32(uint256(3));

        uint256 currentNonce = uint256(
            vm.load(address(supraRouterContract), nonceStorageSlot)
        );

        vm.expectEmit();
        emit RequestGenerated(
            ++currentNonce,
            ISupraGeneratorContract(
                supraRouterContract._supraGeneratorContract()
            ).instanceId(), // instanceId of Supra Generator
            address(perpetualMint), // caller contract
            VRF_REQUEST_FUNCTION_SIGNATURE,
            TEST_NUM_WORDS,
            TEST_VRF_NUMBER_OF_CONFIRMATIONS,
            0, // no client seed used in Supra VRF requests
            address(this) // client wallet address
        );

        perpetualMint.exposed_requestRandomWordsSupra(
            minter,
            COLLECTION,
            TEST_MINT_EARNINGS_FEE_PER_SPIN,
            TEST_ADJUSTMENT_FACTOR,
            TEST_MINT_FOR_COLLECTION_PRIZE_VALUE,
            TEST_NUM_WORDS,
            TEST_RISK_REWARD_RATIO
        );
    }

    /// @dev Tests that _requestRandomWordsSupra functionality updates pendingRequests appropriately.
    function test_requestRandomWordsSupraUpdatesPendingRequests() external {
        // assert that this will be the first request added to pendingRequests
        assert(perpetualMint.exposed_pendingRequestsLength(COLLECTION) == 0);

        perpetualMint.exposed_requestRandomWordsSupra(
            minter,
            COLLECTION,
            TEST_MINT_EARNINGS_FEE_PER_SPIN,
            TEST_ADJUSTMENT_FACTOR,
            TEST_MINT_FOR_COLLECTION_PRIZE_VALUE,
            TEST_NUM_WORDS,
            TEST_RISK_REWARD_RATIO
        );

        // this call succeeds only if the request was added to pendingRequests
        uint256 requestId = perpetualMint.exposed_pendingRequestsAt(
            COLLECTION,
            0
        );

        (
            address requestMinter,
            address requestCollection,
            ,
            uint256 mintPriceAdjustmentFactor,

        ) = perpetualMint.exposed_requests(requestId);

        assert(requestCollection == COLLECTION);

        assert(requestMinter == minter);

        assert(mintPriceAdjustmentFactor == TEST_ADJUSTMENT_FACTOR);
    }

    /// @dev Tests that _requestRandomWordsSupra functionality reverts when more than the current max number of words (255) is requested.
    function test_requestRandomWordsSupraRevertsWhen_MoreThanMaxNumberOfWordsRequested()
        external
    {
        // specify the current max number of words
        uint8 currentMaxNumWords = type(uint8).max;

        vm.expectRevert();

        perpetualMint.exposed_requestRandomWordsSupra(
            minter,
            COLLECTION,
            TEST_MINT_EARNINGS_FEE_PER_SPIN,
            TEST_ADJUSTMENT_FACTOR,
            TEST_MINT_FOR_COLLECTION_PRIZE_VALUE,
            ++currentMaxNumWords,
            TEST_RISK_REWARD_RATIO
        );
    }

    /// @dev Tests that _requestRandomWordsSupra functionality reverts when the configured VRF client has been removed from the Supra VRF Deposit Contract whitelist
    function test_requestRandomWordsSupraRevertsWhen_ClientAddressRemovedFromWhitelist()
        external
    {
        vm.prank(supraVRFDepositContractOwner);
        supraVRFDepositContract.removeClientFromWhitelist(address(this));

        vm.expectRevert("Client address not whitelisted");

        perpetualMint.exposed_requestRandomWordsSupra(
            minter,
            COLLECTION,
            TEST_MINT_EARNINGS_FEE_PER_SPIN,
            TEST_ADJUSTMENT_FACTOR,
            TEST_MINT_FOR_COLLECTION_PRIZE_VALUE,
            TEST_NUM_WORDS,
            TEST_RISK_REWARD_RATIO
        );
    }

    /// @dev Tests that _requestRandomWordsSupra functionality reverts when the configured VRF contract has been removed from the Supra VRF Deposit Contract whitelist
    function test_requestRandomWordsSupraRevertsWhen_ContractAddressRemovedFromWhitelist()
        external
    {
        supraVRFDepositContract.removeContractFromWhitelist(
            address(perpetualMint)
        );

        vm.expectRevert("Contract not eligible to request");

        perpetualMint.exposed_requestRandomWordsSupra(
            minter,
            COLLECTION,
            TEST_MINT_EARNINGS_FEE_PER_SPIN,
            TEST_ADJUSTMENT_FACTOR,
            TEST_MINT_FOR_COLLECTION_PRIZE_VALUE,
            TEST_NUM_WORDS,
            TEST_RISK_REWARD_RATIO
        );
    }

    /// @dev Tests that _requestRandomWordsSupra functionality reverts when the minimum subscription balance has been reached
    function test_requestRandomWordsSupraRevertsWhen_MinimumSubscriptionBalanceReached()
        external
    {
        supraVRFDepositContract.withdrawFundClient(10 ether);

        vm.expectRevert(
            "Insufficient Funds: Minimum balance reached for request"
        );

        perpetualMint.exposed_requestRandomWordsSupra(
            minter,
            COLLECTION,
            TEST_MINT_EARNINGS_FEE_PER_SPIN,
            TEST_ADJUSTMENT_FACTOR,
            TEST_MINT_FOR_COLLECTION_PRIZE_VALUE,
            TEST_NUM_WORDS,
            TEST_RISK_REWARD_RATIO
        );
    }
}
