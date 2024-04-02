// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { CoreTest } from "../diamonds/Core/Core.t.sol";
import { IPerpetualMintTest } from "../facets/PerpetualMint/IPerpetualMintTest.sol";
import { PerpetualMintTest } from "../facets/PerpetualMint/PerpetualMint.t.sol";
import { PerpetualMintHelper } from "../facets/PerpetualMint/PerpetualMintHelper.t.sol";
import { ICore } from "../../contracts/diamonds/Core/ICore.sol";
import { MintTokenTiersData, TiersData, VRFConfig } from "../../contracts/facets/PerpetualMint/Storage.sol";
import { IInsrtVRFCoordinator } from "../../contracts/vrf/Insrt/IInsrtVRFCoordinator.sol";

/// @title PerpetualMintTest_InsrtVRFCoordinator
/// @dev PerpetualMintTest InsrtVRFCoordinator-specific helper contract. Configures PerpetualMint facets for Core testing using the Insrt VRF Coordinator.
/// @dev Should function identically across all forks where the Insrt VRF Coordinator is deployed & configured.
abstract contract PerpetualMintTest_InsrtVRFCoordinator is
    CoreTest,
    PerpetualMintTest
{
    /// @dev sets up PerpetualMint for testing
    function setUp() public virtual override(CoreTest, PerpetualMintTest) {
        CoreTest.setUp();

        initPerpetualMint();

        perpetualMint = IPerpetualMintTest(address(coreDiamond));

        address vrfCoordinator = this.perpetualMintHelper().VRF_COORDINATOR();

        vm.prank(address(this.perpetualMintHelper()));
        IInsrtVRFCoordinator(vrfCoordinator).addConsumer(
            TEST_VRF_SUBSCRIPTION_ID,
            address(perpetualMint)
        );

        perpetualMint.setVRFConfig(
            VRFConfig({
                // Arbitrum 150 GWEI keyhash
                keyHash: bytes32(
                    0x68d24f9a037a649944964c2a1ebd0b2918f4a243d2a99701cc22b548cf2daff0
                ),
                // Initiated Subscription ID
                subscriptionId: TEST_VRF_SUBSCRIPTION_ID,
                // Max Callback Gas Limit
                callbackGasLimit: uint32(2500000),
                // Minimum confimations:
                minConfirmations: uint16(5)
            })
        );

        // mints 100 ETH to minter
        vm.deal(minter, 100 ether);

        perpetualMint.setCollectionReferralFeeBP(
            BORED_APE_YACHT_CLUB,
            baycCollectionReferralFeeBP
        );

        perpetualMint.setCollectionRisk(
            BORED_APE_YACHT_CLUB,
            baycCollectionRisk
        );

        perpetualMint.setCollectionRisk(
            PARALLEL_ALPHA,
            parallelAlphaCollectionRisk
        );

        perpetualMint.setCollectionMintPrice(BORED_APE_YACHT_CLUB, MINT_PRICE);

        perpetualMint.setCollectionMintPrice(PARALLEL_ALPHA, MINT_PRICE);

        // sets the mint for collection consolation fee
        perpetualMint.setCollectionConsolationFeeBP(
            TEST_COLLECTION_CONSOLATION_FEE_BP
        );

        // sets the default mint referral fee for collections
        perpetualMint.setDefaultCollectionReferralFeeBP(
            TEST_DEFAULT_COLLECTION_REFERRAL_FEE_BP
        );

        // sets the mint for $MINT consolation fee
        perpetualMint.setMintTokenConsolationFeeBP(
            TEST_MINT_TOKEN_CONSOLATION_FEE_BP
        );

        // sets the mint fee
        perpetualMint.setMintFeeBP(TEST_MINT_FEE_BP);

        uint256[] memory tierMultipliers = new uint256[](testNumberOfTiers);
        uint32[] memory tierRisks = new uint32[](testNumberOfTiers);

        // exponentially decreasing probabilities, from highest to lowest
        uint32[testNumberOfTiers] memory testRisks = [
            600000000, // 60%
            250000000, // 25%
            100000000, // 10%
            40000000, // 4%
            10000000 // 1%
        ];

        uint256 initialMultiplier = firstTierMultiplier;

        for (uint8 i = 0; i < testNumberOfTiers; ++i) {
            tierMultipliers[i] = initialMultiplier;

            initialMultiplier *= 2; // double the multiplier for each tier

            tierRisks[i] = testRisks[i];
        }

        // for testing, use the same tiers for mint for $MINT and mint for collection consolation tiers
        testMintTokenTiersData = MintTokenTiersData({
            tierMultipliers: tierMultipliers,
            tierRisks: tierRisks
        });

        testTiersData = TiersData({
            tierMultipliers: tierMultipliers,
            tierRisks: tierRisks
        });

        perpetualMint.setMintTokenTiers(testMintTokenTiersData);

        perpetualMint.setTiers(testTiersData);

        TEST_ADJUSTMENT_FACTOR = perpetualMint.BASIS();

        assert(
            baycCollectionRisk ==
                perpetualMint.collectionRisk(BORED_APE_YACHT_CLUB)
        );

        assert(
            MINT_PRICE ==
                perpetualMint.collectionMintPrice(BORED_APE_YACHT_CLUB)
        );

        assert(MINT_PRICE == perpetualMint.collectionMintPrice(PARALLEL_ALPHA));

        assert(
            parallelAlphaCollectionRisk ==
                perpetualMint.collectionRisk(PARALLEL_ALPHA)
        );

        assert(
            TEST_COLLECTION_CONSOLATION_FEE_BP ==
                perpetualMint.collectionConsolationFeeBP()
        );

        assert(
            TEST_DEFAULT_COLLECTION_REFERRAL_FEE_BP ==
                perpetualMint.defaultCollectionReferralFeeBP()
        );

        assert(TEST_MINT_FEE_BP == perpetualMint.mintFeeBP());

        assert(
            TEST_MINT_TOKEN_CONSOLATION_FEE_BP ==
                perpetualMint.mintTokenConsolationFeeBP()
        );
    }

    /// @dev initializes PerpetualMint facets by executing a diamond cut on the Core Diamond.
    function initPerpetualMint() internal override {
        perpetualMintHelper = new PerpetualMintHelper(true);

        ICore.FacetCut[] memory perpetualMintTestFacetCuts = perpetualMintHelper
            .getPerpetualMintTestFacetCuts();

        ICore.FacetCut[]
            memory perpetualMintAdminTestFacetCuts = perpetualMintHelper
                .getPerpetualMintAdminTestFacetCuts();

        ICore.FacetCut[]
            memory perpetualMintBaseTestFacetCuts = perpetualMintHelper
                .getPerpetualMintBaseTestFacetCuts();

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](9);

        facetCuts[0] = perpetualMintTestFacetCuts[0];
        facetCuts[1] = perpetualMintTestFacetCuts[1];
        facetCuts[2] = perpetualMintTestFacetCuts[2];
        facetCuts[3] = perpetualMintTestFacetCuts[3];
        facetCuts[4] = perpetualMintAdminTestFacetCuts[0];
        facetCuts[5] = perpetualMintBaseTestFacetCuts[0];
        facetCuts[6] = perpetualMintBaseTestFacetCuts[1];
        facetCuts[7] = perpetualMintBaseTestFacetCuts[2];
        facetCuts[8] = perpetualMintBaseTestFacetCuts[3];

        coreDiamond.diamondCut(facetCuts, address(0), "");
    }
}
