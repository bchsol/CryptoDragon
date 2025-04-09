// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces/IToken.sol";

contract Items is ERC1155, Ownable {
    IToken public tokenContract;
    
    mapping(uint256 => bool) public validItems;
    uint256 public nextItemId = 1;
    
    uint256 public constant MoonlightGem = 1;
    uint256 public constant genderChange = 2;
    uint256 public constant TrainedEffortReset = 3;
    
    string private _baseUri;

    event ItemAdded(uint256 indexed itemId, string name);
    event ItemUsed(address indexed user, uint256 indexed itemId, uint256 indexed dragonId);

    constructor(
        address _tokenContract, 
        string memory baseUri
    ) ERC1155(baseUri) Ownable(msg.sender) {
        tokenContract = IToken(_tokenContract);
        _baseUri = baseUri;
        
        // 초기 아이템 등록
        validItems[MoonlightGem] = true;
        validItems[genderChange] = true;
        validItems[TrainedEffortReset] = true;
        nextItemId = 4; // 기존 아이템 이후부터 시작
    }

    /**
     * @dev 새로운 아이템을 추가합니다
     * @param name 아이템 이름
     * @return 새로 생성된 아이템 ID
     */
    function addNewItem(string memory name) external onlyOwner returns (uint256) {
        uint256 newItemId = nextItemId;
        validItems[newItemId] = true;
        nextItemId++;
        
        emit ItemAdded(newItemId, name);
        return newItemId;
    }

    /**
     * @dev 아이템이 유효한지 확인합니다
     * @param itemId 확인할 아이템 ID
     */
    function isValidItem(uint256 itemId) public view returns (bool) {
        return validItems[itemId];
    }

    /**
     * @dev 아이템을 민트합니다
     */
    function mintItem(
        address to, 
        uint256 itemId, 
        uint256 amount
    ) external onlyOwner {
        require(isValidItem(itemId), "Invalid item ID");
        _mint(to, itemId, amount, "");
    }

    /**
     * @dev 여러 아이템을 한번에 민트합니다
     * @param to 아이템을 받을 주소
     * @param itemIds 아이템 ID 배열
     * @param amounts 각 아이템별 수량 배열
     */
    function mintBatch(
        address to,
        uint256[] memory itemIds,
        uint256[] memory amounts
    ) external onlyOwner {
        _mintBatch(to, itemIds, amounts, "");
    }

    /**
     * @dev 성격 변경 아이템을 사용합니다
     * @param dragonId 대상 드래곤 ID
     * @param newPersonality 새로운 성격 값 (0-15)
     */
    function usePersonalityChangeItem(uint256 dragonId, IToken.Personality newPersonality) external {
        require(balanceOf(msg.sender, MoonlightGem) > 0, "No personality change item");
        require(tokenContract.ownerOf(dragonId) == msg.sender, "Not dragon owner");

        _burn(msg.sender, MoonlightGem, 1);
        tokenContract.changePersonality(dragonId, IToken.Personality(newPersonality));
        
        emit ItemUsed(msg.sender, MoonlightGem, dragonId);
    }

    /**
     * @dev 성별 변경 아이템을 사용합니다
     * @param dragonId 대상 드래곤 ID
     */
    function useGenderChangeItem(uint256 dragonId) external {
        require(balanceOf(msg.sender, genderChange) > 0, "No gender change item");
        require(tokenContract.ownerOf(dragonId) == msg.sender, "Not dragon owner");

        _burn(msg.sender, genderChange, 1);
        tokenContract.changeGender(dragonId);
        
        emit ItemUsed(msg.sender, genderChange, dragonId);
    }

    /**
     * @dev 훈련 초기화 아이템을 사용합니다
     * @param dragonId 대상 드래곤 ID
     */
    function useTrainingResetItem(uint256 dragonId) external {
        require(balanceOf(msg.sender, TrainedEffortReset) > 0, "No training reset item");
        require(tokenContract.ownerOf(dragonId) == msg.sender, "Not dragon owner");

        _burn(msg.sender, TrainedEffortReset, 1);
        tokenContract.resetTraining(dragonId);
        
        emit ItemUsed(msg.sender, TrainedEffortReset, dragonId);
    }

    /**
     * @dev URI를 설정합니다
     * @param newUri 새로운 URI
     */
    function setURI(string memory newUri) external onlyOwner {
        _baseUri = newUri;
    }

    /**
     * @dev 특정 토큰의 URI를 반환합니다
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(isValidItem(tokenId), "Invalid token ID");
        return string(abi.encodePacked(_baseUri, toString(tokenId)));
    }

    /**
     * @dev uint256를 string으로 변환합니다
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
