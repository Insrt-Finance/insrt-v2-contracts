// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { PerpetualMintStorage as Storage } from "../../../../../contracts/facets/L2/PerpetualMint/Storage.sol";
import { AssetType } from "../../../../../contracts/enums/AssetType.sol";
import { L2ForkTest } from "../../../../L2ForkTest.t.sol";
import { PerpetualMintTest } from "../PerpetualMint.t.sol";

import "forge-std/console.sol";

/// @title PerpetuaMint_bugEarningsAccountScenario
/// @dev PerpetualMint test contract to show bug in earnings accounting
contract PerpetualMint_bugEarningsAccountScenario is
    PerpetualMintTest,
    L2ForkTest
{
    uint256 internal constant COLLECTION_EARNINGS = 1 ether;

    // grab BAYC collection earnings storage slot
    bytes32 internal collectionEarningsStorageSlot =
        keccak256(
            abi.encode(
                PARALLEL_ALPHA, // the ERC721 collection
                uint256(Storage.STORAGE_SLOT) + 9 // the risk storage slot
            )
        );

    // grab totalDepositorsRisk for depositor one storage slot
    bytes32 internal depositorOneRiskStorageSlot =
        keccak256(
            abi.encode(
                PARALLEL_ALPHA, // the ERC721 collection
                keccak256(
                    abi.encode(
                        depositorOne, // address of depositor
                        uint256(Storage.STORAGE_SLOT) + 21 // totalDepositorRisk mapping storage slot
                    )
                )
            )
        );

    // grab totalRisk for PARALLEL_ALPHA storage slot
    bytes32 totalRiskSlot =
        keccak256(
            abi.encode(
                PARALLEL_ALPHA, // address of collection
                uint256(Storage.STORAGE_SLOT) + 11 // totalRisk mapping storage slot
            )
        );

    /// @dev sets up the context for the test cases
    function setUp() public override {
        super.setUp();

        // each encoded deposit is done in sequence: risk, tokenId, amount, as arrays need to be ordered
        // set up encoded deposit array data for depositorOne
        // depositorOne deposits two different tokenIds, with the same amount and same risk
        depositorOneParallelAlphaRisks.push(riskThree);
        depositorOneParallelAlphaTokenIds.push(PARALLEL_ALPHA_TOKEN_ID_ONE);
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

        //overwrite storage
        vm.store(
            address(perpetualMint),
            collectionEarningsStorageSlot,
            bytes32(COLLECTION_EARNINGS)
        );
    }

    // note: both depositors start with a risk of 1000, and the total risk of PARALLEL_ALPHA is 2000
    function test_bugEarningsACcountingScenario() public {
        //prior to initiating scenario, all earnings and deductions for both
        // depositors should be zero
        assert(
            _depositorEarnings(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA
            ) == 0
        );
        assert(
            _depositorDeductions(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA
            ) == 0
        );
        assert(
            _depositorEarnings(
                address(perpetualMint),
                depositorTwo,
                PARALLEL_ALPHA
            ) == 0
        );
        assert(
            _depositorDeductions(
                address(perpetualMint),
                depositorTwo,
                PARALLEL_ALPHA
            ) == 0
        );

        // mimic an action which would cause _updateDepositorEarnings to be called
        perpetualMint.exposed_updateDepositorEarnings(
            depositorOne,
            PARALLEL_ALPHA
        );

        // after updating the depositor earnings for depositorOne, since both depositors have equal risk in the collection,
        // it follows that the earnings for that depositor should be half of the total earnings - and the deductions will be
        // set equal to the earnings
        assert(
            _depositorEarnings(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA
            ) == COLLECTION_EARNINGS / 2
        );
        assert(
            _depositorDeductions(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA
            ) == COLLECTION_EARNINGS / 2
        );
        // double the collection earnings to mimic the protocol functioning during the time prior
        // to an _updateDepositEarnings call
        vm.store(
            address(perpetualMint),
            collectionEarningsStorageSlot,
            bytes32(COLLECTION_EARNINGS * 2)
        );

        // the total risk of depositorOne is set to half of what it was,
        // to mimic an action which alters the total risk, requiring a
        // _updateDepositorEarnings call
        // depositorOne total risk drops by 500 (from 1000 => 500)
        vm.store(
            address(perpetualMint),
            depositorOneRiskStorageSlot,
            bytes32(uint256(500))
        );

        // total risk of collection should also drop by 500 (from 2000 => 1500)
        vm.store(address(perpetualMint), totalRiskSlot, bytes32(uint256(1500)));

        perpetualMint.exposed_updateDepositorEarnings(
            depositorOne,
            PARALLEL_ALPHA
        );

        // at this point, depositorOne should have a total of COLLECTION_EARNINGS * 0.5 +  COLLECTION_EARNINGS * 0.333333333
        // since initially they have half of the total collection risk, and later on they half their own risk, meaning they
        // have a third of the total collection risk so should receive a third of the additional earnings

        uint256 firstEarnings = COLLECTION_EARNINGS / 2;
        uint256 secondEarnings = (COLLECTION_EARNINGS *
            _totalDepositorRisk(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA
            )) / _totalRisk(address(perpetualMint), PARALLEL_ALPHA);

        // the actual earnings are in fact:
        // totalDepositorOneRisk (500) * totalEarnings (COLLECTION_EARNINGS * 2) / totalRisk (1500) + previousEarnings (0.5 * COLLECTION_EARNINGS)  - deductions (0.5 * COLLECTION_EARNINGS)
        // = 2 / 3 * COLLECTION_EARNINGS
        // whereas in fact it should be 0.83333333 * COLLECTION_EARNINGS

        // similar calculation can be made to indicate that depositorTwo earnings are not calculated correctly either
        // the assertion fails as a result
        assert(
            _depositorEarnings(
                address(perpetualMint),
                depositorOne,
                PARALLEL_ALPHA
            ) == firstEarnings + secondEarnings
        );
    }
}
