// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./IToken.sol";

contract Marketplace is Initializable, OwnableUpgradeable, UUPSUpgradeable, ERC721Holder, ERC1155Holder {
    uint128 private _itemIds;
    uint128 private _itemsSold;
    uint128 private _auctionIds;
    uint128 private _auctionItemsSold;

    uint256 public marketFeePer;

    IERC20 public paymentToken;
    IToken public ERC721Contract;
    IToken public ERC1155Contract;

    struct MarketItem {
        uint128 itemId;
        address owner;
        uint256 tokenId;
        uint256 price;
        uint256 quantity;
        bool sold;
        bool cancel;
        bool isERC721;
    }

    struct AuctionItem {
        uint128 itemId;
        address owner;
        uint256 tokenId;
        uint256 reservePrice;
        uint256 startTime;
        uint256 endTime;
        bool sold;
        bool cancel;
    }

    struct Bid {
        uint256 price;
        uint256 timestamp;
    }

    // itemId => ItemInfo
    mapping(uint256 => MarketItem) public items;
    // auctionId => auctionItemInfo
    mapping(uint256 => AuctionItem) public auctionItems;
    // auctionId => bidder Address => Bid
    mapping(uint256 => mapping(address => Bid)) public bids;
    // auctionId => highest bidder address 
    mapping(uint256 => address) public highestBidder;
    // auctionId => claim
    mapping(uint256 => bool) public claimed;
    // userAddress => funds
    mapping(address => uint256) private claimableFunds;

    event ItemListed(uint128 itemId, uint256 tokenId, address owner, uint256 price, uint256 quantity, bool isERC721);
    event ItemDelisted(uint128 itemId, uint256 tokenId, address owner, uint256 price);
    event ItemBought(uint128 itemId, uint256 tokenId, address owner, address buyer, uint256 price, uint256 quantity);
    event AuctionListed(uint128 autionId, uint256 tokenId, address owner, uint256 reservePrice, uint256 startTime, uint256 endTime);

    function initialize(address _ERC721Contract, address _ERC1155Contract, address _paymentToken) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        ERC721Contract = IToken(_ERC721Contract);
        ERC1155Contract = IToken(_ERC1155Contract);
        paymentToken = IERC20(_paymentToken);

        marketFeePer = 25;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function listItem(uint256 tokenId, uint256 price, uint256 quantity, bool isERC721) external {
        require(price > 0, "Price must be at least 1 wei");
        require(quantity > 0, "Quantity must be at least 1");
        require(isERC721 ? quantity == 1 : true, "Only one ERC721 token can be listed");

        if(isERC721) {
            require(ERC721Contract.ownerOf(tokenId) == msg.sender, "You are not the owner");
            require(ERC721Contract.isApprovedForAll(msg.sender, address(this)), "Marketplace not approved");
        } else {
            require(ERC1155Contract.balanceOf(msg.sender, tokenId) >= quantity, "Insufficient token balance");
            require(ERC1155Contract.isApprovedForAll(msg.sender, address(this)), "Marketplace not approved"); 
        }

        unchecked {
            ++_itemIds;
        }

        uint128 itemId = _itemIds;

        items[itemId] = MarketItem({
            itemId: itemId,
            owner: msg.sender,
            tokenId: tokenId,
            price: price,
            quantity: quantity,
            sold: false,
            cancel: false,
            isERC721: isERC721
        });

        emit ItemListed(itemId, tokenId, msg.sender, price, quantity, isERC721);
    }

    function unlistItem(uint128 itemId) public {
        MarketItem storage item = items[itemId];
        require(item.owner == msg.sender, "You are not the owner");
        item.cancel = true;

        emit ItemDelisted(itemId, item.tokenId, msg.sender, item.price);
    }

    function buyItem(uint128 itemId, uint256 quantity) public payable {
        MarketItem storage item = items[itemId];
        require(!item.sold && !item.cancel, "Item is not for sale");
        require(item.quantity >= quantity, "Not enough quantity available");
        require(paymentToken.balanceOf(msg.sender) >= item.price * quantity, "Insufficient funds");
        require(paymentToken.allowance(msg.sender, address(this)) >= item.price * quantity, "Insufficient allowance");

        uint256 totalPrice = item.price * quantity;
        uint256 fee = (item.price * marketFeePer) / 1000;
        uint256 sellerProceeds = totalPrice - fee;

        item.quantity -= quantity;
        if(item.quantity == 0) {
            item.sold = true;
            unchecked{
                ++_itemsSold;
            }
        }

        item.isERC721 
        ? ERC721Contract.safeTransferFrom(item.owner, msg.sender, item.tokenId,"") 
        : ERC1155Contract.safeTransferFrom(item.owner, msg.sender, item.tokenId, quantity, "");

        paymentToken.transferFrom(msg.sender, address(this), totalPrice);
        claimableFunds[owner()] += fee;
        claimableFunds[item.owner] += sellerProceeds;

        emit ItemBought(itemId, item.tokenId, item.owner, msg.sender, item.price, quantity);
    }


    /// Auction
    /// only ERC721

    function listAuction(
        uint256 tokenId, 
        uint256 startTime,
        uint256 endTime,
        uint256 reservePrice) external {
            require(reservePrice > 0, "Price must be at least 1 wei");
            require(ERC721Contract.ownerOf(tokenId) == msg.sender, "You are not the owner");
            require(ERC721Contract.isApprovedForAll(msg.sender, address(this)), "Marketplace not approved");

            unchecked {
            ++_auctionIds;
            }

            auctionItems[_auctionIds] = AuctionItem({
            itemId : _auctionIds,
            owner : msg.sender,
            tokenId : tokenId,
            reservePrice : reservePrice,
            startTime : startTime,
            endTime : endTime,
            sold: false,
            cancel: false
            });
        emit AuctionListed(_auctionIds, tokenId, msg.sender, reservePrice, startTime, endTime);
    }

    function bid(uint128 auctionId, uint256 price) external {
        require(getAuctionStatus(auctionId) == "ACTIVE", "Auction not Active");
        require(msg.sender != highestBidder[auctionId], "Already highest bidder");
        require(price > bids[auctionId][highestBidder[auctionId]].price, "Bid price too low");
        require(price >= auctionItems[auctionId].reservePrice, "Bid below reserve price");

        paymentToken.transferFrom(msg.sender, address(this), price);

        address lastHighestBidder = highestBidder[auctionId];
        uint256 lastHighestPrice = bids[auctionId][lastHighestBidder].price;

        if(lastHighestBidder != msg.sender) {
            delete bids[auctionId][lastHighestBidder].price;
            claimableFunds[lastHighestBidder] += lastHighestPrice;
        }

        bids[auctionId][msg.sender] = Bid({price :price, timestamp: block.timestamp});
        highestBidder[auctionId] = msg.sender;
    }

    function resolveAuction(uint256 auctionId) external {
        require(!claimed[auctionId], "Already claimed");
        
        bytes32 status = getAuctionStatus(auctionId);
        require(status == "CANCELED" || status == "ENDED", "Auction is still active");
        
        uint256 tokenId = auctionItems[auctionId].tokenId;
        address seller = auctionItems[auctionId].owner;
        address winner = highestBidder[auctionId];
        uint256 winningBid = bids[auctionId][winner].price;

        uint256 fee = (winningBid * marketFeePer) / 1000;
        uint256 sellerProceeds = winningBid - fee;

        auctionItems[auctionId].sold = true;
        unchecked{
            ++_auctionItemsSold;
        }
        
        claimableFunds[seller] += sellerProceeds;
        claimableFunds[owner()] += fee;

        ERC721Contract.safeTransferFrom(seller, winner, tokenId, "");

        claimed[auctionId] = true;
    }

    function cancelAuction(uint256 auctionId) external {
        require(msg.sender == auctionItems[auctionId].owner || msg.sender == owner(), "Only owner or sale");

        bytes32 status = getAuctionStatus(auctionId);
        require(status == "ACTIVE" || status == "PENDING", "Auction must be Active or Pending");
        
        address currentHighestBidder = highestBidder[auctionId];
        uint256 currentHighestBid = bids[auctionId][currentHighestBidder].price;

        auctionItems[auctionId].cancel = true;

        claimableFunds[currentHighestBidder] += currentHighestBid;
    }


    function getAuctionStatus(uint256 auctionId) internal view returns(bytes32) {
        uint256 startTime = auctionItems[auctionId].startTime;
        uint256 endTime = auctionItems[auctionId].endTime;

        if(block.timestamp < startTime) return "PENDING";

        if(block.timestamp >= startTime && block.timestamp < endTime) return "ACTIVE";

        if(block.timestamp > endTime) return "ENDED";

        return "NONE";
    }




    function claimFunds() external {
        uint256 payout = claimableFunds[msg.sender];
        require(payout == 0, "No funds to claim");

        delete claimableFunds[msg.sender];
        paymentToken.transfer(msg.sender, payout);
    }

    function checkClaimableFunds() external view returns(uint256) {
        return claimableFunds[msg.sender];
    }

    function updateListingPrice(uint256 itemId, uint256 _listingPrice) public {
        require(items[itemId].owner == msg.sender, "You are not the owner");
        items[itemId].price = _listingPrice;
    }

    function setMarketPlaceFeePer(uint256 newFee) external onlyOwner {
        marketFeePer = newFee;
    }
}
