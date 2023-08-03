// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";

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
    uint256[] amounts;
    uint256[] amountsToIdle;
    uint256[] risks;

    // grab PARALLEL_ALPHA collection earnings storage slot
    bytes32 internal collectionEarningsStorageSlot =
        keccak256(
            abi.encode(
                PARALLEL_ALPHA, // the ERC1155 collection
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
                PARALLEL_ALPHA,
                PARALLEL_ALPHA_ID
            ) / 2
        );
        tokenIds.push(PARALLEL_ALPHA_ID);
        risks.push(NEW_RISK);

        vm.prank(depositorOne);
        perpetualMint.idleERC1155Tokens(
            PARALLEL_ALPHA,
            tokenIds,
            amountsToIdle
        );

        // overwrite storage
        // must be done after idling to not be checking trivial state changes
        vm.store(
            address(perpetualMint),
            collectionEarningsStorageSlot,
            bytes32(COLLECTION_EARNINGS)
        );

        amounts.push(
            _inactiveERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                PARALLEL_ALPHA_ID
            )
        );
    }

    /// @dev tests that upon updating ERC1155 token risks, the depositor deductions are set to be equal to the
    /// collection earnings of the collection of the updated token
    function test_updateERC1155TokenRisksUpdatesDepositorEarningsOfCallerWhenTotalDepositorRiskOfCallerIsZero()
        public
    {
        // grab totalDepositorsRisk storage slot
        bytes32 totalDepositorRiskStorageSlot = keccak256(
            abi.encode(
                PARALLEL_ALPHA, // the ERC1155 collection
                keccak256(
                    abi.encode(
                        depositorOne, // address of depositor
                        uint256(Storage.STORAGE_SLOT) + 21 // totalDepositorRisk mapping storage slot
                    )
                )
            )
        );

        vm.store(address(perpetualMint), totalDepositorRiskStorageSlot, 0);

        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(
            PARALLEL_ALPHA,
            tokenIds,
            amounts,
            risks
        );

        assert(
            _depositorDeductions(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA
            ) == _collectionEarnings(address(perpetualMint), PARALLEL_ALPHA)
        );
    }

    /// @dev tests that upon updating ERC1155 token risks, the depositor earnings are updated and the depositor
    /// deductions set equal to the depositor earnings
    function test_updateERC1155TokenRisksUpdatesDepositorEarningsWhenTotalDepositorRiskIsNonZero()
        public
    {
        uint256 totalRisk = _totalRisk(address(perpetualMint), PARALLEL_ALPHA);
        uint256 totalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );
        uint256 collectionEarnings = _collectionEarnings(
            address(perpetualMint),
            PARALLEL_ALPHA
        );
        uint256 oldDepositorDeductions = _depositorDeductions(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        assert(totalDepositorRisk != 0);
        assert(totalRisk != 0);

        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(
            PARALLEL_ALPHA,
            tokenIds,
            amounts,
            risks
        );

        uint256 newDepositorDeductions = _depositorDeductions(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        uint256 expectedEarnings = (collectionEarnings * totalDepositorRisk) /
            totalRisk -
            oldDepositorDeductions;

        assert(
            expectedEarnings ==
                _depositorEarnings(
                    address(perpetualMint),
                    depositorOne,
                    PARALLEL_ALPHA
                )
        );

        assert(newDepositorDeductions == expectedEarnings);
    }

    /// @dev tests that when updating the risk of ERC1155 tokens the active ERC1155 tokens is increased by the amount of
    /// inactive ERC1155 tokens to be activated for each of the updated tokenIds
    function test_updateERC1155TokenRisksIncreasesActiveTokensOfDepositorBySumOfInactiveTokensAmountsToBeActivatedOfEachTokenId()
        public
    {
        uint256 oldActiveTokens;
        uint256 tokensToActivate;

        for (uint256 i; i < tokenIds.length; ++i) {
            oldActiveTokens += _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                tokenIds[i]
            );
            tokensToActivate += amounts[i];
        }

        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(
            PARALLEL_ALPHA,
            tokenIds,
            amounts,
            risks
        );

        uint256 newActiveTokens;
        for (uint256 i; i < tokenIds.length; ++i) {
            newActiveTokens += _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                tokenIds[i]
            );
        }

        assert(newActiveTokens == oldActiveTokens + tokensToActivate);
    }

    /// @dev tests that when updating the risk of a ERC1155 tokens the total depositor risk of that collection is changed
    /// correctly when overall risk increases and new risk value is larger
    function test_updateERC1155TokenRisksChangesTotalDepositorRiskByTotalRiskChangeWhenOverallRiskChangeIsPositiveNewRiskIsLarger()
        public
    {
        uint256 idsLength = tokenIds.length;
        uint256[] memory oldActiveTokenAmounts = new uint256[](idsLength);
        uint256[] memory oldDepositorTokenRisks = new uint256[](idsLength);

        for (uint256 i; i < tokenIds.length; ++i) {
            oldDepositorTokenRisks[i] = _depositorTokenRisk(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                tokenIds[i]
            );

            oldActiveTokenAmounts[i] = _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                tokenIds[i]
            );
        }

        uint256 oldTotalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(
            PARALLEL_ALPHA,
            tokenIds,
            amounts,
            risks
        );

        uint256 newTotalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        uint256 expectedTotalRiskChange;
        for (uint256 i; i < idsLength; ++i) {
            expectedTotalRiskChange +=
                amounts[i] *
                risks[i] +
                oldActiveTokenAmounts[i] *
                (risks[i] - oldDepositorTokenRisks[i]);
        }
        assert(
            newTotalDepositorRisk - oldTotalDepositorRisk ==
                expectedTotalRiskChange
        );
    }

    /// @dev tests that when updating the risk of a ERC1155 tokens the total depositor risk of that collection is changed
    /// correctly for instances where total risk increases even if new risk value is smaller
    function test_updateERC1155TokenRisksChangesTotalDepositorRiskByTotalRiskChangeWhenOverallRiskChangeIsPositiveAndNewRiskIsSmaller()
        public
    {
        uint256 idsLength = tokenIds.length;
        uint256[] memory oldActiveTokenAmounts = new uint256[](idsLength);
        uint256[] memory oldDepositorTokenRisks = new uint256[](idsLength);

        // pick a value which is smaller than current risk and overall increases risk
        risks[0] =
            (_depositorTokenRisk(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                PARALLEL_ALPHA_ID
            ) * 9) /
            10;

        for (uint256 i; i < tokenIds.length; ++i) {
            oldDepositorTokenRisks[i] = _depositorTokenRisk(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                tokenIds[i]
            );

            oldActiveTokenAmounts[i] = _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                tokenIds[i]
            );
        }

        uint256 oldTotalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(
            PARALLEL_ALPHA,
            tokenIds,
            amounts,
            risks
        );

        uint256 newTotalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        uint256 expectedTotalRiskChange;
        for (uint256 i; i < idsLength; ++i) {
            // this only works because of the chosen value of risk with a given pre-state
            // could be made more general in future
            expectedTotalRiskChange +=
                amounts[i] *
                risks[i] -
                oldActiveTokenAmounts[i] *
                (oldDepositorTokenRisks[i] - risks[i]);
        }

        assert(
            newTotalDepositorRisk - oldTotalDepositorRisk ==
                expectedTotalRiskChange
        );
    }

    /// @dev tests that when updating the risk of a ERC1155 tokens the total depositor risk of that collection is changed
    /// correctly when overall risk change is negative and new risk value is smaller
    function test_updateERC1155TokenRisksChangesTotalDepositorRiskByTotalRiskChangeWhenOverallRiskChangeIsNegativeAndNewRiskIsSmaller()
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
                PARALLEL_ALPHA,
                PARALLEL_ALPHA_ID
            ) * 3) /
            10;

        for (uint256 i; i < tokenIds.length; ++i) {
            oldDepositorTokenRisks[i] = _depositorTokenRisk(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                tokenIds[i]
            );

            oldActiveTokenAmounts[i] = _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                tokenIds[i]
            );
        }

        uint256 oldTotalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(
            PARALLEL_ALPHA,
            tokenIds,
            amounts,
            risks
        );

        uint256 newTotalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        uint256 expectedTotalRiskChange;
        for (uint256 i; i < idsLength; ++i) {
            // this only works because of the chosen value of risk with a given pre-state
            // could be made more general in future
            expectedTotalRiskChange +=
                oldActiveTokenAmounts[i] *
                (oldDepositorTokenRisks[i] - risks[i]) -
                amounts[i] *
                risks[i];
        }

        assert(
            oldTotalDepositorRisk - newTotalDepositorRisk ==
                expectedTotalRiskChange
        );
    }

    /// @dev tests that when updating the risk of a ERC1155 tokens, the token risk of each token is changed
    /// correctly when overall risk change is positive and new risk is higher
    function test_updateERC1155TokenRisksChangesTokenRiskByRiskChangeWhenOverallRiskChangeIsPositiveAndNewRiskIsLarger()
        public
    {
        uint256 idsLength = tokenIds.length;
        uint256[] memory oldTokenRisks = new uint256[](idsLength);
        uint256[] memory oldActiveTokenAmounts = new uint256[](idsLength);
        uint256[] memory oldDepositorTokenRisks = new uint256[](idsLength);

        for (uint256 i; i < idsLength; ++i) {
            oldTokenRisks[i] = _tokenRisk(
                address(perpetualMint),
                PARALLEL_ALPHA,
                tokenIds[i]
            );

            oldActiveTokenAmounts[i] = _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                tokenIds[i]
            );

            oldDepositorTokenRisks[i] = _depositorTokenRisk(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                tokenIds[i]
            );
        }

        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(
            PARALLEL_ALPHA,
            tokenIds,
            amounts,
            risks
        );

        uint256[] memory newTokenRisks = new uint256[](idsLength);

        for (uint256 i; i < idsLength; ++i) {
            newTokenRisks[i] = _tokenRisk(
                address(perpetualMint),
                PARALLEL_ALPHA,
                tokenIds[i]
            );
        }

        for (uint256 i; i < idsLength; ++i) {
            uint256 expectedTokenRiskChange = risks[i] *
                amounts[i] +
                oldActiveTokenAmounts[i] *
                (risks[i] - oldDepositorTokenRisks[i]);

            assert(
                newTokenRisks[i] - oldTokenRisks[i] == expectedTokenRiskChange
            );
        }
    }

    /// @dev tests that when updating the risk of a ERC1155 tokens, the token risk of each token is changed
    /// correctly when overall risk change is positive and new risk is smaller
    function test_updateERC1155TokenRisksChangesTokenRiskByRiskChangeWhenOverallRiskChangeIsPositiveAndNewRiskIsSmaller()
        public
    {
        uint256 idsLength = tokenIds.length;
        uint256[] memory oldTokenRisks = new uint256[](idsLength);
        uint256[] memory oldActiveTokenAmounts = new uint256[](idsLength);
        uint256[] memory oldDepositorTokenRisks = new uint256[](idsLength);

        // pick a value which is smaller than current risk and overall increases risk
        risks[0] =
            (_depositorTokenRisk(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                PARALLEL_ALPHA_ID
            ) * 9) /
            10;

        for (uint256 i; i < idsLength; ++i) {
            oldTokenRisks[i] = _tokenRisk(
                address(perpetualMint),
                PARALLEL_ALPHA,
                tokenIds[i]
            );

            oldActiveTokenAmounts[i] = _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                tokenIds[i]
            );

            oldDepositorTokenRisks[i] = _depositorTokenRisk(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                tokenIds[i]
            );
        }

        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(
            PARALLEL_ALPHA,
            tokenIds,
            amounts,
            risks
        );

        uint256[] memory newTokenRisks = new uint256[](idsLength);

        for (uint256 i; i < idsLength; ++i) {
            newTokenRisks[i] = _tokenRisk(
                address(perpetualMint),
                PARALLEL_ALPHA,
                tokenIds[i]
            );
        }

        for (uint256 i; i < idsLength; ++i) {
            uint256 expectedTokenRiskChange = oldActiveTokenAmounts[i] *
                risks[i] -
                (oldDepositorTokenRisks[i] - risks[i]) *
                amounts[i];

            assert(
                newTokenRisks[i] - oldTokenRisks[i] == expectedTokenRiskChange
            );
        }
    }

    /// @dev tests that when updating the risk of a ERC1155 tokens, the token risk of each token is changed
    /// correctly when overall risk change is negative and new risk is smaller
    function test_updateERC1155TokenRisksChangesTokenRiskByRiskChangeWhenOverallRiskChangeIsNegativeAndNewRiskIsSmaller()
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
                PARALLEL_ALPHA,
                PARALLEL_ALPHA_ID
            ) * 3) /
            10;

        for (uint256 i; i < idsLength; ++i) {
            oldTokenRisks[i] = _tokenRisk(
                address(perpetualMint),
                PARALLEL_ALPHA,
                tokenIds[i]
            );

            oldActiveTokenAmounts[i] = _activeERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                tokenIds[i]
            );

            oldDepositorTokenRisks[i] = _depositorTokenRisk(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                tokenIds[i]
            );
        }

        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(
            PARALLEL_ALPHA,
            tokenIds,
            amounts,
            risks
        );

        uint256[] memory newTokenRisks = new uint256[](idsLength);

        for (uint256 i; i < idsLength; ++i) {
            newTokenRisks[i] = _tokenRisk(
                address(perpetualMint),
                PARALLEL_ALPHA,
                tokenIds[i]
            );
        }

        for (uint256 i; i < idsLength; ++i) {
            uint256 expectedTokenRiskChange = (oldDepositorTokenRisks[i] -
                risks[i]) *
                amounts[i] -
                oldActiveTokenAmounts[i] *
                risks[i];

            assert(
                oldTokenRisks[i] - newTokenRisks[i] == expectedTokenRiskChange
            );
        }
    }

    /// @dev tests that when updating the token risk of ERC1155 tokens the depositor token risk of
    /// that token is set to the new risk
    function test_updateERC1155TokenRisksSetsDepositorTokenRiskToNewRisk()
        public
    {
        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(
            PARALLEL_ALPHA,
            tokenIds,
            amounts,
            risks
        );

        for (uint256 i; i < tokenIds.length; ++i) {
            assert(
                risks[i] ==
                    _depositorTokenRisk(
                        address(perpetualMint),
                        depositorOne,
                        PARALLEL_ALPHA,
                        tokenIds[i]
                    )
            );
        }
    }

    /// @dev tests that upon updatingERC1155TokenRisks the inactive ERC1155 amount decreases by amount of tokens
    /// activated for each tokenId
    function test_updateERC1155TokenRisksReducesInactiveERC1155AmountForEachTokenIdUpdatedByAmount()
        public
    {
        uint256[] memory oldInactiveTokenAmounts = new uint256[](
            tokenIds.length
        );

        for (uint256 i; i < tokenIds.length; ++i) {
            oldInactiveTokenAmounts[i] = _inactiveERC1155Tokens(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                tokenIds[i]
            );
        }

        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(
            PARALLEL_ALPHA,
            tokenIds,
            amounts,
            risks
        );

        for (uint256 i; i < tokenIds.length; ++i) {
            assert(
                oldInactiveTokenAmounts[i] -
                    _inactiveERC1155Tokens(
                        address(perpetualMint),
                        depositorOne,
                        PARALLEL_ALPHA,
                        tokenIds[i]
                    ) ==
                    amounts[i]
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
            amounts,
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
        perpetualMint.updateERC1155TokenRisks(
            PARALLEL_ALPHA,
            tokenIds,
            amounts,
            risks
        );
    }

    /// @dev test that updateERC1155TokenRisks reverts if the risk array and tokenIds array differ in length
    function test_updateERC1155TokenRisksRevertsWhen_TokenIdsAndAmountsArrayLengthsMismatch()
        public
    {
        amounts.push(NEW_RISK);
        vm.expectRevert(IPerpetualMintInternal.ArrayLengthMismatch.selector);
        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(
            PARALLEL_ALPHA,
            tokenIds,
            amounts,
            risks
        );
    }

    /// @dev test that updateERC1155TokenRisks reverts if the risk to be set is larger than the BASIS
    function test_updateERC1155TokenRisksRevertsWhen_RiskExceedsBasis() public {
        risks[0] = FAILING_RISK;
        vm.expectRevert(IPerpetualMintInternal.BasisExceeded.selector);
        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(
            PARALLEL_ALPHA,
            tokenIds,
            amounts,
            risks
        );
    }

    /// @dev test that updateERC1155TokenRisks reverts if the risk to be set is 0
    function test_updateERC1155TokenRisksRevertsWhen_RiskIsSetToZero() public {
        risks[0] = 0;
        vm.expectRevert(IPerpetualMintInternal.TokenRiskMustBeNonZero.selector);
        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(
            PARALLEL_ALPHA,
            tokenIds,
            amounts,
            risks
        );
    }

    /// @dev test that updateERC1155TokenRisks reverts if the caller does not belong to the escrowed1155Owners EnumerableSet
    function test_updateERC1155TokenRisksRevertsWhen_CollectionIsERC1155AndCallerIsNotInEscrowedERC1155Owners()
        public
    {
        amounts[0] = 0;
        vm.expectRevert(IPerpetualMintInternal.OnlyEscrowedTokenOwner.selector);
        vm.prank(NON_OWNER);
        perpetualMint.updateERC1155TokenRisks(
            PARALLEL_ALPHA,
            tokenIds,
            amounts,
            risks
        );
    }
}
