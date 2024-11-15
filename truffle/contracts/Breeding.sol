// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TokenBase.sol";

contract Breeding is TokenBase{

    struct Breed {
        uint256 releaseTime;
        uint256 count;
    }

    mapping(uint256 => Breed) private breedData;

    event TokenBreed(uint256 indexed husbandId, uint256 indexed wifeId, uint256 indexed childId);

    constructor(address initialOwner, string memory name, string memory symbol) TokenBase(initialOwner,name,symbol) {}

    function breed(uint256 husbandId, uint256 wifeId) external returns(uint256){
        require(ownerOf(husbandId) == msg.sender && ownerOf(wifeId) == msg.sender, "Not owner");
        require(!_isIncest(husbandId,wifeId), "Incest");
        require(_canBreed(husbandId) && _canBreed(wifeId), "Breeding not allowed yet");
        require(_areDifferentGenders(husbandId,wifeId), "Same gender");

        _updateBreedData(husbandId);
        _updateBreedData(wifeId);

        string memory tokenType = _determineChildTokenType(husbandId, wifeId);

        uint256 tokenId = _createChildToken(tokenType, husbandId, wifeId);

        emit TokenBreed(husbandId, wifeId, tokenId);

        return tokenId;
    }

    function _determineChildTokenType(uint256 husbandId, uint256 wifeId) internal view returns(string memory) {
        Token storage husband = tokens[husbandId];
        Token storage wife = tokens[wifeId];

        if (keccak256(abi.encodePacked(husband.tokenType)) == keccak256(abi.encodePacked(wife.tokenType))) {
            return husband.tokenType;
        } else {
            return (uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % 2 == 0)
                ? husband.tokenType
                : wife.tokenType;
        }
    }

    function _isIncest(uint256 husbandId, uint256 wifeId) internal view returns(bool){
        Token storage husband = tokens[husbandId];
        Token storage wife = tokens[wifeId];
        
        return (husband.generation == 1 || wife.generation == 1) ? false : (husband.husbandId == wife.husbandId || husband.wifeId == wife.wifeId);
    }

    function _areDifferentGenders(uint256 husbandId, uint256 wifeId) internal view returns(bool) {
        Token storage husband = tokens[husbandId];
        Token storage wife = tokens[wifeId];
        return husband.gender != wife.gender;
    }

    function _canBreed(uint256 tokenId) internal view returns(bool) {
        return breedData[tokenId].releaseTime < block.timestamp;
    }

    function _updateBreedData(uint256 tokenId) internal {
        breedData[tokenId].count++;
        breedData[tokenId].releaseTime = block.timestamp + 3 days;
    }

    function _createChildToken(string memory tokenType, uint256 husbandId, uint256 wifeId) internal returns(uint256){
         Token storage husband = tokens[husbandId];
         Token storage wife = tokens[wifeId];

         uint256 parentGen = (husband.generation > wife.generation) ? husband.generation : wife.generation;
         uint256 tokenId = mintToken(tokenType, husbandId, wifeId, parentGen + 1, msg.sender, false, "");

         return tokenId;
    }

    function getbreedData(uint256 tokenId) external view returns(uint256 releaseTime, uint256 count) {
        releaseTime = breedData[tokenId].releaseTime;
        count = breedData[tokenId].count;
    }
}