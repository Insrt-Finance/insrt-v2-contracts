// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import { IERC20 } from "@solidstate/contracts/interfaces/IERC20.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";
import { IERC20Extended } from "@solidstate/contracts/token/ERC20/extended/IERC20Extended.sol";
import { IERC20Metadata } from "@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol";
import { IERC2612 } from "@solidstate/contracts/token/ERC20/permit/IERC20Permit.sol";

import { ITokenProxy } from "../../contracts/diamonds/Token/ITokenProxy.sol";
import { TokenProxy } from "../../contracts/diamonds/Token/TokenProxy.sol";
import { IToken } from "../../contracts/facets/Token/IToken.sol";
import { Token } from "../../contracts/facets/Token/Token.sol";

/// @title DeployToken
/// @dev deploys the TokenProxy diamond contract and the Token facet, and performs
/// a diamondCut of the Token facet onto the TokenProxy diamond
contract DeployToken is Script {
    /// @dev runs the script logic
    function run() external {
        //NOTE: CHANGE AS NEEDED FOR PRODUCTION
        string memory name = "MINT";
        string memory symbol = "$MINT";

        // read deployer private key
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // deploy Token facet
        Token tokenFacet = new Token();

        // deploy TokenProxy
        TokenProxy proxy = new TokenProxy(name, symbol);

        console.log("Token Facet Address: ", address(tokenFacet));
        console.log("Token Proxy Address: ", address(proxy));

        writeTokenProxyAddress(address(proxy));

        // get Token facet cuts
        ISolidStateDiamond.FacetCut[] memory facetCuts = getTokenFacetCuts(
            address(tokenFacet)
        );

        // cut Token into TokenProxy
        ISolidStateDiamond(proxy).diamondCut(facetCuts, address(0), "");

        vm.stopBroadcast();
    }

    /// @dev provides the facet cuts for cutting Token facet into TokenProxy
    /// @param facetAddress address of Token facet
    function getTokenFacetCuts(
        address facetAddress
    ) internal pure returns (ISolidStateDiamond.FacetCut[] memory) {
        // map the ERC20 function selectors to their respective interfaces
        bytes4[] memory erc20FunctionSelectors = new bytes4[](14);

        // base selector
        erc20FunctionSelectors[0] = IERC20.totalSupply.selector;
        erc20FunctionSelectors[1] = IERC20.balanceOf.selector;
        erc20FunctionSelectors[2] = IERC20.allowance.selector;
        erc20FunctionSelectors[3] = IERC20.approve.selector;
        erc20FunctionSelectors[4] = IERC20.transfer.selector;
        erc20FunctionSelectors[5] = IERC20.transferFrom.selector;

        // extended selectors
        erc20FunctionSelectors[6] = IERC20Extended.increaseAllowance.selector;
        erc20FunctionSelectors[7] = IERC20Extended.decreaseAllowance.selector;

        // metadata selectors
        erc20FunctionSelectors[8] = IERC20Metadata.decimals.selector;
        erc20FunctionSelectors[9] = IERC20Metadata.name.selector;
        erc20FunctionSelectors[10] = IERC20Metadata.symbol.selector;

        // permit selectors
        erc20FunctionSelectors[11] = IERC2612.DOMAIN_SEPARATOR.selector;
        erc20FunctionSelectors[12] = IERC2612.nonces.selector;
        erc20FunctionSelectors[13] = IERC2612.permit.selector;

        ISolidStateDiamond.FacetCut
            memory erc20FacetCut = IDiamondWritableInternal.FacetCut({
                target: address(facetAddress),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: erc20FunctionSelectors
            });

        // map the Token function selectors to their respective interfaces
        bytes4[] memory tokenFunctionSelectors = new bytes4[](17);

        tokenFunctionSelectors[0] = IToken.accrualData.selector;
        tokenFunctionSelectors[1] = IToken.addMintingContract.selector;
        tokenFunctionSelectors[2] = IToken.airdropSupply.selector;
        tokenFunctionSelectors[3] = IToken.BASIS.selector;
        tokenFunctionSelectors[4] = IToken.burn.selector;
        tokenFunctionSelectors[5] = IToken.claim.selector;
        tokenFunctionSelectors[6] = IToken.claimableTokens.selector;
        tokenFunctionSelectors[7] = IToken.disperseTokens.selector;
        tokenFunctionSelectors[8] = IToken.distributionFractionBP.selector;
        tokenFunctionSelectors[9] = IToken.distributionSupply.selector;
        tokenFunctionSelectors[10] = IToken.globalRatio.selector;
        tokenFunctionSelectors[11] = IToken.mint.selector;
        tokenFunctionSelectors[12] = IToken.mintAirdrop.selector;
        tokenFunctionSelectors[13] = IToken.mintingContracts.selector;
        tokenFunctionSelectors[14] = IToken.removeMintingContract.selector;
        tokenFunctionSelectors[15] = IToken.SCALE.selector;
        tokenFunctionSelectors[16] = IToken.setDistributionFractionBP.selector;

        ISolidStateDiamond.FacetCut
            memory tokenFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(facetAddress),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: tokenFunctionSelectors
            });

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](2);

        facetCuts[0] = erc20FacetCut;
        facetCuts[1] = tokenFacetCut;

        return facetCuts;
    }

    function writeTokenProxyAddress(address tokenProxyAddress) internal {
        string memory inputDir = string.concat(
            vm.projectRoot(),
            "/broadcast/01_deployToken.s.sol/"
        );

        string memory chainDir = string.concat(vm.toString(block.chainid), "/");

        string memory file = string.concat(
            "run-latest-token-proxy-address",
            ".txt"
        );

        vm.writeFile(
            string.concat(inputDir, chainDir, file),
            vm.toString(tokenProxyAddress)
        );
    }
}
