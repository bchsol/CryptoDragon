// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../Interfaces/IToken.sol";
import "../Interfaces/IQuest.sol";
import "../Interfaces/IDragonDrink.sol";
import "../Interfaces/IItems.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Exploration is Initializable, OwnableUpgradeable, UUPSUpgradeable{
    IToken public tokenContract;
    IQuest public questContract;
    IDragonDrink public drinkContract;
    IItems public itemContract;

    mapping(address => uint256) private dailyExploreCount;
    mapping(address => uint256) private lastExploreTime;

    uint256 public dailyExploreLimit;
    uint256 public minAdultToken;

    function initialize(
        address _tokenContract,
        address _questContract,
        address _drinkContract
    ) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        tokenContract = IToken(_tokenContract);
        questContract = IQuest(_questContract);
        drinkContract = IDragonDrink(_drinkContract);

        dailyExploreLimit = 1;
        minAdultToken = 5;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    modifier exploreLimitCheck(address player) {
        require(dailyExploreCount[player] < dailyExploreLimit, "Daily battle limit reached");
        _;
    }

    modifier resetDailyExploreCount(address player) {
        if (lastExploreTime[player] < today()) {
            dailyExploreCount[player] = 0;
        }
        _;
    }

    function explore() external resetDailyExploreCount(msg.sender) exploreLimitCheck(msg.sender) {
        require(hasAdultToken(msg.sender), "You must own at least five adult NFT to explore.");

        lastExploreTime[msg.sender] = today();
        dailyExploreCount[msg.sender]++;

        bool questData = questContract.getBattleCompleted(msg.sender);
        if(!questData) {
            questContract.exploreCheck(msg.sender);
        }
        
        (uint256 reward, string memory item) = getRandomReward();
        if(bytes(item).length > 0) {
            itemContract.mint(msg.sender, item, 1, "");
        }
        if(reward > 0) {
            drinkContract.mint(msg.sender, reward);
        }
    }
    
    function hasAdultToken(address user) internal view returns(bool){
        uint256[] memory tokenIds = tokenContract.getUserNftIds(user);
        uint256 adultCount = 0;

       for (uint256 i = 0; i < tokenIds.length; i++) {
            (IToken.GrowthStage currentStage, ) = tokenContract.getGrowthInfo(tokenIds[i]);
            if (currentStage == IToken.GrowthStage.Adult) {
                adultCount++;
                if(adultCount >= minAdultToken) {
                    return true;
                }
            }
        }
        return false;
    }

    function getRandomReward() internal view returns(uint256, string memory) {
        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))) % 100;
        
        if(randomValue < 93) {
            return (50,"");
        } else if(randomValue < 98) {   // 5%
            return (0,"genderChange"); // gender change
        } else {    // 1%
            return (0,"growthUp"); // growthUp
        }
    }

    function setMinAdultToken(uint256 _minAdultToken) external onlyOwner {
        minAdultToken = _minAdultToken;
    }

    function setDailyExploreLimit(uint256 limit) external onlyOwner {
        dailyExploreLimit = limit;
    }

    function today() internal view returns (uint256) {
        return block.timestamp / 1 days;
    }
}