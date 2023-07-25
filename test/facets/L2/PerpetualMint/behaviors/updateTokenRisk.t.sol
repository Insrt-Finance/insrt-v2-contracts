// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";
import { L1ForkTest } from "../../../../L1ForkTest.t.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";

/// @title PerpetualMint_updateTokenRisk
/// @dev PerpetualMint test contract for testing expected behavior of the updateTokenRisk function
contract PerpetualMint_updateTokenRisk is
    IPerpetualMintInternal,
    PerpetualMintTest,
    L1ForkTest
{
    uint256 internal constant COLLECTION_EARNINGS = 1 ether;
    uint64 internal constant FAILING_RISK = 10000000000000;
    uint64 internal constant NEW_RISK = 10000;
    address internal constant NON_OWNER = address(4);
    uint256 internal PARALLEL_ALPHA_ID;
    uint256 internal BAYC_ID;

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

        PARALLEL_ALPHA_ID = parallelAlphaTokenIds[0];
        BAYC_ID = boredApeYachtClubTokenIds[0];

        depositBoredApeYachtClubAssetsMock();
        depositParallelAlphaAssetsMock();

        //overwrite storage
        vm.store(
            address(perpetualMint),
            collectionEarningsStorageSlot,
            bytes32(COLLECTION_EARNINGS)
        );
    }

    /// @dev tests that upon updating token risk, the depositor deductions are set to be equal to the
    /// collection earnings of the collection of the updated token
    function test_updateTokenRiskUpdatesDepositorEarningsOfCallerWhenTotalDepositorRiskOfCallerIsZero()
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
        perpetualMint.updateTokenRisk(BORED_APE_YACHT_CLUB, BAYC_ID, NEW_RISK);

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

    /// @dev tests that upon updating token risk, the depositor earnings are udpated and the depositor
    /// deductions set equal to the depositor earnings
    function test_updateTokenRiskUpdatesDepositorEarningsWhenTotalDepositorRiskIsNonZero()
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
        perpetualMint.updateTokenRisk(BORED_APE_YACHT_CLUB, BAYC_ID, NEW_RISK);

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

    /// @dev tests that upon updating token risk to be zero the total risk of the ERC721 collection decreases by previous
    /// token risk
    function test_updateTokenRiskReducesTotalRiskByPreviousRiskWhenRiskSetIsZeroWhenCollectionIsERC721()
        public
    {
        uint64 oldTotalRisk = _totalRisk(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        uint64 oldTokenRisk = _tokenRisk(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB,
            BAYC_ID
        );

        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(BORED_APE_YACHT_CLUB, BAYC_ID, 0);

        uint64 newTotalRisk = _totalRisk(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        assert(oldTotalRisk - newTotalRisk == oldTokenRisk);
    }

    /// @dev tests that upon updating token risk to be zero the token if is removed from the active token ids of
    /// of the ERC721 collection
    function test_updateTokenRiskRemovesTokenIdFromERC721CollectionActivetokenIdsWhenRiskIsSetToZero()
        public
    {
        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(BORED_APE_YACHT_CLUB, BAYC_ID, 0);

        uint256[] memory activeTokenIds = _activeTokenIds(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        for (uint256 i; i < activeTokenIds.length; ++i) {
            assert(activeTokenIds[i] != BAYC_ID);
        }
    }

    /// @dev tests that upon updating token risk to zero the total active tokens of an ERC721 collection are decremented
    function test_updateTokenRiskDecremetsTotalActiveTokensOfERC721CollectionWhenRiskIsSetToZero()
        public
    {
        uint256 oldActiveTokens = _totalActiveTokens(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(BORED_APE_YACHT_CLUB, BAYC_ID, 0);

        uint256 newActiveTokens = _totalActiveTokens(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        assert(oldActiveTokens - newActiveTokens == 1);
    }

    /// @dev tests that upon updating token risk to zero the active tokens of a depositor of the ERC721 collection
    /// are decremented
    function test_updateTokenRiskDecrementsActiveTokensOfDepositorOfERC721CollectionWhenRiskIsSetToZero()
        public
    {
        uint64 oldActiveTokens = _activeTokens(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(BORED_APE_YACHT_CLUB, BAYC_ID, 0);

        uint64 newActiveTokens = _activeTokens(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        assert(oldActiveTokens - newActiveTokens == 1);
    }

    /// @dev tests that updating a token risk to zero increments the inactive tokens of the depositor of that ERC721 collection
    function test_udpateTokenRiskIncrementsInactiveTokensOfDepositorOfERC721CollectionWhenRiskIsSetToZero()
        public
    {
        uint64 oldInactiveTokens = _inactiveTokens(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(BORED_APE_YACHT_CLUB, BAYC_ID, 0);

        uint64 newInactiveTokens = _inactiveTokens(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        assert(newInactiveTokens - oldInactiveTokens == 1);
    }

    /// @dev tests that upon updating a token risk to zero the total depositor risk for that ERC721 collection
    /// decreases by the old token risk
    function test_updateTokenRiskDecreasesTotalDepositorRiskOfERC721CollectionByOldTokenRiskWhenRiskIsSetToZero()
        public
    {
        uint64 oldRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );
        uint64 oldTokenRisk = _tokenRisk(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB,
            BAYC_ID
        );

        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(BORED_APE_YACHT_CLUB, BAYC_ID, 0);

        uint64 newRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        assert(oldRisk - newRisk == oldTokenRisk);
    }

    /// @dev tests that upon updating token risk to zero the risk of the ERC721 token is deleted
    function test_updateTokenRiskDeletesTokenRiskOfERc721CollectionOfTokenWhenRiskIsSetToZero()
        public
    {
        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(BORED_APE_YACHT_CLUB, BAYC_ID, 0);

        assert(
            0 ==
                _tokenRisk(
                    address(perpetualMint),
                    BORED_APE_YACHT_CLUB,
                    BAYC_ID
                )
        );
    }

    /// @dev tests that the token risk of an ERC721 collection is updated to the new token risk
    /// when updateTokenRisk is called
    function test_updateTokenRiskSetsTheTokenRiskToNewRiskWhenCollectionIsERC721()
        public
    {
        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(BORED_APE_YACHT_CLUB, BAYC_ID, NEW_RISK);

        assert(
            NEW_RISK ==
                _tokenRisk(
                    address(perpetualMint),
                    BORED_APE_YACHT_CLUB,
                    BAYC_ID
                )
        );
    }

    /// @dev tests that total risk of an ERC721 collection is increased or decreased depending on whether new risk
    /// set for the token is larger or smaller than previous risk
    function test_updateTokenRiskChangesTotalRiskByRiskChangeForERC721Collections()
        public
    {
        uint64 oldTokenRisk = _tokenRisk(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB,
            BAYC_ID
        );
        uint64 oldTotalRisk = _totalRisk(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(BORED_APE_YACHT_CLUB, BAYC_ID, NEW_RISK);

        uint64 firstTotalRisk = _totalRisk(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        assert(firstTotalRisk - oldTotalRisk == NEW_RISK - oldTokenRisk);

        uint64 secondTokenRisk = 10;

        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(
            BORED_APE_YACHT_CLUB,
            BAYC_ID,
            secondTokenRisk
        );

        uint64 secondTotalRisk = _totalRisk(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );

        assert(secondTotalRisk < firstTotalRisk);
        assert(firstTotalRisk - secondTotalRisk == NEW_RISK - secondTokenRisk);
    }

    /// @dev tests that total depositor  risk of an ERC721 collection is increased or decreased depending on whether new risk
    /// set for the token is larger or smaller than previous risk
    function test_updateTokenRiskChangesTotalDepositorRiskByRiskChangeForERC721Collections()
        public
    {
        uint64 oldTokenRisk = _tokenRisk(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB,
            BAYC_ID
        );
        uint64 oldDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(BORED_APE_YACHT_CLUB, BAYC_ID, NEW_RISK);

        uint64 firstDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        assert(
            firstDepositorRisk - oldDepositorRisk == NEW_RISK - oldTokenRisk
        );

        uint64 secondTokenRisk = 10;

        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(
            BORED_APE_YACHT_CLUB,
            BAYC_ID,
            secondTokenRisk
        );

        uint64 secondDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        assert(secondDepositorRisk < firstDepositorRisk);
        assert(
            firstDepositorRisk - secondDepositorRisk ==
                NEW_RISK - secondTokenRisk
        );
    }

    /// @dev tests that when updating an ERC721 token risk to zero the total risk changes by
    /// the amount of active tokens of the depositor multiplied by the old token risk
    function test_updateTokenRiskDecreasesTotalRiskByRiskChangeWhenUpdatingAnERC1155TokenRiskToZero()
        public
    {
        uint256 oldTotalRisk = _totalRisk(
            address(perpetualMint),
            PARALLEL_ALPHA
        );

        uint64 oldTokenRisk = _depositorTokenRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID
        );

        uint256 oldActiveTokens = _activeERC1155Tokens(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID
        );

        uint64 riskChange = oldTokenRisk * uint64(oldActiveTokens);

        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(PARALLEL_ALPHA, PARALLEL_ALPHA_ID, 0);

        uint256 newTotalRisk = _totalRisk(
            address(perpetualMint),
            PARALLEL_ALPHA
        );

        assert(oldTotalRisk - newTotalRisk == riskChange);
    }

    /// @dev tests that when updating the token risk of ERC1155 token the total active tokens of the ERC1155 collections is
    /// decreased by the previous active tokens of the depositor
    function test_updateTokenRiskDecreasesTotalActiveTokensOfERC1155CollectionByOldActiveTokensOfDepositorOfERC1155CollectionWhenSettingRiskToZero()
        public
    {
        uint64 oldTotalActiveTokens = uint64(
            _totalActiveTokens(address(perpetualMint), PARALLEL_ALPHA)
        );

        uint256 oldActiveTokens = _activeERC1155Tokens(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID
        );

        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(PARALLEL_ALPHA, PARALLEL_ALPHA_ID, 0);

        uint64 newTotalActiveTokens = uint64(
            _totalActiveTokens(address(perpetualMint), PARALLEL_ALPHA)
        );

        assert(oldTotalActiveTokens - newTotalActiveTokens == oldActiveTokens);
    }

    /// @dev tests that when updating the token risk of an ERC1155 to zero the total depositor risk is decreased by
    /// the amount of active tokens of the depositor multiplied by the difference between the previous and new risks
    function test_updateTokenRiskDecreasesTotalDepositorRiskOfERC1155CollectionByRiskChangeWhenRiskIsSetToZero()
        public
    {
        uint64 oldRisk = _depositorTokenRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID
        );

        uint256 oldActiveTokens = _activeERC1155Tokens(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID
        );

        uint64 oldDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(PARALLEL_ALPHA, PARALLEL_ALPHA_ID, 0);

        uint64 newDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        assert(
            oldDepositorRisk - newDepositorRisk ==
                uint64(oldActiveTokens) * oldRisk
        );
    }

    /// @dev tests that when updating the token risk of an ERC1155 to zero the depositor token risk is deleted
    function test_updateTokenRiskDeletesDepositorTokenRiskOfERC1155CollectionWhenRiskIsSetToZero()
        public
    {
        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(PARALLEL_ALPHA, PARALLEL_ALPHA_ID, 0);

        assert(
            0 ==
                _depositorTokenRisk(
                    address(perpetualMint),
                    depositorOne,
                    PARALLEL_ALPHA,
                    PARALLEL_ALPHA_ID
                )
        );
    }

    /// @dev tests that when updating the token risk of an ERC1155 to zero the depositor active tokens deleted
    function test_updateTokenRiskDeletesActiveERC1155TokensOfDepositorOfERC1155CollectionWhenRiskIsSetToZero()
        public
    {
        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(PARALLEL_ALPHA, PARALLEL_ALPHA_ID, 0);

        assert(
            0 ==
                _activeERC1155Tokens(
                    address(perpetualMint),
                    depositorOne,
                    PARALLEL_ALPHA,
                    PARALLEL_ALPHA_ID
                )
        );
    }

    /// @dev tests that when updating the token risk of an ERC1155 to zero the depositor inactive tokens is increased
    /// by the amount of previously active ERC1155 tokens of that depositor
    function test_updateTokenRiskIncreasesDepositorInactiveTokensOfERC1155CollectionByPreviousActiveTokensWhenRiskIsSetToZero()
        public
    {
        uint256 oldActiveTokens = _activeERC1155Tokens(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID
        );
        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(PARALLEL_ALPHA, PARALLEL_ALPHA_ID, 0);

        uint256 newInactiveTokens = _inactiveERC1155Tokens(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID
        );
        assert(newInactiveTokens == oldActiveTokens);
    }

    /// @dev tests that when updating the token risk of an ERC1155 token to zero the depositor is removed from the
    /// active ERC1155 owners EnumerableSet
    function test_updateTokenRiskRemovesDepositorFromActiveERC1155OwnersOfERC1155CollectionWhenRiskIsSetToZero()
        public
    {
        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(PARALLEL_ALPHA, PARALLEL_ALPHA_ID, 0);

        address[] memory activeOwners = _activeERC1155Owners(
            address(perpetualMint),
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID
        );

        for (uint256 i; i < activeOwners.length; ++i) {
            assert(activeOwners[i] != depositorOne);
        }
    }

    /// @dev tests that a depositor is added to the active ERC1155 owners EnumerableSet if not contained within it already,
    /// if a non-zero risk is set for a token id the depositor owns for an ERC1155 collection
    function test_updateTokenRiskAddsDepositorToActiveERC1155OwnersIfNotAlreadyContainedWhenCollectinIsERC1155()
        public
    {
        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(PARALLEL_ALPHA, PARALLEL_ALPHA_ID, 0);

        address[] memory firstActiveOwners = _activeERC1155Owners(
            address(perpetualMint),
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID
        );

        for (uint256 i; i < firstActiveOwners.length; ++i) {
            assert(firstActiveOwners[i] != depositorOne);
        }

        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID,
            NEW_RISK
        );

        address[] memory secondActiveOwners = _activeERC1155Owners(
            address(perpetualMint),
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID
        );

        assert(depositorOne == secondActiveOwners[1]);
    }

    /// @dev tests that when updating the risk of an ERC1155 token the active ERC1155 tokens is increased by the amount of
    /// inactive ERC1155 tokens of that depositor
    function test_updateTokenRiskIncreasesActiveTokensOfDepositorOfERC1155CollectionByInactiveTokensOfDepositorOfERC1155Collection()
        public
    {
        uint64 oldActiveTokens = uint64(
            _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                PARALLEL_ALPHA_ID
            )
        );

        uint64 inactiveTokens = uint64(
            _inactiveERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                PARALLEL_ALPHA_ID
            )
        );

        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID,
            NEW_RISK
        );

        uint64 newActiveTokens = uint64(
            _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                PARALLEL_ALPHA_ID
            )
        );

        assert(newActiveTokens == oldActiveTokens + inactiveTokens);
    }

    /// @dev tests that when updating the risk of an ERC1155 token the total depositor risk of that collection is changed
    /// by the amount of active tokens of the depositor multiplied by the difference between the previous and new risks
    function test_updateTokenRiskChangesTotalDepositorRiskOfERC1155CollectionByRiskChange()
        public
    {
        uint64 activeTokens = uint64(
            _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                PARALLEL_ALPHA_ID
            )
        );
        uint64 depositorTokenRisk = _depositorTokenRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID
        );

        uint64 oldTotalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID,
            NEW_RISK
        );

        uint64 firstTotalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        assert(
            firstTotalDepositorRisk - oldTotalDepositorRisk ==
                activeTokens * (NEW_RISK - depositorTokenRisk)
        );

        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID,
            NEW_RISK / 2
        );

        uint64 secondTotalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        assert(
            firstTotalDepositorRisk - secondTotalDepositorRisk ==
                activeTokens * (NEW_RISK - NEW_RISK / 2)
        );
    }

    /// @dev tests that when updating the risk of an ERC1155 token the token risk of that token is changed
    /// by the amount of active tokens of the depositor multiplied by the difference between the previous and new risks
    function test_updateTokenRiskChangesTokenRiskOfERC1155CollectionByRiskChange()
        public
    {
        uint64 oldTokenRisk = _tokenRisk(
            address(perpetualMint),
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID
        );
        uint64 activeTokens = uint64(
            _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                PARALLEL_ALPHA_ID
            )
        );
        uint64 depositorTokenRisk = _depositorTokenRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID
        );

        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID,
            NEW_RISK
        );

        uint64 firstTokenRisk = _tokenRisk(
            address(perpetualMint),
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID
        );

        assert(
            firstTokenRisk - oldTokenRisk ==
                activeTokens * (NEW_RISK - depositorTokenRisk)
        );

        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID,
            NEW_RISK / 2
        );

        uint64 secondTokenRisk = _tokenRisk(
            address(perpetualMint),
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID
        );

        assert(
            firstTokenRisk - secondTokenRisk ==
                activeTokens * (NEW_RISK - NEW_RISK / 2)
        );
    }

    /// @dev tests that when updating the token risk of an ERC1155 token the depositor token risk of
    /// that token is set to the new risk
    function test_udpateTokenRiskSetsDepositorTokenRiskOfERC155CollectionToNewRisk()
        public
    {
        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID,
            NEW_RISK
        );

        assert(
            NEW_RISK ==
                _depositorTokenRisk(
                    address(perpetualMint),
                    depositorOne,
                    PARALLEL_ALPHA,
                    PARALLEL_ALPHA_ID
                )
        );
    }

    /// @dev test that updateTokenRisk reverts if the risk to be set is larger than the BASIS
    function test_updateTokenRiskRevertsWhen_RiskExceedsBasis() public {
        vm.expectRevert(IPerpetualMintInternal.BasisExceeded.selector);
        vm.prank(depositorOne);
        perpetualMint.updateTokenRisk(
            BORED_APE_YACHT_CLUB,
            BAYC_ID,
            FAILING_RISK
        );
    }

    /// @dev test that updateTokenRisk reverts if the caller is not the escrowedERC721Owner if the collection selected
    /// is an ERC721 collection
    function test_updateTokenRiskRevertsWhen_CollectionIsERC721AndCallerIsNotEscrowedERC721Owner()
        public
    {
        vm.expectRevert(IPerpetualMintInternal.OnlyEscrowedTokenOwner.selector);
        vm.prank(NON_OWNER);
        perpetualMint.updateTokenRisk(BORED_APE_YACHT_CLUB, BAYC_ID, NEW_RISK);
    }

    /// @dev test that updateTokenRisk reverts if the caller does not belong to the escrowed1155Owners EnumerableSet, if the collection
    /// selected is an 1155 collection
    function test_updateTokenRiskRevertsWhen_CollectionIsERC1155AndCallerIsNotInEscrowedERC1155Owners()
        public
    {
        vm.expectRevert(IPerpetualMintInternal.OnlyEscrowedTokenOwner.selector);
        vm.prank(NON_OWNER);
        perpetualMint.updateTokenRisk(
            PARALLEL_ALPHA,
            PARALLEL_ALPHA_ID,
            NEW_RISK
        );
    }
}
