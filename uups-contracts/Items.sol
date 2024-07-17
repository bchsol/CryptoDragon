// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Items is ERC1155, Ownable, ERC1155Supply {
    using Strings for uint256;

    string public baseURI;

    uint256 private _currentTokenID = 0;

    mapping(string => uint256) private _itemNameToID;
    mapping(uint256 => string) private _itemIDToName;

    mapping(address => bool) private allowedAddresses;

    constructor(address initialOwner,string memory initialURI) ERC1155(initialURI) Ownable(initialOwner) {
        baseURI = initialURI;
    }

    function mint(address account, string calldata name, uint256 amount, bytes memory data)
        external
        onlyOwner
    {
        require(isAllowedAddress(msg.sender), "Only the auth contract can mint tokens");
        require(_itemNameToID[name] != 0, "There is no such item.");
        _mint(account, _itemNameToID[name], amount, data);
    }

    function mintBatch(address to, string[] memory names, uint256[] memory amounts, bytes memory data)
        external
        onlyOwner
    { 
        require(isAllowedAddress(msg.sender), "Only the auth contract can mint tokens");
        require(names.length == amounts.length, "Names and amounts length mismatch");

        uint256[] memory ids = new uint256[](names.length);
        for(uint256 i = 0; i < names.length; i++) {
            require(_itemNameToID[names[i]] != 0, "There is no such item");
            ids[i] = _itemNameToID[names[i]];
        }

        _mintBatch(to, ids, amounts, data);
    }

    function addNewItem(string calldata itemName, uint256 itemId) external onlyOwner {
        require(_itemNameToID[itemName] == 0, "Item already exists");
        require(bytes(_itemIDToName[itemId]).length == 0, "Item ID already exists");

        _itemNameToID[itemName] = itemId;
        _itemIDToName[itemId] = itemName;

        if(itemId > _currentTokenID) {
            _currentTokenID = itemId;
        }
    }

    function setAllowedAddress(address addr, bool allowed) external onlyOwner {
        allowedAddresses[addr] = allowed;
    }

    function isAllowedAddress(address addr) public view returns(bool) {
        return allowedAddresses[addr];
    }

    function setBaseURI(string calldata _newURI) external onlyOwner{
        baseURI = _newURI;
    }

    function getItemID(string calldata itemName) external view returns (uint256) {
        return _itemNameToID[itemName];
    }

    function getItemName(uint256 id) external view returns (string memory) {
        return _itemIDToName[id];
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _itemIDToName[tokenId], ".json")) : "";
    }


    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._update(from, to, ids, values);
    }
}