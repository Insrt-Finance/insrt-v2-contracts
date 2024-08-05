// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { PerpetualMintInternal } from "./PerpetualMintInternal.sol";
import { PerpetualMintStorage as Storage } from "./Storage.sol";
import { IPerpetualMintEmergencyWithdraw } from "./IPerpetualMintEmergencyWithdraw.sol";

import { AddressUtils } from "@solidstate/contracts/utils/AddressUtils.sol";

/// @title PerpetualMintEmergencyWithdraw
/// @dev extracts all ETH balance from PerpetualMintCore under dire market crash situation
contract PerpetualMintEmergencyWithdraw is
    IPerpetualMintEmergencyWithdraw,
    PerpetualMintInternal
{
    using AddressUtils for address payable;

    constructor(address vrf) PerpetualMintInternal(vrf) {}

    function withdrawAllFunds(address to) external onlyOwner {
        Storage.Layout storage l = Storage.layout();

        payable(to).sendValue(address(this).balance);

        delete l.mintEarnings;
        delete l.protocolFees;
        delete l.consolationFees;
    }

    /// @notice Chainlink VRF Coordinator callback
    /// @param requestId id of request for random values
    /// @param randomWords random values returned from Chainlink VRF coordination
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal virtual override {
        _fulfillRandomWords(requestId, randomWords);
    }
}
