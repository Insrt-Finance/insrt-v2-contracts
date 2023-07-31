// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { IERC721 } from "@solidstate/contracts/interfaces/IERC721.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";

import { AssetType } from "../../../../contracts/enums/AssetType.sol";
import { PerpetualMintStorage as Storage } from "../../../../contracts/facets/L2/PerpetualMint/Storage.sol";
import { L2CoreTest } from "../../../diamonds/L2/Core.t.sol";
import { IDepositFacetMock } from "../../../interfaces/IDepositFacetMock.sol";
import { StorageRead } from "../common/StorageRead.t.sol";
import { IPerpetualMintTest } from "./IPerpetualMintTest.t.sol";
import { PerpetualMintHelper } from "./PerpetualMintHelper.t.sol";

/// @title PerpetualMintTest
/// @dev PerpetualMintTest helper contract. Configures PerpetualMint and DepositFacetMock as facets of L1Core test.
/// @dev Should functoin identically across all forks given appropriate Chainlink VRF details are set.
abstract contract PerpetualMintTest is L2CoreTest, StorageRead {
    using stdStorage for StdStorage;

    IPerpetualMintTest public perpetualMint;
    IERC1155 public parallelAlpha;
    IERC721 public boredApeYachtClub;

    //denominator used in percentage calculations
    uint32 internal constant BASIS = 1000000000;

    //Ethereum mainnet Bong Bears contract address.
    address internal constant PARALLEL_ALPHA =
        0x76BE3b62873462d2142405439777e971754E8E77;

    //Ethereum mainnet Bored Ape Yacht Club contract address.
    address internal constant BORED_APE_YACHT_CLUB =
        0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;

    uint256[] internal boredApeYachtClubTokenIds = new uint256[](2);

    uint256[] internal parallelAlphaTokenIds = new uint256[](2);

    // all depositors will deposit the same amount of ParallelAlpha tokens
    uint256 internal parallelAlphaTokenAmount = 10;

    uint256 MINT_PRICE = 0.5 ether;

    // depositors
    address payable internal depositorOne = payable(address(1));
    address payable internal depositorTwo = payable(address(2));
    // minter
    address payable internal minter = payable(address(3));

    // token risk values
    uint64 internal constant riskOne = 400; // for BAYC
    uint64 internal constant riskTwo = 800; // for BAYC
    uint64 internal constant riskThree = 100; //for parallelAlpha

    /// @dev sets up PerpetualMint for testing
    function setUp() public virtual override {
        super.setUp();

        initPerpetualMint();

        perpetualMint = IPerpetualMintTest(address(l2CoreDiamond));
        boredApeYachtClub = IERC721(BORED_APE_YACHT_CLUB);
        parallelAlpha = IERC1155(PARALLEL_ALPHA);

        boredApeYachtClubTokenIds[0] = 101;
        boredApeYachtClubTokenIds[1] = 102;

        parallelAlphaTokenIds[0] = 10951;
        parallelAlphaTokenIds[1] = 11022;

        perpetualMint.setVRFConfig(
            Storage.VRFConfig({
                // Arbitrum 150 GWEI keyhash
                keyHash: bytes32(
                    0x68d24f9a037a649944964c2a1ebd0b2918f4a243d2a99701cc22b548cf2daff0
                ),
                // Initiated Subscription ID
                subscriptionId: uint64(5),
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

    /// @dev initialzies PerpetualMint and DepositFacetMock as facets by executing a diamond cut on L1CoreDiamond.
    function initPerpetualMint() internal {
        PerpetualMintHelper perpetualMintHelper = new PerpetualMintHelper();

        ISolidStateDiamond.FacetCut[] memory facetCuts = perpetualMintHelper
            .getFacetCuts();

        l2CoreDiamond.diamondCut(facetCuts, address(0), "");
    }

    /// @dev deposits bored ape tokens from depositors into the PerpetualMint contracts
    function depositBoredApeYachtClubAssetsMock() internal {
        vm.prank(depositorOne);
        perpetualMint.depositAsset(
            BORED_APE_YACHT_CLUB,
            boredApeYachtClubTokenIds[0],
            1,
            riskOne
        );

        vm.prank(depositorTwo);
        perpetualMint.depositAsset(
            BORED_APE_YACHT_CLUB,
            boredApeYachtClubTokenIds[1],
            1,
            riskTwo
        );
    }

    /// @dev deposits bong bear tokens into the PerpetualMint contracts
    function depositParallelAlphaAssetsMock() internal {
        vm.prank(depositorOne);
        perpetualMint.depositAsset(
            PARALLEL_ALPHA,
            parallelAlphaTokenIds[0],
            uint64(parallelAlphaTokenAmount),
            riskThree
        );

        vm.prank(depositorTwo);
        perpetualMint.depositAsset(
            PARALLEL_ALPHA,
            parallelAlphaTokenIds[0],
            uint64(parallelAlphaTokenAmount),
            riskThree
        );

        vm.prank(depositorOne);
        perpetualMint.depositAsset(
            PARALLEL_ALPHA,
            parallelAlphaTokenIds[1],
            uint64(parallelAlphaTokenAmount),
            riskThree
        );
    }
}
