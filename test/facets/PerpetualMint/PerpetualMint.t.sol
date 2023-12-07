// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";

import { PerpetualMintHelper } from "./PerpetualMintHelper.t.sol";
import { IPerpetualMintTest } from "./IPerpetualMintTest.sol";
import { CoreTest } from "../../diamonds/Core.t.sol";
import { MintTokenTiersData, PerpetualMintStorage as Storage, TiersData, VRFConfig } from "../../../contracts/facets/PerpetualMint/Storage.sol";

/// @title PerpetualMintTest
/// @dev PerpetualMintTest helper contract. Configures PerpetualMint as facets of Core test.
/// @dev Should function identically across all forks given appropriate Chainlink VRF details are set.
abstract contract PerpetualMintTest is CoreTest {
    IPerpetualMintTest public perpetualMint;

    PerpetualMintHelper public perpetualMintHelper;

    MintTokenTiersData internal testMintTokenTiersData;

    TiersData internal testTiersData;

    /// @dev number of tiers
    uint8 internal constant testNumberOfTiers = 5;

    /// @dev mint for collection consolation fee basis points to test
    uint32 internal constant TEST_COLLECTION_CONSOLATION_FEE_BP = 5000000; // 0.5% fee

    uint32 internal constant TEST_COLLECTION_MINT_FEE_DISTRIBUTION_RATIO_BP =
        5e8; // 50%

    uint32 internal constant TEST_MINT_FEE_BP = 5000000; // 0.5% fee

    /// @dev mint for $MINT consolation fee basis points to test
    uint32 internal constant TEST_MINT_TOKEN_CONSOLATION_FEE_BP = 5000000; // 0.5% fee

    uint64 internal constant TEST_VRF_SUBSCRIPTION_ID = 5;

    /// @dev first tier multiplier (lowest multiplier)
    uint256 internal constant firstTierMultiplier = 1e9; // 1x multiplier

    // Ethereum mainnet Bored Ape Yacht Club contract address.
    address internal constant BORED_APE_YACHT_CLUB =
        0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;

    // Ethereum mainnet Parallel Alpha contract address.
    address internal constant PARALLEL_ALPHA =
        0x76BE3b62873462d2142405439777e971754E8E77;

    // realistic mint price in ETH given mint price of 50USD and ETH price 1850USD
    uint256 MINT_PRICE = 0.027 ether;

    // minter
    address payable internal minter = payable(address(3));

    address internal PERPETUAL_MINT_NON_OWNER = address(100);

    // collection risk values
    uint32 internal constant baycCollectionRisk = 100000; // 0.01%

    uint32 internal constant parallelAlphaCollectionRisk = 10000000; // 1%

    /// @dev sets up PerpetualMint for testing
    function setUp() public virtual override {
        super.setUp();

        initPerpetualMint();

        perpetualMint = IPerpetualMintTest(address(coreDiamond));

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

        assert(TEST_MINT_FEE_BP == perpetualMint.mintFeeBP());

        assert(
            TEST_MINT_TOKEN_CONSOLATION_FEE_BP ==
                perpetualMint.mintTokenConsolationFeeBP()
        );
    }

    /// @dev initializes PerpetualMint facets by executing a diamond cut on the Core Diamond.
    function initPerpetualMint() internal {
        perpetualMintHelper = new PerpetualMintHelper();

        ISolidStateDiamond.FacetCut[]
            memory perpetualMintBaseTestFacetCuts = perpetualMintHelper
                .getPerpetualMintBaseTestFacetCuts();

        ISolidStateDiamond.FacetCut[]
            memory perpetualMintTestFacetCuts = perpetualMintHelper
                .getPerpetualMintTestFacetCuts();

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](8);

        facetCuts[0] = perpetualMintBaseTestFacetCuts[0];
        facetCuts[1] = perpetualMintBaseTestFacetCuts[1];
        facetCuts[2] = perpetualMintTestFacetCuts[0];
        facetCuts[3] = perpetualMintTestFacetCuts[1];
        facetCuts[4] = perpetualMintTestFacetCuts[2];
        facetCuts[5] = perpetualMintTestFacetCuts[3];
        facetCuts[6] = perpetualMintTestFacetCuts[4];
        facetCuts[7] = perpetualMintTestFacetCuts[5];

        coreDiamond.diamondCut(facetCuts, address(0), "");
    }

    /// @dev mocks unsuccessful attemptBatchMintForMintWithEth attempts to increase accrued
    /// mint earnings, mint for $MINT consolation fees, & protocol fees by the number of unsuccessful mints
    /// @param numberOfMints number of unsuccessful mint attempts
    function mock_unsuccessfulMintForMintWithEthAttempts(
        uint32 numberOfMints
    ) internal {
        // for now, mints for $MINT are treated as address(0) collections
        address collection = address(0);

        uint256 mockMsgValue = perpetualMint.collectionMintPrice(collection) *
            numberOfMints;

        uint256 mockMintTokenConsolationFee = (mockMsgValue *
            perpetualMint.mintTokenConsolationFeeBP()) / perpetualMint.BASIS();

        perpetualMint.setConsolationFees(
            perpetualMint.accruedConsolationFees() + mockMintTokenConsolationFee
        );

        perpetualMint.setProtocolFees(
            perpetualMint.accruedProtocolFees() +
                mockMsgValue -
                mockMintTokenConsolationFee
        );
    }

    /// @dev mocks unsuccessful attemptBatchMintWithEth attempts to increase accrued
    /// mint earnings, mint for collection consolation fees, & protocol fees by the number of unsuccessful mints
    /// @param collection address of collection
    /// @param numberOfMints number of unsuccessful mint attempts
    function mock_unsuccessfulMintForCollectionWithEthAttempts(
        address collection,
        uint32 numberOfMints
    ) internal {
        uint256 mockMsgValue = perpetualMint.collectionMintPrice(collection) *
            numberOfMints;

        uint256 mockCollectionConsolationFee = (mockMsgValue *
            perpetualMint.collectionConsolationFeeBP()) / perpetualMint.BASIS();

        uint256 mockMintFee = (mockMsgValue * perpetualMint.mintFeeBP()) /
            perpetualMint.BASIS();

        perpetualMint.setConsolationFees(
            perpetualMint.accruedConsolationFees() +
                mockCollectionConsolationFee
        );

        perpetualMint.setMintEarnings(
            perpetualMint.accruedMintEarnings() +
                mockMsgValue -
                mockCollectionConsolationFee -
                mockMintFee
        );

        perpetualMint.setProtocolFees(
            perpetualMint.accruedProtocolFees() + mockMintFee
        );
    }
}
