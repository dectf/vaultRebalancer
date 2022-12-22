// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IVault {
    function deposit(address token, uint256 amount) external;

    function withdraw(
        address token,
        address to,
        uint256 amount
    ) external;

    function approve(
        address token,
        address spender,
        uint256 amount
    ) external;
}
