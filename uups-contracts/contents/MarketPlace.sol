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
    uint128 private _saleIds;
    uint128 private _saleSold;
    uint128 private _auctionIds;
    uint128 private _auctionItemsSold;

    uint256 public marketFeePer;

    IERC20 public paymentToken;

    struct MarketItem {
        uint128 itemId;
        address owner;
        address tokenAddress;
        uint256 tokenId;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        uint256 quantity;
        bool sold;
        bool cancel;
        bool isERC721;
    }

    struct AuctionItem {
        uint128 itemId;
        address owner;
        address tokenAddress;
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
    // erc721 or erc1155 contract
    mapping(address => bool) public approvalContract;

    event ItemListed(uint128 itemId, address tokenAddress, uint256 tokenId, address owner, uint256 price, uint256 quantity, bool isERC721);
    event ItemDelisted(uint128 itemId, uint256 tokenId, address owner, uint256 price);
    event ItemBought(uint128 itemId, address tokenAddress, uint256 tokenId, address owner, address buyer, uint256 price, uint256 quantity);
    event AuctionListed(uint128 autionId, address tokenAddress, uint256 tokenId, address owner, uint256 reservePrice, uint256 startTime, uint256 endTime);

    function initialize(address _paymentToken) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        paymentToken = IERC20(_paymentToken);

        marketFeePer = 25;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function listItem(
        address tokenAddress, 
        uint256 tokenId, 
        uint256 startTime, 
        uint256 endTime, 
        uint256 price, 
        uint256 quantity, 
        bool isERC721) external {
        require(isApprovalAddress(tokenAddress), "Not approval address");
        require(price > 0, "Price must be at least 1 wei");
        require(quantity > 0, "Quantity must be at least 1");
        require(isERC721 ? quantity == 1 : true, "Only one ERC721 token can be listed");

        IToken tokenContract = IToken(tokenAddress);

        if(isERC721) {
            require(tokenContract.ownerOf(tokenId) == msg.sender, "You are not the owner");
        } else {
            require(tokenContract.balanceOf(msg.sender, tokenId) >= quantity, "Insufficient token balance");
        }
        require(tokenContract.isApprovedForAll(msg.sender, address(this)), "Marketplace not approved"); 

        unchecked {
            _saleIds++;
        }

        uint128 itemId = _saleIds;

        items[itemId] = MarketItem({
            itemId: itemId,
            owner: msg.sender,
            tokenAddress: tokenAddress,
            tokenId: tokenId,
            price: price,
            startTime: startTime,
            endTime: endTime,
            quantity: quantity,
            sold: false,
            cancel: false,
            isERC721: isERC721
        });

        emit ItemListed(itemId, tokenAddress, tokenId, msg.sender, price, quantity, isERC721);
    }

    function unlistItem(uint128 itemId) public {
        MarketItem storage item = items[itemId];
        require(item.owner == msg.sender, "You are not the owner");
        item.cancel = true;

        emit ItemDelisted(itemId, item.tokenId, msg.sender, item.price);
    }

    function buyItem(uint128 itemId, uint256 quantity) public payable {
        require(getSaleStatus(itemId) == "ACTIVE", "Not Active");
        MarketItem storage item = items[itemId];
        require(!item.sold && !item.cancel, "Item is not for sale");
        require(item.quantity >= quantity, "Not enough quantity available");
        require(paymentToken.balanceOf(msg.sender) >= item.price * quantity, "Insufficient funds");
        require(paymentToken.allowance(msg.sender, address(this)) >= item.price * quantity, "Insufficient allowance");

        uint256 totalPrice = item.price * quantity;
        uint256 fee = (item.price * marketFeePer) / 1000;
        uint256 sellerProceeds = totalPrice - fee;

        IToken tokenContract = IToken(item.tokenAddress);

        item.quantity -= quantity;
        if(item.quantity == 0) {
            item.sold = true;
            unchecked{
                _saleSold++;
            }
        }

        if(item.isERC721){
            tokenContract.safeTransferFrom(item.owner, msg.sender, item.tokenId,"");
        } else {
            tokenContract.safeTransferFrom(item.owner, msg.sender, item.tokenId, quantity, "");
        }

        require(paymentToken.transferFrom(msg.sender, address(this), totalPrice), "Transfer failed");
        claimableFunds[owner()] += fee;
        claimableFunds[item.owner] += sellerProceeds;

        emit ItemBought(itemId, item.tokenAddress, item.tokenId, item.owner, msg.sender, item.price, quantity);
    }


    /// Auction Fuction
    /// only ERC721

    function listAuction(
        uint256 tokenId, 
        address tokenAddress,
        uint256 startTime,
        uint256 endTime,
        uint256 reservePrice
    ) external {
            require(isApprovalAddress(tokenAddress), "Not approval address");
            require(reservePrice > 0, "Price must be at least 1 wei");
            IToken tokenContract = IToken(tokenAddress);
            require(tokenContract.ownerOf(tokenId) == msg.sender, "You are not the owner");
            require(tokenContract.isApprovedForAll(msg.sender, address(this)), "Marketplace not approved");

            unchecked {
                _auctionIds++;
            }
            uint128 auctionId = _auctionIds;

            auctionItems[auctionId] = AuctionItem({
            itemId: auctionId,
            owner: msg.sender,
            tokenAddress: tokenAddress,
            tokenId: tokenId,
            reservePrice: reservePrice,
            startTime: startTime,
            endTime: endTime,
            sold: false,
            cancel: false
            });
        emit AuctionListed(auctionId, tokenAddress, tokenId, msg.sender, reservePrice, startTime, endTime);
    }

    function bid(uint128 auctionId, uint256 price) external {
        require(getAuctionStatus(auctionId) == "ACTIVE", "Auction not Active");
        require(msg.sender != highestBidder[auctionId], "Already highest bidder");
        require(price > bids[auctionId][highestBidder[auctionId]].price, "Bid price too low");
        require(price >= auctionItems[auctionId].reservePrice, "Bid below reserve price");

        require(paymentToken.transferFrom(msg.sender, address(this), price), "Transfer failed");

        address lastHighestBidder = highestBidder[auctionId];
        uint256 lastHighestPrice = bids[auctionId][lastHighestBidder].price;

        if(lastHighestBidder != msg.sender) {
            delete bids[auctionId][lastHighestBidder].price;
            claimableFunds[lastHighestBidder] += lastHighestPrice;
        }

        bids[auctionId][msg.sender] = Bid({price :price, timestamp: block.timestamp});
        highestBidder[auctionId] = msg.sender;
    }

    function resolveAuction(uint128 auctionId) external {
        require(!claimed[auctionId], "Already claimed");
        
        bytes32 status = getAuctionStatus(auctionId);
        require(status == "CANCELED" || status == "ENDED", "Auction is still active");
        
        uint256 tokenId = auctionItems[auctionId].tokenId;
        address seller = auctionItems[auctionId].owner;
        address winner = highestBidder[auctionId];
        uint256 winningBid = bids[auctionId][winner].price;

        uint256 fee = (winningBid * marketFeePer) / 1000;
        uint256 sellerProceeds = winningBid - fee;

        IToken tokenContract = IToken(auctionItems[auctionId].tokenAddress);

        auctionItems[auctionId].sold = true;
        unchecked{
            _auctionItemsSold++;
        }
        
        claimableFunds[seller] += sellerProceeds;
        claimableFunds[owner()] += fee;

        tokenContract.safeTransferFrom(seller, winner, tokenId, "");

        claimed[auctionId] = true;
    }

    function cancelAuction(uint128 auctionId) external {
        require(msg.sender == auctionItems[auctionId].owner || msg.sender == owner(), "Only owner or sale");

        bytes32 status = getAuctionStatus(auctionId);
        require(status == "ACTIVE" || status == "PENDING", "Auction must be Active or Pending");
        
        address currentHighestBidder = highestBidder[auctionId];
        uint256 currentHighestBid = bids[auctionId][currentHighestBidder].price;

        auctionItems[auctionId].cancel = true;

        claimableFunds[currentHighestBidder] += currentHighestBid;
    }

    /// View Function

    function getAuctionStatus(uint128 auctionId) public view returns(bytes32) {
        AuctionItem memory auctionItem = auctionItems[auctionId];

        if(block.timestamp < auctionItem.startTime) return "PENDING";

        if(auctionItem.cancel) return "CANCELED";

        if(block.timestamp >= auctionItem.startTime && block.timestamp < auctionItem.endTime) return "ACTIVE";

        if(block.timestamp > auctionItem.endTime) return "ENDED";

        return "ERROR";
    }

    function getSaleStatus(uint128 itemId) public view returns(bytes32) {
        MarketItem memory item = items[itemId];

        if(block.timestamp < item.startTime) return "PENDING";

        if(item.cancel) return "CANCELED";

        if(block.timestamp < item.endTime && item.quantity > 0) return "ACTIVE";

        if(block.timestamp >= item.endTime || item.sold) return "ENDED"; 

        return "ERROR";
    }

    function isApprovalAddress(address tokenAddress) internal view returns(bool) {
        return approvalContract[tokenAddress];
    }

    function claimFunds() external {
        uint256 payout = claimableFunds[msg.sender];
        require(payout > 0, "No funds to claim");

        claimableFunds[msg.sender] = 0;
        require(paymentToken.transfer(msg.sender, payout), "Claim failed");
    }

    function checkClaimableFunds() external view returns(uint256) {
        return claimableFunds[msg.sender];
    }

    function updateListingPrice(uint128 itemId, uint256 _listingPrice) public {
        require(items[itemId].owner == msg.sender, "You are not the owner");
        items[itemId].price = _listingPrice;
    }

    function setMarketPlaceFeePer(uint256 newFee) external onlyOwner {
        marketFeePer = newFee;
    }

    function setApprovalAddress(address tokenAddress) external {
        approvalContract[tokenAddress] = true;
    }

    function removeAddress(address tokenAddress) external {
        delete approvalContract[tokenAddress];
    }
}
