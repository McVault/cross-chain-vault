// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
// openZeppelin
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// CCIP
import {BaseToOptimism} from "../src/ccip/baseToOptimism.sol";

// RENZO
import "./interfaces/renzo/IRenzoDepositContract.sol";

// UNISWAP
import "./interfaces/uniswap/ISwapRouter.sol";

// MORPHO
import "../src/interfaces/morpho/IMorpho.sol";
import {MarketParamsLib} from "./interfaces/morpho/libraries/MarketParamsLib.sol";
import {SharesMathLib} from "../src/interfaces/morpho/libraries/SharesMathLib.sol";
import {MorphoLib} from "../src/interfaces/morpho/libraries/periphery/MorphoLib.sol";
import {MorphoBalancesLib} from "../src/interfaces/morpho/libraries/periphery/MorphoBalancesLib.sol";
import {IOracle} from "../src/interfaces/morpho/IOracle.sol";

contract McVault is ERC4626, Ownable {
    using Math for uint256;
    using MorphoLib for IMorpho;
    using MorphoBalancesLib for IMorpho;
    using MarketParamsLib for MarketParams;
    using SharesMathLib for uint256;

    ISwapRouter public swapRouter;
    IRenzoDepositContract public renzo; // renzo WETH to EzETH
    BaseToOptimism public baseToOptimism; // CCIP send USDC from Base to OP
    address public USDC; // USDC
    IERC20 public ezETH; // ezETH
    IERC20 public underlyingAsset; // WETH
    IMorpho public immutable morpho;

    MarketParams public marketParams; // params for morpho market of EzETH and USDC
    uint256 public constant WITHDRAWAL_LOCK_PERIOD = 30 days;
    mapping(address => uint256) public lastDepositTimestamp;

    event Borrowed(uint256 assetsBorrowed, uint256 sharesBorrowed);
    event Repaid(uint256 assetsRepaid, uint256 sharesRepaid);
    event CollateralWithdrawn(uint256 collateralWithdrawn);
    event Swapped(uint256 ezETHAmount, uint256 wethReceived);
    event balanceOFWETH(uint256);

    constructor(
        address _morphoBlue,
        address _swapRouter,
        address _renzo,
        address _baseToOptimism,
        IERC20 _asset,
        IERC20 _ezETH,
        address _USDC
    ) ERC4626(_asset) ERC20("Mc Vault", "MCV") Ownable(msg.sender) {
        underlyingAsset = IERC20(_asset);
        // morphoBlue = MorphoBlueSnippets(_morphoBlue);
        morpho = IMorpho(_morphoBlue);
        renzo = IRenzoDepositContract(_renzo);
        baseToOptimism = BaseToOptimism(payable(_baseToOptimism));
        swapRouter = ISwapRouter(_swapRouter);
        ezETH = _ezETH;
        USDC = _USDC;

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

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override canWithdraw returns (uint256) {
        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override canWithdraw returns (uint256) {
        uint256 maxShares = maxRedeem(owner);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(owner, shares, maxShares);
        }

        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    function depositOnRenzo(
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _deadline
    ) public onlyOwner returns (uint256) {
        underlyingAsset.approve(address(renzo), _amountIn);
        return renzo.deposit(_amountIn, _minOut, _deadline);
    }

    function depositOnMorpho(
        uint256 assets,
        uint256 _morphoUsdcBorrowPercentage
    ) public returns (uint256, uint256) {
        ezETH.approve(address(morpho), assets);
        morpho.supplyCollateral(marketParams, assets, address(this), hex"");
        Position memory pos = morpho.position(marketParams.id(), address(this));

        // set authorization
        morpho.setAuthorization(address(this), true);

        // has to be calcualted
        // uint256 amountToBorrow;
        // Id marketParamsId = MarketParamsLib.id(marketParams);
        uint256 collateralPrice = IOracle(marketParams.oracle).price();

        // Position memory pos = morpho.position(marketParamsId, address(this)); // Fetch the position details

        uint256 maxBorrow = uint256(pos.collateral)
            .mulDiv(collateralPrice, 1e36)
            .mulDiv(marketParams.lltv, 1e18);

        maxBorrow = maxBorrow.mulDiv(_morphoUsdcBorrowPercentage, 100); // 60 percent of the maxBorrow (60% of 77% borrow limit)

        (uint256 assetsBorrowed, uint256 sharesBorrowed) = morpho.borrow(
            marketParams,
            maxBorrow,
            0,
            address(this),
            address(this)
        );

        emit Borrowed(assetsBorrowed, sharesBorrowed);
        return (assetsBorrowed, sharesBorrowed);
    }

    function afterDeposit(
        uint256 assets,
        uint256 _morphoUsdcBorrowPercentage,
        uint256 _minAmount
    ) external onlyOwner {
        uint256 ezETHAmount = depositOnRenzo(
            assets,
            _minAmount,
            block.timestamp
        );
        require(ezETHAmount > 0, "EzETH should be greater than zero");
        (uint256 assetsBorrowed, uint256 sharesBorrowed) = depositOnMorpho(
            ezETHAmount,
            _morphoUsdcBorrowPercentage
        );
        require(assetsBorrowed > 0 && sharesBorrowed > 0, "USDC Not Borrowed");
    }

    function bridgeUsdcFromBaseToOP(
        uint64 _destinationChainSelector,
        address _receiver,
        address ezEth_SiloMarket,
        address _token
    ) external payable onlyOwner {
        uint256 amountToBridge = IERC20(USDC).balanceOf(address(this)); //USDC

        IERC20(USDC).approve(address(baseToOptimism), amountToBridge); //approve USDC to baseOptimism Contract

        baseToOptimism.sendMessagePayNative{value: msg.value}(
            _destinationChainSelector,
            _receiver,
            ezEth_SiloMarket,
            _token,
            amountToBridge
        );
    }

    function beforeWithdraw(
        uint256 _shares,
        uint256 _amount,
        uint256 _withdrawAmount
    ) external onlyOwner returns (uint256) {
        // uint256 amount;
        address onBehalf = address(this);

        IERC20(marketParams.loanToken).approve(
            address(morpho),
            type(uint256).max
        );

        (uint256 assets, uint256 shares) = morpho.repay(
            marketParams,
            _amount,
            _shares,
            onBehalf,
            hex""
        );

        morpho.withdrawCollateral(
            marketParams,
            _withdrawAmount,
            onBehalf,
            address(this)
        );

        uint EzETHAmount = ezETH.balanceOf(address(this));

        return EzETHAmount;
    }

    function swapEzETHForWETH(
        uint256 ezETHAmount,
        uint256 amountOutMinimum,
        uint24 _feetier
    ) external onlyOwner returns (uint256) {
        ezETH.approve(address(swapRouter), ezETHAmount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(ezETH),
                tokenOut: address(underlyingAsset),
                fee: _feetier,
                recipient: address(this),
                amountIn: ezETHAmount,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        // Execute the swap
        uint256 amountOut = swapRouter.exactInputSingle(params);
        emit Swapped(ezETHAmount, amountOut);

        return amountOut;
    }

    function swapRewardsToWETH(
        address _opTokens,
        uint256 amountOutMinimum,
        uint24 _feetier
    ) external onlyOwner returns (uint256) {
        uint256 amountIn = IERC20(_opTokens).balanceOf(address(this));
        IERC20(_opTokens).approve(address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: _opTokens,
                tokenOut: address(underlyingAsset),
                fee: _feetier,
                recipient: address(this),
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        uint256 amountOut = swapRouter.exactInputSingle(params);
        emit Swapped(amountIn, amountOut);

        return amountOut;
    }

    function withdrawOpRewards(
        address target,
        bytes memory data
    ) public onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = target.call(data);
        require(success, "Function call failed");
        return result;
    }

    function emergencyWithdrawl(
        address _token,
        uint256 _amount,
        address _recipient
    ) public onlyOwner returns (bytes memory) {
        IERC20(_token).transfer(_recipient, _amount);
    }
}
