// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ISilo.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

interface ISiloRouter {
    struct Action {
        ActionType actionType;
        ISilo silo;
        IERC20 asset;
        uint256 amount;
        bool collateralOnly;
    }

    enum ActionType { Deposit, Withdraw, Borrow, Repay }

    function execute(Action[] calldata _actions) external payable;
}