// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { IOwnable } from "@solidstate/contracts/access/ownable/IOwnable.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";

import { PerpetualMintHelperBase } from "./PerpetualMintHelper.t.sol";
import { IPerpetualMintTest } from "../IPerpetualMintTest.sol";
import { CoreTest } from "../../../diamonds/Core.t.sol";
import { IDepositContract } from "../../../interfaces/IDepositContract.sol";
import { PerpetualMintStorage as Storage, TiersData } from "../../../../contracts/facets/PerpetualMint/Storage.sol";
import { ISupraRouterContract } from "../../../../contracts/facets/PerpetualMint/Base/ISupraRouterContract.sol";

/// @title PerpetualMintTestBase
/// @dev PerpetualMintTest Base-specific helper contract. Configures PerpetualMint as facets of Core test.
/// @dev Should function identically across all forks.
abstract contract PerpetualMintTestBase is CoreTest {
    IDepositContract internal supraVRFDepositContract;

    IPerpetualMintTest public perpetualMint;

    ISupraRouterContract internal supraRouterContract;

    PerpetualMintHelperBase public perpetualMintHelper;

    TiersData internal testTiersData;

    /// @dev number of tiers
    uint8 internal constant testNumberOfTiers = 5;

    uint32 internal constant TEST_CONSOLATION_FEE_BP = 5000000; // 0.5% fee

    uint32 internal constant TEST_MINT_FEE_BP = 5000000; // 0.5% fee

    uint64 internal constant TEST_VRF_NUMBER_OF_CONFIRMATIONS = 1;

    /// @dev first tier multiplier (lowest multiplier)
    uint256 internal constant firstTierMultiplier = 1; // 1x multiplier

    /// @dev the VRF request function signature
    string internal constant VRF_REQUEST_FUNCTION_SIGNATURE =
        "rawFulfillRandomWords(uint256,uint256[])";

    address internal supraVRFDepositContractOwner;

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

        // sets the consolation fee
        perpetualMint.setConsolationFeeBP(TEST_CONSOLATION_FEE_BP);

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

        testTiersData = TiersData({
            tierMultipliers: tierMultipliers,
            tierRisks: tierRisks
        });

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

        assert(TEST_CONSOLATION_FEE_BP == perpetualMint.consolationFeeBP());

        assert(TEST_MINT_FEE_BP == perpetualMint.mintFeeBP());

        supraRouterContract = ISupraRouterContract(
            this.perpetualMintHelper().VRF_ROUTER()
        );

        supraVRFDepositContract = IDepositContract(
            supraRouterContract._depositContract()
        );

        supraVRFDepositContractOwner = IOwnable(
            address(supraVRFDepositContract)
        ).owner();

        _activateVRF();
    }

    /// @dev initializes PerpetualMint as a facet by executing a diamond cut on coreDiamond.
    function initPerpetualMint() internal {
        perpetualMintHelper = new PerpetualMintHelperBase();

        ISolidStateDiamond.FacetCut[] memory facetCuts = perpetualMintHelper
            .getFacetCuts();

        coreDiamond.diamondCut(facetCuts, address(0), "");
    }

    /// @dev mocks unsuccessful attemptBatchMintWithEth attempts to increase accrued
    /// mint earnings, consolation fees, & protocol fees by the number of unsuccessful mints
    /// @param collection address of collection
    /// @param numberOfMints number of unsuccessful mint attempts
    function mock_unsuccessfulMintWithEthAttempts(
        address collection,
        uint32 numberOfMints
    ) internal {
        uint256 mockMsgValue = perpetualMint.collectionMintPrice(collection) *
            numberOfMints;

        uint256 mockConsolationFee = (mockMsgValue *
            perpetualMint.consolationFeeBP()) / perpetualMint.BASIS();

        uint256 mockMintFee = (mockMsgValue * perpetualMint.mintFeeBP()) /
            perpetualMint.BASIS();

        perpetualMint.setConsolationFees(
            perpetualMint.accruedConsolationFees() + mockConsolationFee
        );

        perpetualMint.setMintEarnings(
            perpetualMint.accruedMintEarnings() +
                mockMsgValue -
                mockConsolationFee -
                mockMintFee
        );

        perpetualMint.setProtocolFees(
            perpetualMint.accruedProtocolFees() + mockMintFee
        );
    }

    /// @dev Helper function to activate Supra VRF by adding the contract and client to the Supra VRF Deposit Contract whitelist and depositing funds.
    function _activateVRF() private {
        vm.prank(supraVRFDepositContractOwner);
        supraVRFDepositContract.addClientToWhitelist(address(this), true);

        supraVRFDepositContract.addContractToWhitelist(address(perpetualMint));

        supraVRFDepositContract.depositFundClient{ value: 10 ether }();
    }
}
