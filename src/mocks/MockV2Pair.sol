// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

contract MockV2Pair {
    address public token0;
    address public token1;

    uint112 public r0;
    uint112 public r1;

    constructor(
        address _token0,
        address _token1,
        uint112 _r0,
        uint112 _r1
    ) {
        token0 = _token0;
        token1 = _token1;
        r0 = _r0;
        r1 = _r1;
    }

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata
    ) external {
        IERC20(token0).transfer(to, amount0Out);
        IERC20(token1).transfer(to, amount1Out);
    }

    function getReserves()
        external
        view
        returns (
            uint112,
            uint112,
            uint32
        )
    {
        return (r0, r1, 0);
    }
}
