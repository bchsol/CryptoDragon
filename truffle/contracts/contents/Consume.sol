// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Consume is ERC2771Context, ERC1155(""), Ownable {
    using Strings for uint256;

    struct Token {
        uint64 limitSupply;
        uint64 totalMinted;
        uint64 burnedAmount;
    }

    string private _defaultBaseURI;

    mapping(uint256 => string) private _tokenBaseURIs;
    mapping(uint256 => Token) private _tokens;

    event TokenLimitSupplySet(uint256 indexed id, uint64 newLimitSupply);
    event DefaultBaseURIChanged(string previousURI, string newURI);
    event TokenBaseURIChanged(uint256 indexed id, string previousURI, string newURI);
    event RetrievedERC1155(address from, address to, uint256 id, uint256 amount, string reason);

    constructor(address trustedForwarder, string memory defaultBaseURI) ERC2771Context(trustedForwarder) Ownable(_msgSender()){
        _defaultBaseURI = defaultBaseURI;
    }

    function setDefaultURI(string memory newURI) external onlyOwner{
        _defaultBaseURI = newURI;
        emit DefaultBaseURIChanged(_defaultBaseURI, newURI);
    }
    
    function setTokenURI(string memory newURI, uint256 id) external onlyOwner{
        _tokenBaseURIs[id] = newURI;
        emit TokenBaseURIChanged(id, _tokenBaseURIs[id], newURI);
    }

    function setLimitSupply(uint256 id, uint64 newLimitSupply) external onlyOwner{
        require(newLimitSupply < 9223372036854775808, "supply Oveflow");

        Token storage token = _tokens[id];
        require(token.limitSupply == 0, "limit supply is already set");
        token.limitSupply = newLimitSupply;
        emit TokenLimitSupplySet(id, newLimitSupply);
    }

    function mintToWallet(address to, uint256 id, uint256 amount, bytes calldata data) external {
        Token storage token = _tokens[id];

        token.totalMinted += uint64(amount);

        _mint(to, id, amount, data);
    }

    function mintToWalletBatch(address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external {
        uint256 idsLength = ids.length;
        for(uint256 i ; i < idsLength;) {
            require(amounts[i] < 9223372036854775808, "amount Overflow");
            Token storage token = _tokens[ids[i]];
            token.totalMinted += uint64(amounts[i]);
            unchecked{
                i++;
            }
        }
        _mintBatch(to, ids, amounts, data);
    }

    function walletToInventory(address from, uint256 id, uint256 amount) external {
        Token storage token = _tokens[id];
        _burn(from, id, amount);
        token.burnedAmount += uint64(amount);
    }

    function walletToInventoryBatch(address from, uint256[] calldata ids, uint256[] calldata amounts) external {
        uint256 idsLength = ids.length;
        for (uint256 i; i < idsLength; ) {
            require(amounts[i] < 9223372036854775808, "amount Overflow");
            Token storage token = _tokens[ids[i]];
            token.burnedAmount += uint64(amounts[i]);
            unchecked {
                i++;
            }
        }
        _burnBatch(from, ids, amounts);
    }

     function retrieveERC1155(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        string memory reason
    ) external onlyOwner {
        safeTransferFrom(from, to, id, amount, "");
        emit RetrievedERC1155(from, to, id, amount, reason);
    }

    function getTokenLimitSupply(uint256 id) external view returns (uint64) {
        return _tokens[id].limitSupply;
    }

    function getTokenTotalMinted(uint256 id) external view returns (uint64) {
        return _tokens[id].totalMinted;
    }

    function getTokenburnedAmount(uint256 id) external view returns (uint64) {
        return _tokens[id].burnedAmount;
    }

    function uri(uint256 id) public view override returns (string memory) {
        string memory _uri = bytes(_tokenBaseURIs[id]).length > 0 ? _tokenBaseURIs[id] : _defaultBaseURI;

        return string(abi.encodePacked(_uri, Strings.toString(id), ".json"));
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