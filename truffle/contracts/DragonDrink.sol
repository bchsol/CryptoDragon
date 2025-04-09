// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DragonDrink is ERC20, Ownable {
    mapping(address => bool) private allowedAddresses;
    uint256 private constant DECIMAL_MULTIPLIER = 10**18;

    event MintTokens(address indexed to, uint256 amount);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) {}

    /// @notice 허가된 주소 설정 (관리자 전용)
    function setAllowedAddress(address addr, bool allowed) external onlyOwner {
        require(addr != address(0), "Invalid address");
        allowedAddresses[addr] = allowed;
    }

    /// @notice 주소의 허가 여부 확인
    function isAllowedAddress(address addr) public view returns(bool) {
        return allowedAddresses[addr];
    }

    /// @notice 토큰 발행 (허가된 주소만 가능)
    function mint(address to, uint256 amount) external {
        require(isAllowedAddress(msg.sender), "Caller not authorized");
        require(to != address(0), "Invalid recipient");
        _mint(to, amount * DECIMAL_MULTIPLIER);
        emit MintTokens(to, amount);
    }

    /// @notice 관리자 전용 토큰 발행
    function adminMint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid recipient");
        _mint(to, amount * DECIMAL_MULTIPLIER);
        emit MintTokens(to, amount);
    }

    /// @notice 토큰 소각 (허가된 주소만 가능)
    function burn(address from, uint256 amount) external {
        require(isAllowedAddress(msg.sender), "Caller not authorized");
        require(from != address(0), "Invalid address");
        _burn(from, amount * DECIMAL_MULTIPLIER);
    }

    /// @notice 토큰 전송
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(isAllowedAddress(msg.sender), "Recipient not authorized");
        return super.transfer(recipient, amount);
    }

    /// @notice 승인된 토큰 전송
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(isAllowedAddress(msg.sender), "Recipient not authorized");
        return super.transferFrom(sender, recipient, amount);
    }
}