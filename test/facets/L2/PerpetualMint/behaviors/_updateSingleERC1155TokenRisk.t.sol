// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";

/// @title PerpetualMint_updateSingleERC1155TokenRisk
/// @dev PerpetualMint test contract for testing expected behavior of the _updateSingleERC1155TokenRisk function
contract PerpetualMint_updateSingleERC1155TokenRisk is
    IPerpetualMintInternal,
    PerpetualMintTest,
    L2ForkTest
{
    uint256 internal constant COLLECTION_EARNINGS = 1 ether;
    uint256 internal constant FAILING_RISK = 10000000000000;
    uint256 internal constant NEW_RISK = 10000;
    address internal constant NON_OWNER = address(4);
    uint256 internal PARALLEL_ALPHA_ID;
    uint256 tokenId;
    uint256 amountToIdle;
    uint256 risk;

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

        amountToIdle = _activeERC1155Tokens(
            address(perpetualMint),
            depositorOne,
            COLLECTION,
            PARALLEL_ALPHA_ID
        );

        tokenId = PARALLEL_ALPHA_ID;
        risk = NEW_RISK;

        // overwrite storage
        // must be done after idling to not be checking trivial state changes
        vm.store(
            address(perpetualMint),
            collectionEarningsStorageSlot,
            bytes32(COLLECTION_EARNINGS)
        );
    }

    /// @dev tests that when updating the risk of a ERC1155 tokens the total depositor risk of that collection is changed
    /// correctly when overall risk increases and new risk value is larger
    function test_updateSingleERC1155TokenRiskChangesTotalDepositorRiskByTotalRiskChangeWhenNewRiskIsLargerThenOldRisk()
        public
    {
        uint256 oldDepositorTokenRisk = _depositorTokenRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION,
            tokenId
        );

        uint256 oldActiveTokenAmount = _activeERC1155Tokens(
            address(perpetualMint),
            depositorOne,
            COLLECTION,
            tokenId
        );

        uint256 oldTotalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        vm.prank(depositorOne);
        perpetualMint.exposed_updateSingleERC1155TokenRisk(
            depositorOne,
            COLLECTION,
            tokenId,
            risk
        );

        uint256 newTotalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        uint256 expectedTotalRiskChange = oldActiveTokenAmount *
            (risk - oldDepositorTokenRisk);

        assert(
            newTotalDepositorRisk - oldTotalDepositorRisk ==
                expectedTotalRiskChange
        );
    }

    /// @dev tests that when updating the risk of a ERC1155 tokens the total depositor risk of that collection is changed
    /// correctly when overall risk change is negative and new risk value is smaller
    function test_updateSingleERC1155TokenRiskChangesTotalDepositorRiskByTotalRiskChangeWhenNewRiskIsSmallerThanOldRisk()
        public
    {
        // pick a value which is smaller than current risk and overall decreases risk
        risk =
            (_depositorTokenRisk(
                address(perpetualMint),
                depositorOne,
                COLLECTION,
                PARALLEL_ALPHA_ID
            ) * 3) /
            10;

        uint256 oldDepositorTokenRisk = _depositorTokenRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION,
            tokenId
        );

        uint256 oldActiveTokenAmount = _activeERC1155Tokens(
            address(perpetualMint),
            depositorOne,
            COLLECTION,
            tokenId
        );

        uint256 oldTotalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        vm.prank(depositorOne);
        perpetualMint.exposed_updateSingleERC1155TokenRisk(
            depositorOne,
            COLLECTION,
            tokenId,
            risk
        );

        uint256 newTotalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        // this only works because of the chosen value of risk with a given pre-state
        // could be made more general in future
        uint256 expectedTotalRiskChange = oldActiveTokenAmount *
            (oldDepositorTokenRisk - risk);

        assert(
            oldTotalDepositorRisk - newTotalDepositorRisk ==
                expectedTotalRiskChange
        );
    }

    /// @dev tests that when updating the risk of a ERC1155 token, the token risk is changed
    /// correctly when overall risk change is positive and new risk is larger
    function test_updateSingleERC1155TokenRiskChangesTokenRiskByRiskChangeWhenNewRiskIsLargerThanOldRisk()
        public
    {
        uint256 oldTokenRisks = _tokenRisk(
            address(perpetualMint),
            COLLECTION,
            tokenId
        );

        uint256 oldActiveTokenAmount = _activeERC1155Tokens(
            address(perpetualMint),
            depositorOne,
            COLLECTION,
            tokenId
        );

        uint256 oldDepositorTokenRisk = _depositorTokenRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION,
            tokenId
        );

        vm.prank(depositorOne);
        perpetualMint.exposed_updateSingleERC1155TokenRisk(
            depositorOne,
            COLLECTION,
            tokenId,
            risk
        );

        uint256 newTokenRisk = _tokenRisk(
            address(perpetualMint),
            COLLECTION,
            tokenId
        );

        uint256 expectedTokenRiskChange = oldActiveTokenAmount *
            (risk - oldDepositorTokenRisk);

        assert(newTokenRisk - oldTokenRisks == expectedTokenRiskChange);
    }

    /// @dev tests that when updating the risk of a ERC1155 tokens, the token risk is changed
    /// correctly when overall risk change is negative and new risk is smaller
    function test_updateSingleERC1155TokenRiskChangesTokenRiskByRiskChangeWhenNewRiskIsSmallerThanOldRisk()
        public
    {
        // pick a value which is smaller than current risk and overall decreases risk
        risk =
            (_depositorTokenRisk(
                address(perpetualMint),
                depositorOne,
                COLLECTION,
                PARALLEL_ALPHA_ID
            ) * 3) /
            10;

        uint256 oldTokenRisk = _tokenRisk(
            address(perpetualMint),
            COLLECTION,
            tokenId
        );

        uint256 oldActiveTokenAmount = _activeERC1155Tokens(
            address(perpetualMint),
            depositorOne,
            COLLECTION,
            tokenId
        );

        uint256 oldDepositorTokenRisk = _depositorTokenRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION,
            tokenId
        );

        vm.prank(depositorOne);
        perpetualMint.exposed_updateSingleERC1155TokenRisk(
            depositorOne,
            COLLECTION,
            tokenId,
            risk
        );

        uint256 newTokenRisk = _tokenRisk(
            address(perpetualMint),
            COLLECTION,
            tokenId
        );

        uint256 expectedTokenRiskChange = (oldDepositorTokenRisk - risk) *
            oldActiveTokenAmount;

        assert(oldTokenRisk - newTokenRisk == expectedTokenRiskChange);
    }

    /// @dev tests that when updating the token risk of ERC1155 tokens the depositor token risk of
    /// that token is set to the new risk
    function test_updateSingleERC1155TokenRiskSetsDepositorTokenRiskToNewRisk()
        public
    {
        vm.prank(depositorOne);
        perpetualMint.exposed_updateSingleERC1155TokenRisk(
            depositorOne,
            COLLECTION,
            tokenId,
            risk
        );

        assert(
            risk ==
                _depositorTokenRisk(
                    address(perpetualMint),
                    depositorOne,
                    COLLECTION,
                    tokenId
                )
        );
    }

    /// @dev test that updateSingleERC1155TokenRisk reverts if the risk to be set is larger than the BASIS
    function test_updateSingleERC1155TokenRiskRevertsWhen_RiskExceedsBasis()
        public
    {
        risk = FAILING_RISK;
        vm.expectRevert(IPerpetualMintInternal.BasisExceeded.selector);
        vm.prank(depositorOne);
        perpetualMint.exposed_updateSingleERC1155TokenRisk(
            depositorOne,
            COLLECTION,
            tokenId,
            risk
        );
    }

    /// @dev test that updateSingleERC1155TokenRisk reverts if the risk to be set is 0
    function test_updateSingleERC1155TokenRiskRevertsWhen_RiskIsSetToZero()
        public
    {
        risk = 0;
        vm.expectRevert(IPerpetualMintInternal.TokenRiskMustBeNonZero.selector);
        vm.prank(depositorOne);
        perpetualMint.exposed_updateSingleERC1155TokenRisk(
            depositorOne,
            COLLECTION,
            tokenId,
            risk
        );
    }

    /// @dev test that updateSingleERC1155TokenRisk reverts if the caller does not have active ERC1155 tokens in that tokenId for the COLLECTION
    function test_updateSingleERC1155TokenRiskRevertsWhen_DoesNotHaveActiveERC1155TokensInCollection()
        public
    {
        vm.expectRevert(IPerpetualMintInternal.OwnerInactive.selector);
        vm.prank(NON_OWNER);
        perpetualMint.exposed_updateSingleERC1155TokenRisk(
            NON_OWNER,
            COLLECTION,
            tokenId,
            risk
        );
    }

    /// @dev test that updateSingleERC1155TokenRisk reverts if the caller is attempting to set the same risk as the previous risk
    function test_updateSingleERC1155TokenRiskRevertsWhen_NewRiskIsSameAsOldRisk()
        public
    {
        risk = _depositorTokenRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION,
            PARALLEL_ALPHA_ID
        );
        vm.expectRevert(IPerpetualMintInternal.IdenticalRisk.selector);
        vm.prank(depositorOne);
        perpetualMint.exposed_updateSingleERC1155TokenRisk(
            depositorOne,
            COLLECTION,
            tokenId,
            risk
        );
    }
}
