// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IRebalancer {
    struct OneSwap {
        address pair;
        address tokenIn;
        bool zeroForOne;
        uint256 amountIn;
        uint256 amountOutMin;
    }

    function rebalance(OneSwap[] calldata swaps) external;

    function getOneSwap(
        address pair,
        address[] calldata path,
        bool zeroForOne,
        uint256 newRatio
    ) external view returns (OneSwap[] memory);
}
