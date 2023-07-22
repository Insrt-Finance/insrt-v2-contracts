// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { IERC721 } from "@solidstate/contracts/interfaces/IERC721.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";

import { L1CoreTest } from "../../../diamonds/L1/Core.t.sol";
import { PerpetualMintHelper } from "./PerpetualMintHelper.t.sol";
import { IPerpetualMintTest } from "./IPerpetualMintTest.t.sol";
import { StorageRead } from "../common/StorageRead.t.sol";

import { IDepositFacetMock } from "../../../interfaces/IDepositFacetMock.sol";

/// @title PerpetualMintTest
/// @dev PerpetualMintTest helper contract. Configures PerpetualMint and DepositFacetMock as facets of L1Core test.
/// @dev Should functoin identically across all forks given appropriate Chainlink VRF details are set.
abstract contract PerpetualMintTest is L1CoreTest, StorageRead {
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

        perpetualMint = IPerpetualMintTest(address(l1CoreDiamond));
        boredApeYachtClub = IERC721(BORED_APE_YACHT_CLUB);
        parallelAlpha = IERC1155(PARALLEL_ALPHA);

        boredApeYachtClubTokenIds[0] = 101;
        boredApeYachtClubTokenIds[1] = 102;

        parallelAlphaTokenIds[0] = 10951;
        parallelAlphaTokenIds[1] = 11022;

        perpetualMint.setCollectionMintPrice(BORED_APE_YACHT_CLUB, MINT_PRICE);
        perpetualMint.setCollectionType(BORED_APE_YACHT_CLUB, true);
        perpetualMint.setCollectionMintPrice(PARALLEL_ALPHA, MINT_PRICE);

        assert(
            _collectionType(address(perpetualMint), BORED_APE_YACHT_CLUB) ==
                true
        );
    }

    /// @dev initialzies PerpetualMint and DepositFacetMock as facets by executing a diamond cut on L1CoreDiamond.
    function initPerpetualMint() internal {
        PerpetualMintHelper perpetualMintHelper = new PerpetualMintHelper();

        ISolidStateDiamond.FacetCut[] memory facetCuts = perpetualMintHelper
            .getFacetCuts();

        l1CoreDiamond.diamondCut(facetCuts, address(0), "");
    }

    /// @dev deposits bored ape tokens from depositors into the PerpetualMint contracts
    function depositBoredApeYachtClubAssetsMock() internal {
        // find owners
        address ownerOne = boredApeYachtClub.ownerOf(
            boredApeYachtClubTokenIds[0]
        );
        address ownerTwo = boredApeYachtClub.ownerOf(
            boredApeYachtClubTokenIds[1]
        );

        // prank owners and transfer tokens
        vm.prank(ownerOne);
        boredApeYachtClub.transferFrom(
            ownerOne,
            depositorOne,
            boredApeYachtClubTokenIds[0]
        );
        vm.prank(ownerTwo);
        boredApeYachtClub.transferFrom(
            ownerTwo,
            depositorTwo,
            boredApeYachtClubTokenIds[1]
        );

        //check tokens are transfered
        assert(
            boredApeYachtClub.ownerOf(boredApeYachtClubTokenIds[0]) ==
                depositorOne
        );
        assert(
            boredApeYachtClub.ownerOf(boredApeYachtClubTokenIds[1]) ==
                depositorTwo
        );

        //deposit tokens
        vm.prank(depositorOne);
        boredApeYachtClub.approve(
            address(perpetualMint),
            boredApeYachtClubTokenIds[0]
        );
        vm.prank(depositorOne);
        perpetualMint.depositAsset(
            BORED_APE_YACHT_CLUB,
            boredApeYachtClubTokenIds[0],
            1,
            riskOne
        );

        vm.prank(depositorTwo);
        boredApeYachtClub.approve(
            address(perpetualMint),
            boredApeYachtClubTokenIds[1]
        );
        vm.prank(depositorTwo);
        perpetualMint.depositAsset(
            BORED_APE_YACHT_CLUB,
            boredApeYachtClubTokenIds[1],
            1,
            riskTwo
        );

        //assert tokens are deposited
        assert(
            boredApeYachtClub.ownerOf(boredApeYachtClubTokenIds[0]) ==
                address(perpetualMint)
        );
        assert(
            boredApeYachtClub.ownerOf(boredApeYachtClubTokenIds[1]) ==
                address(perpetualMint)
        );
    }

    /// @dev deposits bong bear tokens into the PerpetualMint contracts
    function depositParallelAlphaAssetsMock() internal {
        // give PARALLEL_ALPHA tokens to depositors
        // two depositors for parallelAlphaTokenIds[0]
        stdstore
            .target(PARALLEL_ALPHA)
            .sig(parallelAlpha.balanceOf.selector)
            .with_key(address(depositorOne))
            .with_key(parallelAlphaTokenIds[0])
            .checked_write(parallelAlphaTokenAmount);
        stdstore
            .target(PARALLEL_ALPHA)
            .sig(parallelAlpha.balanceOf.selector)
            .with_key(address(depositorTwo))
            .with_key(parallelAlphaTokenIds[0])
            .checked_write(parallelAlphaTokenAmount);

        // one depositor for parallelAlphaTokenIds[1]
        stdstore
            .target(PARALLEL_ALPHA)
            .sig(parallelAlpha.balanceOf.selector)
            .with_key(address(depositorOne))
            .with_key(parallelAlphaTokenIds[1])
            .checked_write(parallelAlphaTokenAmount);

        assert(
            parallelAlpha.balanceOf(
                address(depositorOne),
                parallelAlphaTokenIds[0]
            ) == parallelAlphaTokenAmount
        );
        assert(
            parallelAlpha.balanceOf(
                address(depositorTwo),
                parallelAlphaTokenIds[0]
            ) == parallelAlphaTokenAmount
        );
        assert(
            parallelAlpha.balanceOf(
                address(depositorOne),
                parallelAlphaTokenIds[1]
            ) == parallelAlphaTokenAmount
        );

        //deposit tokens
        vm.prank(depositorOne);
        parallelAlpha.setApprovalForAll(address(perpetualMint), true);
        vm.prank(depositorOne);
        perpetualMint.depositAsset(
            PARALLEL_ALPHA,
            parallelAlphaTokenIds[0],
            uint64(parallelAlphaTokenAmount),
            riskThree
        );

        vm.prank(depositorTwo);
        parallelAlpha.setApprovalForAll(address(perpetualMint), true);
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

        //assert tokens are deposited
        assert(
            parallelAlpha.balanceOf(
                address(perpetualMint),
                parallelAlphaTokenIds[0]
            ) == 2 * parallelAlphaTokenAmount
        );

        assert(
            parallelAlpha.balanceOf(
                address(perpetualMint),
                parallelAlphaTokenIds[1]
            ) == parallelAlphaTokenAmount
        );
    }
}
