// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { ISolidStateDiamond } from "@solidstate/contracts/proxy/diamond/ISolidStateDiamond.sol";

import { ITokenTest } from "./ITokenTest.sol";
import { TokenHelper } from "./TokenHelper.t.sol";
import { TokenProxyTest } from "../../diamonds/TokenProxy.t.sol";

/// @title TokenTest
/// @dev TokenTest helper contract. Configures Token as facet of TokenProxy test.
/// @dev Should function identically across all forks
abstract contract TokenTest is TokenProxyTest {
    ITokenTest public token;

    TokenHelper public tokenHelper;

    uint32 internal constant DISTRIBUTION_FRACTION_BP = 100000000; // 10% split

    /// @dev sets up Token for testing
    function setUp() public virtual override {
        super.setUp();

        initToken();

        token = ITokenTest(address(tokenProxy));

        // set distributionFractionBP value
        token.setDistributionFractionBP(DISTRIBUTION_FRACTION_BP);

        assert(DISTRIBUTION_FRACTION_BP == token.distributionFractionBP());
    }

    /// @dev initializes token as a facet by executing a diamond cut on tokenProxy
    function initToken() internal {
        tokenHelper = new TokenHelper();

        ISolidStateDiamond.FacetCut[] memory facetCuts = tokenHelper
            .getFacetCuts();

        tokenProxy.diamondCut(facetCuts, address(0), "");
    }
}
