// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../src/morphoBlueSnippets.sol";
import "./interfaces/renzo/IRenzoDepositContract.sol";
import {MarketParamsLib} from "./interfaces/morpho/libraries/MarketParamsLib.sol";
import "./interfaces/uniswap/ISwapRouter.sol";

contract McVault is ERC4626, Ownable {
    using MarketParamsLib for MarketParams;
    using Math for uint256;

    ISwapRouter public swapRouter;
    IRenzoDepositContract public renzo; // renzo WETH to EzETH
    MorphoBlueSnippets public morphoBlue; // morpho market EzETH to USDC
    IERC20 public underlyingAsset; // WETH
    IERC20 public ezETH; // ezETH
    MarketParams public marketParams; // params for morpho market of EzETH and USDC
    uint256 public constant WITHDRAWAL_LOCK_PERIOD = 30 days;
    mapping(address => uint256) public lastDepositTimestamp;

    event Borrowed(uint256 assetsBorrowed, uint256 sharesBorrowed);
    event Repaid(uint256 assetsRepaid, uint256 sharesRepaid);
    event CollateralWithdrawn(uint256 collateralWithdrawn);
    event Swapped(uint256 ezETHAmount, uint256 wethReceived);

    constructor(
        address _morphoBlue,
        address _swapRouter,
        address _renzo,
        IERC20 _asset,
        IERC20 _ezETH
    ) ERC4626(_asset) ERC20("Mc Vault", "MCV") Ownable(msg.sender) {
        underlyingAsset = IERC20(_asset);
        morphoBlue = MorphoBlueSnippets(_morphoBlue);
        renzo = IRenzoDepositContract(_renzo);
        swapRouter = ISwapRouter(_swapRouter);
        ezETH = _ezETH;

        //Morpho
        marketParams.loanToken = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // USDC
        marketParams
            .collateralToken = 0x2416092f143378750bb29b79eD961ab195CcEea5; // ezETH
        marketParams.oracle = 0x1BAaB21821c6468f8aee73ee60Fd8Fdc39c0C973;
        marketParams.irm = 0x46415998764C29aB2a25CbeA6254146D50D22687;
        marketParams.lltv = 770000000000000000; // 0.77 in 18 decimal format
    }

    modifier nonZero(uint256 _value) {
        require(_value != 0, "Value must be greater than zero");
        _;
    }

    modifier canWithdraw() {
        require(
            block.timestamp >=
                lastDepositTimestamp[msg.sender] + WITHDRAWAL_LOCK_PERIOD,
            "Withdrawal locked for 30 days after deposit"
        );
        _;
    }

    function depositOnRenzo(
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _deadline
    ) public returns (uint256) {
        underlyingAsset.approve(address(renzo), _amountIn);
        return renzo.deposit(_amountIn, _minOut, _deadline);
    }

    function depositOnMorpho(
        uint256 assets
    ) public returns (uint256 assetsSupplied, uint256 sharesSupplied) {
        IERC20(marketParams.collateralToken).approve(
            address(morphoBlue),
            assets
        );
        uint256 collateralSupplied = morphoBlue.supplyCollateral(
            marketParams,
            assets
        );

        morphoBlue.setAuthorization(true);

        uint256 maxBorrow = (collateralSupplied * marketParams.lltv) / 1e18;
        (uint256 assetsBorrowed, uint256 sharesBorrowed) = morphoBlue.borrow(
            marketParams,
            maxBorrow
        );

        emit Borrowed(assetsBorrowed, sharesBorrowed);
        return (collateralSupplied, sharesBorrowed);
    }

    function deposit(
        uint256 assets,
        address receiver
    ) public virtual override nonZero(assets) returns (uint256) {
        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        afterDeposit(assets, receiver);

        return shares;
    }

    function afterDeposit(uint256 assets, address receiver) internal {
        uint256 ezETHAmount = depositOnRenzo(assets, assets, block.timestamp);
        require(ezETHAmount > 0, "EzETH should be greater than zero");
        depositOnMorpho(ezETHAmount);
        lastDepositTimestamp[receiver] = block.timestamp;
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override canWithdraw returns (uint256) {
        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }

        // Calculate the proportion of total assets to withdraw
        uint256 totalAssets = totalAssets();
        uint256 proportion = (assets * 1e18) / totalAssets;

        // Withdraw assets from Morpho and Renzo
        uint256 withdrawnWETH = beforeWithdraw(proportion);

        // Calculate shares based on the actually withdrawn WETH
        uint256 shares = previewWithdraw(withdrawnWETH);

        _withdraw(_msgSender(), receiver, owner, withdrawnWETH, shares);

        return shares;
    }

    function beforeWithdraw(uint256 proportion) internal returns (uint256) {
        // Get current borrowed amount and collateral
        (uint256 borrowedAmount, ) = morphoBlue.borrowedAmount(
            marketParams,
            address(this)
        );
        (uint256 collateralAmount, ) = morphoBlue.collateralBalance(
            marketParams,
            address(this)
        );

        // Calculate amounts to repay and withdraw
        uint256 amountToRepay = (borrowedAmount * proportion) / 1e18;
        uint256 collateralToWithdraw = (collateralAmount * proportion) / 1e18;

        // Repay borrowed amount
        IERC20(marketParams.loanToken).approve(
            address(morphoBlue),
            amountToRepay
        );
        (uint256 assetsRepaid, uint256 sharesRepaid) = morphoBlue.repay(
            marketParams,
            amountToRepay
        );
        emit Repaid(assetsRepaid, sharesRepaid);

        // Withdraw collateral
        uint256 collateralWithdrawn = morphoBlue.withdrawCollateral(
            marketParams,
            collateralToWithdraw
        );
        emit CollateralWithdrawn(collateralWithdrawn);

        // Exchange EzETH back to WETH through Renzo
        uint256 wethAmount = swapEzETHForWETH(collateralWithdrawn);
        require(wethAmount > 0, "WETH amount should be greater than zero");

        return wethAmount;
    }

    function swapEzETHForWETH(uint256 ezETHAmount) internal returns (uint256) {
        ezETH.approve(address(swapRouter), ezETHAmount);

        // Set up the parameters for the swap
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(ezETH),
                tokenOut: address(underlyingAsset),
                fee: 3000, // 0.3% fee tier
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: ezETHAmount,
                amountOutMinimum: 0, // Be careful with this in production!
                sqrtPriceLimitX96: 0
            });

        // Execute the swap
        uint256 amountOut = swapRouter.exactInputSingle(params);
        emit Swapped(ezETHAmount, amountOut);

        return amountOut;
    }
}
