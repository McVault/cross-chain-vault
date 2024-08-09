// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ISilo.sol";


interface ISiloRepository {
    function getSilo(address asset) external view returns (address);
}