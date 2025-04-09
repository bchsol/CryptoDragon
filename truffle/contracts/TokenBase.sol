// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PersonalityCalculator.sol";

contract TokenBase is ERC721, ERC721URIStorage, Ownable, PersonalityCalculator, ERC2771Context {
    enum GrowthStage{Egg, Hatch, Hatchling, Adult}
    
    struct Token {
        string tokenType;
        uint8 gender; // 1: male 2: female
        uint256 husbandId;
        uint256 wifeId;
        uint16 generation;
        bool isPremium;
        uint256 birth;
        string element;
        string personality;
    }

    struct GrowthTime {
        uint256 hatch;
        uint256 hatchling;
        uint256 adult;
    }

    mapping(uint256 => Token) internal tokens;
    mapping(uint256=> GrowthStage) private growthStages;
    mapping(uint256 => GrowthTime) internal growthTime;
    mapping(address => uint256[]) internal userTokens;

    uint256 internal newTokenId;
    uint256 private randNonce;

    string public baseTokenURI;
    string public dataURI;
    string public metaDescription;
    string private imageExtension;

    // Items 컨트랙트 주소 저장을 위한 변수
    address public itemContract;

    event TokenMinted(address indexed owner, uint256 indexed tokenId);
    event TokenEvolved(uint256 indexed tokenId, string newStage);
    event TokenFeed(uint256 indexed tokenId, uint256 indexed newTime);

    constructor(address initialOwner, address trustedForwarder, string memory name, string memory symbol) ERC721(name,symbol) Ownable(initialOwner) ERC2771Context(trustedForwarder){
        randNonce = 0;
        newTokenId = 0;
        
    }

    // 토큰 진화 단계별 소요 시간 상수 정의
    uint256 private constant HATCH_DURATION = 2 days;
    uint256 private constant HATCHLING_DURATION = 3 days;
    uint256 private constant FEEDING_REDUCTION = 3 hours;


    /// @notice 토큰을 다음 단계로 진화시키는 함수
    /// Egg -> Hatch -> Hatchling -> Adult 순서로 진화
    /// 각 단계별로 필요한 시간이 지나야 진화 가능
    function evolve(uint256 tokenId) external {
        require(ownerOf(tokenId) == _msgSender(), "Not owner");
        GrowthStage currentStage = growthStages[tokenId];
        uint256 currentTime = block.timestamp;

        if(currentStage == GrowthStage.Egg && currentTime >= growthTime[tokenId].hatch) {
            _evolveToHatch(tokenId, currentTime);
        } else if(currentStage == GrowthStage.Hatch && currentTime >= growthTime[tokenId].hatchling) {
            _evolveToHatchling(tokenId, currentTime);
        } else if(currentStage == GrowthStage.Hatchling && currentTime >= growthTime[tokenId].adult) {
            _evolveToAdult(tokenId);
        } else {
            revert("Unable to evolve");
        }
    }


     /// @notice 먹이를 주어 성장 시간을 단축시키는 함수
     /// 하루에 최대 3시간까지 단축 가능
    function feeding(uint256 tokenId) external {
        require(ownerOf(tokenId) == _msgSender(), "Not owner");
        GrowthStage currentStage = growthStages[tokenId];
        GrowthTime storage time = growthTime[tokenId];
        uint256 currentTime = block.timestamp;

        if (currentStage == GrowthStage.Adult) {
            revert("Already adult");
        }

        uint256 targetTime = currentStage == GrowthStage.Egg ? time.hatch :
                            currentStage == GrowthStage.Hatch ? time.hatchling :
                            time.adult;

        uint256 newTime = reduceTimeIfPossible(currentTime, targetTime, FEEDING_REDUCTION);

        if (currentStage == GrowthStage.Egg) {
            time.hatch = newTime;
        } else if (currentStage == GrowthStage.Hatch) {
            time.hatchling = newTime;
        } else {
            time.adult = newTime;
        }

        emit TokenFeed(tokenId, newTime);
    }

    /// 내부 헬퍼 함수들
    function _evolveToHatch(uint256 tokenId, uint256 currentTime) private {
        growthStages[tokenId] = GrowthStage.Hatch;
        tokens[tokenId].gender = getRandomGender();
        growthTime[tokenId].hatchling = currentTime + HATCHLING_DURATION;
        emit TokenEvolved(tokenId, "Hatch");
    }

    function _evolveToHatchling(uint256 tokenId, uint256 currentTime) private {
        growthStages[tokenId] = GrowthStage.Hatchling;
        growthTime[tokenId].adult = currentTime + HATCH_DURATION;
        tokens[tokenId].personality = _getPersonalityString(determinePersonality(tokenId));
        emit TokenEvolved(tokenId, "Hatchling");
    }

    function _evolveToAdult(uint256 tokenId) private {
        growthStages[tokenId] = GrowthStage.Adult;
        emit TokenEvolved(tokenId, "Adult");
    }

    function reduceTimeIfPossible( uint256 currentTime,uint256 growthEndTime, uint256 reduction) internal pure returns(uint256){
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


    /// @notice 새로운 토큰을 발행하는 함수
    /// @return 새로 생성된 토큰의 ID
    function mintToken(
        string memory _tokenType, 
        uint256 _husbandId, 
        uint256 _wifeId, 
        uint16 _generation,
        address _owner, 
        bool _isPremium, 
        string memory _element
    ) internal returns(uint256) {
        uint256 tokenId = ++newTokenId;
        tokens[tokenId] = Token({
            tokenType: _tokenType,
            gender:0,
            husbandId: _husbandId,
            wifeId: _wifeId,
            generation: _generation,
            isPremium: _isPremium,
            birth: block.timestamp,

            element: _element,
            personality: ""
        });

        growthTime[tokenId].hatch = block.timestamp + 2 days;
        growthStages[tokenId] = GrowthStage.Egg;

        _safeMint(_owner, tokenId);
        userTokens[_owner].push(tokenId);

        emit TokenMinted(_owner, tokenId);

        return tokenId;
    }


    /// @notice 관리자가 토큰을 강제로 진화시키는 함수
    function forceEvolve(uint256 tokenId) external onlyOwner {
        GrowthStage currentStage = growthStages[tokenId];
        if(currentStage == GrowthStage.Egg) {
            growthStages[tokenId] = GrowthStage.Hatch;
            tokens[tokenId].gender = getRandomGender();
            growthTime[tokenId].hatchling = block.timestamp + 2 days;
        } else if(currentStage == GrowthStage.Hatch) {
            growthStages[tokenId] = GrowthStage.Hatchling;
            growthTime[tokenId].adult = block.timestamp + 3 days;
            Personality personality = determinePersonality(tokenId);
            tokens[tokenId].personality = _getPersonalityString(personality);
        } else if(currentStage == GrowthStage.Hatchling) {
            growthStages[tokenId] = GrowthStage.Adult;
        } else {
            revert("Unable to evolve");
        }
    }

    function trainAttribute(uint256 tokenId, PersonalityCalculator.Attribute attribute) external {
        require(ownerOf(tokenId) == _msgSender(), "Not token owner");
        _trainAttribute(tokenId, attribute);
    }


    /// @notice 성격 타입을 문자열로 변환하는 내부 함수
    /// @return 성격을 나타내는 문자열
    function _getPersonalityString(Personality personality) internal pure returns (string memory) {
        string[16] memory personalities = [
            "Naive", "Rash", "Hasty", "QuickWitted", 
            "Brave", "Quirky", "Adamant", "Bold", 
            "Quiet", "Calm", "Careful", "Hardy", 
            "Docile", "Bashful", "Lax", "Smart"
            ];
        uint8 index = uint8(personality);
        require(index < 16, "Invalid personality");
        return personalities[index];
    }


    /// @notice 랜덤한 성별을 생성하는 내부 함수
    /// @return 1(수컷) 또는 2(암컷)의 값
    function getRandomGender() internal returns(uint8) {
        randNonce++;
        return uint8(uint(keccak256(abi.encodePacked(block.timestamp,_msgSender(),randNonce))) % 2 + 1);
    }

    
    /// @notice 토큰 메타데이터의 기본 URI를 설정하는 함수
    /// @param _dataURI 설정할 데이터 URI
    function setDataURI(string calldata _dataURI) public onlyOwner {
        dataURI = _dataURI;
    }

    
    /// @notice 토큰의 URI를 설정하는 함수
    /// @param _tokenURI 설정할 토큰 URI
    function setTokenURI(string calldata _tokenURI) public onlyOwner {
        baseTokenURI = _tokenURI;
    }

    /// @notice 메타데이터 설명을 설정하는 함수
    /// @param _metaDec 설정할 메타데이터 설명
    function setMetaDescription(string calldata _metaDec) public onlyOwner {
        metaDescription = _metaDec;
    }

    /// @notice 이미지 확장자를 설정하는 함수
    /// @param _imgEx 설정할 이미지 확장자
    function setImageExtension(string calldata _imgEx) public onlyOwner {
        imageExtension = _imgEx;
    }

    /// @notice 토큰의 메타데이터 URI를 조회하는 함수
    /// @return 토큰의 메타데이터 URI 문자열
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721,ERC721URIStorage)
        returns (string memory)
    {
        if(bytes(baseTokenURI).length > 0) {
            return string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId)));
        } 
        string memory image = _generateImageString(tokenId);

        return string(abi.encodePacked(
        "data:application/json;utf8,{\"name\":\"Dragon #",
        Strings.toString(tokenId),
        "\",\"image\":\"",
        dataURI,
        image,
        imageExtension,
        "\",\"attributes\":[",
        _generateAttributes(tokenId),
        "]}"
    ));
    }

    /// @notice 성장 단계를 문자열로 변환하는 내부 함수
    function _getStageString(GrowthStage stage) internal pure returns (string memory) {
        if(stage == GrowthStage.Hatch) return "hatch";  
        if(stage == GrowthStage.Hatchling) return "hatchling";  
        if(stage == GrowthStage.Adult) return "adult";
        return "egg";
    }
    
    /// @notice 토큰의 속성을 JSON 형식으로 생성하는 내부 함수
    function _generateAttributes(uint256 tokenId) internal view returns (string memory) {
        Token storage token = tokens[tokenId];
        GrowthStage stage = growthStages[tokenId];
        
        string memory attributes = string(abi.encodePacked(
        "{\"trait_type\":\"Type\",\"value\":\"", token.tokenType, "\"},",
        "{\"trait_type\":\"Stage\",\"value\":\"", _getStageString(stage), "\"},",
        "{\"trait_type\":\"Generation\",\"value\":", Strings.toString(token.generation), "},",
            "{\"trait_type\":\"Element\",\"value\":\"", token.element, "\"}"
        ));

        if (stage != GrowthStage.Egg) {
            attributes = string(abi.encodePacked(
                attributes,
                ",{\"trait_type\":\"Gender\",\"value\":", 
                token.gender == 1 ? "\"Male\"" : "\"Female\"", "}"
        ));

        if (stage == GrowthStage.Hatchling || stage == GrowthStage.Adult) {
            attributes = string(abi.encodePacked(
                attributes,
                ",{\"trait_type\":\"Personality\",\"value\":\"",
                token.personality,
                    "\"}"
                ));
            }
        }

        return attributes;
    }


    /// @notice 이미지 문자열 생성을 위한 새로운 헬퍼 함수
    function _generateImageString(uint256 tokenId) internal view returns (string memory) {
        Token storage token = tokens[tokenId];
        if(growthStages[tokenId] == GrowthStage.Egg) {
            return string(abi.encodePacked(token.tokenType,"_egg"));
        }
        
        string memory gen = token.isPremium ? (token.generation == 1 ? "g" : "b") : "n";
        string memory gender = token.gender == 1 ? "m" : "f";
        string memory stage = _getStageString(growthStages[tokenId]);
        
        return string(abi.encodePacked(token.tokenType,"_",gen,"_",gender,"_",stage));
    }

    /// @notice 인터페이스 지원 여부를 확인하는 함수
    /// @return 지원 여부 (bool)
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice 성격을 변경하는 함수
    /// @param tokenId 대상 토큰 ID
    /// @param newPersonality 새로운 성격 값
    function changePersonality(uint256 tokenId, Personality newPersonality) external {
        require(_msgSender() == address(itemContract), "Only item contract can change personality");
        
        // confirmedPersonalities에서 허용된 성격인지 확인
        Personality[] memory allowedPersonalities = confirmedPersonalities[tokenId];
        require(allowedPersonalities.length > 0, "No confirmed personalities");
        
        bool isAllowed = false;
        for(uint i = 0; i < allowedPersonalities.length; i++) {
            if(allowedPersonalities[i] == newPersonality) {
                isAllowed = true;
                break;
            }
        }
        require(isAllowed, "Personality not in confirmed list");
        
        tokens[tokenId].personality = _getPersonalityString(newPersonality);
    }

    /// @notice 성별을 변경하는 함수
    /// @param tokenId 대상 토큰 ID
    function changeGender(uint256 tokenId) external {
        require(_msgSender() == address(itemContract), "Only item contract can change gender");
        require(growthStages[tokenId] != GrowthStage.Egg, "Cannot change gender of egg");
        // 1 -> 2 또는 2 -> 1로 변경
        tokens[tokenId].gender = tokens[tokenId].gender == 1 ? 2 : 1;
    }

    /// @notice Items 컨트랙트 주소를 설정하는 함수
    function setItemContract(address _itemContract) external onlyOwner {
        itemContract = _itemContract;
    }

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns(address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns(bytes calldata) {
        return ERC2771Context._msgData();
    }

    function _contextSuffixLength() internal view virtual override(Context,ERC2771Context) returns (uint256) {
        return 20;
    }
}