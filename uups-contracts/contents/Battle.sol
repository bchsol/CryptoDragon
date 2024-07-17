// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../Interfaces/IToken.sol";
import "../Interfaces/IQuest.sol";
import "../Interfaces/IDragonDrink.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Battle is Initializable, OwnableUpgradeable, UUPSUpgradeable{
    IToken public dragonContract;
    IQuest public questContract;
    IDragonDrink public drinkContract;

    struct Dragon {
        uint256 tokenId;
        uint256 attack;
        uint256 defense;
        uint256 health;
    }

    struct BattleRecord {
        uint256 win;
        uint256 lose;
        OpponentRecord[] opponents;
    }

    struct OpponentRecord {
        Dragon dragon;
        bool winStatus;
    }

    mapping(uint256 => Dragon) private battleDragon;
    mapping(uint256 => BattleRecord) private dragonRecords;
    mapping(address => uint256) private registeredDragons;
    mapping(address => uint256) private dailyBattleCount;
    mapping(address => uint256) private lastBattleTime;

    address[] private registeredBattlers;

    address[] private dummyAddr;
    uint256 private dummyCounter;
    
    uint256 public upgradePrice;
    uint256 public battleReward;
    uint256 public dailyBattleLimit;

    function initialize(
        address _dragonContract, 
        address _questContract, 
        address _drinkContract
    ) public initializer{
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        dragonContract = IToken(_dragonContract);
        questContract = IQuest(_questContract);
        drinkContract = IDragonDrink(_drinkContract);
        upgradePrice = 300;
        battleReward = 10;
        dailyBattleLimit = 3;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    modifier battleLimitCheck(address player) {
        require(dailyBattleCount[player] < dailyBattleLimit, "Daily battle limit reached");
        _;
    }

    modifier resetDailyBattleCount(address player) {
        if (lastBattleTime[player] < today()) {
            dailyBattleCount[player] = 0;
        }
        _;
    }

    function battle(uint256 tokenId) external resetDailyBattleCount(msg.sender) battleLimitCheck(msg.sender)  {
        require(dragonContract.ownerOf(tokenId) == msg.sender, "Not Owner");

        address opponent = findRandomOpponent(msg.sender);
        require(opponent != address(0), "No opponent found");

        dailyBattleCount[msg.sender]++;
        lastBattleTime[msg.sender] = today();
        
        bool questData = questContract.getBattleCompleted(msg.sender);
        if(!questData) {
            questContract.battleCheck(msg.sender);
        }
        
        battleProgress(msg.sender, opponent);

        winReward(msg.sender);
    }

    function battleProgress(address player, address opponent) internal {
        uint256 playerTokenId = registeredDragons[player];
        uint256 opponentTokenId = registeredDragons[opponent];

        Dragon storage myDragon = battleDragon[playerTokenId];
        Dragon storage opponentDragon = battleDragon[opponentTokenId];

        uint256 myHealth = myDragon.health;
        uint256 opponentHealth = opponentDragon.health;

        bool playerFirst = (uint256(keccak256(abi.encodePacked(block.timestamp,block.prevrandao))) % 2) == 0;
        
        for(uint256 i = 0; i < 10 && myHealth > 0 && opponentHealth > 0; i++) {
            if(playerFirst) {
                opponentHealth = applyDamage(myDragon.attack, myDragon.defense, myDragon.health);
                if(opponentHealth == 0) break;
                myHealth = applyDamage(opponentDragon.attack, opponentDragon.defense, opponentDragon.health);
            } else {
                myHealth = applyDamage(opponentDragon.attack, opponentDragon.defense, opponentDragon.health);
                if (myHealth == 0) break;
                opponentHealth = applyDamage(myDragon.attack, myDragon.defense, myDragon.health);
            }
        }

        updateBattleRecords(myHealth, playerTokenId, opponentTokenId);

    }

    function applyDamage(uint256 attack, uint256 defense, uint256 health) private pure returns(uint256) {
        uint256 damage = calculateDamage(attack, defense);
        return health > damage ? health - damage : 0;
    }

    function updateBattleRecords(uint256 myHealth, uint256 playerTokenId, uint256 opponentTokenId) private {        
        Dragon storage myDragon = battleDragon[playerTokenId];
        Dragon storage opponentDragon = battleDragon[opponentTokenId];
        
        if (myHealth == 0) {
            dragonRecords[opponentTokenId].win++;
            dragonRecords[opponentTokenId].opponents.push(OpponentRecord({
                dragon: myDragon,
                winStatus: true
            }));

            dragonRecords[playerTokenId].lose++;
            dragonRecords[playerTokenId].opponents.push(OpponentRecord({
                dragon: opponentDragon,
                winStatus: false
            }));
            
        } else {
            dragonRecords[playerTokenId].win++;
            dragonRecords[playerTokenId].opponents.push(OpponentRecord({
                dragon: opponentDragon,
                winStatus: true
            }));

            dragonRecords[opponentTokenId].lose++;
            dragonRecords[opponentTokenId].opponents.push(OpponentRecord({
                dragon: myDragon,
                winStatus: false
            }));
        }
    }

    function winReward(address player) internal {
        drinkContract.mint(player,battleReward);
    }

    function upgradeDragon(uint256 tokenId) external {
        require(dragonContract.ownerOf(tokenId) == msg.sender, "Not Owner");
        require(registeredDragons[msg.sender] == tokenId, "Dragon not registered for battle");
        require(drinkContract.balanceOf(msg.sender) >= upgradePrice, "Insufficient drinks");

        Dragon storage myDragon = battleDragon[tokenId];

        drinkContract.burn(msg.sender, upgradePrice);

        uint256 randomStat = uint256(keccak256(abi.encodePacked(block.timestamp,block.prevrandao))) % 3;

        if(randomStat == 0) {
            myDragon.attack += 10;
        } else if(randomStat == 1) {
            myDragon.defense += 10;
        }else {
            myDragon.health += 10;
        }
    }

    function calculateDamage(uint256 attack, uint256 defense) private pure returns(uint256){
        uint256 minDamagePercent = 10;
        uint256 defenseEffect = defense * 100 / (defense + 100);

        uint256 effectiveDamagePercent = defenseEffect > 90 ? minDamagePercent : 100 - defenseEffect;

        return (attack * effectiveDamagePercent) / 100;
    }

    function regiBattle(uint256 tokenId) external {
        require(dragonContract.ownerOf(tokenId) == msg.sender, "Not Owner");
        require(registeredDragons[msg.sender] == 0, "Already registered");

        (IToken.GrowthStage currentStage, ) = dragonContract.getGrowthInfo(tokenId);
        require(currentStage == IToken.GrowthStage.Adult, "token is not adult");

        if(battleDragon[tokenId].tokenId == 0){
            battleDragon[tokenId] = Dragon({
                tokenId:tokenId,
                attack:100,
                defense:100,
                health:100
            });
        }

        registeredDragons[msg.sender] = tokenId;
        registeredBattlers.push(msg.sender);
    }

    function unregiBattle(uint256 tokenId) external {
        require(dragonContract.ownerOf(tokenId) == msg.sender, "Not Owner");
        require(registeredDragons[msg.sender] == tokenId, "token is not register");

        delete registeredDragons[msg.sender];
        for(uint256 i = 0; i < registeredBattlers.length; i++) {
            if(registeredBattlers[i] == msg.sender) {
                registeredBattlers[i] = registeredBattlers[registeredBattlers.length - 1];
                registeredBattlers.pop();
                break;
            }
        }
    }

    function findRandomOpponent(address exclude) internal view returns(address) {
        uint256 registeredCount = registeredBattlers.length;
        if(registeredCount <= 1) {
            return address(0);
        }

        uint256 randomIndex;
        address opponent;

        for(uint256 i = 0; i < registeredCount; i++) {
            randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, i))) % registeredCount;
            opponent = registeredBattlers[randomIndex];

            if (opponent != exclude) {
                return opponent;
            }
        }
        return address(0);
    }

    function addDummy(uint256 count) external onlyOwner{
        for(uint256 i = 0; i < count; i++) {
            address dummyAddress = address(uint160(dummyCounter));
            dummyCounter++;
            dummyAddr.push(dummyAddress);
            registeredBattlers.push(dummyAddress);

            battleDragon[0] = Dragon({
                tokenId: 0,
                attack:100,
                defense: 100,
                health: 100
            });
        }
    }


    function deleteDummy() external onlyOwner {
        for(uint256 i = 0; i <= dummyAddr.length; i++) {
            delete battleDragon[0];
        }
        delete dummyAddr;
        dummyCounter = 0;
    }

    function getDragonStatus(uint256 tokenId) external view returns(Dragon memory) {
        return battleDragon[tokenId];
    }

    function getBattleRecord(uint256 tokenId) external view returns (uint256 win, uint256 lose, OpponentRecord[] memory opponents) {
        BattleRecord storage record = dragonRecords[tokenId];
        return (record.win, record.lose, record.opponents);
    }

    function getPlayerRecords(address player) external view onlyOwner returns(BattleRecord memory)  {
        uint256 tokenId = registeredDragons[player];
        return dragonRecords[tokenId];
    }

    function setDailyBattleLimit(uint256 limit) external onlyOwner {
        dailyBattleLimit = limit;
    }

    function today() internal view returns (uint256) {
        return block.timestamp / 1 days;
    }
}