// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPoolAddressesProvider {
    /**
     * @notice Returns the address of the Pool proxy.
     * @return The Pool proxy address
     */
    function getPool() external view returns (address);
}
