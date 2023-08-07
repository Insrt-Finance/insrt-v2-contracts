// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";

/// @title PerpetuaMint_updateDepositorEarnings
/// @dev PerpetualMint test contract for testing expected behavior of the updateDepositorEarnings function
contract PerpetualMint_updateDepositorEarnings is
    PerpetualMintTest,
    L2ForkTest
{
    uint256 internal constant COLLECTION_EARNINGS = 1 ether;

    // grab BAYC collection earnings storage slot
    bytes32 internal collectionEarningsStorageSlot =
        keccak256(
            abi.encode(
                BORED_APE_YACHT_CLUB, // the ERC721 collection
                uint256(Storage.STORAGE_SLOT) + 9 // the collectionEarnings storage slot
            )
        );

    // grab totalDepositorsRisk storage slot
    bytes32 internal totalDepositorRiskStorageSlot =
        keccak256(
            abi.encode(
                BORED_APE_YACHT_CLUB, // the ERC721 collection
                keccak256(
                    abi.encode(
                        depositorOne, // address of depositor
                        uint256(Storage.STORAGE_SLOT) + 21 // totalDepositorRisk mapping storage slot
                    )
                )
            )
        );

    /// @dev sets up the context for the test cases
    function setUp() public override {
        super.setUp();

        depositBoredApeYachtClubAssetsMock();

        //overwrite storage
        vm.store(
            address(perpetualMint),
            collectionEarningsStorageSlot,
            bytes32(COLLECTION_EARNINGS)
        );

        vm.store(address(perpetualMint), totalDepositorRiskStorageSlot, 0);
    }

    /// @dev tests earnings updates when a depositor has no risk, for example after a minter wins an asset
    function test_updateDepositorEarningsWhenTotalDepositorRiskIsZero() public {
        perpetualMint.exposed_updateDepositorEarnings(
            depositorOne,
            BORED_APE_YACHT_CLUB
        );

        assert(
            _depositorDeductions(
                address(perpetualMint),
                depositorOne,
                BORED_APE_YACHT_CLUB
            ) ==
                _collectionEarnings(
                    address(perpetualMint),
                    BORED_APE_YACHT_CLUB
                )
        );
    }

    /// @dev tests earnings updates when a depositor has previous risk, for instance when a depositor updates the risk
    /// of an asset
    function test_updateDepositorEarningsWhenTotalDepositorRiskIsNonZero()
        public
    {
        uint256 totalRisk = _totalRisk(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );
        uint256 totalDepositorRisk = _totalDepositorRisk(
            address(perpetualMint),
            depositorTwo,
            BORED_APE_YACHT_CLUB
        );
        uint256 collectionEarnings = _collectionEarnings(
            address(perpetualMint),
            BORED_APE_YACHT_CLUB
        );
        uint256 oldDepositorDeductions = _depositorDeductions(
            address(perpetualMint),
            depositorTwo,
            BORED_APE_YACHT_CLUB
        );

        assert(totalDepositorRisk != 0);
        assert(totalRisk != 0);

        perpetualMint.exposed_updateDepositorEarnings(
            depositorTwo,
            BORED_APE_YACHT_CLUB
        );

        uint256 newDepositorDeductions = _depositorDeductions(
            address(perpetualMint),
            depositorTwo,
            BORED_APE_YACHT_CLUB
        );

        uint256 expectedEarnings = (collectionEarnings * totalDepositorRisk) /
            totalRisk -
            oldDepositorDeductions;

        assert(
            expectedEarnings ==
                _depositorEarnings(
                    address(perpetualMint),
                    depositorTwo,
                    BORED_APE_YACHT_CLUB
                )
        );

        assert(newDepositorDeductions == expectedEarnings);
    }
}
