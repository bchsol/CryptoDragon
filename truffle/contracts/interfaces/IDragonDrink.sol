// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDragonDrink {
    function mint(address to, uint256 amount) external;
    function burn(address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);

    event Mint(address indexed to, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
