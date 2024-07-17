// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenTypeManager is Ownable {
    string[] private allowedTokenTypes;

    event TokenTypeAdded(string tokenType);
    event TokenTypeRemoved(string tokenType);

    constructor() Ownable(msg.sender){
    }

    function addTokenType(string calldata _tokenType) external onlyOwner {
        allowedTokenTypes.push(_tokenType);
        emit TokenTypeAdded(_tokenType);
    }

    function removeTokenType(string calldata _tokenType) external onlyOwner {
        for (uint i = 0; i < allowedTokenTypes.length; i++) {
            if (keccak256(abi.encodePacked(allowedTokenTypes[i])) == keccak256(abi.encodePacked(_tokenType))) {
                allowedTokenTypes[i] = allowedTokenTypes[allowedTokenTypes.length - 1];
                allowedTokenTypes.pop();
                emit TokenTypeRemoved(_tokenType);
                break;
            }
        }
    }

    function isAllowedTokenType(string calldata _tokenType) external view returns (bool) {
        for (uint i = 0; i < allowedTokenTypes.length; i++) {
            if (keccak256(abi.encodePacked(allowedTokenTypes[i])) == keccak256(abi.encodePacked(_tokenType))) {
                return true;
            }
        }
        return false;
    }

    function getAllowedTokenTypes() external view returns (string[] memory) {
        return allowedTokenTypes;
    }
}