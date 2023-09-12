// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import { VRFCoordinatorV2Interface } from "@chainlink/interfaces/VRFCoordinatorV2Interface.sol";
import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";
import { ERC1155BaseInternal } from "@solidstate/contracts/token/ERC1155/base/ERC1155BaseInternal.sol";
import { AddressUtils } from "@solidstate/contracts/utils/AddressUtils.sol";

import { IPerpetualMintInternal } from "./IPerpetualMintInternal.sol";
import { CollectionData, PerpetualMintStorage as Storage, RequestData, TiersData, VRFConfig } from "./Storage.sol";
import { IToken } from "../Token/IToken.sol";

/// @title PerpetualMintInternal facet contract
/// @dev defines modularly all logic for the PerpetualMint mechanism in internal functions
abstract contract PerpetualMintInternal is
    ERC1155BaseInternal,
    IPerpetualMintInternal,
    VRFConsumerBaseV2
{
    using AddressUtils for address payable;
    using EnumerableSet for EnumerableSet.UintSet;

    /// @dev denominator used in percentage calculations
    uint32 internal constant BASIS = 1000000000;

    /// @dev default mint price for a collection
    uint64 internal constant DEFAULT_COLLECTION_MINT_PRICE = 0.01 ether;

    /// @dev default risk for a collection
    uint32 internal constant DEFAULT_COLLECTION_RISK = 1000000; // 0.1%

    // Starting default conversion ratio: 1 ETH = 1,000,000 $MINT
    uint32 internal constant DEFAULT_ETH_TO_MINT_RATIO = 1000000;

    /// @dev address of Chainlink VRFCoordinatorV2 contract
    address private immutable VRF;

    constructor(
        address vrfCoordinator,
        address mintToken
    ) VRFConsumerBaseV2(vrfCoordinator) {
        VRF = vrfCoordinator;
        Storage.layout().mintToken = mintToken;
    }

    /// @notice returns the current accrued consolation fees
    /// @return accruedFees the current amount of accrued consolation fees
    function _accruedConsolationFees()
        internal
        view
        returns (uint256 accruedFees)
    {
        accruedFees = Storage.layout().consolationFees;
    }

    /// @notice returns the current accrued mint earnings across all collections
    /// @return accruedMintEarnings the current amount of accrued mint earnings across all collections
    function _accruedMintEarnings()
        internal
        view
        returns (uint256 accruedMintEarnings)
    {
        accruedMintEarnings = Storage.layout().mintEarnings;
    }

    /// @notice returns the current accrued protocol fees
    /// @return accruedFees the current amount of accrued protocol fees
    function _accruedProtocolFees()
        internal
        view
        returns (uint256 accruedFees)
    {
        accruedFees = Storage.layout().protocolFees;
    }

    /// @notice Attempts a batch mint for the msg.sender for a single collection using ETH as payment.
    /// @param minter address of minter
    /// @param collection address of collection for mint attempts
    /// @param numberOfMints number of mints to attempt
    function _attemptBatchMintWithEth(
        address minter,
        address collection,
        uint32 numberOfMints
    ) internal {
        Storage.Layout storage l = Storage.layout();

        uint256 msgValue = msg.value;

        if (numberOfMints == 0) {
            revert InvalidNumberOfMints();
        }

        CollectionData storage collectionData = l.collections[collection];

        uint256 collectionMintPrice = _collectionMintPrice(collectionData);

        if (msgValue != collectionMintPrice * numberOfMints) {
            revert IncorrectETHReceived();
        }

        // calculate the consolation fee
        uint256 consolationFee = (msgValue * l.consolationFeeBP) / BASIS;

        // calculate the protocol mint fee
        uint256 mintFee = (msgValue * l.mintFeeBP) / BASIS;

        // update the accrued consolation fees
        l.consolationFees += consolationFee;

        // update the accrued depositor mint earnings
        l.mintEarnings += msgValue - consolationFee - mintFee;

        // update the accrued protocol fees
        l.protocolFees += mintFee;

        // if the number of words requested is greater than the max allowed by the VRF coordinator,
        // the request for random words will fail (max random words is currently 500 per request).
        uint32 numWords = numberOfMints; // 1 word per mint, current max of 500 mints per tx

        _requestRandomWords(l, collectionData, minter, collection, numWords);
    }

    /// @notice Attempts a batch mint for the msg.sender for a single collection using $MINT tokens as payment.
    /// @param minter address of minter
    /// @param collection address of collection for mint attempts
    /// @param numberOfMints number of mints to attempt
    function _attemptBatchMintWithMint(
        address minter,
        address collection,
        uint32 numberOfMints
    ) internal {
        Storage.Layout storage l = Storage.layout();

        if (numberOfMints == 0) {
            revert InvalidNumberOfMints();
        }

        CollectionData storage collectionData = l.collections[collection];

        uint256 collectionMintPrice = _collectionMintPrice(collectionData);
        uint256 ethToMintRatio = _ethToMintRatio(l);

        uint256 ethRequired = collectionMintPrice * numberOfMints;

        if (ethRequired > l.consolationFees) {
            revert InsufficientConsolationFees();
        }

        // calculate amount of $MINT required
        uint256 mintRequired = ethRequired * ethToMintRatio;

        IToken(l.mintToken).burn(minter, mintRequired);

        // calculate the consolation fee
        uint256 consolationFee = (ethRequired * l.consolationFeeBP) / BASIS;

        // calculate the protocol mint fee
        uint256 mintFee = (ethRequired * l.mintFeeBP) / BASIS;

        // update the accrued consolation fees
        // ETH required for mint taken from consolationFees
        l.consolationFees -= ethRequired - consolationFee;

        // update the accrued depositor mint earnings
        l.mintEarnings += ethRequired - consolationFee - mintFee;

        // update the accrued protocol fees
        l.protocolFees += mintFee;

        // if the number of words requested is greater than the max allowed by the VRF coordinator,
        // the request for random words will fail (max random words is currently 500 per request).
        uint32 numWords = numberOfMints; // 1 word per mint, current max of 500 mints per tx

        _requestRandomWords(l, collectionData, minter, collection, numWords);
    }

    /// @notice claims all accrued mint earnings across collections
    /// @param recipient address of mint earnings recipient
    function _claimMintEarnings(address recipient) internal {
        Storage.Layout storage l = Storage.layout();

        uint256 mintEarnings = l.mintEarnings;
        l.mintEarnings = 0;

        payable(recipient).sendValue(mintEarnings);
    }

    /// @notice claims all accrued protocol fees
    /// @param recipient address of protocol fees recipient
    function _claimProtocolFees(address recipient) internal {
        Storage.Layout storage l = Storage.layout();

        uint256 protocolFees = l.protocolFees;
        l.protocolFees = 0;

        payable(recipient).sendValue(protocolFees);
    }

    /// @notice Returns the current mint price for a given collection
    /// @param collectionData the CollectionData struct for a given collection
    /// @return mintPrice current collection mint price
    function _collectionMintPrice(
        CollectionData storage collectionData
    ) internal view returns (uint256 mintPrice) {
        mintPrice = collectionData.mintPrice;

        mintPrice = mintPrice == 0 ? DEFAULT_COLLECTION_MINT_PRICE : mintPrice;
    }

    /// @notice Returns the current collection-wide risk of a collection
    /// @param collectionData the CollectionData struct for a given collection
    /// @return risk value of collection-wide risk
    function _collectionRisk(
        CollectionData storage collectionData
    ) internal view returns (uint32 risk) {
        risk = collectionData.risk;

        risk = risk == 0 ? DEFAULT_COLLECTION_RISK : risk;
    }

    /// @notice Returns the current consolation fee in basis points
    /// @return consolationFeeBasisPoints consolation fee in basis points
    function _consolationFeeBP()
        internal
        view
        returns (uint32 consolationFeeBasisPoints)
    {
        consolationFeeBasisPoints = Storage.layout().consolationFeeBP;
    }

    /// @notice Returns the default mint price for a collection
    /// @return mintPrice default collection mint price
    function _defaultCollectionMintPrice()
        internal
        pure
        returns (uint256 mintPrice)
    {
        mintPrice = DEFAULT_COLLECTION_MINT_PRICE;
    }

    /// @notice Returns the default risk for a collection
    /// @return risk default collection risk
    function _defaultCollectionRisk() internal pure returns (uint32 risk) {
        risk = DEFAULT_COLLECTION_RISK;
    }

    /// @notice Returns the default ETH to $MINT ratio
    /// @return ratio default ETH to $MINT ratio
    function _defaultEthToMintRatio() internal pure returns (uint32 ratio) {
        ratio = DEFAULT_ETH_TO_MINT_RATIO;
    }

    /// @notice enforces that a risk value does not exceed the BASIS
    /// @param risk risk value to check
    function _enforceBasis(uint32 risk) internal pure {
        if (risk > BASIS) {
            revert BasisExceeded();
        }
    }

    /// @dev enforces that there are no pending mint requests for a collection
    /// @param collectionData the CollectionData struct for a given collection
    function _enforceNoPendingMints(
        CollectionData storage collectionData
    ) internal view {
        if (collectionData.pendingRequests.length() != 0) {
            revert PendingRequests();
        }
    }

    /// @notice Returns the current ETH to $MINT ratio
    /// @param l the PerpetualMint storage layout
    /// @return ratio current ETH to $MINT ratio
    function _ethToMintRatio(
        Storage.Layout storage l
    ) internal view returns (uint256 ratio) {
        ratio = l.ethToMintRatio;

        ratio = ratio == 0 ? DEFAULT_ETH_TO_MINT_RATIO : ratio;
    }

    /// @notice internal Chainlink VRF callback
    /// @notice is executed by the ChainlinkVRF Coordinator contract
    /// @param requestId id of chainlinkVRF request
    /// @param randomWords random values return by ChainlinkVRF Coordinator
    function _fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal virtual {
        Storage.Layout storage l = Storage.layout();

        RequestData storage request = l.requests[requestId];

        address collection = request.collection;
        address minter = request.minter;

        CollectionData storage collectionData = l.collections[collection];

        _resolveMints(
            l.mintToken,
            collectionData,
            l.tiers,
            minter,
            collection,
            randomWords
        );

        collectionData.pendingRequests.remove(requestId);

        delete l.requests[requestId];
    }

    /// @notice Returns the current mint fee in basis points
    /// @return mintFeeBasisPoints mint fee in basis points
    function _mintFeeBP() internal view returns (uint32 mintFeeBasisPoints) {
        mintFeeBasisPoints = Storage.layout().mintFeeBP;
    }

    /// @notice Returns the address of the current $MINT token
    /// @return mintToken address of the current $MINT token
    function _mintToken() internal view returns (address mintToken) {
        mintToken = Storage.layout().mintToken;
    }

    /// @notice ensures a value is within the BASIS range
    /// @param value value to normalize
    /// @return normalizedValue value after normalization
    function _normalizeValue(
        uint256 value,
        uint32 basis
    ) internal pure returns (uint256 normalizedValue) {
        normalizedValue = value % basis;
    }

    /// @notice redeems an amount of $MINT tokens for ETH (native token) for an account
    /// @dev only one-sided ($MINT => ETH (native token)) supported
    /// @param account address of account
    /// @param amount amount of $MINT
    function _redeem(
        address account,
        uint256 amount
    ) internal returns (uint256 ethAmount) {
        Storage.Layout storage l = Storage.layout();

        // burn amount of $MINT to be swapped
        IToken(l.mintToken).burn(account, amount);

        // calculate amount of ETH given for $MINT amount
        ethAmount =
            (amount * (BASIS - l.redemptionFeeBP)) /
            (BASIS * _ethToMintRatio(l));

        // decrease mintEarnings
        l.mintEarnings -= ethAmount;

        payable(account).sendValue(ethAmount);
    }

    /// @notice returns the current redemption fee in basis points
    /// @return feeBP redemptionFee in basis points
    function _redemptionFeeBP() internal view returns (uint32 feeBP) {
        feeBP = Storage.layout().redemptionFeeBP;
    }

    /// @notice requests random values from Chainlink VRF
    /// @param l the PerpetualMint storage layout
    /// @param collectionData the CollectionData struct for a given collection
    /// @param minter address calling this function
    /// @param collection address of collection to attempt mint for
    /// @param numWords amount of random values to request
    function _requestRandomWords(
        Storage.Layout storage l,
        CollectionData storage collectionData,
        address minter,
        address collection,
        uint32 numWords
    ) internal {
        uint256 requestId = VRFCoordinatorV2Interface(VRF).requestRandomWords(
            l.vrfConfig.keyHash,
            l.vrfConfig.subscriptionId,
            l.vrfConfig.minConfirmations,
            l.vrfConfig.callbackGasLimit,
            numWords
        );

        collectionData.pendingRequests.add(requestId);

        RequestData storage request = l.requests[requestId];

        request.collection = collection;
        request.minter = minter;
    }

    /// @notice resolves the outcomes of attempted mints for a given collection
    /// @param mintToken address of $MINT token
    /// @param collectionData the CollectionData struct for a given collection
    /// @param tiersData the TiersData struct for mint consolations
    /// @param minter address of minter
    /// @param collection address of collection for mint attempts
    /// @param randomWords array of random values relating to number of attempts
    function _resolveMints(
        address mintToken,
        CollectionData storage collectionData,
        TiersData memory tiersData,
        address minter,
        address collection,
        uint256[] memory randomWords
    ) internal {
        uint32 basis = BASIS;

        uint256 totalMintAmount = 0;
        uint256 totalReceiptAmount = 0;

        for (uint256 i = 0; i < randomWords.length; ++i) {
            uint256 normalizedValue = _normalizeValue(randomWords[i], basis);

            bool result = _collectionRisk(collectionData) > normalizedValue;

            if (!result) {
                uint256 tierMintAmount;
                uint256 cumulativeRisk;

                // iterate through tiers to find the tier that the random value falls into
                for (uint256 j = 0; j < tiersData.tierRisks.length; ++j) {
                    cumulativeRisk += tiersData.tierRisks[j];

                    // if the cumulative risk is greater than the normalized value, the tier has been found
                    if (cumulativeRisk > normalizedValue) {
                        tierMintAmount = tiersData.tierMintAmounts[j];
                        break;
                    }
                }

                totalMintAmount += tierMintAmount;
            } else {
                ++totalReceiptAmount;
            }

            emit MintResolved(collection, result);
        }

        // Mint the cumulative amounts at the end
        if (totalMintAmount > 0) {
            IToken(mintToken).mint(minter, totalMintAmount);
        }

        if (totalReceiptAmount > 0) {
            _safeMint(
                minter,
                uint256(bytes32(abi.encode(collection))), // encode collection address as tokenId
                totalReceiptAmount,
                ""
            );
        }
    }

    /// @notice set the mint price for a given collection
    /// @param collection address of collection
    /// @param price mint price of the collection
    function _setCollectionMintPrice(
        address collection,
        uint256 price
    ) internal {
        Storage.layout().collections[collection].mintPrice = price;

        emit MintPriceSet(collection, price);
    }

    /// @notice sets the risk for a given collection
    /// @param collection address of collection
    /// @param risk risk of the collection
    function _setCollectionRisk(address collection, uint32 risk) internal {
        CollectionData storage collectionData = Storage.layout().collections[
            collection
        ];

        _enforceBasis(risk);

        _enforceNoPendingMints(collectionData);

        collectionData.risk = risk;

        emit CollectionRiskSet(collection, risk);
    }

    /// @notice sets the consolation fee in basis points
    /// @param consolationFeeBP consolation fee in basis points
    function _setConsolationFeeBP(uint32 consolationFeeBP) internal {
        Storage.layout().consolationFeeBP = consolationFeeBP;
    }

    /// @notice sets the ratio of ETH (native token) to $MINT for mint attempts using $MINT as payment
    /// @param ratio new ratio of ETH to $MINT
    function _setEthToMintRatio(uint256 ratio) internal {
        Storage.layout().ethToMintRatio = ratio;
    }

    /// @notice sets the mint fee in basis points
    /// @param mintFeeBP mint fee in basis points
    function _setMintFeeBP(uint32 mintFeeBP) internal {
        Storage.layout().mintFeeBP = mintFeeBP;
    }

    function _setMintToken(address mintToken) internal {
        Storage.layout().mintToken = mintToken;
    }

    /// @notice sets the redemption fee in basis points
    /// @param redemptionFeeBP redemption fee in basis points
    function _setRedemptionFeeBP(uint32 redemptionFeeBP) internal {
        Storage.layout().redemptionFeeBP = redemptionFeeBP;
    }

    /// @notice sets the $MINT consolation tiers data
    /// @param tiersData TiersData struct holding all related data to $MINT consolations
    function _setTiers(TiersData calldata tiersData) internal {
        Storage.layout().tiers = tiersData;
    }

    /// @notice sets the Chainlink VRF config
    /// @param config VRFConfig struct holding all related data to ChainlinkVRF
    function _setVRFConfig(VRFConfig calldata config) internal {
        Storage.layout().vrfConfig = config;

        emit VRFConfigSet(config);
    }

    function _tiers() internal view returns (TiersData memory tiersData) {
        tiersData = Storage.layout().tiers;
    }

    /// @notice Returns the current Chainlink VRF config
    /// @return config VRFConfig struct
    function _vrfConfig() internal view returns (VRFConfig memory config) {
        config = Storage.layout().vrfConfig;
    }
}
