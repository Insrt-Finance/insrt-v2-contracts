// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnable } from "@solidstate/contracts/access/ownable/IOwnable.sol";

import { PerpetualMintTestBase } from "../PerpetualMint.t.sol";
import { BaseForkTest } from "../../../../BaseForkTest.t.sol";
import { IDepositContract } from "../../../../interfaces/IDepositContract.sol";
import { ISupraGeneratorContract } from "../../../../interfaces/ISupraGeneratorContract.sol";
import { ISupraGeneratorContractEvents } from "../../../../interfaces/ISupraGeneratorContractEvents.sol";
import { ISupraRouterContract } from "../../../../../contracts/facets/PerpetualMint/Base/ISupraRouterContract.sol";

/// @title PerpetualMint_requestRandomWordsBase
/// @dev PerpetualMint test contract for testing expected behavior of the _requestRandomWordsBase function
contract PerpetualMint_requestRandomWordsBase is
    BaseForkTest,
    ISupraGeneratorContractEvents,
    PerpetualMintTestBase
{
    IDepositContract private supraVRFDepositContract;

    ISupraRouterContract private supraRouterContract;

    /// @dev test number of random words to request, current ratio of random words to mint attempts is 2:1
    uint8 internal constant TEST_NUM_WORDS = 2;

    /// @dev collection to test
    address COLLECTION = BORED_APE_YACHT_CLUB;

    address supraVRFDepositContractOwner;

    /// @dev Sets up the test case environment.
    function setUp() public override {
        super.setUp();

        supraRouterContract = ISupraRouterContract(
            this.perpetualMintHelper().VRF_ROUTER()
        );

        supraVRFDepositContract = IDepositContract(
            supraRouterContract._depositContract()
        );

        supraVRFDepositContractOwner = IOwnable(
            address(supraVRFDepositContract)
        ).owner();

        _activateVRF();
    }

    /// @dev Tests that _requestRandomWordsBase functionality emits a RequestGenerated event when successfully requesting random words.
    function test_requestRandomWordsBaseEmitsRequestGenerated() external {
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

        perpetualMint.exposed_requestRandomWordsBase(
            minter,
            COLLECTION,
            TEST_NUM_WORDS
        );
    }

    /// @dev Tests that _requestRandomWordsBase functionality updates pendingRequests appropriately.
    function test_requestRandomWordsBaseUpdatesPendingRequests() external {
        // assert that this will be the first request added to pendingRequests
        assert(perpetualMint.exposed_pendingRequestsLength(COLLECTION) == 0);

        perpetualMint.exposed_requestRandomWordsBase(
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

    /// @dev Tests that _requestRandomWordsBase functionality reverts when more than the current max number of words (255) is requested.
    function test_requestRandomWordsBaseRevertsWhen_MoreThanMaxNumberOfWordsRequested()
        external
    {
        // specify the current max number of words
        uint8 currentMaxNumWords = type(uint8).max;

        vm.expectRevert();

        perpetualMint.exposed_requestRandomWordsBase(
            minter,
            COLLECTION,
            ++currentMaxNumWords
        );
    }

    /// @dev Tests that _requestRandomWordsBase functionality reverts when the configured VRF client has been removed from the Supra VRF Deposit Contract whitelist
    function test_requestRandomWordsBaseRevertsWhen_ClientAddressRemovedFromWhitelist()
        external
    {
        vm.prank(supraVRFDepositContractOwner);
        supraVRFDepositContract.removeClientFromWhitelist(address(this));

        vm.expectRevert("Client address not whitelisted");

        perpetualMint.exposed_requestRandomWordsBase(
            minter,
            COLLECTION,
            TEST_NUM_WORDS
        );
    }

    /// @dev Tests that _requestRandomWordsBase functionality reverts when the configured VRF contract has been removed from the Supra VRF Deposit Contract whitelist
    function test_requestRandomWordsBaseRevertsWhen_ContractAddressRemovedFromWhitelist()
        external
    {
        supraVRFDepositContract.removeContractFromWhitelist(
            address(perpetualMint)
        );

        vm.expectRevert("Contract not eligible to request");

        perpetualMint.exposed_requestRandomWordsBase(
            minter,
            COLLECTION,
            TEST_NUM_WORDS
        );
    }

    /// @dev Tests that _requestRandomWordsBase functionality reverts when the minimum subscription balance has been reached
    function test_requestRandomWordsBaseRevertsWhen_MinimumSubscriptionBalanceReached()
        external
    {
        supraVRFDepositContract.withdrawFundClient(10 ether);

        vm.expectRevert(
            "Insufficient Funds: Minimum balance reached for request"
        );

        perpetualMint.exposed_requestRandomWordsBase(
            minter,
            COLLECTION,
            TEST_NUM_WORDS
        );
    }

    function _activateVRF() private {
        vm.prank(supraVRFDepositContractOwner);
        supraVRFDepositContract.addClientToWhitelist(address(this), true);

        supraVRFDepositContract.addContractToWhitelist(address(perpetualMint));

        supraVRFDepositContract.depositFundClient{ value: 10 ether }();
    }
}
