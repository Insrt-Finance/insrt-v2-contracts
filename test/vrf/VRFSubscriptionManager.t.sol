// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { LinkTokenInterface } from "@chainlink/interfaces/LinkTokenInterface.sol";
import { VRFCoordinatorV2Interface } from "@chainlink/interfaces/VRFCoordinatorV2Interface.sol";
import { Ownable } from "@solidstate/contracts/access/ownable/Ownable.sol";

contract VRFSubscriptionManager is Ownable {
    address public immutable VRF;
    address public immutable LINK;
    address public immutable TREASURY;

    constructor(address vrfCoordinator, address linkToken, address treasury) {
        _setOwner(msg.sender);
        VRF = vrfCoordinator;
        LINK = linkToken;
        TREASURY = treasury;
    }

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @dev will revert if original owner of subId has
     * not requested that msg.sender become the new owner.
     */
    function acceptSubscriptionOwnerTransfer(uint64 subId) external onlyOwner {
        VRFCoordinatorV2Interface(VRF).acceptSubscriptionOwnerTransfer(subId);
    }

    /**
     * @notice Add a consumer to a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - New consumer which can use the subscription
     */
    function addConsumer(uint64 subId, address consumer) external onlyOwner {
        VRFCoordinatorV2Interface(VRF).addConsumer(subId, consumer);
    }

    /**
     * @notice Cancel a subscription and send remaining link funds to treasury
     * @param subId - ID of the subscription
     */
    function cancelSubscription(uint64 subId) external onlyOwner {
        VRFCoordinatorV2Interface(VRF).cancelSubscription(subId, TREASURY);
    }

    /**
     * @notice Create a VRF subscription.
     * @return subId - A unique subscription id.
     */
    function createSubscription() external onlyOwner returns (uint64 subId) {
        subId = VRFCoordinatorV2Interface(VRF).createSubscription();
    }

    /**
     * @notice funds a subscription with LINK tokens
     * @param subId - ID of the subscription
     * @param amount amount of LINK tokens to fund with
     */
    function fundSubscription(uint64 subId, uint256 amount) external onlyOwner {
        LinkTokenInterface(LINK).transferAndCall(
            VRF,
            amount,
            abi.encode(subId)
        );
    }

    /**
     * @notice Get a VRF subscription.
     * @param subId - ID of the subscription
     * @return balance - LINK balance of the subscription in juels.
     * @return reqCount - number of requests for this subscription, determines fee tier.
     * @return owner - owner of the subscription.
     * @return consumers - list of consumer address which are able to use this subscription.
     */
    function getSubscription(
        uint64 subId
    )
        external
        view
        returns (
            uint96 balance,
            uint64 reqCount,
            address owner,
            address[] memory consumers
        )
    {
        return VRFCoordinatorV2Interface(VRF).getSubscription(subId);
    }

    /**
     * @notice Check to see if there exists a request commitment consumers
     * for all consumers and keyhashes for a given sub.
     * @param subId - ID of the subscription
     * @return true if there exists at least one unfulfilled request for the subscription, false
     * otherwise.
     */
    function pendingRequestExists(uint64 subId) external view returns (bool) {
        return VRFCoordinatorV2Interface(VRF).pendingRequestExists(subId);
    }

    /**
     * @notice Remove a consumer from a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - Consumer to remove from the subscription
     */
    function removeConsumer(uint64 subId, address consumer) external onlyOwner {
        VRFCoordinatorV2Interface(VRF).removeConsumer(subId, consumer);
    }

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @param newOwner - proposed new owner of the subscription
     */
    function requestSubscriptionOwnerTransfer(
        uint64 subId,
        address newOwner
    ) external onlyOwner {
        VRFCoordinatorV2Interface(VRF).requestSubscriptionOwnerTransfer(
            subId,
            newOwner
        );
    }
}
