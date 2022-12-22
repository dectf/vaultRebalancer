// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";
import "../src/Rebalancer.sol";
import "../src/Rebalancer.sol";
import "../src/mocks/MockToken.sol";

contract VaultTest is Test {
    Rebalancer public rebalancer;
    Vault public vault;
    MockToken public weth;
    MockToken public usdt;
    MockToken public dai;

    function setUp() public {
        weth = new MockToken("weth token", "weth", 18);
        weth.mint(address(this), 10 * 1e18);

        vault = new Vault();
    }

    function testWithdraw() public {
        weth.approve(address(vault), type(uint256).max);
        vault.deposit(address(weth), 10000);

        vault.withdraw(address(weth), address(this), 10000);
        assertEq(weth.balanceOf(address(this)), 10 * 1e18);
    }
}
