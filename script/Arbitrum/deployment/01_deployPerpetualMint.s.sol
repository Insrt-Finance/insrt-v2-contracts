// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IPausable } from "@solidstate/contracts/security/pausable/IPausable.sol";
import { IERC1155Metadata } from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";

import { ICore } from "../../../contracts/diamonds/Core/ICore.sol";
import { Core } from "../../../contracts/diamonds/Core/Core.sol";
import { IERC1155MetadataExtension } from "../../../contracts/facets/PerpetualMint/IERC1155MetadataExtension.sol";
import { IPerpetualMint } from "../../../contracts/facets/PerpetualMint/IPerpetualMint.sol";
import { IPerpetualMintAdmin } from "../../../contracts/facets/PerpetualMint/IPerpetualMintAdmin.sol";
import { IPerpetualMintBase } from "../../../contracts/facets/PerpetualMint/IPerpetualMintBase.sol";
import { IPerpetualMintView } from "../../../contracts/facets/PerpetualMint/IPerpetualMintView.sol";
import { PerpetualMint } from "../../../contracts/facets/PerpetualMint/PerpetualMint.sol";
import { PerpetualMintAdmin } from "../../../contracts/facets/PerpetualMint/PerpetualMintAdmin.sol";
import { PerpetualMintBase } from "../../../contracts/facets/PerpetualMint/PerpetualMintBase.sol";
import { PerpetualMintView } from "../../../contracts/facets/PerpetualMint/PerpetualMintView.sol";

