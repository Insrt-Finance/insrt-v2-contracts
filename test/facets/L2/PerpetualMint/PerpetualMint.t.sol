// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

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
    IERC1155 public bongBears;
    IERC721 public boredApeYachtClub;

    //denominator used in percentage calculations
    uint32 internal constant BASIS = 1000000000;

    //Ethereum mainnet Bong Bears contract address.
    address internal constant BONG_BEARS =
        0x495f947276749Ce646f68AC8c248420045cb7b5e;

    //Ethereum mainnet Bored Ape Yacht Club contract address.
    address internal constant BORED_APE_YACHT_CLUB =
        0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;

    uint256[] internal boredApeYachtClubTokenIds = new uint256[](4);

    uint256[] internal bongBearTokenIds = new uint256[](2);

    uint256[] internal bongBearTokenAmounts = new uint256[](2);

    uint256 BORED_APE_YACHT_CLUB_MINT_PRICE = 0.5 ether;

    // depositors
    address payable internal depositorOne = payable(address(1));
    address payable internal depositorTwo = payable(address(2));
    // minter
    address payable internal minter = payable(address(3));

    // token risk values
    uint64 internal constant riskOne = 400;
    uint64 internal constant riskTwo = 800;

    /// @dev sets up PerpetualMint for testing
    function setUp() public virtual override {
        super.setUp();

        initPerpetualMint();

        perpetualMint = IPerpetualMintTest(address(l1CoreDiamond));
        boredApeYachtClub = IERC721(BORED_APE_YACHT_CLUB);
        bongBears = IERC1155(BONG_BEARS);

        boredApeYachtClubTokenIds[0] = 101;
        boredApeYachtClubTokenIds[1] = 102;
        boredApeYachtClubTokenIds[2] = 103; //unused
        boredApeYachtClubTokenIds[3] = 104; //unused

        bongBearTokenIds[
            0
        ] = 66075445032688988859229341194671037535804503065310441849644897861040871571457; // Bong Bear #01
        bongBearTokenIds[
            1
        ] = 66075445032688988859229341194671037535804503065310441849644897862140383199233; // Bong Bear #02
        bongBearTokenAmounts[0] = 1;
        bongBearTokenAmounts[1] = 1;

        perpetualMint.setCollectionMintPrice(
            BORED_APE_YACHT_CLUB,
            BORED_APE_YACHT_CLUB_MINT_PRICE
        );
        perpetualMint.setCollectionType(BORED_APE_YACHT_CLUB, true);

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
    function depositBongBearsAssetsMock() internal {
        //give tokens to bong bears
        stdstore
            .target(BONG_BEARS)
            .sig(bongBears.balanceOf.selector)
            .with_key(address(depositorOne))
            .with_key(bongBearTokenIds[0])
            .checked_write(bongBearTokenAmounts[0]);
        stdstore
            .target(BONG_BEARS)
            .sig(bongBears.balanceOf.selector)
            .with_key(address(depositorTwo))
            .with_key(bongBearTokenIds[1])
            .checked_write(bongBearTokenAmounts[1]);

        assert(
            bongBears.balanceOf(address(depositorOne), bongBearTokenIds[0]) == 1
        );
        assert(
            bongBears.balanceOf(address(depositorTwo), bongBearTokenIds[1]) == 1
        );

        //deposit tokens
        vm.prank(depositorOne);
        bongBears.setApprovalForAll(address(perpetualMint), true);
        vm.prank(depositorOne);
        perpetualMint.depositAsset(
            BONG_BEARS,
            bongBearTokenIds[0],
            uint64(bongBearTokenAmounts[0]),
            riskOne
        );

        vm.prank(depositorTwo);
        bongBears.setApprovalForAll(address(perpetualMint), true);
        vm.prank(depositorTwo);
        perpetualMint.depositAsset(
            BONG_BEARS,
            bongBearTokenIds[1],
            uint64(bongBearTokenAmounts[1]),
            riskTwo
        );

        //assert tokens are deposited
        assert(
            bongBears.balanceOf(address(perpetualMint), bongBearTokenIds[0]) ==
                1
        );
        assert(
            bongBears.balanceOf(address(perpetualMint), bongBearTokenIds[1]) ==
                1
        );
    }
}
