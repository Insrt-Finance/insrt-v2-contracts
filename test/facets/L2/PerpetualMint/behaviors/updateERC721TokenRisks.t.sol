// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { IGuardsInternal } from "../../../../../contracts/facets/L2/common/IGuardsInternal.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";

/// @title PerpetualMint_updateERC721TokenRisks
/// @dev PerpetualMint test contract for testing expected behavior of the updateERC721TokenRisks function
contract PerpetualMint_updateERC721TokenRisks is
    IPerpetualMintInternal,
    PerpetualMintTest,
    L2ForkTest
{
    uint256 internal constant COLLECTION_EARNINGS = 1 ether;
    uint256 internal constant FAILING_RISK = 10000000000000;
    uint256 internal constant NEW_RISK = 10000;
    address internal constant NON_OWNER = address(4);
    uint256 internal BAYC_ID;
    uint256[] tokenIds;
    uint256[] risks;

    address internal constant COLLECTION = BORED_APE_YACHT_CLUB;

    // grab BAYC collection earnings storage slot
    bytes32 internal collectionEarningsStorageSlot =
        keccak256(
            abi.encode(
                COLLECTION, // the ERC721 collection
                uint256(Storage.STORAGE_SLOT) + 9 // the collectionEarnings storage slot
            )
        );

    function setUp() public override {
        super.setUp();

        BAYC_ID = BORED_APE_YACHT_CLUB_TOKEN_ID_ONE;

        depositBoredApeYachtClubAssetsMock();

        //overwrite storage
        vm.store(
            address(perpetualMint),
            collectionEarningsStorageSlot,
            bytes32(COLLECTION_EARNINGS)
        );

        tokenIds.push(BAYC_ID);
        risks.push(NEW_RISK);
    }

    /// @dev tests that upon updating ERC721 token risks, the depositor deductions are set to be equal to the
    /// collection earnings of the collection of the updated token
    function test_updateERC721TokenRisksUpdatesDepositorEarningsOfDepositorWhenTotalDepositorRiskIsZero()
        public
    {
        // grab totalDepositorsRisk storage slot
        bytes32 totalDepositorRiskStorageSlot = keccak256(
            abi.encode(
                COLLECTION, // the ERC721 collection
                keccak256(
                    abi.encode(
                        depositorOne, // address of depositor
                        uint256(Storage.STORAGE_SLOT) + 21 // totalDepositorRisk mapping storage slot
                    )
                )
            )
        );

        vm.store(address(perpetualMint), totalDepositorRiskStorageSlot, 0);

        uint256 currentEarnings = _collectionEarnings(
            address(perpetualMint),
            COLLECTION
        );
        uint256 lastEarnings = _lastCollectionEarnings(
            address(perpetualMint),
            COLLECTION
        );
        uint256 baseMultiplier = (currentEarnings - lastEarnings) /
            _totalRisk(address(perpetualMint), COLLECTION);

        vm.prank(depositorOne);
        perpetualMint.updateERC721TokenRisks(COLLECTION, tokenIds, risks);

        assert(
            baseMultiplier ==
                _baseMultiplier(address(perpetualMint), COLLECTION)
        );

        assert(
            currentEarnings ==
                _lastCollectionEarnings(address(perpetualMint), COLLECTION)
        );
    }

    /// @dev tests that upon updating ERC721 token risks, the depositor earnings are updated, the depositor
    /// multiplier function is set, and the last collection earnings value is set to the most recent collection
    /// earnings value
    function test_updateERC721TokenRisksUpdatesDepositorEarningsWhenTotalDepositorRiskIsNonZero()
        public
    {
        uint256 currentEarnings = _collectionEarnings(
            address(perpetualMint),
            COLLECTION
        );
        uint256 lastEarnings = _lastCollectionEarnings(
            address(perpetualMint),
            COLLECTION
        );
        uint256 baseMultiplier = (currentEarnings - lastEarnings) /
            _totalRisk(address(perpetualMint), COLLECTION);

        uint256 oldDepositorEarnings = _depositorEarnings(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );
        uint256 totalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );
        uint256 multiplierOffset = _multiplierOffset(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        uint256 expectedEarnings = (baseMultiplier - multiplierOffset) *
            totalDepositorRisk;

        assert(totalDepositorRisk != 0);
        assert(_totalRisk(address(perpetualMint), COLLECTION) != 0);

        vm.prank(depositorOne);
        perpetualMint.updateERC721TokenRisks(COLLECTION, tokenIds, risks);

        assert(
            expectedEarnings + oldDepositorEarnings ==
                _depositorEarnings(
                    address(perpetualMint),
                    depositorOne,
                    COLLECTION
                )
        );
    }

    /// @dev tests that the depositor token risk of an ERC721 collection is updated to the new token risk
    /// when updateERC721TokenRisks is called, for each tokenId in tokenIds
    function test_updateERC721TokenRisksSetsTheDepositorTokenRiskToNewRisk()
        public
    {
        vm.prank(depositorOne);
        perpetualMint.updateERC721TokenRisks(COLLECTION, tokenIds, risks);

        for (uint256 i; i < tokenIds.length; ++i) {
            assert(
                risks[i] ==
                    _tokenRisk(address(perpetualMint), COLLECTION, tokenIds[i])
            );
        }
    }

    /// @dev tests that the token risk of an ERC721 collection is updated to the new token risk
    /// when updateERC721TokenRisks is called, for each tokenId in tokenIds
    function test_updateERC721TokenRisksSetsTheTokenRiskToNewRisk() public {
        vm.prank(depositorOne);
        perpetualMint.updateERC721TokenRisks(COLLECTION, tokenIds, risks);

        for (uint256 i; i < tokenIds.length; ++i) {
            assert(
                risks[i] ==
                    _tokenRisk(address(perpetualMint), COLLECTION, tokenIds[i])
            );
        }
    }

    /// @dev tests that total risk of an ERC721 collection is increased or decreased depending on whether new risk
    /// set for the token is larger or smaller than previous risk, for each tokenId in tokenIds when updating ERC721 token risks
    function test_updateERC721TokenRisksChangesTotalRiskByTotalRiskChange()
        public
    {
        uint256 totalOldTokenRisks;
        uint256 totalNewRisks;

        for (uint256 i; i < tokenIds.length; ++i) {
            totalOldTokenRisks += _tokenRisk(
                address(perpetualMint),
                COLLECTION,
                tokenIds[i]
            );
            totalNewRisks += risks[i];
        }

        uint256 oldTotalRisk = _totalRisk(address(perpetualMint), COLLECTION);

        vm.prank(depositorOne);
        perpetualMint.updateERC721TokenRisks(COLLECTION, tokenIds, risks);

        uint256 firstTotalRisk = _totalRisk(address(perpetualMint), COLLECTION);

        assert(
            firstTotalRisk - oldTotalRisk == totalNewRisks - totalOldTokenRisks
        );

        uint256 secondTokenRisk = 10;

        risks[0] = secondTokenRisk;

        totalOldTokenRisks = 0;
        totalNewRisks = 0;

        for (uint256 i; i < tokenIds.length; ++i) {
            totalOldTokenRisks += _tokenRisk(
                address(perpetualMint),
                COLLECTION,
                tokenIds[i]
            );
            totalNewRisks += risks[i];
        }

        vm.prank(depositorOne);
        perpetualMint.updateERC721TokenRisks(COLLECTION, tokenIds, risks);

        uint256 secondTotalRisk = _totalRisk(
            address(perpetualMint),
            COLLECTION
        );

        assert(secondTotalRisk < firstTotalRisk);
        assert(
            firstTotalRisk - secondTotalRisk ==
                totalOldTokenRisks - totalNewRisks
        );
    }

    /// @dev tests that total depositor  risk of an ERC721 collection is increased or decreased depending on whether new risk
    /// set for the token is larger or smaller than previous risk
    function test_updateERC721TokenRisksChangesTotalDepositorRiskByTotalRiskChange()
        public
    {
        uint256 totalOldTokenRisks;
        uint256 totalNewRisks;

        for (uint256 i; i < tokenIds.length; ++i) {
            totalOldTokenRisks += _tokenRisk(
                address(perpetualMint),
                COLLECTION,
                tokenIds[i]
            );
            totalNewRisks += risks[i];
        }

        uint256 oldDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        vm.prank(depositorOne);
        perpetualMint.updateERC721TokenRisks(COLLECTION, tokenIds, risks);

        uint256 firstDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        assert(
            firstDepositorRisk - oldDepositorRisk ==
                totalNewRisks - totalOldTokenRisks
        );

        uint256 secondTokenRisk = 10;

        risks[0] = secondTokenRisk;

        totalOldTokenRisks = 0;
        totalNewRisks = 0;

        for (uint256 i; i < tokenIds.length; ++i) {
            totalOldTokenRisks += _tokenRisk(
                address(perpetualMint),
                COLLECTION,
                tokenIds[i]
            );
            totalNewRisks += risks[i];
        }

        vm.prank(depositorOne);
        perpetualMint.updateERC721TokenRisks(COLLECTION, tokenIds, risks);

        uint256 secondDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        assert(secondDepositorRisk < firstDepositorRisk);
        assert(
            firstDepositorRisk - secondDepositorRisk ==
                totalOldTokenRisks - totalNewRisks
        );
    }

    /// @dev test that updateERC721TokenRisks reverts if the collection is an ERC1155 collection
    function test_updateERC721TokenRisksRevertsWhen_CollectionIsERC1155()
        public
    {
        vm.expectRevert(IPerpetualMintInternal.CollectionTypeMismatch.selector);
        vm.prank(depositorOne);
        perpetualMint.updateERC721TokenRisks(PARALLEL_ALPHA, tokenIds, risks);
    }

    /// @dev test that updateERC721TokenRisks reverts if the risk array and tokenIds array differ in length
    function test_updateERC721TokenRisksRevertsWhen_TokenIdsAndRisksArrayLengthsMismatch()
        public
    {
        risks.push(NEW_RISK);
        vm.expectRevert(IPerpetualMintInternal.ArrayLengthMismatch.selector);
        vm.prank(depositorOne);
        perpetualMint.updateERC721TokenRisks(COLLECTION, tokenIds, risks);
    }

    /// @dev test that updateERC721TokenRisks reverts if the risk to be set is larger than the BASIS
    function test_updateERC721TokenRisksRevertsWhen_RiskExceedsBasis() public {
        risks[0] = FAILING_RISK;
        vm.expectRevert(IPerpetualMintInternal.BasisExceeded.selector);
        vm.prank(depositorOne);
        perpetualMint.updateERC721TokenRisks(COLLECTION, tokenIds, risks);
    }

    /// @dev test that updateERC721TokenRisks reverts if the risk to be set is 0
    function test_updateERC721TokenRisksRevertsWhen_RiskIsSetToZero() public {
        risks[0] = 0;
        vm.expectRevert(IPerpetualMintInternal.TokenRiskMustBeNonZero.selector);
        vm.prank(depositorOne);
        perpetualMint.updateERC721TokenRisks(COLLECTION, tokenIds, risks);
    }

    /// @dev test that updateERC721TokenRisks reverts if the caller is not the escrowedERC721Owner if the collection selected
    /// is an ERC721 collection
    function test_updateERC721TokenRisksRevertsWhen_CallerIsNotEscrowedERC721Owner()
        public
    {
        vm.expectRevert(IPerpetualMintInternal.OnlyEscrowedTokenOwner.selector);
        vm.prank(NON_OWNER);
        perpetualMint.updateERC721TokenRisks(COLLECTION, tokenIds, risks);
    }

    /// @dev tests that if there are pending mint requests updating ERC721 token risks reverts
    function test_updateERC721TokenRisksRevertsWhen_ThereIsAtLeastOnePendingRequest()
        public
    {
        uint256 mockMintRequestId = 5;

        // calculate pendingRequests enumerable set slot
        bytes32 pendingRequestsSlot = keccak256(
            abi.encode(
                COLLECTION, // address of collection
                uint256(Storage.STORAGE_SLOT) + 28 // requestIds mapping storage slot
            )
        );

        // store EnumerableSet.UintSet._inner._values length
        vm.store(
            address(perpetualMint),
            pendingRequestsSlot,
            bytes32(uint256(1))
        );

        // calculate the PerpetualMint pending request id slot
        bytes32 pendingRequestIdValueSlot = keccak256(
            abi.encodePacked(pendingRequestsSlot)
        );

        // store the mockMintRequestId in the pendingRequests enumerable set
        vm.store(
            address(perpetualMint),
            pendingRequestIdValueSlot,
            bytes32(mockMintRequestId)
        );

        // calcaulte the PerpetualMint pending request id index slot
        bytes32 pendingRequestIdIndexSlot = keccak256(
            abi.encode(
                bytes32(mockMintRequestId),
                uint256(pendingRequestsSlot) + 1
            )
        );

        // store 1 as the index of mockMintRequestId
        vm.store(
            address(perpetualMint),
            pendingRequestIdIndexSlot,
            bytes32(uint256(1))
        );

        vm.expectRevert(IGuardsInternal.PendingRequests.selector);

        vm.prank(depositorOne);
        perpetualMint.updateERC721TokenRisks(COLLECTION, tokenIds, risks);
    }
}
