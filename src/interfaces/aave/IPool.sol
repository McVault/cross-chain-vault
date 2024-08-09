// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

<<<<<<< HEAD
// import "../../libraries/aave/DataTypes.sol";

// interface IPool {
//     struct ReserveData {
//         //stores the reserve configuration
//         ReserveConfigurationMap configuration;
//         //the liquidity index. Expressed in ray
//         uint128 liquidityIndex;
//         //the current supply rate. Expressed in ray
//         uint128 currentLiquidityRate;
//         //variable borrow index. Expressed in ray
//         uint128 variableBorrowIndex;
//         //the current variable borrow rate. Expressed in ray
//         uint128 currentVariableBorrowRate;
//         //the current stable borrow rate. Expressed in ray
//         uint128 currentStableBorrowRate;
//         //timestamp of last update
//         uint40 lastUpdateTimestamp;
//         //the id of the reserve. Represents the position in the list of the active reserves
//         uint16 id;
//         //aToken address
//         address aTokenAddress;
//         //stableDebtToken address
//         address stableDebtTokenAddress;
//         //variableDebtToken address
//         address variableDebtTokenAddress;
//         //address of the interest rate strategy
//         address interestRateStrategyAddress;
//         //the current treasury balance, scaled
//         uint128 accruedToTreasury;
//         //the outstanding unbacked aTokens minted through the bridging feature
//         uint128 unbacked;
//         //the outstanding debt borrowed against this asset in isolation mode
//         uint128 isolationModeTotalDebt;
//     }
=======
interface IPool {
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //aToken address
        address aTokenAddress;
        //stableDebtToken address
        address stableDebtTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
        //the outstanding unbacked aTokens minted through the bridging feature
        uint128 unbacked;
        //the outstanding debt borrowed against this asset in isolation mode
        uint128 isolationModeTotalDebt;
    }
>>>>>>> 6159e3ce31ceb26bc4b148a37d0bf5f620b6b497

//     struct ReserveConfigurationMap {
//         //bit 0-15: LTV
//         //bit 16-31: Liq. threshold
//         //bit 32-47: Liq. bonus
//         //bit 48-55: Decimals
//         //bit 56: reserve is active
//         //bit 57: reserve is frozen
//         //bit 58: borrowing is enabled
//         //bit 59: stable rate borrowing enabled
//         //bit 60: asset is paused
//         //bit 61: borrowing in isolation mode is enabled
//         //bit 62: siloed borrowing enabled
//         //bit 63: flashloaning enabled
//         //bit 64-79: reserve factor
//         //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
//         //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
//         //bit 152-167 liquidation protocol fee
//         //bit 168-175 eMode category
//         //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
//         //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
//         //bit 252-255 unused

//         uint256 data;
//     }

//     /**
//      * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
//      * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
//      * @dev Deprecated: Use the `supply` function instead
//      * @param asset The address of the underlying asset to supply
//      * @param amount The amount to be supplied
//      * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
//      *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
//      *   is a different wallet
//      * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
//      *   0 if the action is executed directly by the user, without any middle-man
//      */
//     function deposit(
//         address asset,
//         uint256 amount,
//         address onBehalfOf,
//         uint16 referralCode
//     ) external;

//     /**
//      * @notice Returns the user account data across all the reserves
//      * @param user The address of the user
//      * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
//      * @return totalDebtBase The total debt of the user in the base currency used by the price feed
//      * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
//      * @return currentLiquidationThreshold The liquidation threshold of the user
//      * @return ltv The loan to value of The user
//      * @return healthFactor The current health factor of the user
//      */
//     function getUserAccountData(
//         address user
//     )
//         external
//         view
//         returns (
//             uint256 totalCollateralBase,
//             uint256 totalDebtBase,
//             uint256 availableBorrowsBase,
//             uint256 currentLiquidationThreshold,
//             uint256 ltv,
//             uint256 healthFactor
//         );

//     /**
//      * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
//      * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
//      * @param asset The address of the underlying asset to withdraw
//      * @param amount The underlying amount to be withdrawn
//      *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
//      * @param to The address that will receive the underlying, same as msg.sender if the user
//      *   wants to receive it on his own wallet, or a different address if the beneficiary is a
//      *   different wallet
//      * @return The final amount withdrawn
//      */
//     function withdraw(
//         address asset,
//         uint256 amount,
//         address to
//     ) external returns (uint256);

//     /**
//      * @notice Returns the state and configuration of the reserve
//      * @param asset The address of the underlying asset of the reserve
//      * @return The state and configuration data of the reserve
//      */
//     function getReserveData(
//         address asset
//     ) external view returns (ReserveData memory);
// }
