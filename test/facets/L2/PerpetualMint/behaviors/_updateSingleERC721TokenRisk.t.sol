// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { IPerpetualMintInternal } from "../../../../../contracts/facets/L2/PerpetualMint/IPerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";

/// @title PerpetualMint_updateSingleERC721TokenRisk
/// @dev PerpetualMint test contract for testing expected behavior of the updateSingleERC721TokenRisk function
contract PerpetualMint_updateSingleERC721TokenRisk is
    IPerpetualMintInternal,
    PerpetualMintTest,
    L2ForkTest
{
    uint256 internal constant COLLECTION_EARNINGS = 1 ether;
    uint256 internal constant FAILING_RISK = 10000000000000;
    uint256 internal constant NEW_RISK = 10000;
    address internal constant NON_OWNER = address(4);
    uint256 internal BAYC_ID;
    uint256 tokenId;
    uint256 risk;

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

        tokenId = BAYC_ID;
        risk = NEW_RISK;
    }

    /// @dev tests that the token risk of an ERC721 collection is updated to the new token risk
    function test_updateSingleERC721TokenRiskSetsTheTokenRiskToNewRisk()
        public
    {
        vm.prank(depositorOne);
        perpetualMint.exposed_updateSingleERC721TokenRisk(
            depositorOne,
            COLLECTION,
            tokenId,
            risk
        );

        assert(risk == _tokenRisk(address(perpetualMint), COLLECTION, tokenId));
    }

    /// @dev tests that total risk of an ERC721 collection is increased or decreased depending on whether new risk
    /// set for the token is larger or smaller than previous risk
    function test_updateSingleERC721TokenRiskChangesTotalRiskByRiskChange()
        public
    {
        uint256 oldTotalRisk = _totalRisk(address(perpetualMint), COLLECTION);
        uint256 oldTokenRisk = _tokenRisk(
            address(perpetualMint),
            COLLECTION,
            tokenId
        );

        vm.prank(depositorOne);
        perpetualMint.exposed_updateSingleERC721TokenRisk(
            depositorOne,
            COLLECTION,
            tokenId,
            risk
        );

        uint256 firstTotalRisk = _totalRisk(address(perpetualMint), COLLECTION);

        assert(firstTotalRisk - oldTotalRisk == risk - oldTokenRisk);

        oldTokenRisk = _tokenRisk(address(perpetualMint), COLLECTION, tokenId);

        risk = 10;

        vm.prank(depositorOne);
        perpetualMint.exposed_updateSingleERC721TokenRisk(
            depositorOne,
            COLLECTION,
            tokenId,
            risk
        );

        uint256 secondTotalRisk = _totalRisk(
            address(perpetualMint),
            COLLECTION
        );

        assert(secondTotalRisk < firstTotalRisk);
        assert(firstTotalRisk - secondTotalRisk == oldTokenRisk - risk);
    }

    /// @dev tests that total depositor risk of an ERC721 collection is increased or decreased depending on whether new risk
    /// set for the token is larger or smaller than previous risk
    function test_updateSingleERC721TokenRiskChangesTotalDepositorRiskByRiskChange()
        public
    {
        uint256 oldTokenRisk = _tokenRisk(
            address(perpetualMint),
            COLLECTION,
            tokenId
        );
        uint256 oldDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        vm.prank(depositorOne);
        perpetualMint.exposed_updateSingleERC721TokenRisk(
            depositorOne,
            COLLECTION,
            tokenId,
            risk
        );

        uint256 firstDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        assert(firstDepositorRisk - oldDepositorRisk == risk - oldTokenRisk);

        oldTokenRisk = _tokenRisk(address(perpetualMint), COLLECTION, tokenId);
        risk = 10;

        vm.prank(depositorOne);
        perpetualMint.exposed_updateSingleERC721TokenRisk(
            depositorOne,
            COLLECTION,
            tokenId,
            risk
        );

        uint256 secondDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorOne,
            COLLECTION
        );

        assert(secondDepositorRisk < firstDepositorRisk);
        assert(firstDepositorRisk - secondDepositorRisk == oldTokenRisk - risk);
    }

    /// @dev test that updateSingleERC721TokenRisk reverts if the risk to be set is larger than the BASIS
    function test_updateSingleERC721TokenRiskRevertsWhen_RiskExceedsBasis()
        public
    {
        risk = FAILING_RISK;
        vm.expectRevert(IPerpetualMintInternal.BasisExceeded.selector);
        vm.prank(depositorOne);
        perpetualMint.exposed_updateSingleERC721TokenRisk(
            depositorOne,
            COLLECTION,
            tokenId,
            risk
        );
    }

    /// @dev test that updateSingleERC721TokenRisk reverts if the risk to be set is 0
    function test_updateSingleERC721TokenRiskRevertsWhen_RiskIsSetToZero()
        public
    {
        risk = 0;
        vm.expectRevert(IPerpetualMintInternal.TokenRiskMustBeNonZero.selector);
        vm.prank(depositorOne);
        perpetualMint.exposed_updateSingleERC721TokenRisk(
            depositorOne,
            COLLECTION,
            tokenId,
            risk
        );
    }

    /// @dev test that updateSingleERC721TokenRisk reverts if the caller is not the escrowedERC721Owner
    function test_updateSingleERC721TokenRiskRevertsWhen_CallerIsNotEscrowedERC721Owner()
        public
    {
        vm.expectRevert(IPerpetualMintInternal.OnlyEscrowedTokenOwner.selector);
        vm.prank(NON_OWNER);
        perpetualMint.exposed_updateSingleERC721TokenRisk(
            NON_OWNER,
            COLLECTION,
            tokenId,
            risk
        );
    }
}
