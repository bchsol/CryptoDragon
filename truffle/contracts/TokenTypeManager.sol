// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenTypeManager is Ownable {
    enum Element {Fire, Water, Wind, Earth, Steel, Light, Dark}

    string[] private normalTokenTypes;
    string[] private premiumTokenTypes;
    
    mapping(string => Element) normalTokenElement;
    mapping(string => Element) premiumTokenElement;

    event NormalTokenTypeAdded(string tokenType);
    event PremiumTokenTypeAdded(string tokenType);
    event NormalTokenTypeRemoved(string tokenType);
    event PremiumTokenTypeRemoved(string tokenType);

    constructor() Ownable(msg.sender){
    }

    /// @notice Element enum을 string으로 변환하는 내부 함수
    /// @param _element 변환할 Element enum 값
    /// @return 해당하는 element의 string 표현
    function _elementToString(Element _element) internal pure returns (string memory) {
        if(_element == Element.Fire) return "Fire";
        if(_element == Element.Water) return "Water";
        if(_element == Element.Wind) return "Wind";
        if(_element == Element.Earth) return "Earth";
        if(_element == Element.Steel) return "Steel";
        if(_element == Element.Light) return "Light";
        if(_element == Element.Dark) return "Dark";
        revert("Invalid element");
    }

    /// @notice 일반 토큰 타입을 추가하는 함수
    /// @param _tokenType 추가할 토큰 타입 이름
    /// @param element 토큰의 속성
    function addNormalTokenType(string calldata _tokenType, Element element) external onlyOwner {
        require(bytes(_tokenType).length > 0, "Token type cannot be empty");
        require(!_isAllowedTokenType(_tokenType, normalTokenTypes), "Token type already exists");
        normalTokenTypes.push(_tokenType);
        normalTokenElement[_tokenType] = element;
        emit NormalTokenTypeAdded(_tokenType);
    }

    function addPremiumTokenType(string calldata _tokenType, Element element) external onlyOwner {
        premiumTokenTypes.push(_tokenType);
        premiumTokenElement[_tokenType] = element;
        emit PremiumTokenTypeAdded(_tokenType);
    }

     function removeNormalTokenType(string calldata _tokenType) external onlyOwner {
        _removeTokenType(_tokenType, normalTokenTypes);
        emit NormalTokenTypeRemoved(_tokenType);
    }

    function removePremiumTokenType(string calldata _tokenType) external onlyOwner {
        _removeTokenType(_tokenType, premiumTokenTypes);
        emit PremiumTokenTypeRemoved(_tokenType);
    }

    /// @notice 토큰 타입 배열에서 특정 토큰을 제거하는 내부 함수
    /// @param _tokenType 제거할 토큰 타입
    /// @param tokenArray 대상 토큰 배열
    function _removeTokenType(string calldata _tokenType, string[] storage tokenArray) internal {
        uint256 length = tokenArray.length;
        for (uint i = 0; i < length; i++) {
            if (keccak256(bytes(tokenArray[i])) == keccak256(bytes(_tokenType))) {
                tokenArray[i] = tokenArray[length - 1];
                tokenArray.pop();
                break;
            }
        }
    }

    function isAllowedNormalTokenType(string calldata _tokenType) external view returns (bool) {
        return _isAllowedTokenType(_tokenType, normalTokenTypes);
    }

    function isAllowedPremiumTokenType(string calldata _tokenType) external view returns (bool) {
        return _isAllowedTokenType(_tokenType, premiumTokenTypes);
    }

    function _isAllowedTokenType(string calldata _tokenType, string[] storage tokenArray) internal view returns (bool) {
        for (uint i = 0; i < tokenArray.length; i++) {
            if (keccak256(abi.encodePacked(tokenArray[i])) == keccak256(abi.encodePacked(_tokenType))) {
                return true;
            }
        }
        return false;
    }

    /// @notice 토큰의 속성을 반환하는 함수
    /// @param _tokenType 조회할 토큰 타입
    /// @return 토큰의 속성을 string으로 반환
    function getTokenElement(string calldata _tokenType) external view returns(string memory) {
        Element element = normalTokenElement[_tokenType];
        require(uint(element) <= uint(Element.Dark), "Invalid element");
        return _elementToString(element);
    }

    function getNormalTokenTypes() external view returns (string[] memory) {
        return normalTokenTypes;
    }

    function getPremiumTokenTypes() external view returns (string[] memory) {
        return premiumTokenTypes;
    }

     /// @notice 랜덤한 일반 토큰 타입을 반환하는 함수
     /// @return 무작위로 선택된 토큰 타입
    function getRandomNormalTokenType() external view returns (string memory) {
        return _getRandomTokenType(normalTokenTypes);
    }

    function getRandomPremiumTokenType() external view returns (string memory) {
        return _getRandomTokenType(premiumTokenTypes);
    }

    /// @notice 내부 랜덤 토큰 선택 함수
    /// @param tokenArray 대상 토큰 배열
    /// @return 무작위로 선택된 토큰 타입
    function _getRandomTokenType(string[] storage tokenArray) internal view returns (string memory) {
        require(tokenArray.length > 0, "No token types available");

        uint256 randomIndex = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    msg.sender,
                    tokenArray.length
                )
            )
        ) % tokenArray.length;
        return tokenArray[randomIndex];
    }
}