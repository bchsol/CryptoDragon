// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

import "../interfaces/IToken.sol";

contract Marketplace is Ownable, ERC721Holder, ERC1155Holder, ERC2771Context {
    uint128 public _saleIds;
    uint128 public _saleSold; 
    uint128 public _auctionIds;
    uint128 public _auctionItemsSold;

    uint96 public marketFeePer;

    IERC20 public immutable paymentToken;

    struct MarketItem {
        uint128 itemId;
        address owner;
        address tokenAddress;
        uint256 tokenId;
        uint256 price;
        uint96 startTime;
        uint96 endTime;
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
        uint96 startTime;
        uint96 endTime;
        bool sold;
        bool cancel;
    }

    struct Bid {
        uint256 price;
        uint96 timestamp;
    }

    // itemId => marketItemInfo
    mapping(uint256 => MarketItem) public items;
    // auctionId => auctionItemInfo
    mapping(uint256 => AuctionItem) public auctionItems;
    // auctionId => bidder Address
    mapping(uint256 => mapping(address => Bid)) public bids;
    // auctionId => highest bidder address 
    mapping(uint256 => address) public highestBidder;
    // auctionId
    mapping(uint256 => bool) public claimed;
    // userAddress => funds
    mapping(address => uint256) private claimableFunds;
    // erc721 or erc1155 contract
    mapping(address => bool) public approvalContract;
    // token contract => token id for marketplace listings
    mapping(address => mapping(uint256 => bool)) private listedInMarket;
    // token contract => token id for auction listings
    mapping(address => mapping(uint256 => bool)) private listedInAuction;
    // token contract => token id => market id
    mapping(address => mapping(uint256 => uint128)) public tokenToItemId;
    // token contract => token id => auction id
    mapping(address => mapping(uint256 => uint128)) public tokenToAuctionId;

    // 이벤트 정의
    event MarketItemListed(uint128 indexed itemId, address tokenAddress, uint256 indexed tokenId, address owner, uint256 price, uint256 quantity, bool isERC721);
    event MarketItemDelisted(uint128 indexed itemId, uint256 tokenId, address owner, uint256 price);
    event MarketItemBought(uint128 indexed itemId, address tokenAddress, uint256 indexed tokenId, address owner, address buyer, uint256 price, uint256 quantity);
    event AuctionListed(uint128 indexed autionId, address tokenAddress, uint256 indexed tokenId, address owner, uint256 reservePrice, uint96 startTime, uint96 endTime);
    event AuctionBid(uint128 indexed auctionId, uint256 price, uint96 bidTime);

    /// @notice 마켓플레이스 컨트랙트 생성자
    /// @param _paymentToken 결제에 사용될 토큰 주소
    constructor(address _paymentToken, address trustedForwarder) Ownable(_msgSender()) ERC2771Context(trustedForwarder){
        paymentToken = IERC20(_paymentToken);
        marketFeePer = 25;
    }

    /// @notice 승인된 토큰 컨트랙트만 사용 가능하도록 하는 modifier
    modifier onlyApprovedToken(address tokenAddress) {
        require(approvalContract[tokenAddress], "Not approved address");
        _;
    }

    /// @notice 아이템 소유자만 접근 가능하도록 하는 modifier
    modifier onlyItemOwner(uint128 itemId) {
        require(items[itemId].owner == _msgSender(), "Not owner");
        _;
    }

    /// @notice 마켓플레이스에 아이템을 등록하는 함수
    function listItem(
        address tokenAddress,
        uint256 tokenId,
        uint96 endTime,
        uint256 price,
        uint256 quantity,
        bool isERC721
    ) external onlyApprovedToken(tokenAddress) {
        require(price > 0 && quantity > 0 && (!isERC721 || quantity == 1), "Invalid parameters");
        require(!listedInMarket[tokenAddress][tokenId], "Already listed");

        IToken tokenContract = IToken(tokenAddress);
        if(isERC721) {
            require(tokenContract.ownerOf(tokenId) == _msgSender(), "Not owner");
        } else {
            require(tokenContract.balanceOf(_msgSender(), tokenId) >= quantity, "Insufficient balance");
        }
        require(tokenContract.isApprovedForAll(_msgSender(), address(this)), "Not approved");

        unchecked {
            _saleIds++;
        }

        items[_saleIds] = MarketItem({
            itemId: _saleIds,
            owner: _msgSender(),
            tokenAddress: tokenAddress,
            tokenId: tokenId,
            price: price,
            startTime: uint96(block.timestamp),
            endTime: uint96(block.timestamp + endTime),
            quantity: quantity,
            sold: false,
            cancel: false,
            isERC721: isERC721
        });

        listedInMarket[tokenAddress][tokenId] = true;
        tokenToItemId[tokenAddress][tokenId] = _saleIds;

        emit MarketItemListed(_saleIds, tokenAddress, tokenId, _msgSender(), price, quantity, isERC721);
    }

    /// @notice 등록된 아이템을 취소하는 함수
    function unlistItem(uint128 itemId) external onlyItemOwner(itemId) {
        MarketItem storage item = items[itemId];
        require(!item.sold && !item.cancel, "Invalid item state");
        
        item.cancel = true;
        listedInMarket[item.tokenAddress][item.tokenId] = false;
        tokenToItemId[item.tokenAddress][item.tokenId] = 0;

        emit MarketItemDelisted(itemId, item.tokenId, _msgSender(), item.price);
    }

    /// @notice 등록된 아이템을 구매하는 함수
    function buyItem(uint128 itemId, uint256 quantity) external {
        require(getSaleStatus(itemId) == "ACTIVE", "Not Active");

        MarketItem storage item = items[itemId];
        require(!item.sold && !item.cancel && item.quantity >= quantity, "Invalid purchase");

        uint256 totalPrice = item.price * quantity;
        require(paymentToken.balanceOf(_msgSender()) >= totalPrice, "Insufficient funds");
        require(paymentToken.allowance(_msgSender(), address(this)) >= totalPrice, "Insufficient allowance");

        (uint256 fee, uint256 sellerProceeds) = _calculateFee(totalPrice);

        unchecked {
            item.quantity -= quantity;
            if(item.quantity == 0) {
                item.sold = true;
                _saleSold++;
            }
        }

        listedInMarket[item.tokenAddress][item.tokenId] = false;
        tokenToItemId[item.tokenAddress][item.tokenId] = 0;

        if(item.isERC721) IToken(item.tokenAddress).safeTransferFrom(item.owner, _msgSender(), item.tokenId, "");
        else IToken(item.tokenAddress).safeTransferFrom(item.owner, _msgSender(), item.tokenId, quantity, "");

        require(paymentToken.transferFrom(_msgSender(), address(this), totalPrice), "Transfer failed");
        
        unchecked {
            claimableFunds[owner()] += fee;
            claimableFunds[item.owner] += sellerProceeds;
        }

        emit MarketItemBought(itemId, item.tokenAddress, item.tokenId, item.owner, _msgSender(), item.price, quantity);
    }

    /// @notice ERC721 토큰을 경매에 등록하는 함수
    function listAuction(
        address tokenAddress,
        uint256 tokenId,
        uint96 endTime,
        uint256 reservePrice
    ) external onlyApprovedToken(tokenAddress) {
        require(reservePrice > 0, "Invalid price");
        require(!listedInAuction[tokenAddress][tokenId], "Already listed");

        IToken tokenContract = IToken(tokenAddress);
        require(tokenContract.ownerOf(tokenId) == _msgSender(), "Not owner");
        require(tokenContract.isApprovedForAll(_msgSender(), address(this)), "Not approved");

        unchecked {
            _auctionIds++;
        }

        auctionItems[_auctionIds] = AuctionItem({
            itemId: _auctionIds,
            owner: _msgSender(),
            tokenAddress: tokenAddress,
            tokenId: tokenId,
            reservePrice: reservePrice,
            startTime: uint96(block.timestamp),
            endTime: uint96(block.timestamp + endTime),
            sold: false,
            cancel: false
        });

        listedInAuction[tokenAddress][tokenId] = true;
        tokenToAuctionId[tokenAddress][tokenId] = _auctionIds;

        emit AuctionListed(_auctionIds, tokenAddress, tokenId, _msgSender(), reservePrice, uint96(block.timestamp), uint96(block.timestamp + endTime));
    }

    /// @notice 경매에 입찰하는 함수
    function bid(uint128 auctionId, uint256 price) external {
        require(getAuctionStatus(auctionId) == "ACTIVE", "Not Active");
        AuctionItem storage auction = auctionItems[auctionId];
        
        address lastHighestBidder = highestBidder[auctionId];
        uint256 lastHighestPrice = bids[auctionId][lastHighestBidder].price;

        require(_msgSender() != lastHighestBidder && _msgSender() != auction.owner, "Invalid bidder");
        require(price > lastHighestPrice && price >= auction.reservePrice, "Invalid price");

        require(paymentToken.transferFrom(_msgSender(), address(this), price), "Transfer failed");

        if(lastHighestBidder != address(0)) {
            unchecked {
                claimableFunds[lastHighestBidder] += lastHighestPrice;
            }
            delete bids[auctionId][lastHighestBidder];
        }

        bids[auctionId][_msgSender()] = Bid({
            price: price,
            timestamp: uint96(block.timestamp)
        });
        highestBidder[auctionId] = _msgSender();

        emit AuctionBid(auctionId, price, uint96(block.timestamp));
    }

    /// @notice 경매를 종료하고 결과를 처리하는 함수
    function resolveAuction(uint128 auctionId) external {
        require(!claimed[auctionId], "Already claimed");
        
        bytes32 status = getAuctionStatus(auctionId);
        require(status == "CANCELED" || status == "ENDED", "Still active");

        AuctionItem storage auction = auctionItems[auctionId];
        address winner = highestBidder[auctionId];
        uint256 winningBid = bids[auctionId][winner].price;

        claimed[auctionId] = true;
        listedInAuction[auction.tokenAddress][auction.tokenId] = false;
        tokenToAuctionId[auction.tokenAddress][auction.tokenId] = 0;

        if (status == "CANCELED" || (status == "ENDED" && winner == address(0))) {
            auction.cancel = true;
        } else {
            (uint256 fee, uint256 sellerProceeds) = _calculateFee(winningBid);
            
            auction.sold = true;
            IToken(auction.tokenAddress).safeTransferFrom(auction.owner, winner, auction.tokenId, "");
            
            unchecked {
                claimableFunds[owner()] += fee;
                claimableFunds[auction.owner] += sellerProceeds;
                _auctionItemsSold++;
            }
        }
    }

    /// @notice 사용자가 받을 수 있는 자금을 인출하는 함수
    function withdrawFunds() external {
        uint256 funds = claimableFunds[_msgSender()];
        require(funds > 0, "No funds");

        claimableFunds[_msgSender()] = 0;
        require(paymentToken.transfer(_msgSender(), funds), "Transfer failed");
    }

    /// @notice 경매를 취소하는 함수
    function cancelAuction(uint128 auctionId) external {
        AuctionItem storage auction = auctionItems[auctionId];
        require(_msgSender() == auction.owner || _msgSender() == owner(), "Not authorized");
        require(getAuctionStatus(auctionId) == "ACTIVE", "Not active");

        address currentHighestBidder = highestBidder[auctionId];
        if(currentHighestBidder != address(0)) {
            unchecked {
                claimableFunds[currentHighestBidder] += bids[auctionId][currentHighestBidder].price;
            }
        }

        auction.cancel = true;
        listedInAuction[auction.tokenAddress][auction.tokenId] = false;
    }

    /// @notice 경매 상태를 조회하는 함수
    /// @return 경매 상태 (NOTLISTED, CANCELED, ENDED, SOLD, ACTIVE)
    function getAuctionStatus(uint128 auctionId) public view returns (bytes32) {
        AuctionItem memory auction = auctionItems[auctionId];
        return _getStatus(auction.endTime, auction.sold, auction.cancel);
    }

    /// @notice 판매 상태를 조회하는 함수
    /// @return 판매 상태 (NOTLISTED, CANCELED, ENDED, SOLD, ACTIVE)
    function getSaleStatus(uint128 saleId) public view returns (bytes32) {
        MarketItem memory item = items[saleId];
        return _getStatus(item.endTime, item.sold, item.cancel);
    }

    /// @notice 상태를 계산하는 내부 함수
    function _getStatus(uint96 endTime, bool sold, bool cancel) internal view returns(bytes32) {
        if(endTime == 0) return "NOTLISTED";
        if(cancel) return "CANCELED";
        if(block.timestamp > endTime && !sold) return "ENDED";
        if(sold) return "SOLD";
        return "ACTIVE";
    }

    /// @notice 수수료를 계산하는 내부 함수
    function _calculateFee(uint256 price) internal view returns(uint256 fee, uint256 sellerProceeds) {
        unchecked {
            fee = (price * marketFeePer) / 1000;
            sellerProceeds = price - fee;
        }
    }

    /// @notice 토큰이 마켓플레이스에 등록되어 있는지 확인하는 함수
    function getListedInMarket(address tokenAddress, uint256 tokenId) external view returns (bool) {
        return listedInMarket[tokenAddress][tokenId];
    }

    /// @notice 토큰이 경매에 등록되어 있는지 확인하는 함수
    function getListedInAuction(address tokenAddress, uint256 tokenId) external view returns (bool) {
        return listedInAuction[tokenAddress][tokenId];
    }

    /// @notice 사용자가 받을 수 있는 자금을 확인하는 함수
    function checkClaimableFunds() external view returns(uint256) {
        return claimableFunds[_msgSender()];
    }

    /// @notice 마켓플레이스 수수료율을 설정하는 함수
    function setMarketPlaceFeePer(uint96 newFee) external onlyOwner {
        marketFeePer = newFee;
    }

    /// @notice 토큰 컨트랙트를 판매 허용하는 함수
    function setApprovalAddress(address tokenAddress) external onlyOwner {
        approvalContract[tokenAddress] = true;
    }

    /// @notice 토큰 컨트랙트 판매 취소하는 함수
    function removeAddress(address tokenAddress) external onlyOwner {
        delete approvalContract[tokenAddress];
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
