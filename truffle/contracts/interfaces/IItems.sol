// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IItems{
    function mint(address account, string calldata name, uint256 amount, bytes memory data) external;
    function mintBatch(address to, string[] memory names, uint256[] memory amounts, bytes memory data) external;
}