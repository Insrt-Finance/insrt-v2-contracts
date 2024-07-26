// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title ISupraGeneratorContract
/// @notice Interface for Supra VRF Generator Contract
interface ISupraGeneratorContract {
    /// @notice Getter for returning the Generator contract's Instance Identification Number
    /// @return instanceId Instance Identification Number
    function instanceId() external view returns (uint256 instanceId);

    /// @notice This function is used to generate random number request
    /// @dev This function will be called from router contract which is for the random number generation request
    /// @param _nonce nonce is an incremental counter which is associated with request
    /// @param _callerContract Actual client contract address from which request has been generated
    /// @param _functionName A combination of a function and the types of parameters it takes, combined together as a string with no spaces
    /// @param _rngCount Number of random numbers requested
    /// @param _numConfirmations Number of Confirmations
    /// @param _clientSeed Use of this is to add some extra randomness
    function rngRequest(
        uint256 _nonce,
        string memory _functionName,
        uint8 _rngCount,
        address _callerContract,
        uint256 _numConfirmations,
        uint256 _clientSeed,
        address _clientWalletAddress
    ) external;
}
