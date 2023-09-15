// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IERC20 } from "@solidstate/contracts/interfaces/IERC20.sol";
import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";
import { IDiamondWritableInternal } from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";

import { ITokenHarness } from "./ITokenHarness.sol";
import { TokenHarness } from "./TokenHarness.t.sol";
import { IToken } from "../../../contracts/facets/Token/IToken.sol";
import { TokenStorage as Storage } from "../../../contracts/facets/Token/Storage.sol";

/// @title TokenHelper
/// @dev Test helper contract for setting up Token facet for diamond cutting and testing
contract TokenHelper {
    TokenHarness public tokenHarnessImplementation;

    /// @dev deploys TokenHarness implementation
    constructor() {
        tokenHarnessImplementation = new TokenHarness();
    }

    /// @dev provides the facet cuts for setting up Token in TokenProxy diamond
    function getFacetCuts()
        external
        view
        returns (ISolidStateDiamond.FacetCut[] memory)
    {
        // map the Token test related function selectors to their respective interfaces
        bytes4[] memory erc20FunctionSelectors = new bytes4[](6);

        erc20FunctionSelectors[0] = IERC20.totalSupply.selector;
        erc20FunctionSelectors[1] = IERC20.balanceOf.selector;
        erc20FunctionSelectors[2] = IERC20.allowance.selector;
        erc20FunctionSelectors[3] = IERC20.approve.selector;
        erc20FunctionSelectors[4] = IERC20.transfer.selector;
        erc20FunctionSelectors[5] = IERC20.transferFrom.selector;

        ISolidStateDiamond.FacetCut
            memory erc20FacetCut = IDiamondWritableInternal.FacetCut({
                target: address(tokenHarnessImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: erc20FunctionSelectors
            });

        bytes4[] memory tokenFunctionSelectors = new bytes4[](14);

        tokenFunctionSelectors[0] = IToken.accrualData.selector;
        tokenFunctionSelectors[1] = IToken.addMintingContract.selector;
        tokenFunctionSelectors[2] = IToken.BASIS.selector;
        tokenFunctionSelectors[3] = IToken.burn.selector;
        tokenFunctionSelectors[4] = IToken.claim.selector;
        tokenFunctionSelectors[5] = IToken.claimableTokens.selector;
        tokenFunctionSelectors[6] = IToken.distributionFractionBP.selector;
        tokenFunctionSelectors[7] = IToken.distributionSupply.selector;
        tokenFunctionSelectors[8] = IToken.globalRatio.selector;
        tokenFunctionSelectors[9] = IToken.mint.selector;
        tokenFunctionSelectors[10] = IToken.mintingContracts.selector;
        tokenFunctionSelectors[11] = IToken.removeMintingContract.selector;
        tokenFunctionSelectors[12] = IToken.SCALE.selector;
        tokenFunctionSelectors[13] = IToken.setDistributionFractionBP.selector;

        ISolidStateDiamond.FacetCut
            memory tokenFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(tokenHarnessImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: tokenFunctionSelectors
            });

        bytes4[] memory tokenHarnessFunctionSelectors = new bytes4[](2);

        tokenHarnessFunctionSelectors[0] = ITokenHarness
            .exposed_accrueTokens
            .selector;

        tokenHarnessFunctionSelectors[1] = ITokenHarness
            .exposed_beforeTokenTransfer
            .selector;

        ISolidStateDiamond.FacetCut
            memory tokenHarnessFacetCut = IDiamondWritableInternal.FacetCut({
                target: address(tokenHarnessImplementation),
                action: IDiamondWritableInternal.FacetCutAction.ADD,
                selectors: tokenHarnessFunctionSelectors
            });

        ISolidStateDiamond.FacetCut[]
            memory facetCuts = new ISolidStateDiamond.FacetCut[](3);

        facetCuts[0] = erc20FacetCut;
        facetCuts[1] = tokenFacetCut;
        facetCuts[2] = tokenHarnessFacetCut;

        return facetCuts;
    }
}
