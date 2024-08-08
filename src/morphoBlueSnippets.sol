// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/interfaces/morpho/IMorpho.sol";

import {IIrm} from "../src/interfaces/morpho/IIrm.sol";
import {IOracle} from "../src/interfaces/morpho/IOracle.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MorphoBalancesLib} from "../src/interfaces/morpho/libraries/periphery/MorphoBalancesLib.sol";
import {MarketParamsLib} from "../src/interfaces/morpho/libraries/MarketParamsLib.sol";
import {MorphoLib} from "../src/interfaces/morpho/libraries/periphery/MorphoLib.sol";
import {SharesMathLib} from "../src/interfaces/morpho/libraries/SharesMathLib.sol";

/// @title Morpho Blue Snippets
/// @author Morpho Labs
/// @custom:contact security@morpho.org
/// @notice The Morpho Blue Snippets contract.
contract MorphoBlueSnippets {
    using MorphoLib for IMorpho;
    using MorphoBalancesLib for IMorpho;
    using MarketParamsLib for MarketParams;
    using SafeERC20 for ERC20;
    using SharesMathLib for uint256;

    /* IMMUTABLES */

    IMorpho public immutable morpho;

    /* CONSTRUCTOR */

    /// @notice Constructs the contract.
    /// @param morphoAddress The address of the Morpho Blue contract.
    constructor(address morphoAddress) {
        morpho = IMorpho(morphoAddress);
    }

    /// @notice Handles the supply of assets by the caller to a specific market.
    /// @param marketParams The parameters of the market.
    /// @param amount The amount of assets the user is supplying.
    /// @return assetsSupplied The actual amount of assets supplied.
    /// @return sharesSupplied The shares supplied in return for the assets.
    function supply(
        MarketParams memory marketParams,
        uint256 amount
    ) external returns (uint256 assetsSupplied, uint256 sharesSupplied) {
        ERC20(marketParams.loanToken).forceApprove(
            address(morpho),
            type(uint256).max
        );
        ERC20(marketParams.loanToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        uint256 shares;
        address onBehalf = msg.sender;

        (assetsSupplied, sharesSupplied) = morpho.supply(
            marketParams,
            amount,
            shares,
            onBehalf,
            hex""
        );
    }

    function getPosition(
        Id id,
        address _address
    ) public view returns (Position memory) {
        return morpho.position(id, _address);
    }

    /// @notice Handles the supply of collateral by the caller to a specific market.
    /// @param marketParams The parameters of the market.
    /// @param amount The amount of collateral the user is supplying.
    function supplyCollateral(
        MarketParams memory marketParams,
        uint256 amount
    ) external returns (uint256) {
        ERC20(marketParams.collateralToken).forceApprove(
            address(morpho),
            type(uint256).max
        );
        ERC20(marketParams.collateralToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        address onBehalf = msg.sender;

        morpho.supplyCollateral(marketParams, amount, onBehalf, hex"");
        Position memory p = morpho.position(marketParams.id(), msg.sender);
        return p.collateral;
    }

    /// @notice Handles the withdrawal of collateral by the caller from a specific market of a specific amount.
    /// @param marketParams The parameters of the market.
    /// @param amount The amount of collateral the user is withdrawing.
    function withdrawCollateral(
        MarketParams memory marketParams,
        uint256 amount
    ) external {
        address onBehalf = msg.sender;
        address receiver = msg.sender;

        morpho.withdrawCollateral(marketParams, amount, onBehalf, receiver);
    }

    /// @notice Handles the withdrawal of a specified amount of assets by the caller from a specific market.
    /// @param marketParams The parameters of the market.
    /// @param amount The amount of assets the user is withdrawing.
    /// @return assetsWithdrawn The actual amount of assets withdrawn.
    /// @return sharesWithdrawn The shares withdrawn in return for the assets.
    function withdrawAmount(
        MarketParams memory marketParams,
        uint256 amount
    ) external returns (uint256 assetsWithdrawn, uint256 sharesWithdrawn) {
        uint256 shares;
        address onBehalf = msg.sender;
        address receiver = msg.sender;

        (assetsWithdrawn, sharesWithdrawn) = morpho.withdraw(
            marketParams,
            amount,
            shares,
            onBehalf,
            receiver
        );
    }

    /// @notice Handles the withdrawal of 50% of the assets by the caller from a specific market.
    /// @param marketParams The parameters of the market.
    /// @return assetsWithdrawn The actual amount of assets withdrawn.
    /// @return sharesWithdrawn The shares withdrawn in return for the assets.
    function withdraw50Percent(
        MarketParams memory marketParams
    ) external returns (uint256 assetsWithdrawn, uint256 sharesWithdrawn) {
        Id marketId = marketParams.id();
        uint256 supplyShares = morpho
            .position(marketId, msg.sender)
            .supplyShares;
        uint256 amount;
        uint256 shares = supplyShares / 2;

        address onBehalf = msg.sender;
        address receiver = msg.sender;

        (assetsWithdrawn, sharesWithdrawn) = morpho.withdraw(
            marketParams,
            amount,
            shares,
            onBehalf,
            receiver
        );
    }

    /// @notice Handles the withdrawal of all the assets by the caller from a specific market.
    /// @param marketParams The parameters of the market.
    /// @return assetsWithdrawn The actual amount of assets withdrawn.
    /// @return sharesWithdrawn The shares withdrawn in return for the assets.
    function withdrawAll(
        MarketParams memory marketParams
    ) external returns (uint256 assetsWithdrawn, uint256 sharesWithdrawn) {
        Id marketId = marketParams.id();
        uint256 supplyShares = morpho
            .position(marketId, msg.sender)
            .supplyShares;
        uint256 amount;

        address onBehalf = msg.sender;
        address receiver = msg.sender;

        (assetsWithdrawn, sharesWithdrawn) = morpho.withdraw(
            marketParams,
            amount,
            supplyShares,
            onBehalf,
            receiver
        );
    }

    /// @notice Handles the withdrawal of a specified amount of assets by the caller from a specific market. If the
    /// amount is greater than the total amount supplied by the user, withdraws all the shares of the user.
    /// @param marketParams The parameters of the market.
    /// @param amount The amount of assets the user is withdrawing.
    /// @return assetsWithdrawn The actual amount of assets withdrawn.
    /// @return sharesWithdrawn The shares withdrawn in return for the assets.
    function withdrawAmountOrAll(
        MarketParams memory marketParams,
        uint256 amount
    ) external returns (uint256 assetsWithdrawn, uint256 sharesWithdrawn) {
        Id id = marketParams.id();

        address onBehalf = msg.sender;
        address receiver = msg.sender;

        morpho.accrueInterest(marketParams);
        uint256 totalSupplyAssets = morpho.totalSupplyAssets(id);
        uint256 totalSupplyShares = morpho.totalSupplyShares(id);
        uint256 shares = morpho.supplyShares(id, msg.sender);

        uint256 assetsMax = shares.toAssetsDown(
            totalSupplyAssets,
            totalSupplyShares
        );

        if (amount >= assetsMax) {
            (assetsWithdrawn, sharesWithdrawn) = morpho.withdraw(
                marketParams,
                0,
                shares,
                onBehalf,
                receiver
            );
        } else {
            (assetsWithdrawn, sharesWithdrawn) = morpho.withdraw(
                marketParams,
                amount,
                0,
                onBehalf,
                receiver
            );
        }
    }

    /// @notice Handles the borrowing of assets by the caller from a specific market.
    /// @param marketParams The parameters of the market.
    /// @param amount The amount of assets the user is borrowing.
    /// @return assetsBorrowed The actual amount of assets borrowed.
    /// @return sharesBorrowed The shares borrowed in return for the assets.
    function borrow(
        MarketParams memory marketParams,
        uint256 amount
    ) external returns (uint256 assetsBorrowed, uint256 sharesBorrowed) {
        uint256 shares;
        address onBehalf = msg.sender;
        address receiver = msg.sender;

        (assetsBorrowed, sharesBorrowed) = morpho.borrow(
            marketParams,
            amount,
            shares,
            onBehalf,
            receiver
        );
    }

    /// @notice Handles the repayment of a specified amount of assets by the caller to a specific market.
    /// @param marketParams The parameters of the market.
    /// @param amount The amount of assets the user is repaying.
    /// @return assetsRepaid The actual amount of assets repaid.
    /// @return sharesRepaid The shares repaid in return for the assets.
    function repayAmount(
        MarketParams memory marketParams,
        uint256 amount
    ) external returns (uint256 assetsRepaid, uint256 sharesRepaid) {
        ERC20(marketParams.loanToken).forceApprove(
            address(morpho),
            type(uint256).max
        );
        ERC20(marketParams.loanToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        uint256 shares;
        address onBehalf = msg.sender;
        (assetsRepaid, sharesRepaid) = morpho.repay(
            marketParams,
            amount,
            shares,
            onBehalf,
            hex""
        );
    }

    /// @notice Handles the repayment of 50% of the borrowed assets by the caller to a specific market.
    /// @param marketParams The parameters of the market.
    /// @return assetsRepaid The actual amount of assets repaid.
    /// @return sharesRepaid The shares repaid in return for the assets.
    function repay50Percent(
        MarketParams memory marketParams
    ) external returns (uint256 assetsRepaid, uint256 sharesRepaid) {
        ERC20(marketParams.loanToken).forceApprove(
            address(morpho),
            type(uint256).max
        );

        Id marketId = marketParams.id();

        (, , uint256 totalBorrowAssets, uint256 totalBorrowShares) = morpho
            .expectedMarketBalances(marketParams);
        uint256 borrowShares = morpho
            .position(marketId, msg.sender)
            .borrowShares;

        uint256 repaidAmount = (borrowShares / 2).toAssetsUp(
            totalBorrowAssets,
            totalBorrowShares
        );
        ERC20(marketParams.loanToken).safeTransferFrom(
            msg.sender,
            address(this),
            repaidAmount
        );

        uint256 amount;
        address onBehalf = msg.sender;

        (assetsRepaid, sharesRepaid) = morpho.repay(
            marketParams,
            amount,
            borrowShares / 2,
            onBehalf,
            hex""
        );
    }

    /// @notice Handles the repayment of all the borrowed assets by the caller to a specific market.
    /// @param marketParams The parameters of the market.
    /// @return assetsRepaid The actual amount of assets repaid.
    /// @return sharesRepaid The shares repaid in return for the assets.
    function repayAll(
        MarketParams memory marketParams
    ) external returns (uint256 assetsRepaid, uint256 sharesRepaid) {
        ERC20(marketParams.loanToken).forceApprove(
            address(morpho),
            type(uint256).max
        );

        Id marketId = marketParams.id();

        (, , uint256 totalBorrowAssets, uint256 totalBorrowShares) = morpho
            .expectedMarketBalances(marketParams);
        uint256 borrowShares = morpho
            .position(marketId, msg.sender)
            .borrowShares;

        uint256 repaidAmount = borrowShares.toAssetsUp(
            totalBorrowAssets,
            totalBorrowShares
        );
        ERC20(marketParams.loanToken).safeTransferFrom(
            msg.sender,
            address(this),
            repaidAmount
        );

        uint256 amount;
        address onBehalf = msg.sender;
        (assetsRepaid, sharesRepaid) = morpho.repay(
            marketParams,
            amount,
            borrowShares,
            onBehalf,
            hex""
        );
    }

    /// @notice Handles the repayment of a specified amount of assets by the caller to a specific market. If the amount
    /// is greater than the total amount borrowed by the user it repays all the shares of the user.
    /// @param marketParams The parameters of the market.
    /// @param amount The amount of assets the user is repaying.
    /// @return assetsRepaid The actual amount of assets repaid.
    /// @return sharesRepaid The shares repaid in return for the assets.
    function repayAmountOrAll(
        MarketParams memory marketParams,
        uint256 amount
    ) external returns (uint256 assetsRepaid, uint256 sharesRepaid) {
        ERC20(marketParams.loanToken).forceApprove(
            address(morpho),
            type(uint256).max
        );

        Id id = marketParams.id();

        address onBehalf = msg.sender;

        morpho.accrueInterest(marketParams);
        uint256 totalBorrowAssets = morpho.totalBorrowAssets(id);
        uint256 totalBorrowShares = morpho.totalBorrowShares(id);
        uint256 shares = morpho.borrowShares(id, msg.sender);
        uint256 assetsMax = shares.toAssetsUp(
            totalBorrowAssets,
            totalBorrowShares
        );

        if (amount >= assetsMax) {
            ERC20(marketParams.loanToken).safeTransferFrom(
                msg.sender,
                address(this),
                assetsMax
            );
            (assetsRepaid, sharesRepaid) = morpho.repay(
                marketParams,
                0,
                shares,
                onBehalf,
                hex""
            );
        } else {
            ERC20(marketParams.loanToken).safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
            (assetsRepaid, sharesRepaid) = morpho.repay(
                marketParams,
                amount,
                0,
                onBehalf,
                hex""
            );
        }
    }
}
