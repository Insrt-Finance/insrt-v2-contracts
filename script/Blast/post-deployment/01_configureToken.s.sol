// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import { ITokenProxy } from "../../../contracts/diamonds/Token/ITokenProxy.sol";
import { IToken } from "../../../contracts/facets/Token/IToken.sol";

/// @title ConfigureToken_Blast
/// @dev configures the Token contract after deployment by setting the distribution fraction BP,
/// and adding the PerpetualMint contract as a minting contract
contract ConfigureToken_Blast is Script {
    /// @dev runs the script logic
    function run() external {
        // read deployer private key
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");

        // read new TokenProxy owner address
        address newOwner = vm.envAddress("NEW_TOKEN_PROXY_OWNER");

        // read PerpetualMint address
        address payable perpetualMint = readCoreBlastAddress();

        uint32 distributionFractionBP = uint32(
            vm.envUint("TOKEN_DISTRIBUTION_FRACTION_BP")
        );

        IToken token = IToken(readTokenProxyAddress());

        vm.startBroadcast(deployerPrivateKey);

        token.addMintingContract(perpetualMint);

        token.setDistributionFractionBP(distributionFractionBP);

        ITokenProxy(payable(address(token))).transferOwnership(newOwner);

        console.log(
            "Token Distribution Fraction BP Set: ",
            distributionFractionBP
        );
        console.log("Token Minting Contract Added: ", perpetualMint);
        console.log("TokenProxy Ownership Transferred To: ", newOwner);

        vm.stopBroadcast();
    }

    /// @notice attempts to read the saved address of the CoreBlast diamond contract, post-deployment
    /// @return coreBlastAddress address of the deployed CoreBlast diamond contract
    function readCoreBlastAddress()
        internal
        view
        returns (address payable coreBlastAddress)
    {
        string memory inputDir = string.concat(
            vm.projectRoot(),
            "/broadcast/02_deployPerpetualMint.s.sol/"
        );

        string memory chainDir = string.concat(vm.toString(block.chainid), "/");

        string memory file = string.concat(
            "run-latest-core-blast-address",
            ".txt"
        );

        return
            payable(
                vm.parseAddress(
                    vm.readFile(string.concat(inputDir, chainDir, file))
                )
            );
    }

    /// @notice attempts to read the saved address of the TokenProxy diamond contract, post-deployment
    /// @return tokenProxyAddress address of the deployed TokenProxy diamond contract
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
}
