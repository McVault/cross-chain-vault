// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/renzo/IRenzoDepositContract.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// type Id is bytes32;

contract Renzosnippets {
    IRenzoDepositContract public renzodeposit;
    address depositToken = 0x4200000000000000000000000000000000000006; //WETH

    // 0xf25484650484de3d554fb0b7125e7696efa4ab99
    constructor(address _address) {
        renzodeposit = IRenzoDepositContract(_address);
    }

    function depositOnRenzo(
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _deadline
    ) public payable returns (uint256) {
        require(
            IERC20(depositToken).transferFrom(
                msg.sender,
                address(this),
                _amountIn
            )
        );
        IERC20(depositToken).approve(address(renzodeposit), _amountIn);
        uint256 ezETHAmount = renzodeposit.deposit(
            _amountIn,
            _minOut,
            _deadline
        );

        return ezETHAmount;
    }
}
