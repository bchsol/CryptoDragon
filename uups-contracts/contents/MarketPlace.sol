// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract Marketplace is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _itemIds;
    CountersUpgradeable.Counter private _itemsSold;

    uint256 public marketFeePer;
    IERC20Upgradeable public paymentToken;
    IERC721Upgradeable public nftContract;

    struct MarketItem {
        uint256 itemId;
        uint256 tokenId;
        address payable owner;
        uint256 price;
        bool sold;
        bool cancel;
    }

    mapping(uint256 => uint256) private itemsByNFTToken;
    mapping(uint256 => MarketItem) public items;

    event ItemListed(uint256 itemId, uint256 tokenId, address owner, uint256 price);
    event ItemDelisted(uint256 itemId, uint256 tokenId, address owner, uint256 price);
    event ItemBought(uint256 itemId, uint256 tokenId, address owner, address buyer, uint256 price);

    function initialize(address _nftContract, address _paymentToken) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        nftContract = IERC721Upgradeable(_nftContract);
        paymentToken = IERC20Upgradeable(_paymentToken);
        marketFeePer = 25;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function listItem(uint256 tokenId, uint256 price) public {
        require(price > 0, "Price must be at least 1 wei");

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        require(nftContract.ownerOf(tokenId) == msg.sender, "You are not the owner");
        require(nftContract.isApprovedForAll(msg.sender, address(this)), "Marketplace not approved");

        nftContract.approve(address(this), tokenId);

        items[itemId] = MarketItem({
            itemId: itemId,
            tokenId: tokenId,
            owner: payable(msg.sender),
            price: price,
            sold: false,
            cancel: false
        });

        itemsByNFTToken[tokenId] = itemId;

        emit ItemListed(itemId, tokenId, msg.sender, price);
    }

    function unlistItem(uint256 itemId) public {
        MarketItem storage item = items[itemId];
        require(item.owner == msg.sender, "You are not the owner");
        item.cancel = true;

        emit ItemDelisted(itemId, item.tokenId, msg.sender, item.price);
    }

    function buyItem(uint256 itemId) public payable {
        MarketItem storage item = items[itemId];
        require(!item.sold, "Item is not for sale");
        require(!item.cancel, "Item is not for sale");
        require(paymentToken.balanceOf(msg.sender) >= item.price, "Insufficient funds");
        require(paymentToken.allowance(msg.sender, address(this)) >= item.price, "Insufficient allowance");

        uint256 fee = (item.price * marketFeePer) / 1000;
        uint256 sellerProceeds = item.price - fee;

        item.sold = true;
        _itemsSold.increment();

        nftContract.transferFrom(item.owner, msg.sender, item.tokenId);

        // Transfer the fee to the market
        require(paymentToken.transferFrom(msg.sender, owner(), fee), "Fee transfer failed");

        // Transfer the sell price to the seller
        require(paymentToken.transferFrom(msg.sender, item.owner, sellerProceeds), "Seller proceeds transfer failed");

        emit ItemBought(itemId, item.tokenId, item.owner, msg.sender, item.price);
    }

    function fetchMarketItemLog() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();

        MarketItem[] memory itemLog = new MarketItem[](totalItemCount);
        for (uint i = 1; i <= totalItemCount; i++) {
            itemLog[i - 1] = items[i];
        }

        return itemLog;
    }

    function fetchMarketItemListed() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint unsoldItemCount = totalItemCount - _itemsSold.current();
        uint currentIndex = 0;

        MarketItem[] memory marketItems = new MarketItem[](unsoldItemCount);
        for (uint i = 1; i <= totalItemCount; i++) {
            if (items[i].sold == false && items[i].cancel == false) {
                marketItems[currentIndex] = items[i];
                currentIndex += 1;
            }
        }
        assembly { mstore(marketItems, currentIndex) }
        return marketItems;
    }

    function fetchMyItemListed() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint currentIndex = 0;

        MarketItem[] memory myItems = new MarketItem[](totalItemCount);
        for (uint i = 1; i <= totalItemCount; i++) {
            if (items[i].owner == msg.sender && items[i].sold == false && items[i].cancel == false) {
                myItems[currentIndex] = items[i];
                currentIndex += 1;
            }
        }
        assembly { mstore(myItems, currentIndex) }
        return myItems;
    }

    function isListed(uint256 tokenId) public view returns (bool) {
        return itemsByNFTToken[tokenId] != 0;
    }

    function updateListingPrice(uint256 itemId, uint256 _listingPrice) public {
        require(items[itemId].owner == msg.sender, "You are not the owner");

        items[itemId].price = _listingPrice;
    }

    function setMarketPlaceFeePer(uint256 newFee) external onlyOwner {
        marketFeePer = newFee;
    }
}
