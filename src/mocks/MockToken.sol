// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    uint8 internal decimal;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimal
    ) ERC20(_name, _symbol) {
        decimal = _decimal;
    }

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function decimals() public view override returns (uint8) {
        return decimal;
    }
}
