// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "forge-std/Test.sol";

import { ICore } from "../../contracts/diamonds/Core/ICore.sol";
import { MintOutcome, MintResultData, MintTokenTiersData, TiersData } from "../../contracts/facets/PerpetualMint/Storage.sol";

/// @title CalculateMintResultArb
/// @dev Script for calculating the result of a batch mint attempt
contract CalculateMintResultArb is Script, Test {
    // get Core PerpetualMint diamond address
    address payable perpetualMintAddress =
        payable(vm.envAddress("CORE_ADDRESS"));

    ICore core = ICore(perpetualMintAddress);

    uint32 BASIS = core.BASIS();

    uint256 ethToMintRatio = core.ethToMintRatio();

    MintTokenTiersData mintTokenTiers = core.mintTokenTiers();

    TiersData tiers = core.tiers();

    /// @dev runs the script logic
    function run() external {
        // get collection address
        address collection = vm.envAddress("COLLECTION_ADDRESS");

        // determine if minting for mint or collection
        bool mintForMint = collection == address(0);

        // get number of mints
        uint32 numberOfMints = uint32(vm.envUint("NUMBER_OF_MINTS"));

        // get randomness
        uint256 randomness = vm.envUint("RANDOMNESS");

        // get price per mint
        uint256 pricePerMint = vm.envUint("PRICE_PER_MINT");

        uint256 collectionMintMultiplier = core.collectionMintMultiplier(
            collection
        );

        uint256 collectionMintPrice = core.collectionMintPrice(collection);

        uint32 collectionRisk = core.collectionRisk(collection);

        console.log("BASIS: ", BASIS);
        console.log("Collection Address: ", collection);
        console.log("Mint for Mint?: ", mintForMint);
        console.log("Collection Mint Multiplier: ", collectionMintMultiplier);
        console.log("Collection Mint Price: ", collectionMintPrice);
        console.log("ETH to Mint Ratio: ", ethToMintRatio);
        console.log("Number of Mints: ", numberOfMints);
        console.log("Randomness: ", randomness);
        console.log("Price Per Mint: ", pricePerMint);

        if (mintForMint) {
            console.log("Mint Token Tiers: ");
            emit log_named_array(
                "  Tier Multipliers: ",
                mintTokenTiers.tierMultipliers
            );
            emit log_named_array(
                "  Tier Risks: ",
                toUint256Array(mintTokenTiers.tierRisks)
            );
        } else {
            console.log("Collection Risk: ", collectionRisk);
            console.log("Tiers: ");
            emit log_named_array("  Tier Multipliers: ", tiers.tierMultipliers);
            emit log_named_array(
                "  Tier Risks: ",
                toUint256Array(tiers.tierRisks)
            );
        }

        MintResultData memory result = core.calculateMintResult(
            collection,
            numberOfMints,
            randomness,
            pricePerMint
        );

        // Iterate over the mintOutcomes array in MintResultData
        for (uint256 i = 0; i < result.mintOutcomes.length; i++) {
            // Access the MintOutcome struct at the i-th index
            MintOutcome memory outcome = result.mintOutcomes[i];

            // Log the outcome
            console.log("\nOutcome #", i + 1, ":");
            console.log("Tier: ", outcome.tierIndex);
            console.log(" | Tier Multiplier: ", outcome.tierMultiplier);
            console.log(" | Tier Risk: ", outcome.tierRisk);
            console.log(" | Tier Mint Amount in Wei: ", outcome.mintAmount);
        }

        console.log("\nTotal Mint Amount: ", result.totalMintAmount);

        if (!mintForMint) {
            console.log(
                "Total Receipt Amount: ",
                result.totalSuccessfulMints,
                "\n"
            );
        }
    }

    /// @notice Converts a uint32 array to a uint256 array
    /// @param uint32Array The uint32 array to convert
    /// @return uint256Array The converted uint256 array
    function toUint256Array(
        uint32[] memory uint32Array
    ) internal pure returns (uint256[] memory uint256Array) {
        uint256Array = new uint256[](uint32Array.length);

        for (uint256 i = 0; i < uint32Array.length; ++i) {
            uint256Array[i] = uint256(uint32Array[i]);
        }

        return uint256Array;
    }
}
