// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IVault.sol";

contract Vault is IVault {
    function deposit(address _token, uint256 _amount) external {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(
        address _token,
        address _to,
        uint256 _amount
    ) external {
        IERC20(_token).transfer(_to, _amount);
    }

    function withdrawAll(address _token, address _to) external {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, balance);
    }

    function approve(
        address _token,
        address _spender,
        uint256 _amount
    ) external {
        IERC20(_token).approve(_spender, _amount);
    }
}
