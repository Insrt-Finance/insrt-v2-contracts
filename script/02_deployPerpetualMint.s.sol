// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IPausable } from "@solidstate/contracts/security/pausable/IPausable.sol";
import { IERC1155Metadata } from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";

import { ICore } from "../contracts/diamonds/Core/ICore.sol";
import { Core } from "../contracts/diamonds/Core/Core.sol";
import { IERC1155MetadataExtension } from "../contracts/facets/PerpetualMint/IERC1155MetadataExtension.sol";
import { IPerpetualMint } from "../contracts/facets/PerpetualMint/IPerpetualMint.sol";
import { PerpetualMint } from "../contracts/facets/PerpetualMint/PerpetualMint.sol";

/// @title DeployPerpetualMint
/// @dev deploys the Core diamond contract and the PerpetualMint facet, and performs
/// a diamondCut of the PerpetualMint facet onto the Core diamond
contract DeployPerpetualMint is Script {
    /// @dev runs the script logic
    function run() external {
        // read address of $MINT token contract
        address mintToken = readTokenProxyAddress();
        // Chainlink VRF Coordinator address
        address VRF_COORDINATOR = vm.envAddress("VRF_COORDINATOR");

        string memory receiptName = "I-O-U";
        string memory receiptSymbol = "IOU";

        // read deployer private key
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // deploy PerpetualMint facet
        PerpetualMint perpetualMint = new PerpetualMint(VRF_COORDINATOR);

        // deploy Core
        Core core = new Core(mintToken, receiptName, receiptSymbol);

        console.log("PerpetualMint Facet Address: ", address(perpetualMint));
        console.log("Core Address: ", address(core));
        console.log("VRF Coordinator Address: ", VRF_COORDINATOR);

        writeCoreAddress(address(core));
        writeVRFCoordinatorAddress(VRF_COORDINATOR);

        // get PerpetualMint facet cuts
        ISolidStateDiamond.FacetCut[]
            memory facetCuts = getPerpetualMintFacetCuts(
                address(perpetualMint)
            );

        // cut PerpetualMint into Core
        ISolidStateDiamond(core).diamondCut(facetCuts, address(0), "");

        vm.stopBroadcast();
    }

    /// @dev provides the facet cuts for cutting PerpetualMint facet into Core
    /// @param facetAddress address of PerpetualMint facet
    function getPerpetualMintFacetCuts(
        address facetAddress
    ) internal pure returns (ISolidStateDiamond.FacetCut[] memory) {
        /// map the ERC1155 test related function selectors to their respective interfaces
        bytes4[] memory erc1155FunctionSelectors = new bytes4[](6);

        erc1155FunctionSelectors[0] = IERC1155.balanceOf.selector;
        erc1155FunctionSelectors[1] = IERC1155.balanceOfBatch.selector;
        erc1155FunctionSelectors[2] = IERC1155.isApprovedForAll.selector;
        erc1155FunctionSelectors[3] = IERC1155.safeBatchTransferFrom.selector;
        erc1155FunctionSelectors[4] = IERC1155.safeTransferFrom.selector;
        erc1155FunctionSelectors[5] = IERC1155.setApprovalForAll.selector;

        ISolidStateDiamond.FacetCut
            memory erc1155FacetCut = IDiamondWritableInternal.FacetCut({
                target: address(facetAddress),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: erc1155FunctionSelectors
            });

        // map the ERC1155Metadata test related function selectors to their respective interfaces
        bytes4[] memory erc1155MetadataFunctionSelectors = new bytes4[](1);

        erc1155MetadataFunctionSelectors[0] = IERC1155Metadata.uri.selector;

        ISolidStateDiamond.FacetCut
            memory erc1155MetadataFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(facetAddress),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: erc1155MetadataFunctionSelectors
            });

        // map the ERC1155Metadata test related function selectors to their respective interfaces
        bytes4[]
            memory erc1155MetadataExtensionFunctionSelectors = new bytes4[](2);

        erc1155MetadataExtensionFunctionSelectors[0] = IERC1155MetadataExtension
            .name
            .selector;
        erc1155MetadataExtensionFunctionSelectors[1] = IERC1155MetadataExtension
            .symbol
            .selector;

        ISolidStateDiamond.FacetCut
            memory erc1155MetadataExtensionFacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: address(facetAddress),
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: erc1155MetadataExtensionFunctionSelectors
                });

        // map the Pausable test related function selectors to their respective interfaces
        bytes4[] memory pausableFunctionSelectors = new bytes4[](1);

        pausableFunctionSelectors[0] = IPausable.paused.selector;

        ISolidStateDiamond.FacetCut
            memory pausableFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(facetAddress),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: pausableFunctionSelectors
            });

        // map the PerpetualMint test related function selectors to their respective interfaces
        bytes4[] memory perpetualMintFunctionSelectors = new bytes4[](40);

        perpetualMintFunctionSelectors[0] = IPerpetualMint
            .accruedConsolationFees
            .selector;

        perpetualMintFunctionSelectors[1] = IPerpetualMint
            .accruedMintEarnings
            .selector;

        perpetualMintFunctionSelectors[2] = IPerpetualMint
            .accruedProtocolFees
            .selector;

        perpetualMintFunctionSelectors[3] = IPerpetualMint
            .attemptBatchMintWithEth
            .selector;

        perpetualMintFunctionSelectors[4] = IPerpetualMint
            .attemptBatchMintWithMint
            .selector;

        perpetualMintFunctionSelectors[5] = IPerpetualMint.BASIS.selector;

        perpetualMintFunctionSelectors[6] = IPerpetualMint.burnReceipt.selector;

        perpetualMintFunctionSelectors[7] = IPerpetualMint.cancelClaim.selector;

        perpetualMintFunctionSelectors[8] = IPerpetualMint
            .claimMintEarnings
            .selector;

        perpetualMintFunctionSelectors[9] = IPerpetualMint.claimPrize.selector;

        perpetualMintFunctionSelectors[10] = IPerpetualMint
            .claimProtocolFees
            .selector;

        perpetualMintFunctionSelectors[11] = IPerpetualMint
            .collectionMintPrice
            .selector;

        perpetualMintFunctionSelectors[12] = IPerpetualMint
            .collectionPriceToMintRatioBP
            .selector;

        perpetualMintFunctionSelectors[13] = IPerpetualMint
            .collectionRisk
            .selector;

        perpetualMintFunctionSelectors[14] = IPerpetualMint
            .consolationFeeBP
            .selector;

        perpetualMintFunctionSelectors[15] = IPerpetualMint
            .defaultCollectionMintPrice
            .selector;

        perpetualMintFunctionSelectors[16] = IPerpetualMint
            .defaultCollectionRisk
            .selector;

        perpetualMintFunctionSelectors[17] = IPerpetualMint
            .defaultEthToMintRatio
            .selector;

        perpetualMintFunctionSelectors[18] = IPerpetualMint
            .ethToMintRatio
            .selector;

        perpetualMintFunctionSelectors[19] = IPerpetualMint.mintFeeBP.selector;

        perpetualMintFunctionSelectors[20] = IPerpetualMint.mintToken.selector;

        perpetualMintFunctionSelectors[21] = IPerpetualMint
            .onERC1155Received
            .selector;

        perpetualMintFunctionSelectors[22] = IPerpetualMint.pause.selector;

        perpetualMintFunctionSelectors[23] = IPerpetualMint.redeem.selector;

        perpetualMintFunctionSelectors[24] = IPerpetualMint
            .redemptionFeeBP
            .selector;

        perpetualMintFunctionSelectors[25] = IPerpetualMint
            .setCollectionMintPrice
            .selector;

        perpetualMintFunctionSelectors[26] = IPerpetualMint
            .setCollectionPriceToMintRatioBP
            .selector;

        perpetualMintFunctionSelectors[27] = IPerpetualMint
            .setCollectionRisk
            .selector;

        perpetualMintFunctionSelectors[28] = IPerpetualMint
            .setConsolationFeeBP
            .selector;

        perpetualMintFunctionSelectors[29] = IPerpetualMint
            .setEthToMintRatio
            .selector;

        perpetualMintFunctionSelectors[30] = IPerpetualMint
            .setMintFeeBP
            .selector;

        perpetualMintFunctionSelectors[31] = IPerpetualMint
            .setMintToken
            .selector;

        perpetualMintFunctionSelectors[32] = IPerpetualMint
            .setReceiptBaseURI
            .selector;

        perpetualMintFunctionSelectors[33] = IPerpetualMint
            .setReceiptTokenURI
            .selector;

        perpetualMintFunctionSelectors[34] = IPerpetualMint
            .setRedemptionFeeBP
            .selector;

        perpetualMintFunctionSelectors[35] = IPerpetualMint.setTiers.selector;

        perpetualMintFunctionSelectors[36] = IPerpetualMint
            .setVRFConfig
            .selector;

        perpetualMintFunctionSelectors[37] = IPerpetualMint.tiers.selector;

        perpetualMintFunctionSelectors[38] = IPerpetualMint.unpause.selector;

        perpetualMintFunctionSelectors[39] = IPerpetualMint.vrfConfig.selector;

        ISolidStateDiamond.FacetCut
            memory perpetualMintFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(facetAddress),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: perpetualMintFunctionSelectors
            });

        // map the VRFConsumerBaseV2 function selectors to their respective interfaces
        bytes4[] memory vrfConsumerBaseV2FunctionSelectors = new bytes4[](1);

        vrfConsumerBaseV2FunctionSelectors[0] = VRFConsumerBaseV2
            .rawFulfillRandomWords
            .selector;

        ISolidStateDiamond.FacetCut
            memory vrfConsumerBaseV2FacetCut = IDiamondWritableInternal
                .FacetCut({
                    target: address(facetAddress),
                    action: IDiamondWritableInternal.FacetCutAction.ADD,
                    selectors: vrfConsumerBaseV2FunctionSelectors
                });

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](6);

        // omit Ownable and ERC165 since SolidStateDiamond includes those
        facetCuts[0] = erc1155FacetCut;
        facetCuts[1] = erc1155MetadataFacetCut;
        facetCuts[2] = erc1155MetadataExtensionFacetCut;
        facetCuts[3] = pausableFacetCut;
        facetCuts[4] = perpetualMintFacetCut;
        facetCuts[5] = vrfConsumerBaseV2FacetCut;

        return facetCuts;
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
            "/broadcast/02_deployPerpetualMint.s.sol/"
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
            "/broadcast/02_deployPerpetualMint.s.sol/"
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
