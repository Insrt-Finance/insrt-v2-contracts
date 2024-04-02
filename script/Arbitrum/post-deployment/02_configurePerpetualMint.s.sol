// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "forge-std/Test.sol";

import { ICore } from "../../../contracts/diamonds/Core/ICore.sol";
import { IPerpetualMintAdmin } from "../../../contracts/facets/PerpetualMint/IPerpetualMintAdmin.sol";
import { MintTokenTiersData, TiersData, VRFConfig } from "../../../contracts/facets/PerpetualMint/Storage.sol";

/// @title ConfigurePerpetualMintArb
/// @dev configures the PerpetualMint contract by setting the collection price to mint ratio BP,
/// consolation fee BP, mint fee BP, mint for $MINT tiers, redemption fee BP, mint for collection tiers, and VRF config
contract ConfigurePerpetualMintArb is Script, Test {
    error Uint256ValueGreaterThanUint32Max(uint256 value);

    struct FeesConfiguration {
        uint32 collectionConsolationFeeBP;
        uint32 defaultCollectionReferralFeeBP;
        uint32 mintFeeBP;
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

        uint64 insrtVRFSubscriptionId = readInsrtVRFSubscriptionId();

        FeesConfiguration memory feesConfig = FeesConfiguration({
            collectionConsolationFeeBP: uint32(
                vm.envUint("COLLECTION_CONSOLATION_FEE_BP")
            ),
            defaultCollectionReferralFeeBP: uint32(
                vm.envUint("DEFAULT_COLLECTION_REFERRAL_FEE_BP")
            ),
            mintFeeBP: uint32(vm.envUint("MINT_FEE_BP")),
            mintTokenConsolationFeeBP: uint32(
                vm.envUint("MINT_TOKEN_CONSOLATION_FEE_BP")
            ),
            redemptionFeeBP: uint32(vm.envUint("REDEMPTION_FEE_BP"))
        });

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

        VRFConfig memory vrfConfig = VRFConfig({
            keyHash: vm.envBytes32("VRF_KEY_HASH"),
            // if the Insrt VRF Coordinator is not being used, use the saved Chainlink VRF subscription ID
            subscriptionId: insrtVRFSubscriptionId == 0
                ? readVRFSubscriptionId()
                : insrtVRFSubscriptionId,
            // Max Callback Gas Limit
            callbackGasLimit: uint32(2500000),
            minConfirmations: uint16(1)
        });

        vm.startBroadcast(deployerPrivateKey);

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

        perpetualMint.setVRFConfig(vrfConfig);

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
            "Mint Token Consolation Fee BP Set: ",
            feesConfig.mintTokenConsolationFeeBP
        );
        console.log("Mint Token Tiers Set: ");
        emit log_named_array("  Tier Multipliers: ", mintTokenTierMultipliers);
        emit log_named_array("  Tier Risks: ", envMintTokenTierRisks);
        console.log("Redemption Fee BP Set: ", feesConfig.redemptionFeeBP);
        console.log("Tiers Set: ");
        emit log_named_array("  Tier Multipliers: ", tierMultipliers);
        emit log_named_array("  Tier Risks: ", envTierRisks);
        console.log("VRF Config Set: ");
        emit log_named_bytes32("  VRF Key Hash: ", vrfConfig.keyHash);
        console.log("  VRF Subscription ID: ", vrfConfig.subscriptionId);
        console.log("  VRF Callback Gas Limit: ", vrfConfig.callbackGasLimit);
        console.log("  VRF Min Confirmations: ", vrfConfig.minConfirmations);

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

        perpetualMint.setMintTokenConsolationFeeBP(
            config.mintTokenConsolationFeeBP
        );

        perpetualMint.setRedemptionFeeBP(config.redemptionFeeBP);
    }

    /// @notice attempts to read the saved address of an Insrt VRF subscription ID, post-configuration
    /// @return subscriptionId the Insrt VRF subscription ID
    function readInsrtVRFSubscriptionId()
        internal
        view
        returns (uint64 subscriptionId)
    {
        string memory inputDir = string.concat(
            vm.projectRoot(),
            "/broadcast/01_configureInsrtVRFSubscription.s.sol/"
        );

        string memory chainDir = string.concat(vm.toString(block.chainid), "/");

        string memory file = string.concat(
            "run-latest-insrt-vrf-subscription-id",
            ".txt"
        );

        try vm.readFile(string.concat(inputDir, chainDir, file)) returns (
            string memory fileData
        ) {
            return uint64(vm.parseUint(fileData));
        } catch {
            return 0;
        }
    }

    /// @notice attempts to read the saved address of the newly created VRF subscription ID, post-configuration
    /// @return subscriptionId the newly created VRF subscription ID
    function readVRFSubscriptionId()
        internal
        view
        returns (uint64 subscriptionId)
    {
        string memory inputDir = string.concat(
            vm.projectRoot(),
            "/broadcast/01_configureVRFSubscription.s.sol/"
        );

        string memory chainDir = string.concat(vm.toString(block.chainid), "/");

        string memory file = string.concat(
            "run-latest-vrf-subscription-id",
            ".txt"
        );

        return
            uint64(
                vm.parseUint(
                    vm.readFile(string.concat(inputDir, chainDir, file))
                )
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
