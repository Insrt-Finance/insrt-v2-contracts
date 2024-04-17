// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import { VRFCoordinatorV2Interface } from "@chainlink/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import { VRFConsumerBaseV2 } from "@chainlink/vrf/VRFConsumerBaseV2.sol";
import { OwnableInternal } from "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";
import { PausableInternal } from "@solidstate/contracts/security/pausable/PausableInternal.sol";
import { ERC1155BaseInternal } from "@solidstate/contracts/token/ERC1155/base/ERC1155BaseInternal.sol";
import { ERC1155MetadataInternal } from "@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataInternal.sol";
import { AddressUtils } from "@solidstate/contracts/utils/AddressUtils.sol";

import { IGas } from "./Blast/IGas.sol";
import { ERC1155MetadataExtensionInternal } from "./ERC1155MetadataExtensionInternal.sol";
import { IPerpetualMintInternal } from "./IPerpetualMintInternal.sol";
import { CollectionData, MintOutcome, MintResultData, MintResultDataBlast, MintTokenTiersData, PerpetualMintStorage as Storage, RequestData, TiersData, VRFConfig } from "./Storage.sol";
import { IToken } from "../Token/IToken.sol";
import { GuardsInternal } from "../../common/GuardsInternal.sol";
import { IBlast } from "../../diamonds/Core/Blast/IBlast.sol";
import { ISupraRouterContract } from "../../vrf/Supra/ISupraRouterContract.sol";

