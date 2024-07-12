// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockYearnV3Vault {
    event Deposit(address sender, address indexed receiver, uint256 amount);
    address public mockUSDT;

    constructor(address _mockUSDT) {
        mockUSDT = _mockUSDT;
    }

    /// @notice Deposit assets into the vault.
    /// @param assets The amount of assets to deposit.
    /// @param receiver The address to receive the shares.
    function deposit(uint256 assets, address receiver) external {
        ERC20(mockUSDT).transferFrom(msg.sender, address(this), assets);
        emit Deposit(msg.sender, receiver, assets);
    }
}
