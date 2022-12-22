// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Vault.sol";
import "../src/Rebalancer.sol";
import "../src/interfaces/IRebalancer.sol";
import "../src/mocks/MockToken.sol";
import "../src/mocks/MockV2Pair.sol";

contract RebalancerTest is Test {
    Rebalancer public rebalancer;
    Vault public vault;
    MockToken public weth;
    MockToken public usdt;
    MockV2Pair public v2Pair;
    uint256 internal constant multiplier = 1e6;
    uint8 internal constant decimal = 18;
    uint256 internal constant decimalPower = 10**decimal;

    struct Input {
        bool zeroForOne;
        uint256 ratio;
    }

    struct ExpectResult {
        address tokenIn;
        uint256 amountIn;
    }

    struct Case {
        Input input;
        ExpectResult expectResult;
        string desc;
    }

    Case[] entries;
    Case c;

    modifier parametrizedTest() {
        for (uint256 i = 0; i < entries.length; i++) {
            c = entries[i];
            _;
        }
    }

    function setUp() public {
        weth = new MockToken("weth token", "weth", 18);
        usdt = new MockToken("usdt token", "usdt", decimal);

        v2Pair = new MockV2Pair(
            address(weth),
            address(usdt),
            1000 * 1e18, //1000 weth
            uint112(10000 * decimalPower) //10000 usdt
        );
        weth.mint(address(this), 10 * 1e18);
        usdt.mint(address(this), 10000 * decimalPower);
        weth.mint(address(v2Pair), 1_000_000 * 1e18);
        usdt.mint(address(v2Pair), 1_000_000 * decimalPower);

        vault = new Vault();
        rebalancer = new Rebalancer(address(vault));

        weth.approve(address(vault), type(uint256).max);
        usdt.approve(address(vault), type(uint256).max);

        entries.push(
            Case({
                input: Input({zeroForOne: true, ratio: 5 * multiplier}),
                expectResult: ExpectResult({
                    tokenIn: address(usdt),
                    amountIn: 3333333333333333333
                }),
                desc: "initial state: v1/v0=10, desire state: v1/v0=5, action: swap 3333333333333333333 usdt to weth"
            })
        );
        entries.push(
            Case({
                input: Input({zeroForOne: true, ratio: 20 * multiplier}),
                expectResult: ExpectResult({
                    tokenIn: address(weth),
                    amountIn: 333333333333333333
                }),
                desc: "initial state: v1/v0=10, desire state: v1/v0=20, action: swap 3333333333333333333 weth to usdt"
            })
        );
        entries.push(
            Case({
                input: Input({zeroForOne: false, ratio: 2 * multiplier}),
                expectResult: ExpectResult({
                    tokenIn: address(usdt),
                    amountIn: 9047619047619047619
                }),
                desc: "initial state: v1/v0=10, desire state: v0/v1=2, action: swap 9047619047619047619 usdt to weth"
            })
        );
        entries.push(
            Case({
                input: Input({zeroForOne: false, ratio: multiplier / 20}),
                expectResult: ExpectResult({
                    tokenIn: address(weth),
                    amountIn: 333333333333333333
                }),
                desc: "initial state: v1/v0=10, desire state: v0/v1=1/20, action: swap 333333333333333333 weth to usdt"
            })
        );
    }

    function testGetOneSwap() public parametrizedTest {
        beforeEach(address(weth), address(usdt));
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(usdt);

        IRebalancer.OneSwap[] memory swaps = rebalancer.getOneSwap(
            address(v2Pair),
            path,
            c.input.zeroForOne,
            c.input.ratio
        );
        assert(swaps[0].tokenIn == c.expectResult.tokenIn);
        assert(swaps[0].amountIn == c.expectResult.amountIn);
        afterEach(address(weth), address(usdt));
    }

    function testRebalance() public parametrizedTest {
        beforeEach(address(weth), address(usdt));
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(usdt);

        uint256 vault00 = weth.balanceOf(address(vault));
        uint256 vault11 = usdt.balanceOf(address(vault));

        IRebalancer.OneSwap[] memory swaps = rebalancer.getOneSwap(
            address(v2Pair),
            path,
            c.input.zeroForOne,
            c.input.ratio
        );
        vault.approve(swaps[0].tokenIn, address(rebalancer), type(uint256).max);
        rebalancer.rebalance(swaps);

        uint256 vault0 = weth.balanceOf(address(vault));
        uint256 vault1 = usdt.balanceOf(address(vault));
        if (c.input.zeroForOne) {
            assert(roughlyEqual(vault1 * multiplier, c.input.ratio * vault0));
        } else {
            assert(roughlyEqual(vault0 * multiplier, c.input.ratio * vault1));
        }
        afterEach(address(weth), address(usdt));
    }

    function roughlyEqual(uint256 a, uint256 b) internal view returns (bool) {
        return (a > b && a - b < a / 500) || (a <= b && b - a < b / 500);
    }

    function beforeEach(address token0, address token1) internal {
        vault.deposit(token0, 1 * 1e18);
        vault.deposit(token1, 10 * decimalPower);
    }

    function afterEach(address token0, address token1) internal {
        vault.withdrawAll(token0, msg.sender);
        vault.withdrawAll(token1, msg.sender);
    }
}
