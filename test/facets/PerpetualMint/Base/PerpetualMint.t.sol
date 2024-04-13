// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";

import { PerpetualMintHelper_Base } from "./PerpetualMintHelper.t.sol";
import { IPerpetualMintTest } from "../IPerpetualMintTest.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";
import { CoreTest } from "../../../diamonds/Core/Core.t.sol";
import { MintTokenTiersData, TiersData } from "../../../../contracts/facets/PerpetualMint/Storage.sol";
import { IDepositContract } from "../../../../contracts/vrf/Supra/IDepositContract.sol";
import { ISupraRouterContract } from "../../../../contracts/vrf/Supra/ISupraRouterContract.sol";

/// @title PerpetualMintTest_Base
/// @dev PerpetualMintTest Base-specific, Supra VRF-specific helper contract. Configures PerpetualMint facets for Core test.
/// @dev Should function identically across all forks.
abstract contract PerpetualMintTest_Base is CoreTest, PerpetualMintTest {
    IDepositContract internal supraVRFDepositContract;

    ISupraRouterContract internal supraRouterContract;

    PerpetualMintHelper_Base public perpetualMintHelper_Base;

    uint64 internal constant TEST_VRF_NUMBER_OF_CONFIRMATIONS = 1;

    /// @dev the VRF request function signature
    string internal constant VRF_REQUEST_FUNCTION_SIGNATURE =
        "rawFulfillRandomWords(uint256,uint256[])";

    address internal supraVRFDepositContractOwner;

    /// @dev sets up PerpetualMint for testing
    function setUp() public virtual override(CoreTest, PerpetualMintTest) {
        CoreTest.setUp();

        initPerpetualMint();

        perpetualMint = IPerpetualMintTest(address(coreDiamond));

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

        // sets the mint earnings buffer
        perpetualMint.setMintEarningsBufferBP(TEST_MINT_EARNINGS_BUFFER_BP);

        // sets the mint fee
        perpetualMint.setMintFeeBP(TEST_MINT_FEE_BP);

        // sets the mint for ETH consolation fee
        perpetualMint.setMintForEthConsolationFeeBP(
            TEST_MINT_FOR_ETH_CONSOLATION_FEE_BP
        );

        // sets the mint for $MINT consolation fee
        perpetualMint.setMintTokenConsolationFeeBP(
            TEST_MINT_TOKEN_CONSOLATION_FEE_BP
        );

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

        assert(TEST_MINT_FEE_BP == perpetualMint.mintFeeBP());

        assert(
            TEST_MINT_TOKEN_CONSOLATION_FEE_BP ==
                perpetualMint.mintTokenConsolationFeeBP()
        );

        supraRouterContract = ISupraRouterContract(
            this.perpetualMintHelper_Base().VRF_ROUTER()
        );

        supraVRFDepositContract = IDepositContract(
            supraRouterContract._depositContract()
        );

        supraVRFDepositContractOwner = ISolidStateDiamond(
            payable(address(supraVRFDepositContract))
        ).owner();

        _activateVRF();
    }

    /// @dev initializes PerpetualMint facets by executing a diamond cut on the Core Diamond.
    function initPerpetualMint() internal override {
        perpetualMintHelper_Base = new PerpetualMintHelper_Base();

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = perpetualMintHelper_Base.getFacetCuts();

        coreDiamond.diamondCut(facetCuts, address(0), "");
    }

    /// @dev Helper function to activate Supra VRF by adding the contract and client to the Supra VRF Deposit Contract whitelist and depositing funds.
    function _activateVRF() private {
        vm.prank(supraVRFDepositContractOwner);
        supraVRFDepositContract.addClientToWhitelist(address(this), true);

        supraVRFDepositContract.addContractToWhitelist(address(perpetualMint));

        supraVRFDepositContract.depositFundClient{ value: 10 ether }();
    }
}