/// @title DeployPerpetualMintArb
/// @dev deploys the Core diamond contract, PerpetualMint facet, PerpetualMintAdmin facet, PerpetualMintBase facet, and PerpetualMintView facet,
/// and performs a diamondCut of the PerpetualMint, PerpetualMintAdmin, PerpetualMintBase, and PerpetualMintView facets onto the Core diamond
contract DeployPerpetualMintArb is Script {
    /// @dev runs the script logic
    function run() external {
        // read address of $MINT token contract
        address mintToken = readTokenProxyAddress();

        address insrtVrfCoordinator = readInsrtVRFCoordinatorAddress();

        // if InsrtVRFCoordinator has not been deployed, use the Chainlink VRF Coordinator
        address VRF_COORDINATOR = insrtVrfCoordinator == address(0)
            ? vm.envAddress("VRF_COORDINATOR")
            : insrtVrfCoordinator;

        string memory receiptName = "Ticket";
        string memory receiptSymbol = "TICKET";

        // read deployer private key
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // deploy PerpetualMint facet
        PerpetualMint perpetualMint = new PerpetualMint(VRF_COORDINATOR);

        // deploy PerpetualMintAdmin facet
        PerpetualMintAdmin perpetualMintAdmin = new PerpetualMintAdmin(
            VRF_COORDINATOR
        );

        // deploy PerpetualMintBase facet
        PerpetualMintBase perpetualMintBase = new PerpetualMintBase(
            VRF_COORDINATOR
        );

        // deploy PerpetualMintView facet
        PerpetualMintView perpetualMintView = new PerpetualMintView(
            VRF_COORDINATOR
        );

        // deploy Core
        Core core = new Core(mintToken, receiptName, receiptSymbol);

        console.log("PerpetualMint Facet Address: ", address(perpetualMint));
        console.log(
            "PerpetualMintAdmin Facet Address: ",
            address(perpetualMintAdmin)
        );
        console.log(
            "PerpetualMintBase Facet Address: ",
            address(perpetualMintBase)
        );
        console.log(
            "PerpetualMintView Facet Address: ",
            address(perpetualMintView)
        );
        console.log("Core Address: ", address(core));
        console.log("VRF Coordinator Address: ", VRF_COORDINATOR);

        writeCoreAddress(address(core));
        writeVRFCoordinatorAddress(VRF_COORDINATOR);

        // get PerpetualMint facet cuts
        ICore.FacetCut[]
            memory perpetualMintFacetCuts = getPerpetualMintFacetCuts(
                address(perpetualMint)
            );

        // get PerpetualMintAdmin facet cuts
        ICore.FacetCut[]
            memory perpetualMintAdminFacetCuts = getPerpetualMintAdminFacetCuts(
                address(perpetualMintAdmin)
            );

        // get PerpetualMintBase facet cuts
        ICore.FacetCut[]
            memory perpetualMintBaseFacetCuts = getPerpetualMintBaseFacetCuts(
                address(perpetualMintBase)
            );

        // get PerpetualMintView facet cuts
        ICore.FacetCut[]
            memory perpetualMintViewFacetCuts = getPerpetualMintViewFacetCuts(
                address(perpetualMintView)
            );

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](9);

        facetCuts[0] = perpetualMintFacetCuts[0];
        facetCuts[1] = perpetualMintFacetCuts[1];
        facetCuts[2] = perpetualMintAdminFacetCuts[0];
        facetCuts[3] = perpetualMintBaseFacetCuts[0];
        facetCuts[4] = perpetualMintBaseFacetCuts[1];
        facetCuts[5] = perpetualMintBaseFacetCuts[2];
        facetCuts[6] = perpetualMintBaseFacetCuts[3];
        facetCuts[7] = perpetualMintViewFacetCuts[0];
        facetCuts[8] = perpetualMintViewFacetCuts[1];

        // cut PerpetualMint into Core
        ICore(payable(core)).diamondCut(facetCuts, address(0), "");

        vm.stopBroadcast();
    }

    /// @dev provides the facet cuts for cutting PerpetualMint facet into Core
    /// @param facetAddress address of PerpetualMint facet
    function getPerpetualMintFacetCuts(
        address facetAddress
    ) internal pure returns (ICore.FacetCut[] memory) {
        // map the PerpetualMint related function selectors to their respective interfaces
        bytes4[] memory perpetualMintFunctionSelectors = new bytes4[](8);

        perpetualMintFunctionSelectors[0] = IPerpetualMint
            .attemptBatchMintForEthWithEth
            .selector;

        perpetualMintFunctionSelectors[1] = IPerpetualMint
            .attemptBatchMintForMintWithEth
            .selector;

        perpetualMintFunctionSelectors[2] = IPerpetualMint
            .attemptBatchMintForMintWithMint
            .selector;

        perpetualMintFunctionSelectors[3] = IPerpetualMint
            .attemptBatchMintWithEth
            .selector;

        perpetualMintFunctionSelectors[4] = IPerpetualMint
            .attemptBatchMintWithMint
            .selector;

        perpetualMintFunctionSelectors[5] = IPerpetualMint.claimPrize.selector;

        perpetualMintFunctionSelectors[6] = IPerpetualMint
            .fundConsolationFees
            .selector;

        perpetualMintFunctionSelectors[7] = IPerpetualMint.redeem.selector;

        ICore.FacetCut memory perpetualMintFacetCut = IDiamondWritableInternal
            .FacetCut({
                target: facetAddress,
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: perpetualMintFunctionSelectors
            });

        // map the VRFConsumerBaseV2 function selectors to their respective interfaces
        bytes4[] memory vrfConsumerBaseV2FunctionSelectors = new bytes4[](1);

        vrfConsumerBaseV2FunctionSelectors[0] = VRFConsumerBaseV2
            .rawFulfillRandomWords
            .selector;

        ICore.FacetCut
            memory vrfConsumerBaseV2FacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: facetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: vrfConsumerBaseV2FunctionSelectors
                });

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](2);

        // omit Ownable since SolidStateDiamond includes those
        facetCuts[0] = perpetualMintFacetCut;
        facetCuts[1] = vrfConsumerBaseV2FacetCut;

        return facetCuts;
    }

    /// @dev provides the facet cuts for cutting PerpetualMintAdmin facet into Core
    /// @param facetAddress address of PerpetualMintAdmin facet
    function getPerpetualMintAdminFacetCuts(
        address facetAddress
    ) internal pure returns (ICore.FacetCut[] memory) {
        // map the PerpetualMintAdmin related function selectors to their respective interfaces
        bytes4[] memory perpetualMintAdminFunctionSelectors = new bytes4[](29);

        perpetualMintAdminFunctionSelectors[0] = IPerpetualMintAdmin
            .burnReceipt
            .selector;

        perpetualMintAdminFunctionSelectors[1] = IPerpetualMintAdmin
            .cancelClaim
            .selector;

        perpetualMintAdminFunctionSelectors[2] = bytes4(
            keccak256("claimMintEarnings()")
        );

        perpetualMintAdminFunctionSelectors[3] = bytes4(
            keccak256("claimMintEarnings(uint256)")
        );

        perpetualMintAdminFunctionSelectors[4] = IPerpetualMintAdmin
            .claimProtocolFees
            .selector;

        perpetualMintAdminFunctionSelectors[5] = IPerpetualMintAdmin
            .mintAirdrop
            .selector;

        perpetualMintAdminFunctionSelectors[6] = IPerpetualMintAdmin
            .pause
            .selector;

        perpetualMintAdminFunctionSelectors[7] = IPerpetualMintAdmin
            .setCollectionConsolationFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[8] = IPerpetualMintAdmin
            .setCollectionMintFeeDistributionRatioBP
            .selector;

        perpetualMintAdminFunctionSelectors[9] = IPerpetualMintAdmin
            .setCollectionMintMultiplier
            .selector;

        perpetualMintAdminFunctionSelectors[10] = IPerpetualMintAdmin
            .setCollectionMintPrice
            .selector;

        perpetualMintAdminFunctionSelectors[11] = IPerpetualMintAdmin
            .setCollectionReferralFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[12] = IPerpetualMintAdmin
            .setCollectionRisk
            .selector;

        perpetualMintAdminFunctionSelectors[13] = IPerpetualMintAdmin
            .setDefaultCollectionReferralFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[14] = IPerpetualMintAdmin
            .setEthToMintRatio
            .selector;

        perpetualMintAdminFunctionSelectors[15] = IPerpetualMintAdmin
            .setMintEarningsBufferBP
            .selector;

        perpetualMintAdminFunctionSelectors[16] = IPerpetualMintAdmin
            .setMintFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[17] = IPerpetualMintAdmin
            .setMintForEthConsolationFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[18] = IPerpetualMintAdmin
            .setMintToken
            .selector;

        perpetualMintAdminFunctionSelectors[19] = IPerpetualMintAdmin
            .setMintTokenConsolationFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[20] = IPerpetualMintAdmin
            .setMintTokenTiers
            .selector;

        perpetualMintAdminFunctionSelectors[21] = IPerpetualMintAdmin
            .setReceiptBaseURI
            .selector;

        perpetualMintAdminFunctionSelectors[22] = IPerpetualMintAdmin
            .setReceiptTokenURI
            .selector;

        perpetualMintAdminFunctionSelectors[23] = IPerpetualMintAdmin
            .setRedemptionFeeBP
            .selector;

        perpetualMintAdminFunctionSelectors[24] = IPerpetualMintAdmin
            .setRedeemPaused
            .selector;

        perpetualMintAdminFunctionSelectors[25] = IPerpetualMintAdmin
            .setTiers
            .selector;

        perpetualMintAdminFunctionSelectors[26] = IPerpetualMintAdmin
            .setVRFConfig
            .selector;

        perpetualMintAdminFunctionSelectors[27] = IPerpetualMintAdmin
            .setVRFSubscriptionBalanceThreshold
            .selector;

        perpetualMintAdminFunctionSelectors[28] = IPerpetualMintAdmin
            .unpause
            .selector;

        ICore.FacetCut
            memory perpetualMintAdminFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: facetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintAdminFunctionSelectors
                });

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](1);

        // omit Ownable since SolidStateDiamond includes those
        facetCuts[0] = perpetualMintAdminFacetCut;

        return facetCuts;
    }

    /// @dev provides the facet cuts for cutting PerpetualMintBase facet into Core
    /// @param facetAddress address of PerpetualMintBase facet
    function getPerpetualMintBaseFacetCuts(
        address facetAddress
    ) internal pure returns (ICore.FacetCut[] memory) {
        /// map the ERC1155 function selectors to their respective interfaces
        bytes4[] memory erc1155FunctionSelectors = new bytes4[](6);

        erc1155FunctionSelectors[0] = IERC1155.balanceOf.selector;
        erc1155FunctionSelectors[1] = IERC1155.balanceOfBatch.selector;
        erc1155FunctionSelectors[2] = IERC1155.isApprovedForAll.selector;
        erc1155FunctionSelectors[3] = IERC1155.safeBatchTransferFrom.selector;
        erc1155FunctionSelectors[4] = IERC1155.safeTransferFrom.selector;
        erc1155FunctionSelectors[5] = IERC1155.setApprovalForAll.selector;

        ICore.FacetCut memory erc1155FacetCut = IDiamondWritableInternal
            .FacetCut({
                target: facetAddress,
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: erc1155FunctionSelectors
            });

        // map the ERC1155Metadata function selectors to their respective interfaces
        bytes4[] memory erc1155MetadataFunctionSelectors = new bytes4[](1);

        erc1155MetadataFunctionSelectors[0] = IERC1155Metadata.uri.selector;

        ICore.FacetCut memory erc1155MetadataFacetCut = IDiamondWritableInternal
            .FacetCut({
                target: facetAddress,
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: erc1155MetadataFunctionSelectors
            });

        // map the ERC1155Metadata function selectors to their respective interfaces
        bytes4[]
            memory erc1155MetadataExtensionFunctionSelectors = new bytes4[](2);

        erc1155MetadataExtensionFunctionSelectors[0] = IERC1155MetadataExtension
            .name
            .selector;
        erc1155MetadataExtensionFunctionSelectors[1] = IERC1155MetadataExtension
            .symbol
            .selector;

        ICore.FacetCut
            memory erc1155MetadataExtensionFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: facetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: erc1155MetadataExtensionFunctionSelectors
                });

        // map the PerpetualMintBase related function selectors to their respective interfaces
        bytes4[] memory perpetualMintBaseFunctionSelectors = new bytes4[](1);

        perpetualMintBaseFunctionSelectors[0] = IPerpetualMintBase
            .onERC1155Received
            .selector;

        ICore.FacetCut
            memory perpetualMintBaseFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: facetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintBaseFunctionSelectors
                });

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](4);

        // omit ERC165 since SolidStateDiamond includes those
        facetCuts[0] = erc1155FacetCut;
        facetCuts[1] = erc1155MetadataFacetCut;
        facetCuts[2] = erc1155MetadataExtensionFacetCut;
        facetCuts[3] = perpetualMintBaseFacetCut;

        return facetCuts;
    }

    /// @dev provides the facet cuts for cutting PerpetualMintView facet into Core
    /// @param facetAddress address of PerpetualMintView facet
    function getPerpetualMintViewFacetCuts(
        address facetAddress
    ) internal pure returns (ICore.FacetCut[] memory) {
        // map the Pausable function selectors to their respective interfaces
        bytes4[] memory pausableFunctionSelectors = new bytes4[](1);

        pausableFunctionSelectors[0] = IPausable.paused.selector;

        ICore.FacetCut memory pausableFacetCut = IDiamondWritableInternal
            .FacetCut({
                target: facetAddress,
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: pausableFunctionSelectors
            });

        // map the PerpetualMintView related function selectors to their respective interfaces
        bytes4[] memory perpetualMintViewFunctionSelectors = new bytes4[](28);

        perpetualMintViewFunctionSelectors[0] = IPerpetualMintView
            .accruedConsolationFees
            .selector;

        perpetualMintViewFunctionSelectors[1] = IPerpetualMintView
            .accruedMintEarnings
            .selector;

        perpetualMintViewFunctionSelectors[2] = IPerpetualMintView
            .accruedProtocolFees
            .selector;

        perpetualMintViewFunctionSelectors[3] = IPerpetualMintView
            .BASIS
            .selector;

        perpetualMintViewFunctionSelectors[4] = IPerpetualMintView
            .calculateMintResult
            .selector;

        perpetualMintViewFunctionSelectors[5] = IPerpetualMintView
            .collectionConsolationFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[6] = IPerpetualMintView
            .collectionMintFeeDistributionRatioBP
            .selector;

        perpetualMintViewFunctionSelectors[7] = IPerpetualMintView
            .collectionMintMultiplier
            .selector;

        perpetualMintViewFunctionSelectors[8] = IPerpetualMintView
            .collectionMintPrice
            .selector;

        perpetualMintViewFunctionSelectors[9] = IPerpetualMintView
            .collectionReferralFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[10] = IPerpetualMintView
            .collectionRisk
            .selector;

        perpetualMintViewFunctionSelectors[11] = IPerpetualMintView
            .defaultCollectionMintPrice
            .selector;

        perpetualMintViewFunctionSelectors[12] = IPerpetualMintView
            .defaultCollectionReferralFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[13] = IPerpetualMintView
            .defaultCollectionRisk
            .selector;

        perpetualMintViewFunctionSelectors[14] = IPerpetualMintView
            .defaultEthToMintRatio
            .selector;

        perpetualMintViewFunctionSelectors[15] = IPerpetualMintView
            .ethToMintRatio
            .selector;

        perpetualMintViewFunctionSelectors[16] = IPerpetualMintView
            .mintEarningsBufferBP
            .selector;

        perpetualMintViewFunctionSelectors[17] = IPerpetualMintView
            .mintFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[18] = IPerpetualMintView
            .mintForEthConsolationFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[19] = IPerpetualMintView
            .mintToken
            .selector;

        perpetualMintViewFunctionSelectors[20] = IPerpetualMintView
            .mintTokenConsolationFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[21] = IPerpetualMintView
            .mintTokenTiers
            .selector;

        perpetualMintViewFunctionSelectors[22] = IPerpetualMintView
            .redemptionFeeBP
            .selector;

        perpetualMintViewFunctionSelectors[23] = IPerpetualMintView
            .redeemPaused
            .selector;

        perpetualMintViewFunctionSelectors[24] = IPerpetualMintView
            .SCALE
            .selector;

        perpetualMintViewFunctionSelectors[25] = IPerpetualMintView
            .tiers
            .selector;

        perpetualMintViewFunctionSelectors[26] = IPerpetualMintView
            .vrfConfig
            .selector;

        perpetualMintViewFunctionSelectors[27] = IPerpetualMintView
            .vrfSubscriptionBalanceThreshold
            .selector;

        ICore.FacetCut
            memory perpetualMintViewFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: facetAddress,
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: perpetualMintViewFunctionSelectors
                });

        ICore.FacetCut[] memory facetCuts = new ICore.FacetCut[](2);

        // omit Ownable since SolidStateDiamond includes those
        facetCuts[0] = pausableFacetCut;
        facetCuts[1] = perpetualMintViewFacetCut;

        return facetCuts;
    }

    /// @notice attempts to read the saved address of an Insrt VRF Coordinator contract, post-deployment
    /// @return insrtVrfCoordinatorAddress address of the deployed Insrt VRF Coordinator contract
    function readInsrtVRFCoordinatorAddress()
        internal
        view
        returns (address insrtVrfCoordinatorAddress)
    {
        string memory inputDir = string.concat(
            vm.projectRoot(),
            "/broadcast/01_deployInsrtVRFCoordinator.s.sol/"
        );

        string memory chainDir = string.concat(vm.toString(block.chainid), "/");

        string memory file = string.concat(
            "run-latest-insrt-vrf-coordinator-address",
            ".txt"
        );

        try vm.readFile(string.concat(inputDir, chainDir, file)) returns (
            string memory fileData
        ) {
            return vm.parseAddress(fileData);
        } catch {
            return address(0);
        }
    }

    function readTokenProxyAddress()
        internal
        view
        returns (address tokenProxyAddress)
    {
        string memory inputDir = string.concat(
            vm.projectRoot(),
            "/broadcast/01_deployToken.s.sol/"
        );

        string memory chainDir = string.concat(vm.toString(block.chainid), "/");

        string memory file = string.concat(
            "run-latest-token-proxy-address",
            ".txt"
        );

        return
            vm.parseAddress(
                vm.readFile(string.concat(inputDir, chainDir, file))
            );
    }

    /// @notice writes the address of the deployed Core diamond to a file
    /// @param coreAddress address of the deployed Core diamond
    function writeCoreAddress(address coreAddress) internal {
        string memory inputDir = string.concat(
            vm.projectRoot(),
            "/broadcast/01_deployPerpetualMint.s.sol/"
        );

        string memory chainDir = string.concat(vm.toString(block.chainid), "/");

        string memory file = string.concat("run-latest-core-address", ".txt");

        vm.writeFile(
            string.concat(inputDir, chainDir, file),
            vm.toString(coreAddress)
        );
    }

    /// @notice writes the address of the VRF Coordinator set in the deployed Core diamond to a file
    /// @param vrfCoordinatorAddress address of the VRF Coordinator set in the deployed Core diamond
    function writeVRFCoordinatorAddress(
        address vrfCoordinatorAddress
    ) internal {
        string memory inputDir = string.concat(
            vm.projectRoot(),
            "/broadcast/01_deployPerpetualMint.s.sol/"
        );

        string memory chainDir = string.concat(vm.toString(block.chainid), "/");

        string memory file = string.concat(
            "run-latest-vrf-coordinator-address",
            ".txt"
        );

        vm.writeFile(
            string.concat(inputDir, chainDir, file),
            vm.toString(vrfCoordinatorAddress)
        );
    }
}
