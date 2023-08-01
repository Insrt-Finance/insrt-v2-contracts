// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";

/// @title PerpetualMint_updateERC721TokenRisks
/// @dev PerpetualMint test contract for testing expected behavior of the updateERC721TokenRisks function
contract PerpetualMint_updateERC721TokenRisks is
    IPerpetualMintInternal,
    PerpetualMintTest,
    L2ForkTest
{
    uint256 internal constant COLLECTION_EARNINGS = 1 ether;
    uint64 internal constant FAILING_RISK = 10000000000000;
    uint64 internal constant NEW_RISK = 10000;
    address internal constant NON_OWNER = address(4);
    uint256 internal BAYC_ID;
    uint256[] tokenIds;
    uint64[] risks;

    // grab BAYC collection earnings storage slot
    bytes32 internal collectionEarningsStorageSlot =
        keccak256(
            abi.encode(
                BORED_APE_YACHT_CLUB, // the ERC721 collection
                uint256(Storage.STORAGE_SLOT) + 7 // the risk storage slot
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
    function test_updateERC721TokenRisksUpdatesDepositorEarningsOfCallerWhenTotalDepositorRiskOfCallerIsZero()
        public
    {
        // grab totalDepositorsRisk storage slot
        bytes32 totalDepositorRiskStorageSlot = keccak256(
            abi.encode(
                BORED_APE_YACHT_CLUB, // the ERC721 collection
                keccak256(
                    abi.encode(
                        depositorOne, // address of depositor
                        uint256(Storage.STORAGE_SLOT) + 20 // totalDepositorRisk mapping storage slot
                    )
                )
            )
        );

        vm.store(address(perpetualMint), totalDepositorRiskStorageSlot, 0);

        vm.prank(depositorOne);
        perpetualMint.updateERC721TokenRisks(
            BORED_APE_YACHT_CLUB,
            tokenIds,
            risks
        );

        assert(
            _depositorDeductions(
                address(perpetualMint),
                depositorOne,
                BORED_APE_YACHT_CLUB
            ) ==
                _collectionEarnings(
                    address(perpetualMint),
                    BORED_APE_YACHT_CLUB
                )
        );
    }

    /// @dev tests that upon updating ERC721 token risks, the depositor earnings are updated and the depositor
    /// deductions set equal to the depositor earnings
    function test_updateERC721TokenRisksUpdatesDepositorEarningsWhenTotalDepositorRiskIsNonZero()
        public
    {
        uint64 totalRisk = _totalRisk(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );
        uint64 totalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );
        uint256 collectionEarnings = _collectionEarnings(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );
        uint256 oldDepositorDeductions = _depositorDeductions(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        assert(totalDepositorRisk != 0);
        assert(totalRisk != 0);

        vm.prank(depositorOne);
        perpetualMint.updateERC721TokenRisks(
            BORED_APE_YACHT_CLUB,
            tokenIds,
            risks
        );

        uint256 newDepositorDeductions = _depositorDeductions(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        uint256 expectedEarnings = (collectionEarnings * totalDepositorRisk) /
            totalRisk -
            oldDepositorDeductions;

        assert(
            expectedEarnings ==
                _depositorEarnings(
                    address(perpetualMint),
                    depositorOne,
                    BORED_APE_YACHT_CLUB
                )
        );

        assert(newDepositorDeductions == expectedEarnings);
    }

    /// @dev tests that the token risk of an ERC721 collection is updated to the new token risk
    /// when updateERC721TokenRisks is called, for each tokenId in tokenIds
    function test_updateERC721TokenRisksSetsTheTokenRiskToNewRisk() public {
        vm.prank(depositorOne);
        perpetualMint.updateERC721TokenRisks(
            BORED_APE_YACHT_CLUB,
            tokenIds,
            risks
        );

        for (uint256 i; i < tokenIds.length; ++i) {
            assert(
                risks[i] ==
                    _tokenRisk(
                        address(perpetualMint),
                        BORED_APE_YACHT_CLUB,
                        tokenIds[i]
                    )
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
                BORED_APE_YACHT_CLUB,
                tokenIds[i]
            );
            totalNewRisks += risks[i];
        }

        uint64 oldTotalRisk = _totalRisk(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        vm.prank(depositorOne);
        perpetualMint.updateERC721TokenRisks(
            BORED_APE_YACHT_CLUB,
            tokenIds,
            risks
        );

        uint64 firstTotalRisk = _totalRisk(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        assert(
            firstTotalRisk - oldTotalRisk == totalNewRisks - totalOldTokenRisks
        );

        uint64 secondTokenRisk = 10;

        risks[0] = secondTokenRisk;

        totalOldTokenRisks = 0;
        totalNewRisks = 0;

        for (uint256 i; i < tokenIds.length; ++i) {
            totalOldTokenRisks += _tokenRisk(
                address(perpetualMint),
                BORED_APE_YACHT_CLUB,
                tokenIds[i]
            );
            totalNewRisks += risks[i];
        }

        vm.prank(depositorOne);
        perpetualMint.updateERC721TokenRisks(
            BORED_APE_YACHT_CLUB,
            tokenIds,
            risks
        );

        uint64 secondTotalRisk = _totalRisk(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
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
                BORED_APE_YACHT_CLUB,
                tokenIds[i]
            );
            totalNewRisks += risks[i];
        }

        uint64 oldDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        vm.prank(depositorOne);
        perpetualMint.updateERC721TokenRisks(
            BORED_APE_YACHT_CLUB,
            tokenIds,
            risks
        );

        uint64 firstDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        assert(
            firstDepositorRisk - oldDepositorRisk ==
                totalNewRisks - totalOldTokenRisks
        );

        uint64 secondTokenRisk = 10;

        risks[0] = secondTokenRisk;

        totalOldTokenRisks = 0;
        totalNewRisks = 0;

        for (uint256 i; i < tokenIds.length; ++i) {
            totalOldTokenRisks += _tokenRisk(
                address(perpetualMint),
                BORED_APE_YACHT_CLUB,
                tokenIds[i]
            );
            totalNewRisks += risks[i];
        }

        vm.prank(depositorOne);
        perpetualMint.updateERC721TokenRisks(
            BORED_APE_YACHT_CLUB,
            tokenIds,
            risks
        );

        uint64 secondDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
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
        perpetualMint.updateERC721TokenRisks(
            BORED_APE_YACHT_CLUB,
            tokenIds,
            risks
        );
    }

    /// @dev test that updateERC721TokenRisks reverts if the risk to be set is larger than the BASIS
    function test_updateERC721TokenRisksRevertsWhen_RiskExceedsBasis() public {
        risks[0] = FAILING_RISK;
        vm.expectRevert(IPerpetualMintInternal.BasisExceeded.selector);
        vm.prank(depositorOne);
        perpetualMint.updateERC721TokenRisks(
            BORED_APE_YACHT_CLUB,
            tokenIds,
            risks
        );
    }

    /// @dev test that updateERC721TokenRisks reverts if the risk to be set is 0
    function test_updateERC721TokenRisksRevertsWhen_RiskIsSetToZero() public {
        risks[0] = 0;
        vm.expectRevert(IPerpetualMintInternal.TokenRiskMustBeNonZero.selector);
        vm.prank(depositorOne);
        perpetualMint.updateERC721TokenRisks(
            BORED_APE_YACHT_CLUB,
            tokenIds,
            risks
        );
    }

    /// @dev test that updateERC721TokenRisks reverts if the caller is not the escrowedERC721Owner if the collection selected
    /// is an ERC721 collection
    function test_updateERC721TokenRisksRevertsWhen_CallerIsNotEscrowedERC721Owner()
        public
    {
        vm.expectRevert(IPerpetualMintInternal.OnlyEscrowedTokenOwner.selector);
        vm.prank(NON_OWNER);
        perpetualMint.updateERC721TokenRisks(
            BORED_APE_YACHT_CLUB,
            tokenIds,
            risks
        );
    }
}
