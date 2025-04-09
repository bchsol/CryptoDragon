// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Interfaces/IToken.sol";
import "../Interfaces/IQuest.sol";

contract Exploration is Ownable {
    IToken public tokenContract;
    IQuest public questContract;

    struct ExplorationInfo {
        address owner;
        uint256[5] dragonIds;
        uint256 startTime;
        bool isActive;
        bool isSameType;
    }

    mapping(uint256 => ExplorationInfo) public explorations;
    mapping(uint256 => bool) public isDragonInExploration;
    uint256 public explorationCount;

    uint256 public constant EXPLORATION_DURATION = 6 hours;
    uint256 public constant BASE_SUCCESS_RATE = 40;
    uint256 public constant SAME_TYPE_BONUS = 20;
    uint256 public constant DAILY_EXPLORATION_LIMIT = 2;

    mapping(address => uint256) public dailyExplorationCount;
    mapping(address => uint256) public lastExplorationTimestamp;
    mapping(address => uint256) public additionalExplorations;

    event ExplorationStarted(uint256 indexed explorationId, address indexed owner, uint256[5] dragonIds);
    event ExplorationCompleted(uint256 indexed explorationId, address indexed owner, bool success);

    constructor(address _tokenContract, address _questContract) Ownable(msg.sender) {
        tokenContract = IToken(_tokenContract);
        questContract = IQuest(_questContract);
    }

    /**
     * @dev 새로운 탐험을 시작합니다
     * @param dragonIds 탐험에 참여할 5마리의 드래곤 ID 배열
     * @param isSameType 모든 드래곤이 같은 타입인지 여부
     */
    function startExploration(uint256[5] memory dragonIds, bool isSameType) external {
        require(hasAdultToken(msg.sender), "You must own at least five adult NFT to explore.");
        require(getRemainingDailyExplorations(msg.sender) > 0, "Daily exploration limit reached");
        
        if (block.timestamp >= lastExplorationTimestamp[msg.sender] + 1 days) {
            dailyExplorationCount[msg.sender] = 0;
            lastExplorationTimestamp[msg.sender] = block.timestamp;
        }
        
        dailyExplorationCount[msg.sender]++;
        
        for(uint i = 0; i < 5; i++) {
            require(tokenContract.ownerOf(dragonIds[i]) == msg.sender, "Not the owner of dragon");
            require(!isDragonInExploration[dragonIds[i]], "Dragon already in exploration");
            isDragonInExploration[dragonIds[i]] = true;
        }
        
        explorationCount++;
        explorations[explorationCount] = ExplorationInfo({
            owner: msg.sender,
            dragonIds: dragonIds,
            startTime: block.timestamp,
            isActive: true,
            isSameType: isSameType
        });
        
        emit ExplorationStarted(explorationCount, msg.sender, dragonIds);
    }

    /**
     * @dev 사용자가 5마리의 성체 드래곤을 소유하고 있는지 확인합니다
     */
    function hasAdultToken(address user) internal view returns(bool){
        uint256[] memory tokenIds = tokenContract.getUserNftIds(user);
        uint256 adultCount = 0;

       for (uint256 i = 0; i < tokenIds.length; i++) {
            (IToken.GrowthStage currentStage, ) = tokenContract.getGrowthInfo(tokenIds[i]);
            if (currentStage == IToken.GrowthStage.Adult) {
                adultCount++;
                if(adultCount == 5) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @dev 탐험을 완료하고 보상을 지급합니다
     * @param explorationId 완료할 탐험의 ID
     */
    function completeExploration(uint256 explorationId) external {
        ExplorationInfo storage exploration = explorations[explorationId];
        require(exploration.isActive, "Exploration not active");
        require(exploration.owner == msg.sender, "Not exploration owner");
        require(block.timestamp >= exploration.startTime + EXPLORATION_DURATION, "Exploration not finished");
        
        exploration.isActive = false;
        
        for(uint i = 0; i < 5; i++) {
            isDragonInExploration[exploration.dragonIds[i]] = false;
        }
        
        uint256 successRate = BASE_SUCCESS_RATE;
        if(exploration.isSameType) {
            successRate += SAME_TYPE_BONUS;
        }
        
        bool success = _random(explorationId) % 100 < successRate;
        
        if(success) {
            questContract.exploreCheck(msg.sender);
        }
        
        emit ExplorationCompleted(explorationId, msg.sender, success);
    }
    
    /**
     * @dev 드래곤이 현재 탐험 중인지 확인합니다
     */
    function isDragonOnExploration(uint256 dragonId) external view returns (bool) {
        return isDragonInExploration[dragonId];
    }
    
    /**
     * @dev 간단한 의사 난수 생성기
     */
    function _random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, seed)));
    }

    /**
     * @dev 사용자의 남은 일일 탐험 횟수를 반환합니다
     */
    function getRemainingDailyExplorations(address user) public view returns (uint256) {
        if (block.timestamp >= lastExplorationTimestamp[user] + 1 days) {
            return DAILY_EXPLORATION_LIMIT + additionalExplorations[user];
        }
        
        uint256 maxExplorations = DAILY_EXPLORATION_LIMIT + additionalExplorations[user];
        return dailyExplorationCount[user] >= maxExplorations ? 0 : maxExplorations - dailyExplorationCount[user];
    }

    function addExplorationCount(address user, uint256 amount) external onlyOwner {
        additionalExplorations[user] += amount;
    }
}
