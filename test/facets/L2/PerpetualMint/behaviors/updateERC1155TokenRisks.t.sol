// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";

/// @title PerpetualMint_updateERC1155TokenRisks
/// @dev PerpetualMint test contract for testing expected behavior of the updateERC1155TokenRisks function
contract PerpetualMint_updateERC1155TokenRisks is
    IPerpetualMintInternal,
    PerpetualMintTest,
    L2ForkTest
{
    uint256 internal constant COLLECTION_EARNINGS = 1 ether;
    uint256 internal constant FAILING_RISK = 10000000000000;
    uint256 internal constant NEW_RISK = 10000;
    address internal constant NON_OWNER = address(4);
    uint256 internal PARALLEL_ALPHA_ID;
    uint256[] tokenIds;
    uint256[] amountsToIdle;
    uint256[] risks;

    address internal constant COLLECTION = PARALLEL_ALPHA;

    // grab COLLECTION collection earnings storage slot
    bytes32 internal collectionEarningsStorageSlot =
        keccak256(
            abi.encode(
                COLLECTION, // the ERC1155 collection
                uint256(Storage.STORAGE_SLOT) + 9 // the collectionEarnings storage slot
            )
        );

    function setUp() public override {
        super.setUp();

        PARALLEL_ALPHA_ID = PARALLEL_ALPHA_TOKEN_ID_ONE;

        depositParallelAlphaAssetsMock();

        amountsToIdle.push(
            _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                COLLECTION,
                PARALLEL_ALPHA_ID
            )
        );
        tokenIds.push(PARALLEL_ALPHA_ID);
        risks.push(NEW_RISK);

        // overwrite storage
        // must be done after idling to not be checking trivial state changes
        vm.store(
            address(perpetualMint),
            collectionEarningsStorageSlot,
            bytes32(COLLECTION_EARNINGS)
        );
    }

    /// @dev tests that upon updating ERC1155 token risks, the depositor earnings are updated, the last
    /// collection earnings are set to the current collection earnings, and the multiplier offset for the depositor
    /// is updated
    function test_updateERC1155TokenRisksUpdatesDepositorEarningsWhenTotalDepositorRiskIsNonZero()
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
        perpetualMint.updateERC1155TokenRisks(COLLECTION, tokenIds, risks);

        assert(
            expectedEarnings + oldDepositorEarnings ==
                _depositorEarnings(
                    address(perpetualMint),
                    depositorOne,
                    COLLECTION
                )
        );

        assert(
            baseMultiplier ==
                _baseMultiplier(address(perpetualMint), COLLECTION)
        );

        assert(
            currentEarnings ==
                _lastCollectionEarnings(address(perpetualMint), COLLECTION)
        );
    }

    /// @dev tests that when updating the risk of a ERC1155 tokens the total depositor risk of that collection is changed
    /// correctly when overall risk increases and new risk value is larger
    function test_updateERC1155TokenRisksChangesTotalDepositorRiskByTotalRiskChangeWhenNewRiskIsLargerThenOldRisk()
        public
    {
        uint256 idsLength = tokenIds.length;
        uint256[] memory oldActiveTokenAmounts = new uint256[](idsLength);
        uint256[] memory oldDepositorTokenRisks = new uint256[](idsLength);

        for (uint256 i; i < tokenIds.length; ++i) {
            oldDepositorTokenRisks[i] = _depositorTokenRisk(
                address(perpetualMint),
                depositorOne,
                COLLECTION,
                tokenIds[i]
            );

            oldActiveTokenAmounts[i] = _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                COLLECTION,
                tokenIds[i]
            );
        }

        uint256 oldTotalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(COLLECTION, tokenIds, risks);

        uint256 newTotalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        uint256 expectedTotalRiskChange;
        for (uint256 i; i < idsLength; ++i) {
            expectedTotalRiskChange +=
                oldActiveTokenAmounts[i] *
                (risks[i] - oldDepositorTokenRisks[i]);
        }
        assert(
            newTotalDepositorRisk - oldTotalDepositorRisk ==
                expectedTotalRiskChange
        );
    }

    /// @dev tests that when updating the risk of a ERC1155 tokens the total depositor risk of that collection is changed
    /// correctly when overall risk change is negative and new risk value is smaller
    function test_updateERC1155TokenRisksChangesTotalDepositorRiskByTotalRiskChangeWhenNewRiskIsSmallerThanOldRisk()
        public
    {
        uint256 idsLength = tokenIds.length;
        uint256[] memory oldActiveTokenAmounts = new uint256[](idsLength);
        uint256[] memory oldDepositorTokenRisks = new uint256[](idsLength);

        // pick a value which is smaller than current risk and overall decreases risk
        risks[0] =
            (_depositorTokenRisk(
                address(perpetualMint),
                depositorOne,
                COLLECTION,
                PARALLEL_ALPHA_ID
            ) * 3) /
            10;

        for (uint256 i; i < tokenIds.length; ++i) {
            oldDepositorTokenRisks[i] = _depositorTokenRisk(
                address(perpetualMint),
                depositorOne,
                COLLECTION,
                tokenIds[i]
            );

            oldActiveTokenAmounts[i] = _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                COLLECTION,
                tokenIds[i]
            );
        }

        uint256 oldTotalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(COLLECTION, tokenIds, risks);

        uint256 newTotalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        uint256 expectedTotalRiskChange;
        for (uint256 i; i < idsLength; ++i) {
            // this only works because of the chosen value of risk with a given pre-state
            // could be made more general in future
            expectedTotalRiskChange +=
                oldActiveTokenAmounts[i] *
                (oldDepositorTokenRisks[i] - risks[i]);
        }

        assert(
            oldTotalDepositorRisk - newTotalDepositorRisk ==
                expectedTotalRiskChange
        );
    }

    /// @dev tests that when updating the risk of a ERC1155 tokens, the token risk of each token is changed
    /// correctly when overall risk change is positive and new risk is larger
    function test_updateERC1155TokenRisksChangesTokenRiskByRiskChangeWhenNewRiskIsLargerThanOldRisk()
        public
    {
        uint256 idsLength = tokenIds.length;
        uint256[] memory oldTokenRisks = new uint256[](idsLength);
        uint256[] memory oldActiveTokenAmounts = new uint256[](idsLength);
        uint256[] memory oldDepositorTokenRisks = new uint256[](idsLength);

        for (uint256 i; i < idsLength; ++i) {
            oldTokenRisks[i] = _tokenRisk(
                address(perpetualMint),
                COLLECTION,
                tokenIds[i]
            );

            oldActiveTokenAmounts[i] = _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                COLLECTION,
                tokenIds[i]
            );

            oldDepositorTokenRisks[i] = _depositorTokenRisk(
                address(perpetualMint),
                depositorOne,
                COLLECTION,
                tokenIds[i]
            );
        }

        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(COLLECTION, tokenIds, risks);

        uint256[] memory newTokenRisks = new uint256[](idsLength);

        for (uint256 i; i < idsLength; ++i) {
            newTokenRisks[i] = _tokenRisk(
                address(perpetualMint),
                COLLECTION,
                tokenIds[i]
            );
        }

        for (uint256 i; i < idsLength; ++i) {
            uint256 expectedTokenRiskChange = oldActiveTokenAmounts[i] *
                (risks[i] - oldDepositorTokenRisks[i]);

            assert(
                newTokenRisks[i] - oldTokenRisks[i] == expectedTokenRiskChange
            );
        }
    }

    /// @dev tests that when updating the risk of a ERC1155 tokens, the token risk of each token is changed
    /// correctly when overall risk change is negative and new risk is smaller
    function test_updateERC1155TokenRisksChangesTokenRiskByRiskChangeWhenNewRiskIsSmallerThanOldRisk()
        public
    {
        uint256 idsLength = tokenIds.length;
        uint256[] memory oldTokenRisks = new uint256[](idsLength);
        uint256[] memory oldActiveTokenAmounts = new uint256[](idsLength);
        uint256[] memory oldDepositorTokenRisks = new uint256[](idsLength);

        // pick a value which is smaller than current risk and overall decreases risk
        risks[0] =
            (_depositorTokenRisk(
                address(perpetualMint),
                depositorOne,
                COLLECTION,
                PARALLEL_ALPHA_ID
            ) * 3) /
            10;

        for (uint256 i; i < idsLength; ++i) {
            oldTokenRisks[i] = _tokenRisk(
                address(perpetualMint),
                COLLECTION,
                tokenIds[i]
            );

            oldActiveTokenAmounts[i] = _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                COLLECTION,
                tokenIds[i]
            );

            oldDepositorTokenRisks[i] = _depositorTokenRisk(
                address(perpetualMint),
                depositorOne,
                COLLECTION,
                tokenIds[i]
            );
        }

        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(COLLECTION, tokenIds, risks);

        uint256[] memory newTokenRisks = new uint256[](idsLength);

        for (uint256 i; i < idsLength; ++i) {
            newTokenRisks[i] = _tokenRisk(
                address(perpetualMint),
                COLLECTION,
                tokenIds[i]
            );
        }

        for (uint256 i; i < idsLength; ++i) {
            uint256 expectedTokenRiskChange = (oldDepositorTokenRisks[i] -
                risks[i]) * oldActiveTokenAmounts[i];

            assert(
                oldTokenRisks[i] - newTokenRisks[i] == expectedTokenRiskChange
            );
        }
    }

    /// @dev tests that when updating the risk of ERC1155 tokens, the total risk of the collection is changed
    /// correctly when overall risk change is positive and new risk is larger
    function test_updateERC1155TokenRisksChangesTotalRiskByRiskChangeWhenNewRiskIsLargerThanOldRisk()
        public
    {
        uint256 idsLength = tokenIds.length;
        uint256 newTotalRisk;
        uint256 oldTotalRisk;
        uint256[] memory oldActiveTokenAmounts = new uint256[](idsLength);
        uint256[] memory oldDepositorTokenRisks = new uint256[](idsLength);

        oldTotalRisk = _totalRisk(address(perpetualMint), COLLECTION);

        for (uint256 i; i < idsLength; ++i) {
            oldActiveTokenAmounts[i] = _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                COLLECTION,
                tokenIds[i]
            );

            oldDepositorTokenRisks[i] = _depositorTokenRisk(
                address(perpetualMint),
                depositorOne,
                COLLECTION,
                tokenIds[i]
            );
        }

        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(COLLECTION, tokenIds, risks);

        newTotalRisk = _totalRisk(address(perpetualMint), COLLECTION);

        for (uint256 i; i < idsLength; ++i) {
            uint256 expectedTokenRiskChange = oldActiveTokenAmounts[i] *
                (risks[i] - oldDepositorTokenRisks[i]);

            assert(newTotalRisk - oldTotalRisk == expectedTokenRiskChange);
        }
    }

    /// @dev tests that when updating the risk of ERC1155 tokens, the total risk of the collection is changed
    /// correctly when overall risk change is negative and new risk is smaller
    function test_updateERC1155TokenRisksChangesTotalRiskByRiskChangeWhenNewRiskIsSmallerThanOldRisk()
        public
    {
        uint256 idsLength = tokenIds.length;
        uint256 newTotalRisk;
        uint256 oldTotalRisk;
        uint256[] memory oldActiveTokenAmounts = new uint256[](idsLength);
        uint256[] memory oldDepositorTokenRisks = new uint256[](idsLength);

        // pick a value which is smaller than current risk and overall decreases risk
        risks[0] =
            (_depositorTokenRisk(
                address(perpetualMint),
                depositorOne,
                COLLECTION,
                PARALLEL_ALPHA_ID
            ) * 3) /
            10;

        oldTotalRisk = _totalRisk(address(perpetualMint), COLLECTION);

        for (uint256 i; i < idsLength; ++i) {
            oldActiveTokenAmounts[i] = _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                COLLECTION,
                tokenIds[i]
            );

            oldDepositorTokenRisks[i] = _depositorTokenRisk(
                address(perpetualMint),
                depositorOne,
                COLLECTION,
                tokenIds[i]
            );
        }

        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(COLLECTION, tokenIds, risks);

        newTotalRisk = _totalRisk(address(perpetualMint), COLLECTION);

        for (uint256 i; i < idsLength; ++i) {
            uint256 expectedTokenRiskChange = (oldDepositorTokenRisks[i] -
                risks[i]) * oldActiveTokenAmounts[i];

            assert(oldTotalRisk - newTotalRisk == expectedTokenRiskChange);
        }
    }

    /// @dev tests that when updating the token risk of ERC1155 tokens the depositor token risk of
    /// that token is set to the new risk
    function test_updateERC1155TokenRisksSetsDepositorTokenRiskToNewRisk()
        public
    {
        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(COLLECTION, tokenIds, risks);

        for (uint256 i; i < tokenIds.length; ++i) {
            assert(
                risks[i] ==
                    _depositorTokenRisk(
                        address(perpetualMint),
                        depositorOne,
                        COLLECTION,
                        tokenIds[i]
                    )
            );
        }
    }

    /// @dev test that updateERC1155TokenRisks reverts if the collection is an ERC721 collection
    function test_updateERC1155TokenRisksRevertsWhen_CollectionIsERC721()
        public
    {
        vm.expectRevert(IPerpetualMintInternal.CollectionTypeMismatch.selector);
        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(
            BORED_APE_YACHT_CLUB,
            tokenIds,
            risks
        );
    }

    /// @dev test that updateERC1155TokenRisks reverts if the risk array and tokenIds array differ in length
    function test_updateERC1155TokenRisksRevertsWhen_TokenIdsAndRisksArrayLengthsMismatch()
        public
    {
        risks.push(NEW_RISK);
        vm.expectRevert(IPerpetualMintInternal.ArrayLengthMismatch.selector);
        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(COLLECTION, tokenIds, risks);
    }

    /// @dev test that updateERC1155TokenRisks reverts if the risk to be set is larger than the BASIS
    function test_updateERC1155TokenRisksRevertsWhen_RiskExceedsBasis() public {
        risks[0] = FAILING_RISK;
        vm.expectRevert(IPerpetualMintInternal.BasisExceeded.selector);
        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(COLLECTION, tokenIds, risks);
    }

    /// @dev test that updateERC1155TokenRisks reverts if the risk to be set is 0
    function test_updateERC1155TokenRisksRevertsWhen_RiskIsSetToZero() public {
        risks[0] = 0;
        vm.expectRevert(IPerpetualMintInternal.TokenRiskMustBeNonZero.selector);
        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(COLLECTION, tokenIds, risks);
    }

    /// @dev test that updateERC1155TokenRisks reverts if the caller does not have active ERC1155 tokens in that tokenId for that collection
    function test_updateERC1155TokenRisksRevertsWhen_DoesNotHaveActiveERC1155TokensInCollection()
        public
    {
        vm.expectRevert(IPerpetualMintInternal.OwnerInactive.selector);
        vm.prank(NON_OWNER);
        perpetualMint.updateERC1155TokenRisks(COLLECTION, tokenIds, risks);
    }

    /// @dev test that updateERC1155TokenRisks reverts if the caller is attempting to set the same risk as the previous risk
    function test_updateERC1155TokenRisksRevertsWhen_NewRiskIsSameAsOldRisk()
        public
    {
        risks[0] = _depositorTokenRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION,
            PARALLEL_ALPHA_ID
        );
        vm.expectRevert(IPerpetualMintInternal.IdenticalRisk.selector);
        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(COLLECTION, tokenIds, risks);
    }
}
