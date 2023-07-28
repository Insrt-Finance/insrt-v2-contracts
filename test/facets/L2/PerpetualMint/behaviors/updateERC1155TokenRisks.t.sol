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
    uint64 internal constant FAILING_RISK = 10000000000000;
    uint64 internal constant NEW_RISK = 10000;
    address internal constant NON_OWNER = address(4);
    uint256 internal PARALLEL_ALPHA_ID;
    uint256[] tokenIds;
    uint64[] risks;

    // grab PARALLEL_ALPHA collection earnings storage slot
    bytes32 internal collectionEarningsStorageSlot =
        keccak256(
            abi.encode(
                PARALLEL_ALPHA, // the ERC1155 collection
                uint256(Storage.STORAGE_SLOT) + 7 // the risk storage slot
            )
        );

    function setUp() public override {
        super.setUp();

        PARALLEL_ALPHA_ID = parallelAlphaTokenIds[0];

        depositParallelAlphaAssetsMock();

        //overwrite storage
        vm.store(
            address(perpetualMint),
            collectionEarningsStorageSlot,
            bytes32(COLLECTION_EARNINGS)
        );

        tokenIds.push(PARALLEL_ALPHA_ID);
        risks.push(NEW_RISK);
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
                        uint256(Storage.STORAGE_SLOT) + 20 // totalDepositorRisk mapping storage slot
                    )
                )
            )
        );

        vm.store(address(perpetualMint), totalDepositorRiskStorageSlot, 0);

        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(PARALLEL_ALPHA, tokenIds, risks);

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
        uint64 totalRisk = _totalRisk(address(perpetualMint), PARALLEL_ALPHA);
        uint64 totalDepositorRisk = _totalDepositorRisk(
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
        perpetualMint.updateERC1155TokenRisks(PARALLEL_ALPHA, tokenIds, risks);

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

    /// @dev tests that when updating the risk of ERC1155 tokens the active ERC1155 tokens is increased by the total amount of
    /// inactive ERC1155 tokens of that depositor across each of the updated tokenIds
    function test_updateERC1155TokenRisksIncreasesActiveTokensOfDepositorBySumOfInactiveTokensOfDepositorAcrossTokenIdsUpdated()
        public
    {
        uint64 oldActiveTokens;
        uint64 inactiveTokens;

        for (uint256 i; i < tokenIds.length; ++i) {
            oldActiveTokens += uint64(
                _activeERC1155Tokens(
                    address(perpetualMint),
                    depositorOne,
                    PARALLEL_ALPHA,
                    tokenIds[i]
                )
            );
            inactiveTokens = uint64(
                _inactiveERC1155Tokens(
                    address(perpetualMint),
                    depositorOne,
                    PARALLEL_ALPHA,
                    tokenIds[i]
                )
            );
        }

        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(PARALLEL_ALPHA, tokenIds, risks);

        uint64 newActiveTokens;
        for (uint256 i; i < tokenIds.length; ++i) {
            newActiveTokens += uint64(
                _activeERC1155Tokens(
                    address(perpetualMint),
                    depositorOne,
                    PARALLEL_ALPHA,
                    tokenIds[i]
                )
            );
        }

        assert(newActiveTokens == oldActiveTokens + inactiveTokens);
    }

    /// @dev tests that when updating the risk of a ERC1155 tokens the total depositor risk of that collection is changed
    /// by the new amount of active tokens of the depositor multiplied by the difference between the previous and new risks
    /// across each updated tokenId
    function test_updateERC1155TokenRisksChangesTotalDepositorRiskOfERC1155CollectionByTotalRiskChange()
        public
    {
        uint256 idsLength = tokenIds.length;
        uint64[] memory oldInactiveTokenAmounts = new uint64[](idsLength);
        uint64[] memory oldActiveTokenAmounts = new uint64[](idsLength);
        uint64[] memory oldDepositorTokenRisks = new uint64[](idsLength);

        for (uint256 i; i < tokenIds.length; ++i) {
            oldDepositorTokenRisks[i] = _depositorTokenRisk(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                tokenIds[i]
            );

            oldActiveTokenAmounts[i] = uint64(
                _activeERC1155Tokens(
                    address(perpetualMint),
                    depositorOne,
                    PARALLEL_ALPHA,
                    tokenIds[i]
                )
            );

            oldInactiveTokenAmounts[i] = uint64(
                _inactiveERC1155Tokens(
                    address(perpetualMint),
                    depositorOne,
                    PARALLEL_ALPHA,
                    tokenIds[i]
                )
            );
        }

        uint64 oldTotalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(PARALLEL_ALPHA, tokenIds, risks);

        uint64 firstTotalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        uint64[] memory firstActiveTokenAmounts = new uint64[](idsLength);
        uint64[] memory firstDepositorTokenRisks = new uint64[](idsLength);

        for (uint256 i; i < idsLength; ++i) {
            firstActiveTokenAmounts[i] = uint64(
                _activeERC1155Tokens(
                    address(perpetualMint),
                    depositorOne,
                    PARALLEL_ALPHA,
                    tokenIds[i]
                )
            );

            firstDepositorTokenRisks[i] = _depositorTokenRisk(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                tokenIds[i]
            );
        }

        uint64 expectedTotalRiskChange;
        for (uint256 i; i < idsLength; ++i) {
            expectedTotalRiskChange +=
                oldInactiveTokenAmounts[i] *
                risks[i] +
                oldActiveTokenAmounts[i] *
                (risks[i] - oldDepositorTokenRisks[i]);
        }
        assert(
            firstTotalDepositorRisk - oldTotalDepositorRisk ==
                expectedTotalRiskChange
        );

        risks[0] = NEW_RISK / 2;

        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(PARALLEL_ALPHA, tokenIds, risks);

        expectedTotalRiskChange = 0;

        for (uint256 i; i < idsLength; ++i) {
            expectedTotalRiskChange +=
                firstActiveTokenAmounts[i] *
                (firstDepositorTokenRisks[i] - risks[i]);
        }

        uint64 secondTotalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            PARALLEL_ALPHA
        );

        assert(
            firstTotalDepositorRisk - secondTotalDepositorRisk ==
                expectedTotalRiskChange
        );
    }

    /// @dev tests that when updating the risk of a ERC1155 tokens, the token risk of each token is changed
    /// by the amount of active tokens of the depositor multiplied by the difference between the previous and new risks
    function test_updateERC1155TokenRisksChangesTokenRiskOfERC1155CollectionByRiskChange()
        public
    {
        uint256 idsLength = tokenIds.length;
        uint64[] memory oldTokenRisks = new uint64[](idsLength);
        uint64[] memory oldInactiveTokenAmounts = new uint64[](idsLength);
        uint64[] memory oldActiveTokenAmounts = new uint64[](idsLength);
        uint64[] memory oldDepositorTokenRisks = new uint64[](idsLength);

        for (uint256 i; i < idsLength; ++i) {
            oldTokenRisks[i] = _tokenRisk(
                address(perpetualMint),
                PARALLEL_ALPHA,
                tokenIds[i]
            );

            oldActiveTokenAmounts[i] = uint64(
                _activeERC1155Tokens(
                    address(perpetualMint),
                    depositorOne,
                    PARALLEL_ALPHA,
                    tokenIds[i]
                )
            );

            oldInactiveTokenAmounts[i] = uint64(
                _inactiveERC1155Tokens(
                    address(perpetualMint),
                    depositorOne,
                    PARALLEL_ALPHA,
                    tokenIds[i]
                )
            );

            oldDepositorTokenRisks[i] = _depositorTokenRisk(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA,
                tokenIds[i]
            );
        }

        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(PARALLEL_ALPHA, tokenIds, risks);

        uint64[] memory firstTokenRisks = new uint64[](idsLength);
        uint64[] memory firstActiveTokenAmounts = new uint64[](idsLength);
        uint64[] memory firstDepositorTokenRisks = new uint64[](idsLength);

        for (uint256 i; i < idsLength; ++i) {
            firstTokenRisks[i] = _tokenRisk(
                address(perpetualMint),
                PARALLEL_ALPHA,
                tokenIds[i]
            );
            firstActiveTokenAmounts[i] = uint64(
                _activeERC1155Tokens(
                    address(perpetualMint),
                    depositorOne,
                    PARALLEL_ALPHA,
                    tokenIds[i]
                )
            );
            firstDepositorTokenRisks[i] = risks[i];
        }

        for (uint256 i; i < idsLength; ++i) {
            uint64 expectedTokenRiskChange = risks[i] *
                oldInactiveTokenAmounts[i] +
                oldActiveTokenAmounts[i] *
                (risks[i] - oldDepositorTokenRisks[i]);

            assert(
                firstTokenRisks[i] - oldTokenRisks[i] == expectedTokenRiskChange
            );
        }

        risks[0] = NEW_RISK / 2;

        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(PARALLEL_ALPHA, tokenIds, risks);

        for (uint256 i; i < idsLength; ++i) {
            _tokenRisk(address(perpetualMint), PARALLEL_ALPHA, tokenIds[i]);
            uint64 expectedTokenRiskChange = firstActiveTokenAmounts[i] *
                (firstDepositorTokenRisks[i] - risks[i]);

            assert(
                firstTokenRisks[i] -
                    _tokenRisk(
                        address(perpetualMint),
                        PARALLEL_ALPHA,
                        tokenIds[i]
                    ) ==
                    expectedTokenRiskChange
            );
        }
    }

    /// @dev tests that when updating the token risk of ERC1155 tokens the depositor token risk of
    /// that token is set to the new risk
    function test_updateERC1155TokenRisksSetsDepositorTokenRiskOfERC155CollectionToNewRisk()
        public
    {
        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(PARALLEL_ALPHA, tokenIds, risks);

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

    /// @dev test that updateERC721TokenRisks reverts if the collection is an ERC1155 collection
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
        vm.expectRevert(
            IPerpetualMintInternal.TokenIdsAndRisksMismatch.selector
        );
        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(PARALLEL_ALPHA, tokenIds, risks);
    }

    /// @dev test that updateERC1155TokenRisks reverts if the risk to be set is larger than the BASIS
    function test_updateERC155TokenRisksRevertsWhen_RiskExceedsBasis() public {
        risks[0] = FAILING_RISK;
        vm.expectRevert(IPerpetualMintInternal.BasisExceeded.selector);
        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(PARALLEL_ALPHA, tokenIds, risks);
    }

    /// @dev test that updateERC1155TokenRisks reverts if the risk to be set is 0
    function test_updateERC1155TokenRisksRevertsWhen_RiskIsSetToZero() public {
        risks[0] = 0;
        vm.expectRevert(IPerpetualMintInternal.TokenRiskMustBeNonZero.selector);
        vm.prank(depositorOne);
        perpetualMint.updateERC1155TokenRisks(PARALLEL_ALPHA, tokenIds, risks);
    }

    /// @dev test that updateERC1155TokenRisks reverts if the caller does not belong to the escrowed1155Owners EnumerableSet
    function test_updateERC1155TokenRisksRevertsWhen_CollectionIsERC1155AndCallerIsNotInEscrowedERC1155Owners()
        public
    {
        vm.expectRevert(IPerpetualMintInternal.OnlyEscrowedTokenOwner.selector);
        vm.prank(NON_OWNER);
        perpetualMint.updateERC1155TokenRisks(PARALLEL_ALPHA, tokenIds, risks);
    }
}
