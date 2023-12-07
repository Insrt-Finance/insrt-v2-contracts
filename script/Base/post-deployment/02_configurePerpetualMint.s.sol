// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "forge-std/Test.sol";

import { ICore } from "../../../contracts/diamonds/Core/ICore.sol";
import { IPerpetualMint, MintTokenTiersData, TiersData } from "../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";

/// @title ConfigurePerpetualMint_Base
/// @dev configures the PerpetualMint_Base contract by setting the collection price to mint ratio BP,
/// consolation fee BP, mint fee BP, mint for $MINT tiers, redemption fee BP, mint for collection tiers, and activates (unpauses) the protocol
contract ConfigurePerpetualMint_Base is Script, Test {
    error Uint256ValueGreaterThanUint32Max(uint256 value);

    /// @dev runs the script logic
    function run() external {
        // get PerpetualMint address
        address perpetualMintAddress = readCoreAddress();

        // read new Core/PerpetualMint owner address
        address newOwner = vm.envAddress("NEW_PERP_MINT_OWNER");

        // read deployer private key
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");

        uint32 collectionConsolationFeeBP = uint32(
            vm.envUint("COLLECTION_CONSOLATION_FEE_BP")
        );

        uint32 mintFeeBP = uint32(vm.envUint("MINT_FEE_BP"));

        uint32 mintTokenConsolationFeeBP = uint32(
            vm.envUint("MINT_TOKEN_CONSOLATION_FEE_BP")
        );

        uint256[] memory mintTokenTierMultipliers = vm.envUint(
            "MINT_TOKEN_TIER_MULTIPLIERS",
            ","
        );

        uint256[] memory envMintTokenTierRisks = vm.envUint(
            "MINT_TOKEN_TIER_RISKS",
            ","
        );

        uint32[] memory mintTokenTierRisks = toUint32Array(
            envMintTokenTierRisks
        );

        uint32 redemptionFeeBP = uint32(vm.envUint("REDEMPTION_FEE_BP"));

        uint256[] memory tierMultipliers = vm.envUint("TIER_MULTIPLIERS", ",");

        uint256[] memory envTierRisks = vm.envUint("TIER_RISKS", ",");

        uint32[] memory tierRisks = toUint32Array(envTierRisks);

        IPerpetualMint perpetualMint = IPerpetualMint(perpetualMintAddress);

        vm.startBroadcast(deployerPrivateKey);

        perpetualMint.setCollectionConsolationFeeBP(collectionConsolationFeeBP);

        perpetualMint.setMintFeeBP(mintFeeBP);

        perpetualMint.setMintTokenConsolationFeeBP(mintTokenConsolationFeeBP);

        perpetualMint.setMintTokenTiers(
            MintTokenTiersData({
                tierMultipliers: mintTokenTierMultipliers,
                tierRisks: mintTokenTierRisks
            })
        );

        perpetualMint.setRedemptionFeeBP(redemptionFeeBP);

        perpetualMint.setTiers(
            TiersData({
                tierMultipliers: tierMultipliers,
                tierRisks: tierRisks
            })
        );

        perpetualMint.unpause();

        ICore(perpetualMintAddress).transferOwnership(newOwner);

        console.log(
            "Collection Consolation Fee BP Set: ",
            collectionConsolationFeeBP
        );
        console.log("Core/PerpetualMint Ownership Transferred To: ", newOwner);
        console.log("Mint Fee BP Set: ", mintFeeBP);
        console.log(
            "Mint Token Consolation Fee BP Set: ",
            mintTokenConsolationFeeBP
        );
        console.log("Mint Token Tiers Set: ");
        emit log_named_array("  Tier Multipliers: ", mintTokenTierMultipliers);
        emit log_named_array("  Tier Risks: ", envMintTokenTierRisks);
        console.log("Redemption Fee BP Set: ", redemptionFeeBP);
        console.log("Tiers Set: ");
        emit log_named_array("  Tier Multipliers: ", tierMultipliers);
        emit log_named_array("  Tier Risks: ", envTierRisks);
        console.log("PerpetualMint Unpaused (Activated)!");

        vm.stopBroadcast();
    }

    /// @notice attempts to read the saved address of the Core diamond contract, post-deployment
    /// @return coreAddress address of the deployed Core diamond contract
    function readCoreAddress() internal view returns (address coreAddress) {
        string memory inputDir = string.concat(
            vm.projectRoot(),
            "/broadcast/01_deployPerpetualMint.s.sol/"
        );

        string memory chainDir = string.concat(vm.toString(block.chainid), "/");

        string memory file = string.concat("run-latest-core-address", ".txt");

        return
            vm.parseAddress(
                vm.readFile(string.concat(inputDir, chainDir, file))
            );
    }

    /// @notice converts a uint256 array to a uint32 array
    /// @param uint256Array the uint256 array to convert
    /// @return uint32Array the converted uint32 array
    function toUint32Array(
        uint256[] memory uint256Array
    ) internal pure returns (uint32[] memory uint32Array) {
        uint32Array = new uint32[](uint256Array.length);

        for (uint256 i = 0; i < uint256Array.length; ++i) {
            if (uint256Array[i] >= type(uint32).max) {
                revert Uint256ValueGreaterThanUint32Max(uint256Array[i]);
            }

            uint32Array[i] = uint32(uint256Array[i]);
        }

        return uint32Array;
    }
}
