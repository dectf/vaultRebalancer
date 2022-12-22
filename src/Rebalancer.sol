// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IRebalancer.sol";
import "./libraries/UniswapV2Library.sol";

contract Rebalancer is IRebalancer {
    struct ReserveInfo {
        uint112 r0; //reserve0 of v2 pool
        uint112 r1; //reserve1 of v2 pool
        uint256 v0; //token0 amount in vault
        uint256 v1; //token1 amount in vault
        uint256 multipliedRatio; //desired ratio: multiplier*v1/v0(ratioFlag=true) or multiplier*v0/v1(ratioFlag=false)
        bool ratioFlag; //determine multipliedRatio
        bool zeroForOne;
    }

    address public vault;
    uint256 internal constant multiplier = 1e6;

    constructor(address _vault) {
        vault = _vault;
    }

    //execute the action of rebalance
    function rebalance(OneSwap[] calldata _swaps) external {
        address vaultAddress = vault;
        for (uint256 i = 0; i < _swaps.length; i++) {
            OneSwap memory oneSwap = _swaps[i];
            IERC20(oneSwap.tokenIn).transferFrom(
                vaultAddress,
                oneSwap.pair,
                oneSwap.amountIn
            );

            (uint256 amount0Out, uint256 amount1Out) = oneSwap.zeroForOne
                ? (uint256(0), oneSwap.amountOutMin)
                : (oneSwap.amountOutMin, uint256(0));
            IUniswapV2Pair(oneSwap.pair).swap(
                amount0Out,
                amount1Out,
                vaultAddress,
                bytes("")
            );
        }
    }

    //note: shouldn't use this function with rebalance in the same block
    function getOneSwap(
        address pair,
        address[] calldata path, //[token0,token1]
        bool ratioFlag,
        uint256 multipliedNewRatio //been multiplied by `multiplier` to keep precision
    ) external view returns (OneSwap[] memory) {
        uint256 amountIn;
        address tokenIn;
        uint256 amountOutMin;
        ReserveInfo memory ri;
        ri.ratioFlag = ratioFlag;
        ri.multipliedRatio = multipliedNewRatio;
        {
            address vaultAddress = vault;
            ri.v0 = IERC20(path[0]).balanceOf(vaultAddress);
            ri.v1 = IERC20(path[1]).balanceOf(vaultAddress);
            (ri.r0, ri.r1, ) = IUniswapV2Pair(pair).getReserves();

            ri.zeroForOne = ratioFlag
                ? (ri.v1 * multiplier < multipliedNewRatio * ri.v0)
                : (ri.v0 * multiplier > multipliedNewRatio * ri.v1);

            amountIn = _getAmountIn(ri);
            if (ri.zeroForOne) {
                tokenIn = path[0];
                amountOutMin = UniswapV2Library.getAmountOut(
                    amountIn,
                    ri.r0,
                    ri.r1
                );
            } else {
                tokenIn = path[1];
                amountOutMin = UniswapV2Library.getAmountOut(
                    amountIn,
                    ri.r1,
                    ri.r0
                );
            }
        }

        OneSwap[] memory swaps = new OneSwap[](1);
        swaps[0] = OneSwap({
            pair: pair,
            tokenIn: tokenIn,
            zeroForOne: ri.zeroForOne,
            amountIn: amountIn,
            amountOutMin: amountOutMin
        });
        return swaps;
    }

    function _getAmountIn(ReserveInfo memory ri)
        internal
        pure
        returns (uint256)
    {
        if (ri.zeroForOne) {
            return
                ri.ratioFlag
                    ? ((ri.v0 * ri.multipliedRatio - ri.v1 * multiplier) *
                        ri.r0) /
                        (ri.r1 * multiplier + ri.multipliedRatio * ri.r0)
                    : ((ri.v0 * multiplier - ri.v1 * ri.multipliedRatio) *
                        ri.r0) /
                        (ri.r1 * ri.multipliedRatio + multiplier * ri.r0);
        }
        return
            ri.ratioFlag
                ? ((ri.v1 * multiplier - ri.v0 * ri.multipliedRatio) * ri.r1) /
                    (ri.r0 * ri.multipliedRatio + multiplier * ri.r1)
                : ((ri.v1 * ri.multipliedRatio - ri.v0 * multiplier) * ri.r1) /
                    (ri.r0 * multiplier + ri.multipliedRatio * ri.r1);
    }
}
