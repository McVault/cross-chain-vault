// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRenzoDepositContract {
    /**
     * @notice Deposits tokens into the contract.
     * @param _amountIn The amount of tokens to deposit.
     * @param _minOut The minimum amount of output tokens expected.
     * @param _deadline The deadline for the deposit transaction.
     * @return The amount of tokens received.
     */
    function deposit(
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _deadline
    ) external  returns (uint256);
}