/// @title PerpetualMintInternal
/// @dev defines modularly all logic for the PerpetualMint mechanism in internal functions
abstract contract PerpetualMintInternal is
    ERC1155BaseInternal,
    ERC1155MetadataExtensionInternal,
    ERC1155MetadataInternal,
    GuardsInternal,
    OwnableInternal,
    PausableInternal,
    IPerpetualMintInternal,
    VRFConsumerBaseV2
{
    using AddressUtils for address payable;
    using EnumerableSet for EnumerableSet.UintSet;

    /// @dev used for floating point calculations
    uint256 private constant SCALE = 1e36;

    /// @dev denominator used in percentage calculations
    uint32 private constant BASIS = 1e9;

    /// @dev default mint price for a collection
    uint64 internal constant DEFAULT_COLLECTION_MINT_PRICE = 0.01 ether;

    /// @dev default risk for a collection
    uint32 internal constant DEFAULT_COLLECTION_RISK = 1e6; // 0.1%

    /// @dev Starting default conversion ratio: 1 ETH = 1,000,000 $MINT
    uint32 internal constant DEFAULT_ETH_TO_MINT_RATIO = 1e6;

    /// @dev minimum price per spin, 0.0025 ETH / 2,500 $MINT
    uint256 internal constant MINIMUM_PRICE_PER_SPIN = 0.0025 ether;

    /// @dev address of the Blast precompile
    address private constant BLAST = 0x4300000000000000000000000000000000000002;

    /// @dev address used to represent ETH as a collection
    address private constant ETH_COLLECTION_ADDRESS =
        address(type(uint160).max);

    /// @dev address of the Blast Gas precompile
    address private constant GAS = 0x4300000000000000000000000000000000000001;

    /// @dev address used to represent the $MINT token as a collection
    address private constant MINT_TOKEN_COLLECTION_ADDRESS = address(0);

    /// @dev address of the configured VRF
    address private immutable VRF;

    constructor(address vrfCoordinator) VRFConsumerBaseV2(vrfCoordinator) {
        VRF = vrfCoordinator;
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

    function _attemptBatchMint_calculateMintPriceAdjustmentFactor(
        CollectionData storage collectionData,
        uint256 pricePerSpin
    ) private view returns (uint256 mintPriceAdjustmentFactor) {
        // upscale pricePerSpin before division to maintain precision
        uint256 scaledPricePerSpin = pricePerSpin * SCALE;

        // calculate the mint price adjustment factor & scale back down
        mintPriceAdjustmentFactor =
            ((scaledPricePerSpin / _collectionMintPrice(collectionData)) *
                BASIS) /
            SCALE;
    }

    function _attemptBatchMint_paidInEth_validateMintParameters(
        uint256 msgValue,
        uint256 pricePerSpin
    ) private pure {
        // throw if the price per spin is less than the minimum price per spin
        if (pricePerSpin < MINIMUM_PRICE_PER_SPIN) {
            revert PricePerSpinTooLow();
        }

        // throw if the price per spin is not evenly divisible by the ETH sent, i.e. the ETH sent is not a multiple of the price per spin
        if (msgValue % pricePerSpin != 0) {
            revert IncorrectETHReceived();
        }
    }

    function _attemptBatchMint_paidInMint_validateMintParameters(
        uint32 numberOfMints,
        uint256 consolationFees,
        uint256 ethRequired,
        uint256 pricePerSpinInWei,
        uint256 pricePerMint
    ) private pure {
        if (numberOfMints == 0) {
            revert InvalidNumberOfMints();
        }

        // throw if the price per spin is less than the minimum price per spin
        if (pricePerSpinInWei < MINIMUM_PRICE_PER_SPIN) {
            revert PricePerSpinTooLow();
        }

        // throw if the price per mint specified is a fraction and not evenly divisible by the price per spin in wei
        if (pricePerMint % pricePerSpinInWei != 0) {
            revert InvalidPricePerMint();
        }

        if (ethRequired > consolationFees) {
            revert InsufficientConsolationFees();
        }
    }

    function _attemptBatchMintForEth_checkMaxPayout(
        uint256 mintEarnings,
        uint256 ethPrizeValueInWei,
        uint32 mintEarningsBufferBP,
        uint32 numberOfMints
    ) private pure {
        // throw if the potential max payout is greater than mint earnings when adjusted using the mint earnings buffer
        if (
            numberOfMints * ethPrizeValueInWei >
            (mintEarnings * (BASIS - mintEarningsBufferBP)) / BASIS
        ) {
            revert InsufficientMintEarnings();
        }
    }

    /// @notice Attempts a batch mint for the msg.sender for ETH using ETH as payment.
    /// @param minter address of minter
    /// @param referrer address of referrer
    /// @param numberOfMints number of mints to attempt
    /// @param ethPrizeValueInWei value of ETH prize in wei
    function _attemptBatchMintForEthWithEth(
        address minter,
        address referrer,
        uint32 numberOfMints,
        uint256 ethPrizeValueInWei
    ) internal {
        uint256 msgValue = msg.value;

        uint256 pricePerSpin = msgValue / numberOfMints;

        _attemptBatchMint_paidInEth_validateMintParameters(
            msgValue,
            pricePerSpin
        );

        Storage.Layout storage l = Storage.layout();

        _attemptBatchMintForEth_checkMaxPayout(
            l.mintEarnings,
            ethPrizeValueInWei,
            l.mintEarningsBufferBP,
            numberOfMints
        );

        CollectionData storage collectionData = l.collections[
            ETH_COLLECTION_ADDRESS
        ];

        uint256 mintEarningsFee = _attemptBatchMintForEthWithEth_calculateAndDistributeFees(
                l,
                collectionData,
                msgValue,
                referrer
            );

        // if the number of words requested is greater than the max allowed by the VRF coordinator,
        // the request for random words will fail (max random words is currently 500 per request).
        uint32 numWords = numberOfMints * 2; // 2 words per mint for ETH, current max of 250 mints per tx

        uint256 mintPriceAdjustmentFactor = _attemptBatchMint_calculateMintPriceAdjustmentFactor(
                collectionData,
                pricePerSpin
            );

        _requestRandomWords(
            l,
            collectionData,
            minter,
            ETH_COLLECTION_ADDRESS,
            mintEarningsFee,
            mintPriceAdjustmentFactor,
            ethPrizeValueInWei,
            numWords
        );
    }

    function _attemptBatchMintForEthWithEthSupra(
        address minter,
        address referrer,
        uint8 numberOfMints,
        uint8 wordsPerMint,
        uint256 ethPrizeValueInWei
    ) internal {
        uint256 msgValue = msg.value;

        uint256 pricePerSpin = msgValue / numberOfMints;

        _attemptBatchMint_paidInEth_validateMintParameters(
            msgValue,
            pricePerSpin
        );

        Storage.Layout storage l = Storage.layout();

        _attemptBatchMintForEth_checkMaxPayout(
            l.mintEarnings,
            ethPrizeValueInWei,
            l.mintEarningsBufferBP,
            numberOfMints
        );

        CollectionData storage collectionData = l.collections[
            ETH_COLLECTION_ADDRESS
        ];

        uint256 mintEarningsFee = _attemptBatchMintForEthWithEth_calculateAndDistributeFees(
                l,
                collectionData,
                msgValue,
                referrer
            );

        // Calculate the total number of random words required for the Supra VRF request.
        // Constraints:
        // 1. numWords = 0 results in a revert.
        // 2. Supra VRF limit: The maximum number of words allowed per request is 255.
        // If the number of words requested exceeds this limit, the function call will revert.
        //    - For Blast Supra: 3 words per mint (max 85 mints per transaction).
        //    - For standard Supra: 2 word per mint (max 127 mints per transaction).
        uint8 numWords = numberOfMints * wordsPerMint;

        uint256 mintPriceAdjustmentFactor = _attemptBatchMint_calculateMintPriceAdjustmentFactor(
                collectionData,
                pricePerSpin
            );

        _requestRandomWordsSupra(
            l,
            collectionData,
            minter,
            ETH_COLLECTION_ADDRESS,
            mintEarningsFee,
            mintPriceAdjustmentFactor,
            ethPrizeValueInWei,
            numWords
        );
    }

    function _attemptBatchMintForEthWithEth_calculateAndDistributeFees(
        Storage.Layout storage l,
        CollectionData storage collectionData,
        uint256 msgValue,
        address referrer
    ) private returns (uint256 mintEarningsFee) {
        // calculate the mint for ETH consolation fee
        uint256 mintForEthConsolationFee = (msgValue *
            l.mintForEthConsolationFeeBP) / BASIS;

        // Apply the mint for ETH-specific fee ratio
        uint256 additionalDepositorFee = (mintForEthConsolationFee *
            collectionData.mintFeeDistributionRatioBP) / BASIS;

        // calculate the protocol mint fee
        uint256 mintFee = (msgValue * l.mintFeeBP) / BASIS;

        uint256 referralFee;

        // Calculate the referral fee if a referrer is provided
        if (referrer != address(0)) {
            uint256 referralFeeBP = _collectionReferralFeeBP(collectionData);

            if (referralFeeBP == 0) {
                referralFeeBP = l.defaultCollectionReferralFeeBP;
            }

            // Calculate referral fee based on the mintFee and referral fee percentage
            referralFee = (mintFee * referralFeeBP) / BASIS;

            // Pay the referrer
            payable(referrer).sendValue(referralFee);
        }

        // update the accrued consolation fees
        l.consolationFees += mintForEthConsolationFee - additionalDepositorFee;

        mintEarningsFee =
            msgValue -
            mintForEthConsolationFee -
            mintFee +
            additionalDepositorFee;

        // update the accrued depositor mint earnings
        l.mintEarnings += mintEarningsFee;

        // Update the accrued protocol fees (subtracting the referral fee if applicable)
        l.protocolFees += mintFee - referralFee;
    }

    function _attemptBatchMintForEthWithMint(
        address minter,
        address referrer,
        uint256 pricePerMint,
        uint32 numberOfMints,
        uint256 ethPrizeValueInWei
    ) internal {
        Storage.Layout storage l = Storage.layout();

        uint256 ethToMintRatio = _ethToMintRatio(l);

        uint256 pricePerSpinInWei = pricePerMint / ethToMintRatio;

        uint256 ethRequired = pricePerSpinInWei * numberOfMints;

        _attemptBatchMint_paidInMint_validateMintParameters(
            numberOfMints,
            l.consolationFees,
            ethRequired,
            pricePerSpinInWei,
            pricePerMint
        );

        _attemptBatchMintForEth_checkMaxPayout(
            l.mintEarnings,
            ethPrizeValueInWei,
            l.mintEarningsBufferBP,
            numberOfMints
        );

        CollectionData storage collectionData = l.collections[
            ETH_COLLECTION_ADDRESS
        ];

        uint256 mintEarningsFee = _attemptBatchMintForEthWithMint_calculateAndDistributeFees(
                l,
                collectionData,
                minter,
                referrer,
                ethRequired,
                ethToMintRatio
            );

        // if the number of words requested is greater than the max allowed by the VRF coordinator,
        // the request for random words will fail (max random words is currently 500 per request).
        uint32 numWords = numberOfMints * 2; // 2 words per mint for ETH, current max of 250 mints per tx

        uint256 mintPriceAdjustmentFactor = _attemptBatchMint_calculateMintPriceAdjustmentFactor(
                collectionData,
                pricePerSpinInWei
            );

        _requestRandomWords(
            l,
            collectionData,
            minter,
            ETH_COLLECTION_ADDRESS,
            mintEarningsFee,
            mintPriceAdjustmentFactor,
            ethPrizeValueInWei,
            numWords
        );
    }

    function _attemptBatchMintForEthWithMintSupra(
        address minter,
        address referrer,
        uint256 pricePerMint,
        uint8 numberOfMints,
        uint8 wordsPerMint,
        uint256 ethPrizeValueInWei
    ) internal {
        Storage.Layout storage l = Storage.layout();

        uint256 ethToMintRatio = _ethToMintRatio(l);

        uint256 pricePerSpinInWei = pricePerMint / ethToMintRatio;

        uint256 ethRequired = pricePerSpinInWei * numberOfMints;

        CollectionData storage collectionData = l.collections[
            ETH_COLLECTION_ADDRESS
        ];

        uint256 mintEarningsFee = _attemptBatchMintForEthWithMintSupra_validateAndDistributeFees(
                minter,
                referrer,
                numberOfMints,
                ethPrizeValueInWei,
                pricePerMint,
                pricePerSpinInWei,
                ethRequired,
                ethToMintRatio,
                l,
                collectionData
            );

        _attemptBatchMintForEthWithMintSupra_requestRandomWordsSupra(
            minter,
            numberOfMints,
            wordsPerMint,
            ethPrizeValueInWei,
            mintEarningsFee,
            pricePerSpinInWei,
            l,
            collectionData
        );
    }

    function _attemptBatchMintForEthWithMint_calculateAndDistributeFees(
        Storage.Layout storage l,
        CollectionData storage collectionData,
        address minter,
        address referrer,
        uint256 ethRequired,
        uint256 ethToMintRatio
    ) private returns (uint256 mintEarningsFee) {
        // calculate amount of $MINT required
        uint256 mintRequired = ethRequired * ethToMintRatio;

        IToken(l.mintToken).burn(minter, mintRequired);

        // calculate the mint for ETH consolation fee
        uint256 mintForEthConsolationFee = (ethRequired *
            l.mintForEthConsolationFeeBP) / BASIS;

        // Apply the mint for ETH-specific fee ratio
        uint256 additionalDepositorFee = (mintForEthConsolationFee *
            collectionData.mintFeeDistributionRatioBP) / BASIS;

        // calculate the protocol mint fee
        uint256 mintFee = (ethRequired * l.mintFeeBP) / BASIS;

        uint256 referralFee;

        // Calculate the referral fee if a referrer is provided
        if (referrer != address(0)) {
            uint256 referralFeeBP = _collectionReferralFeeBP(collectionData);

            if (referralFeeBP == 0) {
                referralFeeBP = l.defaultCollectionReferralFeeBP;
            }

            // Calculate referral fee based on the mintFee and referral fee percentage
            referralFee = (mintFee * referralFeeBP) / BASIS;

            // Pay the referrer in $MINT
            IToken(l.mintToken).mintReferral(
                referrer,
                referralFee * ethToMintRatio
            );
        }

        // calculate the net mint for ETH consolation fee
        // ETH required for mint taken from the mintForEthConsolationFee
        uint256 netConsolationFee = ethRequired -
            mintForEthConsolationFee +
            additionalDepositorFee;

        // update the accrued consolation fees
        l.consolationFees -= netConsolationFee;

        mintEarningsFee = netConsolationFee - mintFee;

        // update the accrued depositor mint earnings
        l.mintEarnings += mintEarningsFee;

        // Update the accrued protocol fees (subtracting the referral fee if applicable)
        l.protocolFees += mintFee - referralFee;
    }

    function _attemptBatchMintForEthWithMintSupra_requestRandomWordsSupra(
        address minter,
        uint8 numberOfMints,
        uint8 wordsPerMint,
        uint256 ethPrizeValueInWei,
        uint256 mintEarningsFee,
        uint256 pricePerSpinInWei,
        Storage.Layout storage l,
        CollectionData storage collectionData
    ) private {
        // Calculate the total number of random words required for the Supra VRF request.
        // Constraints:
        // 1. numWords = 0 results in a revert.
        // 2. Supra VRF limit: The maximum number of words allowed per request is 255.
        // If the number of words requested exceeds this limit, the function call will revert.
        //    - For Blast Supra: 3 words per mint (max 85 mints per transaction).
        //    - For standard Supra: 2 word per mint (max 127 mints per transaction).
        uint8 numWords = numberOfMints * wordsPerMint;

        uint256 mintPriceAdjustmentFactor = _attemptBatchMint_calculateMintPriceAdjustmentFactor(
                collectionData,
                pricePerSpinInWei
            );

        _requestRandomWordsSupra(
            l,
            collectionData,
            minter,
            ETH_COLLECTION_ADDRESS,
            mintEarningsFee,
            mintPriceAdjustmentFactor,
            ethPrizeValueInWei,
            numWords
        );
    }

    function _attemptBatchMintForEthWithMintSupra_validateAndDistributeFees(
        address minter,
        address referrer,
        uint8 numberOfMints,
        uint256 ethPrizeValueInWei,
        uint256 pricePerMint,
        uint256 pricePerSpinInWei,
        uint256 ethRequired,
        uint256 ethToMintRatio,
        Storage.Layout storage l,
        CollectionData storage collectionData
    ) private returns (uint256 mintEarningsFee) {
        _attemptBatchMint_paidInMint_validateMintParameters(
            numberOfMints,
            l.consolationFees,
            ethRequired,
            pricePerSpinInWei,
            pricePerMint
        );

        _attemptBatchMintForEth_checkMaxPayout(
            l.mintEarnings,
            ethPrizeValueInWei,
            l.mintEarningsBufferBP,
            numberOfMints
        );

        mintEarningsFee = _attemptBatchMintForEthWithMint_calculateAndDistributeFees(
            l,
            collectionData,
            minter,
            referrer,
            ethRequired,
            ethToMintRatio
        );
    }

    /// @notice Attempts a batch mint for the msg.sender for $MINT using ETH as payment.
    /// @param minter address of minter
    /// @param referrer address of referrer
    /// @param numberOfMints number of mints to attempt
    function _attemptBatchMintForMintWithEth(
        address minter,
        address referrer,
        uint32 numberOfMints
    ) internal {
        uint256 msgValue = msg.value;

        uint256 pricePerSpin = msgValue / numberOfMints;

        _attemptBatchMint_paidInEth_validateMintParameters(
            msgValue,
            pricePerSpin
        );

        Storage.Layout storage l = Storage.layout();

        CollectionData storage collectionData = l.collections[
            MINT_TOKEN_COLLECTION_ADDRESS
        ];

        _attemptBatchMintForMintWithEth_calculateAndDistributeFees(
            l,
            msgValue,
            referrer
        );

        // if the number of words requested is greater than the max allowed by the VRF coordinator,
        // the request for random words will fail (max random words is currently 500 per request).
        uint32 numWords = numberOfMints * 1; // 1 words per mint for $MINT, current max of 500 mints per tx

        uint256 mintPriceAdjustmentFactor = _attemptBatchMint_calculateMintPriceAdjustmentFactor(
                collectionData,
                pricePerSpin
            );

        _requestRandomWords(
            l,
            collectionData,
            minter,
            MINT_TOKEN_COLLECTION_ADDRESS,
            0,
            mintPriceAdjustmentFactor,
            0,
            numWords
        );
    }

    /// @notice Attempts a Supra VRF-specific batch mint for the msg.sender for $MINT using ETH as payment.
    /// @param minter address of minter
    /// @param referrer address of referrer
    /// @param numberOfMints number of mints to attempt
    /// @param wordsPerMint number of random words per mint (1 for PerpetualMintSupra, 2 for PerpetualMintSupraBlast)
    function _attemptBatchMintForMintWithEthSupra(
        address minter,
        address referrer,
        uint8 numberOfMints,
        uint8 wordsPerMint
    ) internal {
        uint256 msgValue = msg.value;

        uint256 pricePerSpin = msgValue / numberOfMints;

        _attemptBatchMint_paidInEth_validateMintParameters(
            msgValue,
            pricePerSpin
        );

        Storage.Layout storage l = Storage.layout();

        CollectionData storage collectionData = l.collections[
            MINT_TOKEN_COLLECTION_ADDRESS
        ];

        _attemptBatchMintForMintWithEth_calculateAndDistributeFees(
            l,
            msgValue,
            referrer
        );

        // Calculate the total number of random words required for the Supra VRF request.
        // Constraints:
        // 1. numWords = 0 results in a revert.
        // 2. Supra VRF limit: The maximum number of words allowed per request is 255.
        // If the number of words requested exceeds this limit, the function call will revert.
        //    - For Blast Supra: 2 words per mint for $MINT (max 127 mints per transaction).
        //    - For standard Supra: 1 word per mint for $MINT (max 255 mints per transaction).
        uint8 numWords = numberOfMints * wordsPerMint;

        uint256 mintPriceAdjustmentFactor = _attemptBatchMint_calculateMintPriceAdjustmentFactor(
                collectionData,
                pricePerSpin
            );

        _requestRandomWordsSupra(
            l,
            collectionData,
            minter,
            MINT_TOKEN_COLLECTION_ADDRESS,
            0,
            mintPriceAdjustmentFactor,
            0,
            numWords
        );
    }

    function _attemptBatchMintForMintWithEth_calculateAndDistributeFees(
        Storage.Layout storage l,
        uint256 msgValue,
        address referrer
    ) private {
        // calculate the mint for $MINT consolation fee
        uint256 mintTokenConsolationFee = (msgValue *
            l.mintTokenConsolationFeeBP) / BASIS;

        // update the accrued consolation fees
        l.consolationFees += mintTokenConsolationFee;

        // calculate the protocol mint fee
        uint256 mintFee = msgValue - mintTokenConsolationFee;

        uint256 referralFee;

        // Calculate the referral fee if a referrer is provided
        if (referrer != address(0)) {
            uint256 referralFeeBP = _collectionReferralFeeBP(
                l.collections[MINT_TOKEN_COLLECTION_ADDRESS]
            );

            if (referralFeeBP == 0) {
                referralFeeBP = l.defaultCollectionReferralFeeBP;
            }

            // Calculate referral fee based on the mintFee and referral fee percentage
            referralFee = (mintFee * referralFeeBP) / BASIS;

            // Pay the referrer
            payable(referrer).sendValue(referralFee);
        }

        // Update the accrued protocol fees (subtracting the referral fee if applicable)
        l.protocolFees += mintFee - referralFee;
    }

    /// @notice Attempts a batch mint for the msg.sender for $MINT using $MINT tokens as payment.
    /// @param minter address of minter
    /// @param referrer address of referrer
    /// @param pricePerMint price per mint for collection ($MINT denominated in units of wei)
    /// @param numberOfMints number of mints to attempt
    function _attemptBatchMintForMintWithMint(
        address minter,
        address referrer,
        uint256 pricePerMint,
        uint32 numberOfMints
    ) internal {
        Storage.Layout storage l = Storage.layout();

        uint256 ethToMintRatio = _ethToMintRatio(l);

        uint256 pricePerSpinInWei = pricePerMint / ethToMintRatio;

        uint256 ethRequired = pricePerSpinInWei * numberOfMints;

        _attemptBatchMint_paidInMint_validateMintParameters(
            numberOfMints,
            l.consolationFees,
            ethRequired,
            pricePerSpinInWei,
            pricePerMint
        );

        CollectionData storage collectionData = l.collections[
            MINT_TOKEN_COLLECTION_ADDRESS
        ];

        _attemptBatchMintForMintWithMint_calculateAndDistributeFees(
            l,
            ethRequired,
            ethToMintRatio,
            minter,
            referrer
        );

        // if the number of words requested is greater than the max allowed by the VRF coordinator,
        // the request for random words will fail (max random words is currently 500 per request).
        uint32 numWords = numberOfMints * 1; // 1 words per mint for $MINT, current max of 500 mints per tx

        uint256 mintPriceAdjustmentFactor = _attemptBatchMint_calculateMintPriceAdjustmentFactor(
                collectionData,
                pricePerSpinInWei
            );

        _requestRandomWords(
            l,
            collectionData,
            minter,
            MINT_TOKEN_COLLECTION_ADDRESS,
            0,
            mintPriceAdjustmentFactor,
            0,
            numWords
        );
    }

    /// @notice Attempts a Supra VRF-specific batch mint for the msg.sender for $MINT using $MINT tokens as payment.
    /// @param minter address of minter
    /// @param referrer address of referrer
    /// @param pricePerMint price per mint for collection ($MINT denominated in units of wei)
    /// @param numberOfMints number of mints to attempt
    /// @param wordsPerMint number of random words per mint (1 for PerpetualMintSupra, 2 for PerpetualMintSupraBlast)
    function _attemptBatchMintForMintWithMintSupra(
        address minter,
        address referrer,
        uint256 pricePerMint,
        uint8 numberOfMints,
        uint8 wordsPerMint
    ) internal {
        Storage.Layout storage l = Storage.layout();

        uint256 ethToMintRatio = _ethToMintRatio(l);

        uint256 pricePerSpinInWei = pricePerMint / ethToMintRatio;

        uint256 ethRequired = pricePerSpinInWei * numberOfMints;

        _attemptBatchMint_paidInMint_validateMintParameters(
            numberOfMints,
            l.consolationFees,
            ethRequired,
            pricePerSpinInWei,
            pricePerMint
        );

        CollectionData storage collectionData = l.collections[
            MINT_TOKEN_COLLECTION_ADDRESS
        ];

        _attemptBatchMintForMintWithMint_calculateAndDistributeFees(
            l,
            ethRequired,
            ethToMintRatio,
            minter,
            referrer
        );

        // Calculate the total number of random words required for the Supra VRF request.
        // Constraints:
        // 1. numWords = 0 results in a revert.
        // 2. Supra VRF limit: The maximum number of words allowed per request is 255.
        // If the number of words requested exceeds this limit, the function call will revert.
        //    - For Blast Supra: 2 words per mint for $MINT (max 127 mints per transaction).
        //    - For standard Supra: 1 word per mint for $MINT (max 255 mints per transaction).
        uint8 numWords = numberOfMints * wordsPerMint;

        uint256 mintPriceAdjustmentFactor = _attemptBatchMint_calculateMintPriceAdjustmentFactor(
                collectionData,
                pricePerSpinInWei
            );

        _requestRandomWordsSupra(
            l,
            collectionData,
            minter,
            MINT_TOKEN_COLLECTION_ADDRESS,
            0,
            mintPriceAdjustmentFactor,
            0,
            numWords
        );
    }

    function _attemptBatchMintForMintWithMint_calculateAndDistributeFees(
        Storage.Layout storage l,
        uint256 ethRequired,
        uint256 ethToMintRatio,
        address minter,
        address referrer
    ) private {
        // calculate amount of $MINT required
        uint256 mintRequired = ethRequired * ethToMintRatio;

        IToken(l.mintToken).burn(minter, mintRequired);

        // calculate the mint for $MINT consolation fee
        uint256 mintTokenConsolationFee = (ethRequired *
            l.mintTokenConsolationFeeBP) / BASIS;

        // Calculate the net mint fee
        uint256 netMintFee = ethRequired - mintTokenConsolationFee;

        uint256 referralFee;

        // Calculate the referral fee if a referrer is provided
        if (referrer != address(0)) {
            uint256 referralFeeBP = _collectionReferralFeeBP(
                l.collections[MINT_TOKEN_COLLECTION_ADDRESS]
            );

            if (referralFeeBP == 0) {
                referralFeeBP = l.defaultCollectionReferralFeeBP;
            }

            // Calculate referral fee based on the netMintFee and referral fee percentage
            referralFee = (netMintFee * referralFeeBP) / BASIS;

            // Pay the referrer in $MINT
            IToken(l.mintToken).mintReferral(
                referrer,
                referralFee * ethToMintRatio
            );
        }

        // Update the accrued consolation fees
        l.consolationFees -= netMintFee;

        // Update the accrued protocol fees
        l.protocolFees += netMintFee - referralFee;
    }

    /// @notice Attempts a batch mint for the msg.sender for a single collection using ETH as payment.
    /// @param minter address of minter
    /// @param collection address of collection for mint attempts
    /// @param referrer address of referrer
    /// @param numberOfMints number of mints to attempt
    function _attemptBatchMintWithEth(
        address minter,
        address collection,
        address referrer,
        uint32 numberOfMints
    ) internal {
        if (collection == MINT_TOKEN_COLLECTION_ADDRESS) {
            // throw if collection is $MINT
            revert InvalidCollectionAddress();
        }

        uint256 msgValue = msg.value;

        uint256 pricePerSpin = msgValue / numberOfMints;

        _attemptBatchMint_paidInEth_validateMintParameters(
            msgValue,
            pricePerSpin
        );

        Storage.Layout storage l = Storage.layout();

        CollectionData storage collectionData = l.collections[collection];

        _attemptBatchMintWithEth_calculateAndDistributeFees(
            l,
            collectionData,
            msgValue,
            referrer
        );

        // if the number of words requested is greater than the max allowed by the VRF coordinator,
        // the request for random words will fail (max random words is currently 500 per request).
        uint32 numWords = numberOfMints * 2; // 2 words per mint, current max of 250 mints per tx

        uint256 mintPriceAdjustmentFactor = _attemptBatchMint_calculateMintPriceAdjustmentFactor(
                collectionData,
                pricePerSpin
            );

        _requestRandomWords(
            l,
            collectionData,
            minter,
            collection,
            0,
            mintPriceAdjustmentFactor,
            0,
            numWords
        );
    }

    /// @notice Attempts a Supra VRF-specific batch mint for the msg.sender for a single collection using ETH as payment.
    /// @param minter address of minter
    /// @param collection address of collection for mint attempts
    /// @param referrer address of referrer
    /// @param numberOfMints number of mints to attempt
    /// @param wordsPerMint number of random words per mint (2 for PerpetualMintSupra, 3 for PerpetualMintSupraBlast)
    function _attemptBatchMintWithEthSupra(
        address minter,
        address collection,
        address referrer,
        uint8 numberOfMints,
        uint8 wordsPerMint
    ) internal {
        if (collection == MINT_TOKEN_COLLECTION_ADDRESS) {
            // throw if collection is $MINT
            revert InvalidCollectionAddress();
        }

        uint256 msgValue = msg.value;

        uint256 pricePerSpin = msgValue / numberOfMints;

        _attemptBatchMint_paidInEth_validateMintParameters(
            msgValue,
            pricePerSpin
        );

        Storage.Layout storage l = Storage.layout();

        CollectionData storage collectionData = l.collections[collection];

        _attemptBatchMintWithEth_calculateAndDistributeFees(
            l,
            collectionData,
            msgValue,
            referrer
        );

        // Calculate the total number of random words required for the Supra VRF request.
        // Constraints:
        // 1. numWords = 0 results in a revert.
        // 2. Supra VRF limit: The maximum number of words allowed per request is 255.
        // If the number of words requested exceeds this limit, the function call will revert.
        //    - For Blast Supra: 3 words per mint (max 85 mints per transaction).
        //    - For standard Supra: 2 word per mint (max 127 mints per transaction).
        uint8 numWords = numberOfMints * wordsPerMint;

        uint256 mintPriceAdjustmentFactor = _attemptBatchMint_calculateMintPriceAdjustmentFactor(
                collectionData,
                pricePerSpin
            );

        _requestRandomWordsSupra(
            l,
            collectionData,
            minter,
            collection,
            0,
            mintPriceAdjustmentFactor,
            0,
            numWords
        );
    }

    function _attemptBatchMintWithEth_calculateAndDistributeFees(
        Storage.Layout storage l,
        CollectionData storage collectionData,
        uint256 msgValue,
        address referrer
    ) private returns (uint256 mintEarningsFee) {
        // calculate the mint for collection consolation fee
        uint256 collectionConsolationFee = (msgValue *
            l.collectionConsolationFeeBP) / BASIS;

        // apply the collection-specific mint fee ratio
        uint256 additionalDepositorFee = (collectionConsolationFee *
            collectionData.mintFeeDistributionRatioBP) / BASIS;

        // calculate the protocol mint fee
        uint256 mintFee = (msgValue * l.mintFeeBP) / BASIS;

        uint256 referralFee;

        // Calculate the referral fee if a referrer is provided
        if (referrer != address(0)) {
            uint256 referralFeeBP = _collectionReferralFeeBP(collectionData);

            if (referralFeeBP == 0) {
                referralFeeBP = l.defaultCollectionReferralFeeBP;
            }

            // Calculate referral fee based on the mintFee and referral fee percentage
            referralFee = (mintFee * referralFeeBP) / BASIS;

            // Pay the referrer
            payable(referrer).sendValue(referralFee);
        }

        // update the accrued consolation fees
        l.consolationFees += collectionConsolationFee - additionalDepositorFee;

        mintEarningsFee =
            msgValue -
            collectionConsolationFee -
            mintFee +
            additionalDepositorFee;

        // update the accrued depositor mint earnings
        l.mintEarnings += mintEarningsFee;

        // Update the accrued protocol fees (subtracting the referral fee if applicable)
        l.protocolFees += mintFee - referralFee;
    }

    /// @notice Attempts a batch mint for the msg.sender for a single collection using $MINT tokens as payment.
    /// @param minter address of minter
    /// @param collection address of collection for mint attempts
    /// @param referrer address of referrer
    /// @param numberOfMints number of mints to attempt
    function _attemptBatchMintWithMint(
        address minter,
        address collection,
        address referrer,
        uint256 pricePerMint,
        uint32 numberOfMints
    ) internal {
        if (collection == MINT_TOKEN_COLLECTION_ADDRESS) {
            // throw if collection is $MINT
            revert InvalidCollectionAddress();
        }

        Storage.Layout storage l = Storage.layout();

        uint256 ethToMintRatio = _ethToMintRatio(l);

        uint256 pricePerSpinInWei = pricePerMint / ethToMintRatio;

        uint256 ethRequired = pricePerSpinInWei * numberOfMints;

        _attemptBatchMint_paidInMint_validateMintParameters(
            numberOfMints,
            l.consolationFees,
            ethRequired,
            pricePerSpinInWei,
            pricePerMint
        );

        CollectionData storage collectionData = l.collections[collection];

        _attemptBatchMintWithMint_calculateAndDistributeFees(
            l,
            collectionData,
            minter,
            referrer,
            ethRequired,
            ethToMintRatio
        );

        // if the number of words requested is greater than the max allowed by the VRF coordinator,
        // the request for random words will fail (max random words is currently 500 per request).
        uint32 numWords = numberOfMints * 2; // 2 words per mint, current max of 250 mints per tx

        uint256 mintPriceAdjustmentFactor = _attemptBatchMint_calculateMintPriceAdjustmentFactor(
                collectionData,
                pricePerSpinInWei
            );

        _requestRandomWords(
            l,
            collectionData,
            minter,
            collection,
            0,
            mintPriceAdjustmentFactor,
            0,
            numWords
        );
    }

    /// @notice Attempts a Supra VRF-specific batch mint for the msg.sender for a single collection using $MINT tokens as payment.
    /// @param minter address of minter
    /// @param collection address of collection for mint attempts
    /// @param referrer address of referrer
    /// @param pricePerMint price per mint for collection ($MINT denominated in units of wei)
    /// @param numberOfMints number of mints to attempt
    /// @param wordsPerMint number of random words per mint (2 for PerpetualMintSupra, 3 for PerpetualMintSupraBlast)
    function _attemptBatchMintWithMintSupra(
        address minter,
        address collection,
        address referrer,
        uint256 pricePerMint,
        uint8 numberOfMints,
        uint8 wordsPerMint
    ) internal {
        if (collection == MINT_TOKEN_COLLECTION_ADDRESS) {
            // throw if collection is $MINT
            revert InvalidCollectionAddress();
        }

        Storage.Layout storage l = Storage.layout();

        uint256 ethToMintRatio = _ethToMintRatio(l);

        uint256 pricePerSpinInWei = pricePerMint / ethToMintRatio;

        uint256 ethRequired = pricePerSpinInWei * numberOfMints;

        _attemptBatchMint_paidInMint_validateMintParameters(
            numberOfMints,
            l.consolationFees,
            ethRequired,
            pricePerSpinInWei,
            pricePerMint
        );

        CollectionData storage collectionData = l.collections[collection];

        _attemptBatchMintWithMint_calculateAndDistributeFees(
            l,
            collectionData,
            minter,
            referrer,
            ethRequired,
            ethToMintRatio
        );

        // Calculate the total number of random words required for the Supra VRF request.
        // Constraints:
        // 1. numWords = 0 results in a revert.
        // 2. Supra VRF limit: The maximum number of words allowed per request is 255.
        // If the number of words requested exceeds this limit, the function call will revert.
        //    - For Blast Supra: 3 words per mint (max 85 mints per transaction).
        //    - For standard Supra: 2 word per mint (max 127 mints per transaction).
        uint8 numWords = numberOfMints * wordsPerMint;

        uint256 mintPriceAdjustmentFactor = _attemptBatchMint_calculateMintPriceAdjustmentFactor(
                collectionData,
                pricePerSpinInWei
            );

        _requestRandomWordsSupra(
            l,
            collectionData,
            minter,
            collection,
            0,
            mintPriceAdjustmentFactor,
            0,
            numWords
        );
    }

    function _attemptBatchMintWithMint_calculateAndDistributeFees(
        Storage.Layout storage l,
        CollectionData storage collectionData,
        address minter,
        address referrer,
        uint256 ethRequired,
        uint256 ethToMintRatio
    ) private returns (uint256 mintEarningsFee) {
        // calculate amount of $MINT required
        uint256 mintRequired = ethRequired * ethToMintRatio;

        IToken(l.mintToken).burn(minter, mintRequired);

        // calculate the mint for collection consolation fee
        uint256 collectionConsolationFee = (ethRequired *
            l.collectionConsolationFeeBP) / BASIS;

        // apply the collection-specific mint fee ratio
        uint256 additionalDepositorFee = (collectionConsolationFee *
            collectionData.mintFeeDistributionRatioBP) / BASIS;

        // calculate the protocol mint fee
        uint256 mintFee = (ethRequired * l.mintFeeBP) / BASIS;

        uint256 referralFee;

        // Calculate the referral fee if a referrer is provided
        if (referrer != address(0)) {
            uint256 referralFeeBP = _collectionReferralFeeBP(collectionData);

            if (referralFeeBP == 0) {
                referralFeeBP = l.defaultCollectionReferralFeeBP;
            }

            // Calculate referral fee based on the mintFee and referral fee percentage
            referralFee = (mintFee * referralFeeBP) / BASIS;

            // Pay the referrer in $MINT
            IToken(l.mintToken).mintReferral(
                referrer,
                referralFee * ethToMintRatio
            );
        }

        // calculate the net collection consolation fee
        // ETH required for mint taken from collectionConsolationFee
        uint256 netConsolationFee = ethRequired -
            collectionConsolationFee +
            additionalDepositorFee;

        // update the accrued consolation fees
        l.consolationFees -= netConsolationFee;

        mintEarningsFee = netConsolationFee - mintFee;

        // update the accrued depositor mint earnings
        l.mintEarnings += mintEarningsFee;

        // Update the accrued protocol fees, subtracting the referral fee
        l.protocolFees += mintFee - referralFee;
    }

    /// @notice returns the value of BASIS
    /// @return value BASIS value
    function _BASIS() internal pure returns (uint32 value) {
        value = BASIS;
    }

    /// @notice returns the current blast yield risk
    /// @return risk current blast yield risk
    function _blastYieldRisk() internal view returns (uint32 risk) {
        risk = Storage.layout().yieldRisk;
    }

    /// @notice burns a receipt after a claim request is fulfilled
    /// @param tokenId id of receipt to burn
    function _burnReceipt(uint256 tokenId) internal {
        _burn(address(this), tokenId, 1);
    }

    /// @notice calculates the mint result of a given number of mint attempts for a given collection using given randomness
    /// @param collection address of collection for mint attempts
    /// @param numberOfMints number of mints to attempt
    /// @param randomness random value to use in calculation
    /// @param pricePerMint price paid per mint for collection (denominated in units of wei)
    function _calculateMintResult(
        address collection,
        uint32 numberOfMints,
        uint256 randomness,
        uint256 pricePerMint
    ) internal view returns (MintResultData memory result) {
        Storage.Layout storage l = Storage.layout();

        CollectionData storage collectionData = l.collections[collection];

        bool mintForMint = collection == MINT_TOKEN_COLLECTION_ADDRESS;

        uint32 numberOfWords = numberOfMints * (mintForMint ? 1 : 2);

        uint256 collectionMintMultiplier = _collectionMintMultiplier(
            collectionData
        );

        uint256 ethToMintRatio = _ethToMintRatio(l);

        uint256 mintPriceAdjustmentFactor = _attemptBatchMint_calculateMintPriceAdjustmentFactor(
                collectionData,
                pricePerMint
            );

        uint256[] memory randomWords = new uint256[](numberOfWords);

        for (uint256 i = 0; i < numberOfWords; ++i) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        if (mintForMint) {
            result = _calculateMintForMintResult_sharedLogic(
                l,
                numberOfMints,
                randomWords,
                collectionMintMultiplier,
                ethToMintRatio,
                mintPriceAdjustmentFactor,
                collectionData
            );
        } else {
            result = _calculateMintForCollectionResult_sharedLogic(
                l,
                numberOfMints,
                randomWords,
                collectionMintMultiplier,
                ethToMintRatio,
                mintPriceAdjustmentFactor,
                collectionData
            );
        }
    }

    /// @notice calculates the Supra VRF-specific mint result on Blast of a given number of mint attempts for a given collection using given signature as randomness
    /// @param collection address of collection for mint attempts
    /// @param numberOfMints number of mints to attempt
    /// @param signature signature value to use as randomness in calculation
    /// @param pricePerMint price paid per mint for collection (denominated in units of wei)
    function _calculateMintResultSupraBlast(
        address collection,
        uint8 numberOfMints,
        uint256[2] calldata signature,
        uint256 pricePerMint
    ) internal view returns (MintResultDataBlast memory result) {
        Storage.Layout storage l = Storage.layout();

        CollectionData storage collectionData = l.collections[collection];

        bool mintForMint = collection == MINT_TOKEN_COLLECTION_ADDRESS;

        uint8 numberOfWords = numberOfMints * (mintForMint ? 2 : 3);

        uint256 collectionMintMultiplier = _collectionMintMultiplier(
            collectionData
        );

        uint256 ethToMintRatio = _ethToMintRatio(l);

        uint256 mintPriceAdjustmentFactor = _attemptBatchMint_calculateMintPriceAdjustmentFactor(
                collectionData,
                pricePerMint
            );

        uint256[] memory randomWords = new uint256[](numberOfWords);

        for (uint256 i = 0; i < numberOfWords; ++i) {
            randomWords[i] = uint256(
                keccak256(abi.encodePacked(signature, i + 1))
            );
        }

        if (mintForMint) {
            result = _calculateMintForMintResultBlast_sharedLogic(
                l,
                numberOfMints,
                randomWords,
                collectionMintMultiplier,
                ethToMintRatio,
                mintPriceAdjustmentFactor,
                collectionData
            );
        } else {
            result = _calculateMintForCollectionResultBlast_sharedLogic(
                l,
                numberOfMints,
                randomWords,
                collectionMintMultiplier,
                ethToMintRatio,
                mintPriceAdjustmentFactor,
                collectionData
            );
        }
    }

    /// @notice calculates the Supra VRF-specific mint result of a given number of mint attempts for a given collection using given signature as randomness
    /// @param collection address of collection for mint attempts
    /// @param numberOfMints number of mints to attempt
    /// @param signature signature value to use as randomness in calculation
    /// @param pricePerMint price paid per mint for collection (denominated in units of wei)
    function _calculateMintResultSupra(
        address collection,
        uint8 numberOfMints,
        uint256[2] calldata signature,
        uint256 pricePerMint
    ) internal view returns (MintResultData memory result) {
        Storage.Layout storage l = Storage.layout();

        CollectionData storage collectionData = l.collections[collection];

        bool mintForMint = collection == MINT_TOKEN_COLLECTION_ADDRESS;

        uint8 numberOfWords = numberOfMints * (mintForMint ? 1 : 2);

        uint256 collectionMintMultiplier = _collectionMintMultiplier(
            collectionData
        );

        uint256 ethToMintRatio = _ethToMintRatio(l);

        uint256 mintPriceAdjustmentFactor = _attemptBatchMint_calculateMintPriceAdjustmentFactor(
                collectionData,
                pricePerMint
            );

        uint256[] memory randomWords = new uint256[](numberOfWords);

        for (uint256 i = 0; i < numberOfWords; ++i) {
            randomWords[i] = uint256(
                keccak256(abi.encodePacked(signature, i + 1))
            );
        }

        if (mintForMint) {
            result = _calculateMintForMintResult_sharedLogic(
                l,
                numberOfMints,
                randomWords,
                collectionMintMultiplier,
                ethToMintRatio,
                mintPriceAdjustmentFactor,
                collectionData
            );
        } else {
            result = _calculateMintForCollectionResult_sharedLogic(
                l,
                numberOfMints,
                randomWords,
                collectionMintMultiplier,
                ethToMintRatio,
                mintPriceAdjustmentFactor,
                collectionData
            );
        }
    }

    function _calculateMintForCollectionResult_sharedLogic(
        Storage.Layout storage l,
        uint32 numberOfMints,
        uint256[] memory randomWords,
        uint256 collectionMintMultiplier,
        uint256 ethToMintRatio,
        uint256 mintPriceAdjustmentFactor,
        CollectionData storage collectionData
    ) private view returns (MintResultData memory result) {
        // adjust the collection risk by the mint price adjustment factor
        uint256 collectionRisk = (_collectionRisk(collectionData) *
            mintPriceAdjustmentFactor) / BASIS;

        result.mintOutcomes = new MintOutcome[](numberOfMints);

        for (uint256 i = 0; i < randomWords.length; i += 2) {
            MintOutcome memory outcome;

            uint256 firstNormalizedValue = _normalizeValue(
                randomWords[i],
                BASIS
            );

            if (!(collectionRisk > firstNormalizedValue)) {
                outcome = _calculateMintForCollectionOutcome(
                    _normalizeValue(randomWords[i + 1], BASIS), // secondNormalizedValue
                    l.tiers,
                    mintPriceAdjustmentFactor,
                    ethToMintRatio,
                    _collectionMintPrice(collectionData),
                    collectionMintMultiplier
                );

                result.totalMintAmount += outcome.mintAmount;
            } else {
                ++result.totalSuccessfulMints;
            }

            result.mintOutcomes[i / 2] = outcome;
        }
    }

    function _calculateMintForCollectionResultBlast_sharedLogic(
        Storage.Layout storage l,
        uint32 numberOfMints,
        uint256[] memory randomWords,
        uint256 collectionMintMultiplier,
        uint256 ethToMintRatio,
        uint256 mintPriceAdjustmentFactor,
        CollectionData storage collectionData
    ) private view returns (MintResultDataBlast memory result) {
        uint32 blastYieldRisk = _blastYieldRisk();

        // adjust the collection risk by the mint price adjustment factor
        uint256 collectionRisk = (_collectionRisk(collectionData) *
            mintPriceAdjustmentFactor) / BASIS;

        result.mintOutcomes = new MintOutcome[](numberOfMints);

        for (uint256 i = 0; i < randomWords.length; i += 3) {
            MintOutcome memory outcome;

            uint256 firstNormalizedValue = _normalizeValue(
                randomWords[i],
                BASIS
            );

            if (!(collectionRisk > firstNormalizedValue)) {
                outcome = _calculateMintForCollectionOutcome(
                    _normalizeValue(randomWords[i + 1], BASIS), // secondNormalizedValue
                    l.tiers,
                    mintPriceAdjustmentFactor,
                    ethToMintRatio,
                    _collectionMintPrice(collectionData),
                    collectionMintMultiplier
                );

                result.totalMintAmount += outcome.mintAmount;
            } else {
                ++result.totalSuccessfulMints;
            }

            uint256 thirdNormalizedValue = _normalizeValue(
                randomWords[i + 2],
                BASIS
            );

            if (blastYieldRisk > thirdNormalizedValue) {
                result.totalBlastYieldAmount += IBlast(BLAST)
                    .readClaimableYield(address(this));

                result.totalBlastYieldAmount += _calculateMaxClaimableGas();
            }

            result.mintOutcomes[i / 3] = outcome;
        }
    }

    function _calculateMintForCollectionOutcome(
        uint256 secondNormalizedValue,
        TiersData storage tiers,
        uint256 mintPriceAdjustmentFactor,
        uint256 ethToMintRatio,
        uint256 collectionMintPrice,
        uint256 collectionMintMultiplier
    ) private view returns (MintOutcome memory outcome) {
        uint256 cumulativeRisk;

        for (uint256 j = 0; j < tiers.tierRisks.length; ++j) {
            cumulativeRisk += tiers.tierRisks[j];

            if (cumulativeRisk > secondNormalizedValue) {
                uint256 mintAmount = (tiers.tierMultipliers[j] *
                    mintPriceAdjustmentFactor *
                    ethToMintRatio *
                    collectionMintPrice *
                    collectionMintMultiplier) /
                    (uint256(BASIS) * BASIS * BASIS);

                outcome.tierIndex = j;
                outcome.tierMultiplier = tiers.tierMultipliers[j];
                outcome.tierRisk = tiers.tierRisks[j];
                outcome.mintAmount = mintAmount;

                break;
            }
        }
    }

    function _calculateMintForMintResult_sharedLogic(
        Storage.Layout storage l,
        uint32 numberOfMints,
        uint256[] memory randomWords,
        uint256 collectionMintMultiplier,
        uint256 ethToMintRatio,
        uint256 mintPriceAdjustmentFactor,
        CollectionData storage collectionData
    ) private view returns (MintResultData memory result) {
        MintTokenTiersData storage mintTokenTiers = l.mintTokenTiers;

        uint256 collectionMintPrice = _collectionMintPrice(collectionData);

        result.mintOutcomes = new MintOutcome[](numberOfMints);

        for (uint256 i = 0; i < randomWords.length; ++i) {
            MintOutcome memory outcome;

            uint256 normalizedValue = _normalizeValue(randomWords[i], BASIS);

            uint256 mintAmount;
            uint256 cumulativeRisk;

            for (uint256 j = 0; j < mintTokenTiers.tierRisks.length; ++j) {
                cumulativeRisk += mintTokenTiers.tierRisks[j];

                if (cumulativeRisk > normalizedValue) {
                    mintAmount =
                        (mintTokenTiers.tierMultipliers[j] *
                            mintPriceAdjustmentFactor *
                            ethToMintRatio *
                            collectionMintPrice *
                            collectionMintMultiplier) /
                        (uint256(BASIS) * BASIS * BASIS);

                    outcome.tierIndex = j;
                    outcome.tierMultiplier = mintTokenTiers.tierMultipliers[j];
                    outcome.tierRisk = mintTokenTiers.tierRisks[j];
                    outcome.mintAmount = mintAmount;

                    break;
                }
            }

            result.totalMintAmount += mintAmount;

            result.mintOutcomes[i] = outcome;
        }
    }

    function _calculateMintForMintResultBlast_sharedLogic(
        Storage.Layout storage l,
        uint32 numberOfMints,
        uint256[] memory randomWords,
        uint256 collectionMintMultiplier,
        uint256 ethToMintRatio,
        uint256 mintPriceAdjustmentFactor,
        CollectionData storage collectionData
    ) private view returns (MintResultDataBlast memory result) {
        MintTokenTiersData storage mintTokenTiers = l.mintTokenTiers;

        uint32 blastYieldRisk = _blastYieldRisk();

        uint256 collectionMintPrice = _collectionMintPrice(collectionData);

        result.mintOutcomes = new MintOutcome[](numberOfMints);

        for (uint256 i = 0; i < randomWords.length; i += 2) {
            MintOutcome memory outcome;

            uint256 firstNormalizedValue = _normalizeValue(
                randomWords[i],
                BASIS
            );

            uint256 mintAmount;
            uint256 cumulativeRisk;

            for (uint256 j = 0; j < mintTokenTiers.tierRisks.length; ++j) {
                cumulativeRisk += mintTokenTiers.tierRisks[j];

                if (cumulativeRisk > firstNormalizedValue) {
                    mintAmount =
                        (mintTokenTiers.tierMultipliers[j] *
                            mintPriceAdjustmentFactor *
                            ethToMintRatio *
                            collectionMintPrice *
                            collectionMintMultiplier) /
                        (uint256(BASIS) * BASIS * BASIS);

                    outcome.tierIndex = j;
                    outcome.tierMultiplier = mintTokenTiers.tierMultipliers[j];
                    outcome.tierRisk = mintTokenTiers.tierRisks[j];
                    outcome.mintAmount = mintAmount;

                    break;
                }
            }

            uint256 secondNormalizedValue = _normalizeValue(
                randomWords[i + 1],
                BASIS
            );

            if (blastYieldRisk > secondNormalizedValue) {
                result.totalBlastYieldAmount += IBlast(BLAST)
                    .readClaimableYield(address(this));

                result.totalBlastYieldAmount += _calculateMaxClaimableGas();
            }

            result.totalMintAmount += mintAmount;

            result.mintOutcomes[i / 2] = outcome;
        }
    }

    /// @notice calculates & returns the maximum claimable blast gas yield for the current block
    /// @return maxClaimableGas maximum claimable gas yield
    function _calculateMaxClaimableGas()
        internal
        view
        returns (uint256 maxClaimableGas)
    {
        (uint256 etherSeconds, uint256 etherBalance, , ) = IBlast(BLAST)
            .readGasParams(address(this));

        // Calculate the maximum ether that can be claimed based on accumulated ether seconds
        uint256 maxEtherClaimableByTime = etherSeconds /
            IGas(GAS).ceilGasSeconds();

        // The actual claimable amount is the lesser of the ether balance and the amount based on time
        maxClaimableGas = (maxEtherClaimableByTime < etherBalance)
            ? maxEtherClaimableByTime
            : etherBalance;
    }

    /// @notice Cancels a claim for a given claimer for given token ID
    /// @param claimer address of rejected claimer
    /// @param tokenId token ID of rejected claim
    function _cancelClaim(address claimer, uint256 tokenId) internal {
        _safeTransfer(address(this), address(this), claimer, tokenId, 1, "");

        emit ClaimCancelled(
            claimer,
            address(uint160(tokenId)) // decode tokenId to get collection address
        );
    }

    /// @notice claims all accrued mint earnings
    /// @param recipient address of mint earnings recipient
    function _claimMintEarnings(address recipient) internal {
        Storage.Layout storage l = Storage.layout();

        uint256 mintEarnings = l.mintEarnings;
        l.mintEarnings = 0;

        payable(recipient).sendValue(mintEarnings);
    }

    /// @notice claims a specific amount of accrued mint earnings
    /// @param recipient address of mint earnings recipient
    /// @param amount amount of mint earnings to claim
    function _claimMintEarnings(address recipient, uint256 amount) internal {
        Storage.Layout storage l = Storage.layout();

        l.mintEarnings -= amount;

        payable(recipient).sendValue(amount);
    }

    /// @notice Initiates a claim for a prize for a given collection
    /// @param claimer address of claimer
    /// @param prizeRecipient address of intended prize recipient
    /// @param tokenId token ID of prize, which is the prize collection address encoded as uint256
    function _claimPrize(
        address claimer,
        address prizeRecipient,
        uint256 tokenId
    ) internal {
        _safeTransfer(msg.sender, claimer, address(this), tokenId, 1, "");

        emit PrizeClaimed(
            claimer,
            prizeRecipient,
            address(uint160(tokenId)) // decode tokenId to get collection address
        );
    }

    /// @notice claims all accrued protocol fees
    /// @param recipient address of protocol fees recipient
    function _claimProtocolFees(address recipient) internal {
        Storage.Layout storage l = Storage.layout();

        uint256 protocolFees = l.protocolFees;
        l.protocolFees = 0;

        payable(recipient).sendValue(protocolFees);
    }

    /// @notice Returns the current mint fee distribution ratio in basis points for a collection
    /// @param collection address of collection
    /// @return ratioBP current collection mint fee distribution ratio in basis points
    function _collectionMintFeeDistributionRatioBP(
        address collection
    ) internal view returns (uint32 ratioBP) {
        ratioBP = Storage
            .layout()
            .collections[collection]
            .mintFeeDistributionRatioBP;
    }

    /// @notice Returns the current collection multiplier for a given collection
    /// @param collectionData the CollectionData struct for a given collection
    /// @return multiplier current collection multiplier
    function _collectionMintMultiplier(
        CollectionData storage collectionData
    ) internal view returns (uint256 multiplier) {
        multiplier = collectionData.mintMultiplier;

        multiplier = multiplier == 0 ? BASIS : multiplier; // default multiplier is 1x
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

    /// @notice Returns the current mint referral fee for a given collection in basis points
    /// @param collectionData the CollectionData struct for a given collection
    /// @return referralFeeBP current mint collection referral fee in basis
    function _collectionReferralFeeBP(
        CollectionData storage collectionData
    ) internal view returns (uint32 referralFeeBP) {
        referralFeeBP = collectionData.referralFeeBP;
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

    /// @notice Returns the current collection consolation fee in basis points
    /// @return collectionConsolationFeeBasisPoints mint for collection consolation fee in basis points
    function _collectionConsolationFeeBP()
        internal
        view
        returns (uint32 collectionConsolationFeeBasisPoints)
    {
        collectionConsolationFeeBasisPoints = Storage
            .layout()
            .collectionConsolationFeeBP;
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

    /// @notice Returns the default mint referral fee for a collection in basis points
    /// @return referralFeeBP default mint collection referral fee in basis points
    function _defaultCollectionReferralFeeBP()
        internal
        view
        returns (uint32 referralFeeBP)
    {
        referralFeeBP = Storage.layout().defaultCollectionReferralFeeBP;
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

    /// @notice internal VRF callback
    /// @notice is executed by the configured VRF contract
    /// @param requestId id of VRF request
    /// @param randomWords random values return by the configured VRF contract
    function _fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal {
        Storage.Layout storage l = Storage.layout();

        RequestData storage request = l.requests[requestId];

        address collection = request.collection;
        address minter = request.minter;
        uint256 mintPriceAdjustmentFactor = request.mintPriceAdjustmentFactor;

        CollectionData storage collectionData = l.collections[collection];

        if (collection == MINT_TOKEN_COLLECTION_ADDRESS) {
            // the mint is for $MINT
            _resolveMintsForMint(
                l.mintToken,
                _collectionMintMultiplier(collectionData),
                _collectionMintPrice(collectionData),
                mintPriceAdjustmentFactor,
                l.mintTokenTiers,
                minter,
                randomWords,
                _ethToMintRatio(l)
            );
        } else if (collection == ETH_COLLECTION_ADDRESS) {
            // the mint is for ETH
            _resolveMintsForEth(
                l,
                request,
                _collectionMintMultiplier(collectionData),
                _collectionMintPrice(collectionData),
                randomWords,
                _ethToMintRatio(l)
            );
        } else {
            // the mint is for a collection
            _resolveMints(
                l.mintToken,
                collectionData,
                mintPriceAdjustmentFactor,
                l.tiers,
                minter,
                collection,
                randomWords,
                _ethToMintRatio(l)
            );
        }

        collectionData.pendingRequests.remove(requestId);

        delete l.requests[requestId];
    }

    /// @notice Blast-specific internal VRF callback
    /// @notice is executed by the configured VRF contract
    /// @param requestId id of VRF request
    /// @param randomWords random values return by the configured VRF contract
    function _fulfillRandomWordsBlast(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal {
        Storage.Layout storage l = Storage.layout();

        RequestData storage request = l.requests[requestId];

        address collection = request.collection;
        address minter = request.minter;
        uint256 mintPriceAdjustmentFactor = request.mintPriceAdjustmentFactor;

        CollectionData storage collectionData = l.collections[collection];

        if (collection == MINT_TOKEN_COLLECTION_ADDRESS) {
            // the mint is for $MINT
            _resolveMintsForMintBlast(
                l.mintToken,
                _collectionMintMultiplier(collectionData),
                _collectionMintPrice(collectionData),
                mintPriceAdjustmentFactor,
                l.mintTokenTiers,
                minter,
                randomWords,
                _ethToMintRatio(l)
            );
        } else if (collection == ETH_COLLECTION_ADDRESS) {
            // the mint is for ETH
            _resolveMintsForEthBlast(
                l,
                request,
                _collectionMintMultiplier(collectionData),
                _collectionMintPrice(collectionData),
                randomWords,
                _ethToMintRatio(l)
            );
        } else {
            // the mint is for a collection
            _resolveMintsBlast(
                l.mintToken,
                collectionData,
                mintPriceAdjustmentFactor,
                l.tiers,
                minter,
                collection,
                randomWords,
                _ethToMintRatio(l)
            );
        }

        collectionData.pendingRequests.remove(requestId);

        delete l.requests[requestId];
    }

    /// @notice funds the consolation fees pool with ETH
    function _fundConsolationFees() internal {
        Storage.layout().consolationFees += msg.value;

        emit ConsolationFeesFunded(msg.sender, msg.value);
    }

    /// @notice mints an amount of mintToken tokens to the mintToken contract in exchange for ETH
    /// @param amount amount of mintToken tokens to mint
    function _mintAirdrop(uint256 amount) internal {
        Storage.Layout storage l = Storage.layout();

        if (amount / _ethToMintRatio(l) != msg.value) {
            revert IncorrectETHReceived();
        }

        l.consolationFees += msg.value;

        IToken(l.mintToken).mintAirdrop(amount);
    }

    /// @notice Returns the current mint earnings buffer in basis points
    /// @return mintEarningsBufferBasisPoints mint earnings buffer in basis points
    function _mintEarningsBufferBP()
        internal
        view
        returns (uint32 mintEarningsBufferBasisPoints)
    {
        mintEarningsBufferBasisPoints = Storage.layout().mintEarningsBufferBP;
    }

    /// @notice Returns the current mint fee in basis points
    /// @return mintFeeBasisPoints mint fee in basis points
    function _mintFeeBP() internal view returns (uint32 mintFeeBasisPoints) {
        mintFeeBasisPoints = Storage.layout().mintFeeBP;
    }

    /// @notice Returns the current mint for ETH consolation fee in basis points
    /// @return mintForEthConsolationFeeBasisPoints mint for ETH consolation fee in basis points
    function _mintForEthConsolationFeeBP()
        internal
        view
        returns (uint32 mintForEthConsolationFeeBasisPoints)
    {
        mintForEthConsolationFeeBasisPoints = Storage
            .layout()
            .mintForEthConsolationFeeBP;
    }

    /// @notice Returns the address of the current $MINT token
    /// @return mintToken address of the current $MINT token
    function _mintToken() internal view returns (address mintToken) {
        mintToken = Storage.layout().mintToken;
    }

    /// @notice Returns the current mint for $MINT consolation fee in basis points
    /// @return mintTokenConsolationFeeBasisPoints mint for $MINT consolation fee in basis points
    function _mintTokenConsolationFeeBP()
        internal
        view
        returns (uint32 mintTokenConsolationFeeBasisPoints)
    {
        mintTokenConsolationFeeBasisPoints = Storage
            .layout()
            .mintTokenConsolationFeeBP;
    }

    /// @notice Returns the current tier risks and multipliers for minting for $MINT
    function _mintTokenTiers()
        internal
        view
        returns (MintTokenTiersData memory mintTokenTiersData)
    {
        mintTokenTiersData = Storage.layout().mintTokenTiers;
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
    function _redeem(address account, uint256 amount) internal {
        Storage.Layout storage l = Storage.layout();

        if (l.redeemPaused) {
            revert RedeemPaused();
        }

        // burn amount of $MINT to be swapped
        IToken(l.mintToken).burn(account, amount);

        // calculate amount of ETH given for $MINT amount
        uint256 ethAmount = (amount * (BASIS - l.redemptionFeeBP)) /
            (BASIS * _ethToMintRatio(l));

        if (ethAmount > l.consolationFees) {
            revert InsufficientConsolationFees();
        }

        // decrease consolationFees
        l.consolationFees -= ethAmount;

        payable(account).sendValue(ethAmount);
    }

    /// @notice returns value of redeemPaused
    /// @return status boolean indicating whether redeeming is paused
    function _redeemPaused() internal view returns (bool status) {
        status = Storage.layout().redeemPaused;
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
    /// @param mintEarningsFee fee contributed to the mint earnings pool
    /// @param mintPriceAdjustmentFactor adjustment factor for mint price
    /// @param prizeValueInWei value of prize in ETH (denominated in wei)
    /// @param numWords amount of random values to request
    function _requestRandomWords(
        Storage.Layout storage l,
        CollectionData storage collectionData,
        address minter,
        address collection,
        uint256 mintEarningsFee,
        uint256 mintPriceAdjustmentFactor,
        uint256 prizeValueInWei,
        uint32 numWords
    ) internal {
        VRFCoordinatorV2Interface vrfCoordinator = VRFCoordinatorV2Interface(
            VRF
        );

        (uint96 vrfSubscriptionBalance, , , ) = vrfCoordinator.getSubscription(
            l.vrfConfig.subscriptionId
        );

        if (vrfSubscriptionBalance < l.vrfSubscriptionBalanceThreshold) {
            revert VRFSubscriptionBalanceBelowThreshold();
        }

        uint256 requestId = vrfCoordinator.requestRandomWords(
            l.vrfConfig.keyHash,
            l.vrfConfig.subscriptionId,
            l.vrfConfig.minConfirmations,
            l.vrfConfig.callbackGasLimit,
            numWords
        );

        collectionData.pendingRequests.add(requestId);

        l.requests[requestId] = RequestData({
            collection: collection,
            minter: minter,
            mintEarningsFee: mintEarningsFee,
            mintPriceAdjustmentFactor: mintPriceAdjustmentFactor,
            prizeValueInWei: prizeValueInWei
        });
    }

    /// @notice requests random values from Supra VRF, Supra VRF-specific
    /// @param l the PerpetualMint storage layout
    /// @param collectionData the CollectionData struct for a given collection
    /// @param minter address calling this function
    /// @param collection address of collection to attempt mint for
    /// @param mintEarningsFee fee contributed to the mint earnings pool
    /// @param mintPriceAdjustmentFactor adjustment factor for mint price
    /// @param prizeValueInWei value of prize in ETH (denominated in wei)
    /// @param numWords amount of random values to request
    function _requestRandomWordsSupra(
        Storage.Layout storage l,
        CollectionData storage collectionData,
        address minter,
        address collection,
        uint256 mintEarningsFee,
        uint256 mintPriceAdjustmentFactor,
        uint256 prizeValueInWei,
        uint8 numWords
    ) internal {
        ISupraRouterContract supraRouter = ISupraRouterContract(VRF);

        uint256 requestId = supraRouter.generateRequest(
            "rawFulfillRandomWords(uint256,uint256[])",
            numWords,
            1, // number of confirmations
            _owner()
        );

        collectionData.pendingRequests.add(requestId);

        l.requests[requestId] = RequestData({
            collection: collection,
            minter: minter,
            mintEarningsFee: mintEarningsFee,
            mintPriceAdjustmentFactor: mintPriceAdjustmentFactor,
            prizeValueInWei: prizeValueInWei
        });
    }

    /// @notice resolves the outcomes of attempted mints for a given collection
    /// @param mintToken address of $MINT token
    /// @param collectionData the CollectionData struct for a given collection
    /// @param mintPriceAdjustmentFactor adjustment factor for mint price
    /// @param tiersData the TiersData struct for mint consolations
    /// @param minter address of minter
    /// @param collection address of collection for mint attempts
    /// @param randomWords array of random values relating to number of attempts
    /// @param ethToMintRatio ratio of ETH to $MINT
    function _resolveMints(
        address mintToken,
        CollectionData storage collectionData,
        uint256 mintPriceAdjustmentFactor,
        TiersData memory tiersData,
        address minter,
        address collection,
        uint256[] memory randomWords,
        uint256 ethToMintRatio
    ) internal {
        // ensure the number of random words is even
        // each valid mint attempt requires two random words
        if (randomWords.length % 2 != 0) {
            revert UnmatchedRandomWords();
        }

        uint256 collectionMintMultiplier = _collectionMintMultiplier(
            collectionData
        );

        uint256 collectionMintPrice = _collectionMintPrice(collectionData);

        // adjust the collection risk by the mint price adjustment factor
        uint256 collectionRisk = (_collectionRisk(collectionData) *
            mintPriceAdjustmentFactor) / BASIS;

        uint256 cumulativeTierMultiplier;
        uint256 totalReceiptAmount;

        for (uint256 i = 0; i < randomWords.length; i += 2) {
            // first random word is used to determine whether the mint attempt was successful
            uint256 firstNormalizedValue = _normalizeValue(
                randomWords[i],
                BASIS
            );

            // if the collection risk is less than the first normalized value, the mint attempt is unsuccessful
            // and the second normalized value is used to determine the consolation tier
            if (!(collectionRisk > firstNormalizedValue)) {
                // second random word is used to determine the consolation tier
                uint256 secondNormalizedValue = _normalizeValue(
                    randomWords[i + 1],
                    BASIS
                );

                cumulativeTierMultiplier += _calculateTierMultiplier(
                    tiersData,
                    secondNormalizedValue
                );
            } else {
                // mint attempt is successful, so the total receipt amount is incremented
                ++totalReceiptAmount;
            }
        }

        uint256 totalMintAmount;

        // Mint the cumulative amounts at the end
        if (cumulativeTierMultiplier > 0) {
            // Adjust for the cumulative tier multiplier, ETH to $MINT ratio, collection mint price, and apply collection-specific multiplier & mint price adjustment factor
            totalMintAmount =
                (cumulativeTierMultiplier *
                    ethToMintRatio *
                    collectionMintPrice *
                    collectionMintMultiplier *
                    mintPriceAdjustmentFactor) /
                (uint256(BASIS) * BASIS * BASIS);

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

        emit MintResult(
            minter,
            collection,
            randomWords.length / 2,
            totalMintAmount,
            totalReceiptAmount,
            0
        );
    }

    /// @notice resolves the outcomes of attempted mints for a given collection on Blast
    /// @param mintToken address of $MINT token
    /// @param collectionData the CollectionData struct for a given collection
    /// @param mintPriceAdjustmentFactor adjustment factor for mint price
    /// @param tiersData the TiersData struct for mint consolations
    /// @param minter address of minter
    /// @param collection address of collection for mint attempts
    /// @param randomWords array of random values relating to number of attempts
    /// @param ethToMintRatio ratio of ETH to $MINT
    function _resolveMintsBlast(
        address mintToken,
        CollectionData storage collectionData,
        uint256 mintPriceAdjustmentFactor,
        TiersData memory tiersData,
        address minter,
        address collection,
        uint256[] memory randomWords,
        uint256 ethToMintRatio
    ) internal {
        // ensure the number of random words is odd
        // each valid mint attempt requires three random words
        if (randomWords.length % 3 != 0) {
            revert UnmatchedRandomWords();
        }

        uint32 blastYieldRisk = _blastYieldRisk();

        uint256 collectionMintMultiplier = _collectionMintMultiplier(
            collectionData
        );

        uint256 collectionMintPrice = _collectionMintPrice(collectionData);

        // adjust the collection risk by the mint price adjustment factor
        uint256 collectionRisk = (_collectionRisk(collectionData) *
            mintPriceAdjustmentFactor) / BASIS;

        uint256 cumulativeTierMultiplier;
        uint256 totalBlastYieldAmount;
        uint256 totalReceiptAmount;

        for (uint256 i = 0; i < randomWords.length; i += 3) {
            // first random word is used to determine whether the mint attempt was successful
            uint256 firstNormalizedValue = _normalizeValue(
                randomWords[i],
                BASIS
            );

            // if the collection risk is less than the first normalized value, the mint attempt is unsuccessful
            // and the second normalized value is used to determine the consolation tier
            if (!(collectionRisk > firstNormalizedValue)) {
                // second random word is used to determine the consolation tier
                uint256 secondNormalizedValue = _normalizeValue(
                    randomWords[i + 1],
                    BASIS
                );

                cumulativeTierMultiplier += _calculateTierMultiplier(
                    tiersData,
                    secondNormalizedValue
                );
            } else {
                // mint attempt is successful, so the total receipt amount is incremented
                ++totalReceiptAmount;
            }

            // third random word is used to determine the Blast yield outcome
            uint256 thirdNormalizedValue = _normalizeValue(
                randomWords[i + 2],
                BASIS
            );

            totalBlastYieldAmount += _processBlastYieldOutcome(
                thirdNormalizedValue,
                minter,
                blastYieldRisk,
                totalBlastYieldAmount
            );
        }

        uint256 totalMintAmount;

        // Mint the cumulative amounts at the end
        if (cumulativeTierMultiplier > 0) {
            // Adjust for the cumulative tier multiplier, ETH to $MINT ratio, collection mint price, and apply collection-specific multiplier & mint price adjustment factor
            totalMintAmount =
                (cumulativeTierMultiplier *
                    ethToMintRatio *
                    collectionMintPrice *
                    collectionMintMultiplier *
                    mintPriceAdjustmentFactor) /
                (uint256(BASIS) * BASIS * BASIS);

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

        emit MintResultBlast(
            minter,
            collection,
            randomWords.length / 3,
            totalBlastYieldAmount,
            totalMintAmount,
            totalReceiptAmount,
            0
        );
    }

    /// @notice resolves the outcomes of attempted mints for ETH
    /// @param l the PerpetualMint storage layout
    /// @param request the RequestData struct for the mint request
    /// @param mintForEthMultiplier minting for ETH multiplier
    /// @param mintForEthPrice mint for ETH mint price
    /// @param randomWords array of random values relating to number of attempts
    /// @param ethToMintRatio ratio of ETH to $MINT
    function _resolveMintsForEth(
        Storage.Layout storage l,
        RequestData memory request,
        uint256 mintForEthMultiplier,
        uint256 mintForEthPrice,
        uint256[] memory randomWords,
        uint256 ethToMintRatio
    ) internal {
        // ensure the number of random words is even
        // each valid mint attempt requires two random words
        if (randomWords.length % 2 != 0) {
            revert UnmatchedRandomWords();
        }

        // determine the risk by dividing the mint earnings fee by the prize value in wei
        uint256 risk = (request.mintEarningsFee * BASIS) /
            request.prizeValueInWei;

        uint256 cumulativeTierMultiplier;
        uint256 totalReceiptAmount;
        uint256 totalPrizeValueAmount;

        for (uint256 i = 0; i < randomWords.length; i += 2) {
            // first random word is used to determine whether the mint attempt was successful
            uint256 firstNormalizedValue = _normalizeValue(
                randomWords[i],
                BASIS
            );

            // if the risk is less than the first normalized value, the mint attempt is unsuccessful
            // and the second normalized value is used to determine the consolation tier
            if (!(risk > firstNormalizedValue)) {
                // second random word is used to determine the consolation tier
                uint256 secondNormalizedValue = _normalizeValue(
                    randomWords[i + 1],
                    BASIS
                );

                cumulativeTierMultiplier += _calculateTierMultiplier(
                    l.tiers,
                    secondNormalizedValue
                );
            } else {
                // successful attempt, increment prize amount
                totalPrizeValueAmount += request.prizeValueInWei;

                // increment receipt amount in case automated ETH payout fails
                ++totalReceiptAmount;
            }
        }

        uint256 totalMintAmount;

        // Mint the cumulative amounts at the end
        if (cumulativeTierMultiplier > 0) {
            // Adjust for the cumulative tier multiplier, ETH to $MINT ratio, mint for ETH price, and apply mint for ETH-specific multiplier & mint price adjustment factor
            totalMintAmount =
                (cumulativeTierMultiplier *
                    ethToMintRatio *
                    mintForEthPrice *
                    mintForEthMultiplier *
                    request.mintPriceAdjustmentFactor) /
                (uint256(BASIS) * BASIS * BASIS);

            IToken(l.mintToken).mint(request.minter, totalMintAmount);
        }

        // Pay out ETH prize for successful attempts
        if (totalPrizeValueAmount > 0) {
            // Ensure there are enough mint earnings to cover the prize payout
            if (l.mintEarnings < totalPrizeValueAmount) {
                // Not enough mint earnings, mint receipts for manual payout
                _safeMint(
                    request.minter,
                    uint256(bytes32(abi.encode(ETH_COLLECTION_ADDRESS))), // encode address as tokenId
                    totalReceiptAmount,
                    ""
                );
            } else {
                // decrease mint earnings by the total prize value amount
                l.mintEarnings -= totalPrizeValueAmount;

                // try to send ETH prize
                (bool success, ) = request.minter.call{
                    value: totalPrizeValueAmount
                }("");

                if (!success) {
                    // transfer ETH failed, revert the deduction
                    l.mintEarnings += totalPrizeValueAmount;

                    // mint receipts for manual payout
                    _safeMint(
                        request.minter,
                        uint256(bytes32(abi.encode(ETH_COLLECTION_ADDRESS))), // encode address as tokenId
                        totalReceiptAmount,
                        ""
                    );
                }
            }
        }

        emit MintResult(
            request.minter,
            ETH_COLLECTION_ADDRESS,
            randomWords.length / 2,
            totalMintAmount,
            totalReceiptAmount,
            totalPrizeValueAmount
        );
    }

    /// @notice resolves the outcomes of attempted mints for ETH on Blast
    /// @param l the PerpetualMint storage layout
    /// @param request the RequestData struct for the mint request
    /// @param mintForEthMultiplier minting for ETH multiplier
    /// @param mintForEthPrice mint for ETH mint price
    /// @param randomWords array of random values relating to number of attempts
    /// @param ethToMintRatio ratio of ETH to $MINT
    function _resolveMintsForEthBlast(
        Storage.Layout storage l,
        RequestData memory request,
        uint256 mintForEthMultiplier,
        uint256 mintForEthPrice,
        uint256[] memory randomWords,
        uint256 ethToMintRatio
    ) internal {
        // ensure the number of random words is odd
        // each valid mint attempt requires three random words
        if (randomWords.length % 3 != 0) {
            revert UnmatchedRandomWords();
        }

        uint32 blastYieldRisk = _blastYieldRisk();

        // determine the risk by dividing the mint earnings fee by the prize value in wei
        uint256 risk = (request.mintEarningsFee * BASIS) /
            request.prizeValueInWei;

        uint256 cumulativeTierMultiplier;
        uint256 totalBlastYieldAmount;
        uint256 totalReceiptAmount;
        uint256 totalPrizeValueAmount;

        for (uint256 i = 0; i < randomWords.length; i += 3) {
            // first random word is used to determine whether the mint attempt was successful
            uint256 firstNormalizedValue = _normalizeValue(
                randomWords[i],
                BASIS
            );

            // if the risk is less than the first normalized value, the mint attempt is unsuccessful
            // and the second normalized value is used to determine the consolation tier
            if (!(risk > firstNormalizedValue)) {
                // second random word is used to determine the consolation tier
                uint256 secondNormalizedValue = _normalizeValue(
                    randomWords[i + 1],
                    BASIS
                );

                cumulativeTierMultiplier += _calculateTierMultiplier(
                    l.tiers,
                    secondNormalizedValue
                );
            } else {
                // successful attempt, increment prize amount
                totalPrizeValueAmount += request.prizeValueInWei;

                // increment receipt amount in case automated ETH payout fails
                ++totalReceiptAmount;
            }

            // third random word is used to determine the Blast yield outcome
            uint256 thirdNormalizedValue = _normalizeValue(
                randomWords[i + 2],
                BASIS
            );

            totalBlastYieldAmount += _processBlastYieldOutcome(
                thirdNormalizedValue,
                request.minter,
                blastYieldRisk,
                totalBlastYieldAmount
            );
        }

        uint256 totalMintAmount;

        // Mint the cumulative amounts at the end
        if (cumulativeTierMultiplier > 0) {
            // Adjust for the cumulative tier multiplier, ETH to $MINT ratio, mint for ETH price, and apply mint for ETH-specific multiplier & mint price adjustment factor
            totalMintAmount =
                (cumulativeTierMultiplier *
                    ethToMintRatio *
                    mintForEthPrice *
                    mintForEthMultiplier *
                    request.mintPriceAdjustmentFactor) /
                (uint256(BASIS) * BASIS * BASIS);

            IToken(l.mintToken).mint(request.minter, totalMintAmount);
        }

        // Pay out ETH prize for successful attempts
        if (totalPrizeValueAmount > 0) {
            // Ensure there are enough mint earnings to cover the prize payout
            if (l.mintEarnings < totalPrizeValueAmount) {
                // Not enough mint earnings, mint receipts for manual payout
                _safeMint(
                    request.minter,
                    uint256(bytes32(abi.encode(ETH_COLLECTION_ADDRESS))), // encode address as tokenId
                    totalReceiptAmount,
                    ""
                );
            } else {
                // decrease mint earnings by the total prize value amount
                l.mintEarnings -= totalPrizeValueAmount;

                // try to send ETH prize
                (bool success, ) = request.minter.call{
                    value: totalPrizeValueAmount
                }("");

                if (!success) {
                    // transfer ETH failed, revert the deduction
                    l.mintEarnings += totalPrizeValueAmount;

                    // mint receipts for manual payout
                    _safeMint(
                        request.minter,
                        uint256(bytes32(abi.encode(ETH_COLLECTION_ADDRESS))), // encode address as tokenId
                        totalReceiptAmount,
                        ""
                    );
                }
            }
        }

        emit MintResultBlast(
            request.minter,
            ETH_COLLECTION_ADDRESS,
            randomWords.length / 3,
            totalBlastYieldAmount,
            totalMintAmount,
            totalReceiptAmount,
            totalPrizeValueAmount
        );
    }

    /// @notice resolves the outcomes of attempted mints for $MINT
    /// @param mintToken address of $MINT token
    /// @param mintForMintMultiplier minting for $MINT multiplier
    /// @param mintForMintPrice mint for $MINT mint price
    /// @param mintPriceAdjustmentFactor adjustment factor for mint price
    /// @param mintTokenTiersData the MintTokenTiersData struct for mint for $MINT consolations
    /// @param minter address of minter
    /// @param randomWords array of random values relating to number of attempts
    /// @param ethToMintRatio ratio of ETH to $MINT
    function _resolveMintsForMint(
        address mintToken,
        uint256 mintForMintMultiplier,
        uint256 mintForMintPrice,
        uint256 mintPriceAdjustmentFactor,
        MintTokenTiersData memory mintTokenTiersData,
        address minter,
        uint256[] memory randomWords,
        uint256 ethToMintRatio
    ) internal {
        uint256 cumulativeTierMultiplier;

        for (uint256 i = 0; i < randomWords.length; ++i) {
            // random word is used to determine the reward tier
            uint256 normalizedValue = _normalizeValue(randomWords[i], BASIS);

            cumulativeTierMultiplier += _calculateMintTokenTierMultiplier(
                mintTokenTiersData,
                normalizedValue
            );
        }

        // Mint the cumulative amounts at the end
        // Adjust for the cumulative tier multiplier, ETH to $MINT ratio, mint for $MINT price, and apply $MINT-specific multiplier & mint price adjustment factor
        uint256 totalMintAmount = (cumulativeTierMultiplier *
            ethToMintRatio *
            mintForMintPrice *
            mintForMintMultiplier *
            mintPriceAdjustmentFactor) / (uint256(BASIS) * BASIS * BASIS);

        IToken(mintToken).mint(minter, totalMintAmount);

        emit MintResult(
            minter,
            MINT_TOKEN_COLLECTION_ADDRESS,
            randomWords.length,
            totalMintAmount,
            0,
            0
        );
    }

    /// @notice resolves the outcomes of attempted mints for $MINT on Blast
    /// @param mintToken address of $MINT token
    /// @param mintForMintMultiplier minting for $MINT multiplier
    /// @param mintForMintPrice mint for $MINT mint price
    /// @param mintPriceAdjustmentFactor adjustment factor for mint price
    /// @param mintTokenTiersData the MintTokenTiersData struct for mint for $MINT consolations
    /// @param minter address of minter
    /// @param randomWords array of random values relating to number of attempts
    /// @param ethToMintRatio ratio of ETH to $MINT
    function _resolveMintsForMintBlast(
        address mintToken,
        uint256 mintForMintMultiplier,
        uint256 mintForMintPrice,
        uint256 mintPriceAdjustmentFactor,
        MintTokenTiersData memory mintTokenTiersData,
        address minter,
        uint256[] memory randomWords,
        uint256 ethToMintRatio
    ) internal {
        // ensure the number of random words is even
        // each valid mint for $MINT attempt on Blast requires two random words
        if (randomWords.length % 2 != 0) {
            revert UnmatchedRandomWords();
        }

        uint32 blastYieldRisk = _blastYieldRisk();

        uint256 cumulativeTierMultiplier;
        uint256 totalBlastYieldAmount;

        for (uint256 i = 0; i < randomWords.length; i += 2) {
            // random word is used to determine the reward tier
            uint256 firstNormalizedValue = _normalizeValue(
                randomWords[i],
                BASIS
            );

            cumulativeTierMultiplier += _calculateMintTokenTierMultiplier(
                mintTokenTiersData,
                firstNormalizedValue
            );

            // second random word is used to determine the Blast yield outcome
            uint256 secondNormalizedValue = _normalizeValue(
                randomWords[i + 1],
                BASIS
            );

            totalBlastYieldAmount += _processBlastYieldOutcome(
                secondNormalizedValue,
                minter,
                blastYieldRisk,
                totalBlastYieldAmount
            );
        }

        // Mint the cumulative amounts at the end
        // Adjust for the cumulative tier multiplier, ETH to $MINT ratio, mint for $MINT price, and apply $MINT-specific multiplier & mint price adjustment factor
        uint256 totalMintAmount = (cumulativeTierMultiplier *
            ethToMintRatio *
            mintForMintPrice *
            mintForMintMultiplier *
            mintPriceAdjustmentFactor) / (uint256(BASIS) * BASIS * BASIS);

        IToken(mintToken).mint(minter, totalMintAmount);

        emit MintResultBlast(
            minter,
            MINT_TOKEN_COLLECTION_ADDRESS,
            randomWords.length / 2,
            totalBlastYieldAmount,
            totalMintAmount,
            0,
            0
        );
    }

    function _calculateMintTokenTierMultiplier(
        MintTokenTiersData memory mintTokenTiersData,
        uint256 normalizedValue
    ) private pure returns (uint256 tierMultiplier) {
        uint256 cumulativeRisk;

        // iterate through tiers to find the tier that the random value falls into
        for (uint256 j = 0; j < mintTokenTiersData.tierRisks.length; ++j) {
            cumulativeRisk += mintTokenTiersData.tierRisks[j];

            // if the cumulative risk is greater than the second normalized value, the tier has been found
            if (cumulativeRisk > normalizedValue) {
                tierMultiplier = mintTokenTiersData.tierMultipliers[j];

                break;
            }
        }
    }

    function _calculateTierMultiplier(
        TiersData memory tiersData,
        uint256 normalizedValue
    ) private pure returns (uint256 tierMultiplier) {
        uint256 cumulativeRisk;

        // iterate through tiers to find the tier that the random value falls into
        for (uint256 j = 0; j < tiersData.tierRisks.length; ++j) {
            cumulativeRisk += tiersData.tierRisks[j];

            // if the cumulative risk is greater than the second normalized value, the tier has been found
            if (cumulativeRisk > normalizedValue) {
                tierMultiplier = tiersData.tierMultipliers[j];

                break;
            }
        }
    }

    function _processBlastYieldOutcome(
        uint256 normalizedValue,
        address minter,
        uint32 blastYieldRisk,
        uint256 _totalBlastYieldAmount
    ) private returns (uint256 totalBlastYieldAmount) {
        // if the Blast yield risk is greater than the normalized value, the minter receives all claimable, matured Blast yield
        if (blastYieldRisk > normalizedValue) {
            _totalBlastYieldAmount += IBlast(BLAST).claimAllYield(
                address(this),
                minter
            );

            if (_calculateMaxClaimableGas() > 0) {
                _totalBlastYieldAmount += IBlast(BLAST).claimMaxGas(
                    address(this),
                    minter
                );
            }
        }

        totalBlastYieldAmount = _totalBlastYieldAmount;
    }

    /// @notice returns the value of SCALE
    /// @return value SCALE value
    function _SCALE() internal pure returns (uint256 value) {
        value = SCALE;
    }

    /// @notice sets the risk for Blast yield
    /// @param risk risk of Blast yield
    function _setBlastYieldRisk(uint32 risk) internal {
        _enforceBasis(risk, BASIS);

        Storage.layout().yieldRisk = risk;

        emit BlastYieldRiskSet(risk);
    }

    /// @notice sets the collection mint fee distribution ratio in basis points
    /// @param collection address of collection
    /// @param ratioBP collection mint fee distribution ratio in basis points
    function _setCollectionMintFeeDistributionRatioBP(
        address collection,
        uint32 ratioBP
    ) internal {
        _enforceBasis(ratioBP, BASIS);

        CollectionData storage collectionData = Storage.layout().collections[
            collection
        ];

        collectionData.mintFeeDistributionRatioBP = ratioBP;

        emit CollectionMintFeeRatioUpdated(collection, ratioBP);
    }

    /// @notice sets the mint multiplier for a given collection
    /// @param collection address of collection
    /// @param multiplier mint multiplier of the collection
    function _setCollectionMintMultiplier(
        address collection,
        uint256 multiplier
    ) internal {
        CollectionData storage collectionData = Storage.layout().collections[
            collection
        ];

        _enforceNoPendingMints(collectionData);

        collectionData.mintMultiplier = multiplier;

        emit CollectionMultiplierSet(collection, multiplier);
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

    /// @notice sets the mint referral fee for a given collection in basis points
    /// @param collection address of collection
    /// @param referralFeeBP mint referral fee of the collection in basis points
    function _setCollectionReferralFeeBP(
        address collection,
        uint32 referralFeeBP
    ) internal {
        CollectionData storage collectionData = Storage.layout().collections[
            collection
        ];

        _enforceBasis(referralFeeBP, BASIS);

        collectionData.referralFeeBP = referralFeeBP;

        emit CollectionReferralFeeBPSet(collection, referralFeeBP);
    }

    /// @notice sets the risk for a given collection
    /// @param collection address of collection
    /// @param risk risk of the collection
    function _setCollectionRisk(address collection, uint32 risk) internal {
        CollectionData storage collectionData = Storage.layout().collections[
            collection
        ];

        _enforceBasis(risk, BASIS);

        _enforceNoPendingMints(collectionData);

        collectionData.risk = risk;

        emit CollectionRiskSet(collection, risk);
    }

    /// @notice sets the mint for collection consolation fee in basis points
    /// @param collectionConsolationFeeBP mint for collection consolation fee in basis points
    function _setCollectionConsolationFeeBP(
        uint32 collectionConsolationFeeBP
    ) internal {
        _enforceBasis(collectionConsolationFeeBP, BASIS);

        Storage
            .layout()
            .collectionConsolationFeeBP = collectionConsolationFeeBP;

        emit CollectionConsolationFeeSet(collectionConsolationFeeBP);
    }

    /// @notice sets the default mint referral fee for collections in basis points
    /// @param referralFeeBP new default mint referral fee for collections in basis points
    function _setDefaultCollectionReferralFeeBP(uint32 referralFeeBP) internal {
        _enforceBasis(referralFeeBP, BASIS);

        Storage.layout().defaultCollectionReferralFeeBP = referralFeeBP;

        emit DefaultCollectionReferralFeeBPSet(referralFeeBP);
    }

    /// @notice sets the ratio of ETH (native token) to $MINT for mint attempts using $MINT as payment
    /// @param ratio new ratio of ETH to $MINT
    function _setEthToMintRatio(uint256 ratio) internal {
        Storage.layout().ethToMintRatio = ratio;

        emit EthToMintRatioSet(ratio);
    }

    /// @notice sets the mint earnings buffer in basis points
    /// @param mintEarningsBufferBP mint earnings buffer in basis points
    function _setMintEarningsBufferBP(uint32 mintEarningsBufferBP) internal {
        _enforceBasis(mintEarningsBufferBP, BASIS);

        Storage.layout().mintEarningsBufferBP = mintEarningsBufferBP;

        emit MintEarningsBufferSet(mintEarningsBufferBP);
    }

    /// @notice sets the mint fee in basis points
    /// @param mintFeeBP mint fee in basis points
    function _setMintFeeBP(uint32 mintFeeBP) internal {
        _enforceBasis(mintFeeBP, BASIS);

        Storage.layout().mintFeeBP = mintFeeBP;

        emit MintFeeSet(mintFeeBP);
    }

    /// @notice sets the mint for ETH consolation fee in basis points
    /// @param mintForEthConsolationFeeBP mint for ETH consolation fee in basis points
    function _setMintForEthConsolationFeeBP(
        uint32 mintForEthConsolationFeeBP
    ) internal {
        _enforceBasis(mintForEthConsolationFeeBP, BASIS);

        Storage
            .layout()
            .mintForEthConsolationFeeBP = mintForEthConsolationFeeBP;

        emit MintForEthConsolationFeeSet(mintForEthConsolationFeeBP);
    }

    /// @notice sets the address of the mint consolation token
    /// @param mintToken address of the mint consolation token
    function _setMintToken(address mintToken) internal {
        Storage.layout().mintToken = mintToken;

        emit MintTokenSet(mintToken);
    }

    /// @notice sets the mint for $MINT consolation fee in basis points
    /// @param mintTokenConsolationFeeBP mint for $MINT consolation fee in basis points
    function _setMintTokenConsolationFeeBP(
        uint32 mintTokenConsolationFeeBP
    ) internal {
        _enforceBasis(mintTokenConsolationFeeBP, BASIS);

        Storage.layout().mintTokenConsolationFeeBP = mintTokenConsolationFeeBP;

        emit MintTokenConsolationFeeSet(mintTokenConsolationFeeBP);
    }

    /// @notice sets the mint for $MINT tiers data
    /// @param mintTokenTiersData MintTokenTiersData struct holding all related data to mint for $MINT consolations
    function _setMintTokenTiers(
        MintTokenTiersData calldata mintTokenTiersData
    ) internal {
        Storage.layout().mintTokenTiers = mintTokenTiersData;

        emit MintTokenTiersSet(mintTokenTiersData);
    }

    /// @notice sets the status of the redeemPaused state
    /// @param status boolean indicating whether redeeming is paused
    function _setRedeemPaused(bool status) internal {
        Storage.layout().redeemPaused = status;

        emit RedeemPausedSet(status);
    }

    /// @notice sets the redemption fee in basis points
    /// @param redemptionFeeBP redemption fee in basis points
    function _setRedemptionFeeBP(uint32 redemptionFeeBP) internal {
        _enforceBasis(redemptionFeeBP, BASIS);

        Storage.layout().redemptionFeeBP = redemptionFeeBP;

        emit RedemptionFeeSet(redemptionFeeBP);
    }

    /// @notice sets the mint for collection $MINT consolation tiers data
    /// @param tiersData TiersData struct holding all related data to mint for collection $MINT consolations
    function _setTiers(TiersData calldata tiersData) internal {
        Storage.layout().tiers = tiersData;

        emit TiersSet(tiersData);
    }

    /// @notice sets the Chainlink VRF config
    /// @param config VRFConfig struct holding all related data to ChainlinkVRF
    function _setVRFConfig(VRFConfig calldata config) internal {
        Storage.layout().vrfConfig = config;

        emit VRFConfigSet(config);
    }

    /// @notice sets the Chainlink VRF subscription LINK balance threshold
    /// @param vrfSubscriptionBalanceThreshold VRF subscription balance threshold
    function _setVRFSubscriptionBalanceThreshold(
        uint96 vrfSubscriptionBalanceThreshold
    ) internal {
        Storage
            .layout()
            .vrfSubscriptionBalanceThreshold = vrfSubscriptionBalanceThreshold;

        emit VRFSubscriptionBalanceThresholdSet(
            vrfSubscriptionBalanceThreshold
        );
    }

    /// @notice Returns the current tier risks and multipliers for minting for collection $MINT consolations
    function _tiers() internal view returns (TiersData memory tiersData) {
        tiersData = Storage.layout().tiers;
    }

    /// @notice Returns the current Chainlink VRF config
    /// @return config VRFConfig struct
    function _vrfConfig() internal view returns (VRFConfig memory config) {
        config = Storage.layout().vrfConfig;
    }

    /// @notice Returns the current Chainlink VRF subscription LINK balance threshold
    /// @return vrfSubscriptionBalanceThreshold VRF subscription balance threshold
    function _vrfSubscriptionBalanceThreshold()
        internal
        view
        returns (uint96 vrfSubscriptionBalanceThreshold)
    {
        vrfSubscriptionBalanceThreshold = Storage
            .layout()
            .vrfSubscriptionBalanceThreshold;
    }
}
