// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/morpho/IMorpho.sol";

// type Id is bytes32;

contract Vault {
    IMorphoBase public morphoLendingPool;

    // 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb
    constructor(address _address) {
        morphoLendingPool = IMorphoBase(_address);
    }

    function depositOnMorpho(
        MarketParams memory marketParams,
        uint256 assets,
        uint256 shares,
        address onBehalf,
        bytes memory data
    ) public returns (uint256 assetsSupplied, uint256 sharesSupplied) {
        IERC20(marketParams.collateralToken).approve(
            address(morphoLendingPool),
            assets
        );
        return
            morphoLendingPool.supply(
                marketParams,
                assets,
                shares,
                onBehalf,
                data
            );
    }
}
