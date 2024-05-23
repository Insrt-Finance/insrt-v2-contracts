// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title IPerpetualMint
/// @dev Interface of the PerpetualMint facet
interface IPerpetualMint {
    /// @notice Attempts a batch mint for the msg.sender for ETH using ETH as payment.
    /// @param referrer referrer address for mint attempts
    /// @param numberOfMints number of mints to attempt
    /// @param ethPrizeValueInWei value of ETH prize in wei
    /// @param riskRewardRatio risk reward ratio for mint attempts
    function attemptBatchMintForEthWithEth(
        address referrer,
        uint32 numberOfMints,
        uint256 ethPrizeValueInWei,
        uint32 riskRewardRatio
    ) external payable;

    /// @notice Attempts a batch mint for the msg.sender for ETH using $MINT tokens as payment.
    /// @param referrer referrer address for mint attempts
    /// @param pricePerMint price per mint for ETH ($MINT denominated in units of wei)
    /// @param numberOfMints number of mints to attempt
    /// @param ethPrizeValueInWei value of ETH prize in wei
    /// @param riskRewardRatio risk reward ratio for mint attempts
    function attemptBatchMintForEthWithMint(
        address referrer,
        uint256 pricePerMint,
        uint32 numberOfMints,
        uint256 ethPrizeValueInWei,
        uint32 riskRewardRatio
    ) external;

    /// @notice Attempts a batch mint for the msg.sender for $MINT using ETH as payment.
    /// @param referrer referrer address for mint attempts
    /// @param numberOfMints number of mints to attempt
    function attemptBatchMintForMintWithEth(
        address referrer,
        uint32 numberOfMints
    ) external payable;

    /// @notice Attempts a batch mint for the msg.sender for $MINT using $MINT tokens as payment.
    /// @param referrer referrer address for mint attempts
    /// @param pricePerMint price per mint for $MINT ($MINT denominated in units of wei)
    /// @param numberOfMints number of mints to attempt
    function attemptBatchMintForMintWithMint(
        address referrer,
        uint256 pricePerMint,
        uint32 numberOfMints
    ) external;

    /// @notice Attempts a batch mint for the msg.sender for a single collection using ETH as payment.
    /// @param collection address of collection for mint attempts
    /// @param referrer referrer address for mint attempts
    /// @param numberOfMints number of mints to attempt
    function attemptBatchMintWithEth(
        address collection,
        address referrer,
        uint32 numberOfMints
    ) external payable;

    /// @notice Attempts a batch mint for the msg.sender for a single collection using $MINT tokens as payment.
    /// @param collection address of collection for mint attempts
    /// @param referrer referrer address for mint attempts
    /// @param pricePerMint price per mint for collection ($MINT denominated in units of wei)
    /// @param numberOfMints number of mints to attempt
    function attemptBatchMintWithMint(
        address collection,
        address referrer,
        uint256 pricePerMint,
        uint32 numberOfMints
    ) external;

    /// @notice Initiates a claim for a prize for a given collection
    /// @param prizeRecipient address of intended prize recipient
    /// @param tokenId token ID of prize, which is the prize collection address encoded as uint256
    function claimPrize(address prizeRecipient, uint256 tokenId) external;

    /// @notice funds the consolation fees pool with ETH
    function fundConsolationFees() external payable;

    /// @notice redeems an amount of $MINT tokens for ETH (native token) for the msg.sender
    /// @param amount amount of $MINT
    function redeem(uint256 amount) external;
}
