// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./NFTCollectionFactory.sol";
import "./NFTCollection.sol";


// Main Marketplace Contract with Auctions and Offers
contract NFTMarketplace is ReentrancyGuard, Ownable(msg.sender) {
    using Strings for uint256;

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool isAuction;
        uint256 auctionEndTime;
        address highestBidder;
        uint256 highestBid;
        bool sold;
    }

    struct Offer {
        address buyer;
        uint256 price;
        uint256 expirationTime;
    }

    struct PriceHistory {
        uint256 timestamp;
        uint256 price;
        address seller;
        address buyer;
        PriceActionType actionType;
    }

    enum PriceActionType {
        LISTING,
        SALE,
        AUCTION_BID,
        AUCTION_END,
        OFFER_ACCEPTED
    }

    enum SaleType {
        ALL,
        FIXED_PRICE,
        AUCTION
    }

    enum SortOrder {
        PRICE_LOW_TO_HIGH,
        PRICE_HIGH_TO_LOW,
        NEWEST_FIRST,
        OLDEST_FIRST
    }

    struct TrendingStats {
        uint256 volume24h;
        uint256 volume7d;
        uint256 transactions24h;
        uint256 transactions7d;
        int256 priceChange24h; // Percentage change, multiplied by 100 for precision
        int256 priceChange7d;  // Percentage change, multiplied by 100 for precision
        uint256 lastUpdateTime;
    }

    struct TrendingScore {
        uint256 itemId;
        uint256 score;
    }

    uint256 private _itemIds;
    uint256 private _itemsSold;
    uint256 public constant AUCTION_DURATION = 7 days;
    uint256 public constant MIN_AUCTION_INCREMENT = 0.01 ether;
    uint256 public constant LISTING_PRICE = 0.0005 ether;
    address public immutable factoryAddress;

    mapping(uint256 => MarketItem) private _idToMarketItem;
    mapping(uint256 => mapping(address => uint256)) private _auctionPendingReturns;
    mapping(uint256 => Offer[]) private _itemOffers;
    mapping(uint256 => PriceHistory[]) private _itemPriceHistory;
    mapping(address => mapping(string => bool)) private _collectionFilters; 
    mapping(uint256 => TrendingStats) private _itemTrendingStats;
    mapping(address => TrendingStats) private _collectionTrendingStats;

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool isAuction,
        uint256 auctionEndTime
    );

    event AuctionBid(
        uint256 indexed itemId,
        address indexed bidder,
        uint256 bid
    );

    event AuctionEnded(
        uint256 indexed itemId,
        address winner,
        uint256 amount
    );

    event OfferCreated(
        uint256 indexed itemId,
        address indexed buyer,
        uint256 price,
        uint256 expirationTime
    );

    event OfferAccepted(
        uint256 indexed itemId,
        address indexed buyer,
        uint256 price
    );

    // Constructor
    constructor(address _factoryAddress){
        factoryAddress = _factoryAddress;
    }

    // Function to add a price history entry
    function _addPriceHistory(
        uint256 itemId,
        uint256 price,
        address seller,
        address buyer,
        PriceActionType actionType
    ) internal {
        PriceHistory memory history = PriceHistory(
            block.timestamp,
            price,
            seller,
            buyer,
            actionType
        );
        _itemPriceHistory[itemId].push(history);
    }

    // Create Market Item (Fixed Price)
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external payable nonReentrant {
        require(price > 0, "Price must be greater than 0");
        require(msg.value == LISTING_PRICE, "Must pay listing price");

        uint256 itemId = _itemIds++;

        _idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false,
            0,
            address(0),
            0,
            false
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        // Add price history for listing
        _addPriceHistory(
            itemId,
            price,
            msg.sender,
            address(0),
            PriceActionType.LISTING
        );

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false,
            0
        );
    }

    function getListingPrice() public pure returns (uint256) {
        return LISTING_PRICE;
    }

    

    // Create market sale for fixed price items
    function createMarketSale(
        address nftContract,
        uint256 itemId
    ) external payable nonReentrant {
        MarketItem storage item = _idToMarketItem[itemId];
        uint256 price = item.price;
        uint256 tokenId = item.tokenId;
        
        require(!item.isAuction, "Cannot buy auction items directly");
        require(
            msg.value == price,
            "Please submit the asking price"
        );
        require(!item.sold, "Item already sold");

        item.seller.transfer(msg.value);
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        item.owner = payable(msg.sender);
        item.sold = true;
        _itemsSold++;

        // Add price history for sale
        _addPriceHistory(
            itemId,
            price,
            item.seller,
            msg.sender,
            PriceActionType.SALE
        );
        
        payable(owner()).transfer(LISTING_PRICE);
    }


    // Fetch all unsold market items
    function fetchMarketItems() external view returns (MarketItem[] memory) {
        uint256 itemCount = _itemIds;
        uint256 unsoldItemCount = _itemIds - _itemsSold;
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        
        for (uint256 i = 0; i < itemCount; i++) {
            if (!_idToMarketItem[i].sold) {
                MarketItem storage currentItem = _idToMarketItem[i];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }
        
        return items;
    }

    // Fetch NFTs owned by msg.sender
    function fetchMyNFTs() external view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds;
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        // First, count the number of items owned by msg.sender
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (_idToMarketItem[i].owner == msg.sender) {
                itemCount++;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (_idToMarketItem[i].owner == msg.sender) {
                MarketItem storage currentItem = _idToMarketItem[i];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }
        
        return items;
    }

    // Fetch NFTs listed by msg.sender
    function fetchMyListedNFTs() external view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds;
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        // First, count the number of items listed by msg.sender
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (_idToMarketItem[i].seller == msg.sender) {
                itemCount++;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (_idToMarketItem[i].seller == msg.sender) {
                MarketItem storage currentItem = _idToMarketItem[i];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }
        
        return items;
    }

    // Advanced filtering function for market items
    function fetchMarketItemsWithFilters(
        uint256 minPrice,
        uint256 maxPrice,
        SaleType saleType,
        address nftContract,
        bool onlyVerified,
        SortOrder sortOrder,
        uint256 offset,
        uint256 limit
    ) external view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds;
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        
        // First pass: count valid items
        for (uint256 i = 0; i < totalItemCount; i++) {
            MarketItem storage item = _idToMarketItem[i];
            if (_meetsFilterCriteria(
                item,
                minPrice,
                maxPrice,
                saleType,
                nftContract,
                onlyVerified
            )) {
                itemCount++;
            }
        }
        
        // Create array of correct size
        MarketItem[] memory items = new MarketItem[](
            itemCount < limit ? itemCount : limit
        );
        
        // Second pass: populate array
        for (uint256 i = 0; i < totalItemCount && currentIndex < limit; i++) {
            MarketItem storage item = _idToMarketItem[i];
            if (_meetsFilterCriteria(
                item,
                minPrice,
                maxPrice,
                saleType,
                nftContract,
                onlyVerified
            )) {
                if (currentIndex >= offset) {
                    items[currentIndex - offset] = item;
                }
                currentIndex++;
            }
        }
        
        // Sort items based on sortOrder
        _sortItems(items, sortOrder);
        
        return items;
    }

    // Helper function for filtering
    function _meetsFilterCriteria(
        MarketItem memory item,
        uint256 minPrice,
        uint256 maxPrice,
        SaleType saleType,
        address nftContract,
        bool onlyVerified
    ) private view returns (bool) {
        if (item.sold) {
            return false;
        }
        
        if (minPrice > 0 && item.price < minPrice) {
            return false;
        }
        
        if (maxPrice > 0 && item.price > maxPrice) {
            return false;
        }
        
        if (saleType == SaleType.FIXED_PRICE && item.isAuction) {
            return false;
        }
        
        if (saleType == SaleType.AUCTION && !item.isAuction) {
            return false;
        }
        
        if (nftContract != address(0) && item.nftContract != nftContract) {
            return false;
        }
        
        if (onlyVerified) {
            NFTCollectionFactory factory = NFTCollectionFactory(factoryAddress);
            (
                string memory name,
                string memory symbol,
                address collectionAddress,
                address creator,
                bool isVerified
            ) = factory.collections(item.nftContract);
            if (!isVerified) {
                return false;
            }
        }
        
        return true;
    }

    // Helper function to sort items
    function _sortItems(MarketItem[] memory items, SortOrder sortOrder) private pure {
        uint256 length = items.length;
        for (uint256 i = 0; i < length - 1; i++) {
            for (uint256 j = 0; j < length - i - 1; j++) {
                bool shouldSwap;
                if (sortOrder == SortOrder.PRICE_LOW_TO_HIGH) {
                    shouldSwap = items[j].price > items[j + 1].price;
                } else if (sortOrder == SortOrder.PRICE_HIGH_TO_LOW) {
                    shouldSwap = items[j].price < items[j + 1].price;
                } else if (sortOrder == SortOrder.NEWEST_FIRST) {
                    shouldSwap = items[j].auctionEndTime < items[j + 1].auctionEndTime;
                } else {
                    shouldSwap = items[j].auctionEndTime > items[j + 1].auctionEndTime;
                }
                
                if (shouldSwap) {
                    MarketItem memory temp = items[j];
                    items[j] = items[j + 1];
                    items[j + 1] = temp;
                }
            }
        }
    }

    // Fetch price history for an item
    function fetchPriceHistory(uint256 itemId) 
        external 
        view 
        returns (PriceHistory[] memory) 
    {
        return _itemPriceHistory[itemId];
    }

    // Get price statistics for an item
    function getItemPriceStats(uint256 itemId)
        external
        view
        returns (
            uint256 lowestPrice,
            uint256 highestPrice,
            uint256 averagePrice,
            uint256 totalSales
        )
    {
        PriceHistory[] memory history = _itemPriceHistory[itemId];
        uint256 total = 0;
        uint256 salesCount = 0;
        lowestPrice = type(uint256).max;
        highestPrice = 0;
        
        for (uint256 i = 0; i < history.length; i++) {
            // Only consider actual sales, not listings
            if (history[i].actionType == PriceActionType.SALE ||
                history[i].actionType == PriceActionType.AUCTION_END ||
                history[i].actionType == PriceActionType.OFFER_ACCEPTED) {
                uint256 price = history[i].price;
                if (price < lowestPrice) {
                    lowestPrice = price;
                }
                if (price > highestPrice) {
                    highestPrice = price;
                }
                total += price;
                salesCount++;
            }
        }
        
        averagePrice = salesCount > 0 ? total / salesCount : 0;
        totalSales = salesCount;
        
        if (lowestPrice == type(uint256).max) {
            lowestPrice = 0;
        }
    }

    

    // Create Auction
    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startingPrice
    ) external payable nonReentrant {
        require(startingPrice > 0, "Starting price must be greater than 0");
        require(msg.value == LISTING_PRICE, "Must pay listing price");

        uint256 itemId = _itemIds++;
        uint256 auctionEnd = block.timestamp + AUCTION_DURATION;

        _idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            startingPrice,
            true,
            auctionEnd,
            address(0),
            0,
            false
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            startingPrice,
            true,
            auctionEnd
        );
    }

    // Place Bid
    function placeBid(uint256 itemId) external payable nonReentrant {
        MarketItem storage item = _idToMarketItem[itemId];
        require(item.isAuction, "Item is not an auction");
        require(block.timestamp < item.auctionEndTime, "Auction ended");
        require(
            msg.value >= item.price + MIN_AUCTION_INCREMENT,
            "Bid too low"
        );

        if (item.highestBidder != address(0)) {
            _auctionPendingReturns[itemId][item.highestBidder] += item.highestBid;
        }

        item.highestBidder = msg.sender;
        item.highestBid = msg.value;

        // Add price history for bid
        _addPriceHistory(
            itemId,
            msg.value,
            item.seller,
            msg.sender,
            PriceActionType.AUCTION_BID
        );

        emit AuctionBid(itemId, msg.sender, msg.value);
    }

    // End Auction
    function endAuction(uint256 itemId) external nonReentrant {
        MarketItem storage item = _idToMarketItem[itemId];
        require(item.isAuction, "Not an auction");
        require(block.timestamp >= item.auctionEndTime, "Auction not ended");
        require(!item.sold, "Auction already ended");

        item.sold = true;
        item.owner = payable(item.highestBidder);
        _itemsSold++;

        if (item.highestBidder != address(0)) {
            item.seller.transfer(item.highestBid);
            IERC721(item.nftContract).transferFrom(
                address(this),
                item.highestBidder,
                item.tokenId
            );
        } else {
            IERC721(item.nftContract).transferFrom(
                address(this),
                item.seller,
                item.tokenId
            );
        }

        payable(owner()).transfer(LISTING_PRICE);

        emit AuctionEnded(itemId, item.highestBidder, item.highestBid);
    }

    // Withdraw Bid
    function withdrawBid(uint256 itemId) external nonReentrant {
        uint256 amount = _auctionPendingReturns[itemId][msg.sender];
        require(amount > 0, "No funds to withdraw");

        _auctionPendingReturns[itemId][msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    // Make Offer
    function makeOffer(uint256 itemId, uint256 expirationTime) 
        external 
        payable 
        nonReentrant 
    {
        require(msg.value > 0, "Offer must be greater than 0");
        require(
            expirationTime > block.timestamp,
            "Expiration must be in future"
        );

        MarketItem storage item = _idToMarketItem[itemId];
        require(!item.sold, "Item already sold");
        require(!item.isAuction, "Cannot make offers on auctions");

        Offer memory newOffer = Offer(
            msg.sender,
            msg.value,
            expirationTime
        );
        _itemOffers[itemId].push(newOffer);

        emit OfferCreated(
            itemId,
            msg.sender,
            msg.value,
            expirationTime
        );
    }

    // Accept Offer
    function acceptOffer(uint256 itemId, uint256 offerIndex) 
        external 
        nonReentrant 
    {
        MarketItem storage item = _idToMarketItem[itemId];
        require(msg.sender == item.seller, "Only seller can accept");
        require(!item.sold, "Item already sold");

        Offer memory offer = _itemOffers[itemId][offerIndex];
        require(
            block.timestamp <= offer.expirationTime,
            "Offer expired"
        );

        item.sold = true;
        item.owner = payable(offer.buyer);
        _itemsSold++;

        // Transfer NFT to buyer
        IERC721(item.nftContract).transferFrom(
            address(this),
            offer.buyer,
            item.tokenId
        );

        // Transfer payment to seller
        payable(item.seller).transfer(offer.price);
        payable(owner()).transfer(LISTING_PRICE);

        // Refund other offers
        for (uint i = 0; i < _itemOffers[itemId].length; i++) {
            if (i != offerIndex && 
                block.timestamp <= _itemOffers[itemId][i].expirationTime) {
                payable(_itemOffers[itemId][i].buyer).transfer(
                    _itemOffers[itemId][i].price
                );
            }
        }

        emit OfferAccepted(itemId, offer.buyer, offer.price);
    }

    // View Functions
    function fetchMarketItem(uint256 itemId) 
        external 
        view 
        returns (MarketItem memory) 
    {
        return _idToMarketItem[itemId];
    }

    function fetchItemOffers(uint256 itemId)
        external
        view
        returns (Offer[] memory)
    {
        return _itemOffers[itemId];
    }

    function fetchActiveAuctions() 
        external 
        view 
        returns (MarketItem[] memory) 
    {
        uint256 itemCount = _itemIds;
        uint256 activeCount = 0;
        
        for (uint256 i = 0; i < itemCount; i++) {
            if (_idToMarketItem[i].isAuction && 
                !_idToMarketItem[i].sold &&
                block.timestamp < _idToMarketItem[i].auctionEndTime) {
                activeCount++;
            }
        }

        MarketItem[] memory items = new MarketItem[](activeCount);
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < itemCount; i++) {
            if (_idToMarketItem[i].isAuction && 
                !_idToMarketItem[i].sold &&
                block.timestamp < _idToMarketItem[i].auctionEndTime) {
                items[currentIndex] = _idToMarketItem[i];
                currentIndex++;
            }
        }
        return items;
    }

    function updateTrendingStats(uint256 itemId, uint256 price) internal {
        TrendingStats storage stats = _itemTrendingStats[itemId];
        uint256 currentTime = block.timestamp;
        
        // Update 24h stats
        if (currentTime - stats.lastUpdateTime <= 1 days) {
            stats.volume24h += price;
            stats.transactions24h++;
            
            // Calculate price change
            PriceHistory[] memory history = _itemPriceHistory[itemId];
            if (history.length >= 2) {
                uint256 oldPrice = _findPriceAtTime(history, currentTime - 1 days);
                if (oldPrice > 0) {
                    stats.priceChange24h = int256(((price - oldPrice) * 10000) / oldPrice);
                }
            }
        } else {
            // Reset 24h stats
            stats.volume24h = price;
            stats.transactions24h = 1;
        }
        
        // Update 7d stats
        if (currentTime - stats.lastUpdateTime <= 7 days) {
            stats.volume7d += price;
            stats.transactions7d++;
            
            // Calculate price change
            PriceHistory[] memory history = _itemPriceHistory[itemId];
            if (history.length >= 2) {
                uint256 oldPrice = _findPriceAtTime(history, currentTime - 7 days);
                if (oldPrice > 0) {
                    stats.priceChange7d = int256(((price - oldPrice) * 10000) / oldPrice);
                }
            }
        } else {
            // Reset 7d stats
            stats.volume7d = price;
            stats.transactions7d = 1;
        }
        
        stats.lastUpdateTime = currentTime;
        
        // Update collection stats
        address collection = _idToMarketItem[itemId].nftContract;
        _updateCollectionStats(collection, price);
    }

    function _findPriceAtTime(PriceHistory[] memory history, uint256 targetTime) 
        private 
        pure 
        returns (uint256) 
    {
        for (uint256 i = history.length; i > 0; i--) {
            if (history[i-1].timestamp <= targetTime) {
                return history[i-1].price;
            }
        }
        return 0;
    }

    function _updateCollectionStats(address collection, uint256 price) private {
        TrendingStats storage stats = _collectionTrendingStats[collection];
        uint256 currentTime = block.timestamp;
        
        if (currentTime - stats.lastUpdateTime <= 1 days) {
            stats.volume24h += price;
            stats.transactions24h++;
        } else {
            stats.volume24h = price;
            stats.transactions24h = 1;
        }
        
        if (currentTime - stats.lastUpdateTime <= 7 days) {
            stats.volume7d += price;
            stats.transactions7d++;
        } else {
            stats.volume7d = price;
            stats.transactions7d = 1;
        }
        
        stats.lastUpdateTime = currentTime;
    }

    function _calculateTrendingScore(uint256 itemId) private view returns (uint256) {
        TrendingStats memory stats = _itemTrendingStats[itemId];
        
        // Weights for different metrics (adjust these based on your preferences)
        uint256 VOLUME_24H_WEIGHT = 40;
        uint256 VOLUME_7D_WEIGHT = 20;
        uint256 TRANSACTIONS_24H_WEIGHT = 20;
        uint256 TRANSACTIONS_7D_WEIGHT = 10;
        uint256 PRICE_CHANGE_WEIGHT = 10;
        
        // Calculate score components
        uint256 volumeScore = (stats.volume24h * VOLUME_24H_WEIGHT / 1 ether) +
                            (stats.volume7d * VOLUME_7D_WEIGHT / 1 ether);
                            
        uint256 transactionScore = (stats.transactions24h * TRANSACTIONS_24H_WEIGHT) +
                                (stats.transactions7d * TRANSACTIONS_7D_WEIGHT);
                                
        uint256 priceChangeScore;
        if (stats.priceChange24h > 0) {
            priceChangeScore = uint256(stats.priceChange24h) * PRICE_CHANGE_WEIGHT;
        }
        
        return volumeScore + transactionScore + priceChangeScore;
    }

    function getTrendingItems(uint256 limit) 
        external 
        view 
        returns (MarketItem[] memory) 
    {
        require(limit > 0 && limit <= 100, "Invalid limit");
        
        // Create array of all items with their scores
        uint256 totalItems = _itemIds;
        TrendingScore[] memory scores = new TrendingScore[](totalItems);
        uint256 activeItems = 0;
        
        for (uint256 i = 0; i < totalItems; i++) {
            if (!_idToMarketItem[i].sold) {
                scores[activeItems] = TrendingScore(
                    i,
                    _calculateTrendingScore(i)
                );
                activeItems++;
            }
        }
        
        // Sort items by score (bubble sort for simplicity)
        for (uint256 i = 0; i < activeItems - 1; i++) {
            for (uint256 j = 0; j < activeItems - i - 1; j++) {
                if (scores[j].score < scores[j + 1].score) {
                    TrendingScore memory temp = scores[j];
                    scores[j] = scores[j + 1];
                    scores[j + 1] = temp;
                }
            }
        }
        
        // Return top N items
        uint256 resultCount = limit > activeItems ? activeItems : limit;
        MarketItem[] memory trendingItems = new MarketItem[](resultCount);
        
        for (uint256 i = 0; i < resultCount; i++) {
            trendingItems[i] = _idToMarketItem[scores[i].itemId];
        }
        
        return trendingItems;
    }

    function getItemTrendingStats(uint256 itemId) 
        external 
        view 
        returns (TrendingStats memory) 
    {
        return _itemTrendingStats[itemId];
    }

    function getCollectionTrendingStats(address collection) 
        external 
        view 
        returns (TrendingStats memory) 
    {
        return _collectionTrendingStats[collection];
    }       
}

