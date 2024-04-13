// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "forge-std/Test.sol";

import { ICore } from "../../../contracts/diamonds/Core/ICore.sol";
import { IPerpetualMintAdmin } from "../../../contracts/facets/PerpetualMint/IPerpetualMintAdmin.sol";
import { MintTokenTiersData, TiersData } from "../../../contracts/facets/PerpetualMint/Storage.sol";

/// @title ConfigurePerpetualMint_Base
/// @dev configures the PerpetualMintSupra contract by setting the collection price to mint ratio BP,
/// consolation fee BP, mint fee BP, mint for $MINT tiers, redemption fee BP, mint for collection tiers, and activates (unpauses) the protocol
contract ConfigurePerpetualMint_Base is Script, Test {
    error Uint256ValueGreaterThanUint32Max(uint256 value);

    struct FeesConfiguration {
        uint32 collectionConsolationFeeBP;
        uint32 defaultCollectionReferralFeeBP;
        uint32 mintFeeBP;
        uint32 mintForEthConsolationFeeBP;
        uint32 mintTokenConsolationFeeBP;
        uint32 redemptionFeeBP;
    }

    /// @dev runs the script logic
    function run() external {
        // get PerpetualMint address
        address payable perpetualMintAddress = readCoreAddress();

        // read new Core/PerpetualMint owner address
        address newOwner = vm.envAddress("NEW_PERP_MINT_OWNER");

        // read deployer private key
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");

        FeesConfiguration memory feesConfig = FeesConfiguration({
            collectionConsolationFeeBP: uint32(
                vm.envUint("COLLECTION_CONSOLATION_FEE_BP")
            ),
            defaultCollectionReferralFeeBP: uint32(
                vm.envUint("DEFAULT_COLLECTION_REFERRAL_FEE_BP")
            ),
            mintFeeBP: uint32(vm.envUint("MINT_FEE_BP")),
            mintForEthConsolationFeeBP: uint32(
                vm.envUint("MINT_FOR_ETH_CONSOLATION_FEE_BP")
            ),
            mintTokenConsolationFeeBP: uint32(
                vm.envUint("MINT_TOKEN_CONSOLATION_FEE_BP")
            ),
            redemptionFeeBP: uint32(vm.envUint("REDEMPTION_FEE_BP"))
        });

        uint32 mintEarningsBufferBP = uint32(
            vm.envUint("MINT_EARNINGS_BUFFER_BP")
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

        uint256[] memory tierMultipliers = vm.envUint("TIER_MULTIPLIERS", ",");

        uint256[] memory envTierRisks = vm.envUint("TIER_RISKS", ",");

        uint32[] memory tierRisks = toUint32Array(envTierRisks);

        IPerpetualMintAdmin perpetualMint = IPerpetualMintAdmin(
            perpetualMintAddress
        );

        vm.startBroadcast(deployerPrivateKey);

        perpetualMint.setMintEarningsBufferBP(mintEarningsBufferBP);

        perpetualMint.setMintTokenTiers(
            MintTokenTiersData({
                tierMultipliers: mintTokenTierMultipliers,
                tierRisks: mintTokenTierRisks
            })
        );

        setFees(perpetualMint, feesConfig);

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
            feesConfig.collectionConsolationFeeBP
        );
        console.log("Core/PerpetualMint Ownership Transferred To: ", newOwner);
        console.log(
            "Default Collection Referral Fee BP Set: ",
            feesConfig.defaultCollectionReferralFeeBP
        );
        console.log("Mint Fee BP Set: ", feesConfig.mintFeeBP);
        console.log(
            "Mint For ETH Consolation Fee BP Set: ",
            feesConfig.mintForEthConsolationFeeBP
        );
        console.log(
            "Mint Token Consolation Fee BP Set: ",
            feesConfig.mintTokenConsolationFeeBP
        );
        console.log("Mint Earnings Buffer BP Set: ", mintEarningsBufferBP);
        console.log("Mint Token Tiers Set: ");
        emit log_named_array("  Tier Multipliers: ", mintTokenTierMultipliers);
        emit log_named_array("  Tier Risks: ", envMintTokenTierRisks);
        console.log("Redemption Fee BP Set: ", feesConfig.redemptionFeeBP);
        console.log("Tiers Set: ");
        emit log_named_array("  Tier Multipliers: ", tierMultipliers);
        emit log_named_array("  Tier Risks: ", envTierRisks);
        console.log("PerpetualMint Unpaused (Activated)!");

        vm.stopBroadcast();
    }

    /// @notice attempts to read the saved address of the Core diamond contract, post-deployment
    /// @return coreAddress address of the deployed Core diamond contract
    function readCoreAddress()
        internal
        view
        returns (address payable coreAddress)
    {
        string memory inputDir = string.concat(
            vm.projectRoot(),
            "/broadcast/01_deployPerpetualMint.s.sol/"
        );

        string memory chainDir = string.concat(vm.toString(block.chainid), "/");

        string memory file = string.concat("run-latest-core-address", ".txt");

        return
            payable(
                vm.parseAddress(
                    vm.readFile(string.concat(inputDir, chainDir, file))
                )
            );
    }

    function setFees(
        IPerpetualMintAdmin perpetualMint,
        FeesConfiguration memory config
    ) private {
        perpetualMint.setCollectionConsolationFeeBP(
            config.collectionConsolationFeeBP
        );

        perpetualMint.setDefaultCollectionReferralFeeBP(
            config.defaultCollectionReferralFeeBP
        );

        perpetualMint.setMintFeeBP(config.mintFeeBP);

        perpetualMint.setMintForEthConsolationFeeBP(
            config.mintForEthConsolationFeeBP
        );

        perpetualMint.setMintTokenConsolationFeeBP(
            config.mintTokenConsolationFeeBP
        );

        perpetualMint.setRedemptionFeeBP(config.redemptionFeeBP);
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
