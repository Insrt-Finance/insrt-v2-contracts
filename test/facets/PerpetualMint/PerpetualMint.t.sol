// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";

import { PerpetualMintHelper } from "./PerpetualMintHelper.t.sol";
import { IPerpetualMintTest } from "./IPerpetualMintTest.sol";
import { CoreTest } from "../../diamonds/Core.t.sol";
import { PerpetualMintStorage as Storage, VRFConfig } from "../../../contracts/facets/PerpetualMint/Storage.sol";

/// @title PerpetualMintTest
/// @dev PerpetualMintTest helper contract. Configures PerpetualMint as facets of Core test.
/// @dev Should function identically across all forks given appropriate Chainlink VRF details are set.
abstract contract PerpetualMintTest is CoreTest {
    IPerpetualMintTest public perpetualMint;

    PerpetualMintHelper public perpetualMintHelper;

    uint32 internal constant TEST_CONSOLATION_FEE_BP = 5000000; // 0.5% fee

    uint32 internal constant TEST_MINT_FEE_BP = 5000000; // 0.5% fee

    uint64 internal constant TEST_VRF_SUBSCRIPTION_ID = 5;

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

    address internal NON_OWNER = address(100);

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

        // sets the consolation fee
        perpetualMint.setConsolationFeeBP(TEST_CONSOLATION_FEE_BP);

        // sets the mint fee
        perpetualMint.setMintFeeBP(TEST_MINT_FEE_BP);

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
    }

    /// @dev initializes PerpetualMint as a facet by executing a diamond cut on coreDiamond.
    function initPerpetualMint() internal {
        perpetualMintHelper = new PerpetualMintHelper();

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
            perpetualMint.consolationFeeBP()) / perpetualMint.exposed_basis();

        uint256 mockMintFee = (mockMsgValue * perpetualMint.mintFeeBP()) /
            perpetualMint.exposed_basis();

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
}
