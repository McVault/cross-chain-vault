// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ISiloRepository.sol";

interface ISilo {
    function siloRepository() external view returns (ISiloRepository);
}
