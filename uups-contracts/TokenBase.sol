// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./TokenTypeManager.sol";

contract TokenBase is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable, OwnableUpgradeable, UUPSUpgradeable  {
    enum GrowthStage{Egg, Hatch, Hatchling, Adult}
    
    struct Token {
        string tokenType;
        uint256 gender; // 1: male 2: female
        uint256 husbandId;
        uint256 wifeId;
        uint256 generation;
        bool isPremium;
        uint256 birth;
    }

    struct GrowthTime {
        uint256 hatch;
        uint256 hatchling;
        uint256 adult;
    }

    mapping(uint256 => Token) internal tokens;
    mapping(uint256=>GrowthStage) private growthStages;
    mapping(uint256 => GrowthTime) internal growthTime;
    mapping(address => uint256[]) internal userTokens;

    uint256 internal newTokenId;
    uint256 private randNonce;

    string public baseTokenURI;
    string public dataURI;
    string public metaDescription;
    string private imageExtension;

    TokenTypeManager private tokenTypeManager;

    event TokenMinted(address indexed owner, uint256 indexed tokenId);
    event TokenEvolved(uint256 indexed tokenId, string newStage);
    event TokenFeed(uint256 indexed tokenId, uint256 indexed newTime);

    function initialize(
        address initialOwner, 
        address _tokenTypeManager, 
        string memory name, 
        string memory symbol
    ) initializer public {
        __ERC721_init(name, symbol);
        __ERC721URIStorage_init();
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        transferOwnership(initialOwner);

        randNonce = 0;
        newTokenId = 0;
        tokenTypeManager = TokenTypeManager(_tokenTypeManager);
    }

     function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function evolve(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        GrowthStage currentStage = growthStages[tokenId];
        uint256 currentTime = block.timestamp;

        if(currentStage == GrowthStage.Egg && currentTime >= growthTime[tokenId].hatch) {
            _evolveStage(tokenId, GrowthStage.Hatch, currentTime + 2 days, "Hatch");
        } else if(currentStage == GrowthStage.Hatch && currentTime >= growthTime[tokenId].hatchling) {
            _evolveStage(tokenId, GrowthStage.Hatchling, currentTime + 3 days, "Hatchling");
        } else if(currentStage == GrowthStage.Hatchling && currentTime >= growthTime[tokenId].adult) {
            _evolveStage(tokenId, GrowthStage.Adult, 0, "Adult");
        } else {
            revert( "Unable to evolve");
        }
    }

    function _evolveStage(
        uint256 tokenId,
        GrowthStage newStage,
        uint256 newGrowthTime,
        string memory stageName
    ) internal {
        growthStages[tokenId] = newStage;
        if(newStage == GrowthStage.Hatch) {
            tokens[tokenId].gender = getRandomGender();
            growthTime[tokenId].hatchling = newGrowthTime;
        } else if(newStage == GrowthStage.Hatchling){
            growthTime[tokenId].adult = newGrowthTime;
        } 
        emit TokenEvolved(tokenId, stageName);
    }
    
    
    function feeding(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        GrowthStage currentStage = growthStages[tokenId];
        GrowthTime storage time = growthTime[tokenId];
        uint256 currentTime = block.timestamp;

        if (currentStage == GrowthStage.Egg) {
            time.hatch = reduceTimeIfPossible(currentTime, time.hatch, 3 hours);
        } else if (currentStage == GrowthStage.Hatch) {
            time.hatchling = reduceTimeIfPossible(currentTime, time.hatchling, 3 hours);
        } else if (currentStage == GrowthStage.Hatchling) {
            time.adult = reduceTimeIfPossible(currentTime, time.adult, 3 hours);
        } else {
            revert("Invalid growth stage");
        }
        emit TokenFeed(tokenId, currentTime);
    }

    function reduceTimeIfPossible(
        uint256 currentTime,
        uint256 growthEndTime, 
        uint256 reduction
    ) internal pure returns(uint256){
        return (growthEndTime > currentTime + reduction) ? (growthEndTime - reduction) : currentTime;
    }

    function getGrowthInfo(uint256 tokenId) external view returns(GrowthStage currentStage, uint256 timeRemaining) {
        currentStage = growthStages[tokenId];
        uint256 currentTime = block.timestamp;
        uint256 endTime;

        if(currentStage == GrowthStage.Egg) {
            endTime = growthTime[tokenId].hatch;
        } else if(currentStage == GrowthStage.Hatch) {
            endTime = growthTime[tokenId].hatchling;
        } else if(currentStage == GrowthStage.Hatchling) {
            endTime = growthTime[tokenId].adult;
        } else {
            endTime = 0;
        }
        timeRemaining = (endTime > currentTime) ? (endTime - currentTime) : 0;

    }

    function mintToken(
        string calldata _tokenType, 
        uint256 _husbandId, 
        uint256 _wifeId, 
        uint256 _generation,
        address _owner, 
        bool _isPremium
    ) internal returns(uint256) {
        require(tokenTypeManager.isAllowedTokenType(_tokenType), "Invalid token type");
        
        uint256 tokenId = ++newTokenId;
        tokens[tokenId] = Token({
            tokenType: _tokenType,
            gender:0,
            husbandId: _husbandId,
            wifeId: _wifeId,
            generation: _generation,
            isPremium: _isPremium,
            birth: block.timestamp
        });

        growthTime[tokenId].hatch = block.timestamp + 2 days;
        growthStages[tokenId] = GrowthStage.Egg;

        _safeMint(_owner, tokenId);
        userTokens[_owner].push(tokenId);

        emit TokenMinted(_owner, tokenId);

        return tokenId;
    }

    function getRandomGender() internal returns(uint) {
        randNonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce))) % 2 + 1;
    }

    function setDataURI(string calldata _dataURI) public onlyOwner {
        dataURI = _dataURI;
    }

    function setTokenURI(string calldata _tokenURI) public onlyOwner {
        baseTokenURI = _tokenURI;
    }

    function setMetaDescription(string calldata _metaDec) public onlyOwner {
        metaDescription = _metaDec;
    }

    function setImageExtension(string calldata _imgEx) public onlyOwner {
        imageExtension = _imgEx;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        if(bytes(baseTokenURI).length > 0) {
            return string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId)));
        } else {
            string memory image = _getTokenImage(tokenId);

            return string(abi.encodePacked(
                "data:application/json;utf8,{\"name\": \"Dragon #",
                Strings.toString(tokenId),
                "\",\"external_url\":\"https://github.com/bchsol/CryptoDragon\",\"image\":\"",
                dataURI,
                image,
                imageExtension,
                "\",\"attributes\":[{\"trait_type\":\"Dragon\",\"value\":\"",
                tokens[tokenId].tokenType,
                "\"}]}"
            ));
        }
    }

    function _getTokenImage(uint256 tokenId) internal view returns (string memory) {
        if (growthStages[tokenId] == GrowthStage.Egg) {
            return string(abi.encodePacked(tokens[tokenId].tokenType, "_egg"));
        } else {
            string memory gen = tokens[tokenId].isPremium
                ? (tokens[tokenId].generation == 1 ? "g" : "b")
                : "n";
            string memory gender = tokens[tokenId].gender == 1 ? "m" : "f";
            string memory stage;

            if (growthStages[tokenId] == GrowthStage.Hatch) {
                stage = "hatch";
            } else if (growthStages[tokenId] == GrowthStage.Hatchling) {
                stage = "hatchling";
            } else if (growthStages[tokenId] == GrowthStage.Adult) {
                stage = "adult";
            }

            return string(
                abi.encodePacked(tokens[tokenId].tokenType, "_", gen, "_", gender, "_", stage)
            );
        }
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}