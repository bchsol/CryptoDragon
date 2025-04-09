// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TokenBase.sol";

contract Breeding is TokenBase {

    struct Breed {
        uint256 releaseTime;  // 다음 번식이 가능한 시간
        uint256 count;        // 총 번식 횟수
    }

    mapping(uint256 => Breed) private breedData;

    event TokenBreed(uint256 indexed husbandId, uint256 indexed wifeId, uint256 indexed childId);

    constructor(address initialOwner, address trustedForwarder, string memory name, string memory symbol) TokenBase(initialOwner,trustedForwarder, name,symbol){}

    /// @notice 두 토큰을 번식시켜 새로운 토큰을 생성
    /// @return 새로 생성된 자식 토큰 ID
    function breedTokens(uint256 husbandId, uint256 wifeId) external returns(uint256) {
        require(_validateBreeding(husbandId, wifeId), "Breeding conditions not met");
        
        _updateBreedData(husbandId);
        _updateBreedData(wifeId);
        
        Token storage husband = tokens[husbandId];
        Token storage wife = tokens[wifeId];
        string memory tokenType = _determineChildTokenType(husband, wife);
        uint256 tokenId = _createChildToken(tokenType, husbandId, wifeId,husband.generation, wife.generation);

        emit TokenBreed(husbandId, wifeId, tokenId);
        return tokenId;
    }

    function _validateBreeding(uint256 husbandId, uint256 wifeId) private view returns (bool) {
        return ownerOf(husbandId) == _msgSender() && 
           ownerOf(wifeId) == _msgSender() &&
           !_isIncest(tokens[husbandId], tokens[wifeId]) &&
           _canBreed(husbandId) && 
           _canBreed(wifeId) &&
           tokens[husbandId].gender != tokens[wifeId].gender;
    }
    
    /// @notice 자식 토큰의 타입을 결정하는 내부 함수
    function _determineChildTokenType(Token storage husband, Token storage wife) 
        private 
        view 
        returns(string memory) 
    {
        bytes32 husbandType = keccak256(abi.encodePacked(husband.tokenType));
        bytes32 wifeType = keccak256(abi.encodePacked(wife.tokenType));
        
        if (husbandType == wifeType) {
            return husband.tokenType;
        }

        uint256 rand = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            _msgSender()
        )));
        
        return (rand % 2 == 0) ? husband.tokenType : wife.tokenType;
    }

    /// @notice 근친 여부를 확인하는 내부 함수
    function _isIncest(Token storage husband, Token storage wife) 
        private 
        view 
        returns(bool)
    {
        if (husband.generation == 1 || wife.generation == 1) return false;
        return husband.husbandId == wife.husbandId || husband.wifeId == wife.wifeId;
    }

    /// @notice 번식 가능 여부를 확인하는 내부 함수
    function _canBreed(uint256 tokenId) private view returns(bool) {
        return breedData[tokenId].releaseTime < block.timestamp;
    }

    /// @notice 번식 데이터를 업데이트하는 내부 함수
    function _updateBreedData(uint256 tokenId) private {
        Breed storage breed = breedData[tokenId];
        breed.count++;
        breed.releaseTime = block.timestamp + 3 days;
    }

    /// @notice 자식 토큰을 생성하는 내부 함수
    function _createChildToken(
        string memory tokenType, 
        uint256 husbandId,
        uint256 wifeId,
        uint16 husbandGen,
        uint16 wifeGen
    ) private returns(uint256) {
        uint16 parentGen = husbandGen > wifeGen ? 
            husbandGen : wifeGen;
            
        return mintToken(
            tokenType,
            husbandId,
            wifeId,
            parentGen + 1,
            _msgSender(),
            false,
            ""
        );
    }

    /// @notice 토큰의 번식 데이터를 조회하는 외부 함수
    function getBreedData(uint256 tokenId) 
        external 
        view 
        returns(uint256 releaseTime, uint256 count) 
    {
        Breed memory breed = breedData[tokenId];
        return (breed.releaseTime, breed.count);
    }
}