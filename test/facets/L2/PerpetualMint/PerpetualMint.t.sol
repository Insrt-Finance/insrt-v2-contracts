// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { IERC721 } from "@solidstate/contracts/interfaces/IERC721.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";

import { AssetType } from "../../../../contracts/enums/AssetType.sol";
import { PerpetualMintStorage as Storage } from "../../../../contracts/facets/L2/PerpetualMint/Storage.sol";
import { L2CoreTest } from "../../../diamonds/L2/Core.t.sol";
import { StorageRead } from "../common/StorageRead.t.sol";
import { IPerpetualMintTest } from "./IPerpetualMintTest.sol";
import { PerpetualMintHelper } from "./PerpetualMintHelper.t.sol";

/// @title PerpetualMintTest
/// @dev PerpetualMintTest helper contract. Configures PerpetualMint and L2AssetHandlerMock as facets of L2Core test.
/// @dev Should functoin identically across all forks given appropriate Chainlink VRF details are set.
abstract contract PerpetualMintTest is L2CoreTest, StorageRead {
    using stdStorage for StdStorage;

    IPerpetualMintTest public perpetualMint;

    PerpetualMintHelper public perpetualMintHelper;

    //denominator used in percentage calculations
    uint32 internal constant BASIS = 1000000000;

    //Ethereum mainnet Bong Bears contract address.
    address internal constant PARALLEL_ALPHA =
        0x76BE3b62873462d2142405439777e971754E8E77;

    //Ethereum mainnet Bored Ape Yacht Club contract address.
    address internal constant BORED_APE_YACHT_CLUB =
        0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;

    // Token Ids used of Bored Ape Yacht Club collection
    uint256 BORED_APE_YACHT_CLUB_TOKEN_ID_ONE = 101;
    uint256 BORED_APE_YACHT_CLUB_TOKEN_ID_TWO = 102;

    // Token Ids used of Parallel Alpha collection
    uint256 PARALLEL_ALPHA_TOKEN_ID_ONE = 10951;
    uint256 PARALLEL_ALPHA_TOKEN_ID_TWO = 11022;

    // all depositors will deposit the same amount of ParallelAlpha tokens
    uint256 internal parallelAlphaTokenAmount = 10;

    uint256 MINT_PRICE = 0.5 ether;

    // depositors
    address payable internal depositorOne = payable(address(1));
    address payable internal depositorTwo = payable(address(2));
    // minter
    address payable internal minter = payable(address(3));

    // token risk values
    uint256 internal constant riskOne = 400; // for BAYC
    uint256 internal constant riskTwo = 800; // for BAYC
    uint256 internal constant riskThree = 100; //for parallelAlpha

    /// @dev Dummy trusted remote test path.
    bytes internal TEST_PATH =
        bytes.concat(bytes20(vm.addr(1234)), bytes20(vm.addr(5678)));

    /// @dev Dummy test nonce value.
    uint64 internal constant TEST_NONCE = 0;

    /// @dev The LayerZero proprietary chain ID for setting Ethereum mainnet as the destination blockchain.
    uint16 internal constant DESTINATION_LAYER_ZERO_CHAIN_ID = 101;

    /// @dev BAYC depositor test data holders
    /// @dev BAYC risks for tokens that depositorOne and depositorTwo will deposit respectively
    uint256[] internal depositorOneBAYCRisks;
    uint256[] internal depositorTwoBAYCRisks;

    /// @dev BAYC tokenIds for tokens that depositorOne and depositorTwo will deposit respectively
    uint256[] internal depositorOneBAYCIds;
    uint256[] internal depositorTwoBAYCIds;

    /// @dev Parallel Alpha depositor test data holders
    /// @dev Parallel Alpha token risks for tokens thatn depositorOne and depositorTwo will deposit respectively
    uint256[] internal depositorOneParallelAlphaRisks;
    uint256[] internal depositorTwoParallelAlphaRisks;

    /// @dev Parallel Alpha token ids for tokens thatn depositorOne and depositorTwo will deposit respectively
    uint256[] internal depositorOneParallelAlphaTokenIds;
    uint256[] internal depositorTwoParallelAlphaTokenIds;

    /// @dev Parallel Alpha token amounts for tokens thatn depositorOne and depositorTwo will deposit respectively
    uint256[] internal depositorOneParallelAlphaAmounts;
    uint256[] internal depositorTwoParallelAlphaAmounts;

    uint64 internal constant TEST_VRF_SUBSCRIPTION_ID = 5;

    /// @dev sets up PerpetualMint for testing
    function setUp() public virtual override {
        super.setUp();

        initPerpetualMint();

        perpetualMint = IPerpetualMintTest(address(l2CoreDiamond));

        perpetualMint.setVRFConfig(
            Storage.VRFConfig({
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

        perpetualMint.setCollectionMintPrice(BORED_APE_YACHT_CLUB, MINT_PRICE);
        perpetualMint.setCollectionMintPrice(PARALLEL_ALPHA, MINT_PRICE);

        bytes32 collectionTypeSlot = keccak256(
            abi.encode(
                BORED_APE_YACHT_CLUB, // address of collection
                uint256(Storage.STORAGE_SLOT) + 8 // collectionType mapping storage slot
            )
        );

        vm.store(
            address(perpetualMint),
            collectionTypeSlot,
            bytes32(uint256(1))
        );

        assert(
            _collectionType(address(perpetualMint), BORED_APE_YACHT_CLUB) ==
                AssetType.ERC721
        );
    }

    /// @dev initialzies PerpetualMint and L2AssetHandlerMock as facets by executing a diamond cut on L2CoreDiamond.
    function initPerpetualMint() internal {
        perpetualMintHelper = new PerpetualMintHelper();

        ISolidStateDiamond.FacetCut[] memory facetCuts = perpetualMintHelper
            .getFacetCuts();

        l2CoreDiamond.diamondCut(facetCuts, address(0), "");
    }

    /// @dev deposits bored ape tokens from depositors into the PerpetualMint contracts
    /// using the L2AssetHandlerMock facet logic
    function depositBoredApeYachtClubAssetsMock() internal {
        // add token risks to depositor risk arrays
        depositorOneBAYCRisks.push(riskOne);
        depositorTwoBAYCRisks.push(riskTwo);

        // add token ids to depositor token arrays
        depositorOneBAYCIds.push(BORED_APE_YACHT_CLUB_TOKEN_ID_ONE);
        depositorTwoBAYCIds.push(BORED_APE_YACHT_CLUB_TOKEN_ID_TWO);

        bytes memory depositOneData = abi.encode(
            AssetType.ERC721,
            depositorOne,
            BORED_APE_YACHT_CLUB,
            depositorOneBAYCRisks,
            depositorOneBAYCIds
        );

        bytes memory depositTwoData = abi.encode(
            AssetType.ERC721,
            depositorTwo,
            BORED_APE_YACHT_CLUB,
            depositorTwoBAYCRisks,
            depositorTwoBAYCIds
        );

        perpetualMint.mock_HandleLayerZeroMessage(
            DESTINATION_LAYER_ZERO_CHAIN_ID, // would be the expected source chain ID in production, here this is a dummy value
            TEST_PATH, // would be the expected path in production, here this is a dummy value
            TEST_NONCE, // dummy nonce value
            depositOneData
        );

        perpetualMint.mock_HandleLayerZeroMessage(
            DESTINATION_LAYER_ZERO_CHAIN_ID, // would be the expected source chain ID in production, here this is a dummy value
            TEST_PATH, // would be the expected path in production, here this is a dummy value
            TEST_NONCE, // dummy nonce value
            depositTwoData
        );
    }

    /// @dev deposits bong bear tokens into the PerpetualMint contracts
    function depositParallelAlphaAssetsMock() internal {
        // each encoded deposit is done in sequence: risk, tokenId, amount, as arrays need to be ordered
        // set up encoded deposit array data for depositorOne
        // depositorOne deposits two different tokenIds, with the same amount and same risk
        depositorOneParallelAlphaRisks.push(riskThree);
        depositorOneParallelAlphaTokenIds.push(PARALLEL_ALPHA_TOKEN_ID_ONE);
        depositorOneParallelAlphaAmounts.push(parallelAlphaTokenAmount);

        depositorOneParallelAlphaRisks.push(riskThree);
        depositorOneParallelAlphaTokenIds.push(PARALLEL_ALPHA_TOKEN_ID_TWO);
        depositorOneParallelAlphaAmounts.push(parallelAlphaTokenAmount);

        // set up encoded deposit array data for depositorTwo
        // // depositorOne deposits one tokenId, with the same amount and same risk as depositorOne
        depositorTwoParallelAlphaRisks.push(riskThree);
        depositorTwoParallelAlphaTokenIds.push(PARALLEL_ALPHA_TOKEN_ID_ONE);
        depositorTwoParallelAlphaAmounts.push(parallelAlphaTokenAmount);

        bytes memory depositOneData = abi.encode(
            AssetType.ERC1155,
            depositorOne,
            PARALLEL_ALPHA,
            depositorOneParallelAlphaRisks,
            depositorOneParallelAlphaTokenIds,
            depositorOneParallelAlphaAmounts
        );

        bytes memory depositTwoData = abi.encode(
            AssetType.ERC1155,
            depositorTwo,
            PARALLEL_ALPHA,
            depositorTwoParallelAlphaRisks,
            depositorTwoParallelAlphaTokenIds,
            depositorTwoParallelAlphaAmounts
        );

        perpetualMint.mock_HandleLayerZeroMessage(
            DESTINATION_LAYER_ZERO_CHAIN_ID, // would be the expected source chain ID in production, here this is a dummy value
            TEST_PATH, // would be the expected path in production, here this is a dummy value
            TEST_NONCE, // dummy nonce value
            depositOneData
        );

        perpetualMint.mock_HandleLayerZeroMessage(
            DESTINATION_LAYER_ZERO_CHAIN_ID, // would be the expected source chain ID in production, here this is a dummy value
            TEST_PATH, // would be the expected path in production, here this is a dummy value
            TEST_NONCE, // dummy nonce value
            depositTwoData
        );
    }
}
