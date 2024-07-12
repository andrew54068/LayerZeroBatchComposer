/**
 *Submitted for verification at polygonscan.com on 2024-07-11
 */

// SPDX-License-Identifier: MIT

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

pragma solidity ^0.8.22;

contract MockUSDT is ERC20 {
    constructor() ERC20("mock-usdt", "MOCK-USDT") {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}
