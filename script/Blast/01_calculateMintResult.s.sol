// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "forge-std/Test.sol";

import { ICore } from "../../contracts/diamonds/Core/ICore.sol";
import { MintOutcome, MintResultDataBlast, MintTokenTiersData, TiersData } from "../../contracts/facets/PerpetualMint/Storage.sol";

/// @title CalculateMintResultSupraBlast
/// @dev Script for calculating the result of a batch mint attempt on Blast, Supra-specific
contract CalculateMintResultSupraBlast is Script, Test {
    struct ConfigData {
        address collection;
        bool mintForEth;
        bool mintForMint;
        bool referralMint;
        uint8 numberOfMints;
        uint32 riskRewardRatio;
        uint256 pricePerMint;
        uint256 prizeValueInWei;
        uint256[] envRandomness;
        uint256[2] randomness;
    }

    // get CoreBlast PerpetualMint diamond address
    address payable perpetualMintAddress =
        payable(vm.envAddress("CORE_BLAST_ADDRESS"));

    ICore core = ICore(perpetualMintAddress);

    uint32 BASIS = core.BASIS();

    uint256 ethToMintRatio = core.ethToMintRatio();

    MintTokenTiersData mintTokenTiers = core.mintTokenTiers();

    TiersData tiers = core.tiers();

    /// @dev runs the script logic
    function run() external {
        ConfigData memory config = getConfigData();

        uint256 collectionMintMultiplier = core.collectionMintMultiplier(
            config.collection
        );

        uint256 collectionMintPrice = core.collectionMintPrice(
            config.collection
        );

        console.log("BASIS: ", BASIS);
        printConfigData(config);

        if (!config.mintForEth) {
            console.log(
                "Collection Mint Multiplier: ",
                collectionMintMultiplier
            );
        }

        console.log("Collection Mint Price: ", collectionMintPrice);
        console.log("ETH to Mint Ratio: ", ethToMintRatio);

        if (config.mintForMint) {
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
            if (config.mintForEth) {
                uint256 msgValue = config.numberOfMints * config.pricePerMint;

                // calculate the mint for ETH consolation fee
                uint256 mintForEthConsolationFee = (msgValue *
                    core.mintForEthConsolationFeeBP()) / BASIS;

                // calculate additional mint earnings fee
                uint256 additionalMintEarningsFee = (mintForEthConsolationFee *
                    config.riskRewardRatio) / BASIS;

                // calculate the protocol mint fee
                uint256 mintFee = (msgValue * core.mintFeeBP()) / BASIS;

                uint256 referralFee;

                if (config.referralMint) {
                    uint256 referralFeeBP = core.collectionReferralFeeBP(
                        config.collection
                    );

                    if (referralFeeBP == 0) {
                        referralFeeBP = core.defaultCollectionReferralFeeBP();
                    }

                    // Calculate referral fee based on the mintFee and referral fee percentage
                    referralFee = (mintFee * referralFeeBP) / BASIS;
                }

                uint256 mintEarningsFee = msgValue -
                    mintForEthConsolationFee -
                    referralFee +
                    additionalMintEarningsFee;

                uint256 risk = (mintEarningsFee * BASIS) /
                    config.prizeValueInWei;

                console.log("Risk: ", risk);
                console.log("Risk Reward Ratio: ", config.riskRewardRatio);
            } else {
                uint32 collectionRisk = core.collectionRisk(config.collection);

                console.log("Collection Risk: ", collectionRisk);
            }

            console.log("Tiers: ");
            emit log_named_array("  Tier Multipliers: ", tiers.tierMultipliers);
            emit log_named_array(
                "  Tier Risks: ",
                toUint256Array(tiers.tierRisks)
            );
        }

        MintResultDataBlast memory result = core.calculateMintResultSupraBlast(
            config.collection,
            config.numberOfMints,
            config.randomness,
            config.pricePerMint,
            config.prizeValueInWei,
            config.referralMint,
            config.riskRewardRatio
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

        console.log(
            "\nTotal Blast Bounty Yield Amount: ",
            result.totalBlastYieldAmount
        );

        console.log("\nTotal Mint Amount: ", result.totalMintAmount);

        if (!config.mintForMint) {
            if (config.mintForEth) {
                console.log(
                    "Total Prize Value Amount: ",
                    result.totalPrizeValueAmount
                );
            }

            console.log(
                "Total Number of Wins: ",
                result.totalSuccessfulMints,
                "\n"
            );
        }
    }

    function getConfigData() internal view returns (ConfigData memory config) {
        // get collection address
        config.collection = vm.envAddress("COLLECTION_ADDRESS");

        // determine if minting for ETH
        config.mintForEth = config.collection == address(type(uint160).max);

        // determine if minting for mint or collection
        config.mintForMint = config.collection == address(0);

        // determine if referral mint
        config.referralMint = vm.envBool("REFERRAL_MINT");

        // get risk reward ratio
        config.riskRewardRatio = uint32(vm.envUint("RISK_REWARD_RATIO"));

        // get number of mints
        config.numberOfMints = uint8(vm.envUint("NUMBER_OF_MINTS"));

        // get price per mint
        config.pricePerMint = vm.envUint("PRICE_PER_MINT");

        // get prize value in wei
        config.prizeValueInWei = vm.envUint("PRIZE_VALUE_IN_WEI");

        // get randomness signature from environment
        config.envRandomness = vm.envUint("RANDOMNESS", ",");

        // convert randomness signature to fixed size array
        config.randomness = toFixedRandomnessArray(config.envRandomness);
    }

    function printConfigData(ConfigData memory config) internal {
        console.log("Collection Address: ", config.collection);
        console.log("Mint for ETH?: ", config.mintForEth);
        console.log("Mint for Mint?: ", config.mintForMint);
        console.log("Referral Mint?: ", config.referralMint);
        console.log("Number of Mints: ", config.numberOfMints);
        emit log_named_array("Randomness Signature: ", config.envRandomness);
        console.log("Price Per Mint: ", config.pricePerMint);
        console.log("Prize Value in Wei: ", config.prizeValueInWei);
    }

    function toFixedRandomnessArray(
        uint256[] memory input
    ) internal pure returns (uint256[2] memory fixedRandomness) {
        require(
            input.length >= 2,
            "Input array must contain at least two elements."
        );

        fixedRandomness[0] = input[0];
        fixedRandomness[1] = input[1];
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
