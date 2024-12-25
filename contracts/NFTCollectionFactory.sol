// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./NFTCollection.sol";
import "./CategoryLib.sol";
import "./StatsLib.sol";

contract NFTCollectionFactory is Ownable {
    using CategoryLib for CategoryLib.CategoryStorage;
    using StatsLib for StatsLib.CollectionStats;

    struct Collection {
        string name;
        string symbol;
        address collectionAddress;
        address creator;
        bool isVerified;
        uint256 floorPrice;
        uint256 totalVolume;
        uint256 totalSales;
        string category;
    }

    CategoryLib.CategoryStorage internal categoryStorage;
    mapping(address => StatsLib.CollectionStats) public collectionStats;
    mapping(address => Collection) public collections;
    mapping(address => address[]) public creatorCollections;

    address[] public allCollections;
    address public marketplaceAddress;

    error InvalidMarketplace();
    error OnlyMarketplace();
    error InvalidLimit();
    error InvalidAddress();

    event MarketplaceAddressUpdated(address indexed newMarketplace);
    event CollectionCreated(
        address indexed collectionAddress,
        string name,
        string symbol,
        address indexed creator,
        string category
    );
    event CollectionVerified(address indexed collectionAddress);
    event CollectionStatsUpdated(
        address indexed collectionAddress,
        uint256 floorPrice,
        uint256 volume24h,
        uint256 sales24h
    );
    event CategoryAdded(string category);
    event CategoryRemoved(string category);

    constructor() Ownable(msg.sender) {
        _initializeDefaultCategories();
    }

    function _initializeDefaultCategories() private {
        string[4] memory defaults = ["art", "gaming", "music", "sports"];
        for (uint i = 0; i < defaults.length; i++) {
            categoryStorage.addCategory(defaults[i]);
            emit CategoryAdded(defaults[i]);
        }
    }

    function setMarketplaceAddress(
        address _marketplaceAddress
    ) external onlyOwner {
        if (_marketplaceAddress == address(0)) revert InvalidMarketplace();
        marketplaceAddress = _marketplaceAddress;
        emit MarketplaceAddressUpdated(_marketplaceAddress);
    }

    function addCategory(string calldata category) external onlyOwner {
        categoryStorage.addCategory(category);
        emit CategoryAdded(category);
    }

    function removeCategory(string calldata category) external onlyOwner {
        categoryStorage.removeCategory(category);
        emit CategoryRemoved(category);
    }

    function createCollection(
        string calldata name,
        string calldata symbol,
        string calldata category,
        string calldata collectionURI
    ) external returns (address) {
        NFTCollection newCollection = new NFTCollection(
            name,
            symbol,
            msg.sender,
            collectionURI
        );
        address collectionAddress = address(newCollection);

        collections[collectionAddress] = Collection({
            name: name,
            symbol: symbol,
            collectionAddress: collectionAddress,
            creator: msg.sender,
            isVerified: false,
            category: category,
            floorPrice: 0,
            totalVolume: 0,
            totalSales: 0
        });

        collectionStats[collectionAddress].lastUpdateTime24h = block.timestamp;
        collectionStats[collectionAddress].lastUpdateTime7d = block.timestamp;

        creatorCollections[msg.sender].push(collectionAddress);
        allCollections.push(collectionAddress);
        categoryStorage.addCollectionToCategory(category, collectionAddress);

        emit CollectionCreated(
            collectionAddress,
            name,
            symbol,
            msg.sender,
            category
        );
        return collectionAddress;
    }

    function getCollectionsByCategory(
        string calldata category
    ) external view returns (Collection[] memory) {
        address[] storage categoryAddresses = categoryStorage
            .categoryCollections[category];
        Collection[] memory result = new Collection[](categoryAddresses.length);

        for (uint256 i = 0; i < categoryAddresses.length; i++) {
            result[i] = collections[categoryAddresses[i]];
        }

        return result;
    }

    function getTrendingCollectionsByCategory(
        string calldata category,
        uint256 limit
    ) external view returns (Collection[] memory) {
        if (limit == 0 || limit > 100) revert InvalidLimit();

        address[] storage categoryAddresses = categoryStorage
            .categoryCollections[category];
        uint256 resultCount = limit > categoryAddresses.length
            ? categoryAddresses.length
            : limit;
        Collection[] memory result = new Collection[](resultCount);

        // Create memory arrays for sorting
        uint256[] memory volumes = new uint256[](categoryAddresses.length);
        uint256[] memory indices = new uint256[](categoryAddresses.length);

        // Initialize arrays
        for (uint256 i = 0; i < categoryAddresses.length; i++) {
            volumes[i] = collectionStats[categoryAddresses[i]].volume24h;
            indices[i] = i;
        }

        // Sort indices by volume
        for (uint256 i = 0; i < resultCount; i++) {
            for (uint256 j = i + 1; j < categoryAddresses.length; j++) {
                if (volumes[indices[i]] < volumes[indices[j]]) {
                    (indices[i], indices[j]) = (indices[j], indices[i]);
                }
            }
            result[i] = collections[categoryAddresses[indices[i]]];
        }

        return result;
    }

    function updateCollectionStats(
        address collectionAddress,
        uint256 price,
        bool isSale
    ) external {
        if (msg.sender != marketplaceAddress) revert OnlyMarketplace();

        Collection storage collection = collections[collectionAddress];
        StatsLib.CollectionStats storage stats = collectionStats[
            collectionAddress
        ];

        if (price < collection.floorPrice || collection.floorPrice == 0) {
            collection.floorPrice = price;
        }

        if (isSale) {
            collection.totalVolume += price;
            collection.totalSales++;
            stats.updateStats(price, block.timestamp);

            emit CollectionStatsUpdated(
                collectionAddress,
                collection.floorPrice,
                stats.volume24h,
                stats.sales24h
            );
        }
    }

    function getValidCategories() external view returns (string[] memory) {
        return categoryStorage.getValidCategories();
    }

    // Remaining view functions
    function getAllCollections()
        external
        view
        returns (Collection[] memory result)
    {
        result = new Collection[](allCollections.length);
        for (uint256 i = 0; i < allCollections.length; i++) {
            result[i] = collections[allCollections[i]];
        }
    }

    function getCreatorCollections(
        address creator
    ) external view returns (Collection[] memory result) {
        if (creator == address(0)) revert InvalidAddress();
        address[] storage creatorAddrs = creatorCollections[creator];
        result = new Collection[](creatorAddrs.length);

        for (uint256 i = 0; i < creatorAddrs.length; i++) {
            result[i] = collections[creatorAddrs[i]];
        }
    }

    function verifyCollection(address collectionAddress) external onlyOwner {
        if (collectionAddress == address(0)) revert InvalidAddress();
        collections[collectionAddress].isVerified = true;
        emit CollectionVerified(collectionAddress);
    }
}

// contract NFTMarketplace is ReentrancyGuard, Ownable(msg.sender) {
//     using Strings for uint256;

//     struct MarketItem {
//         uint256 itemId;
//         address nftContract;
//         uint256 tokenId;
//         address payable seller;
//         address payable owner;
//         uint256 price;
//         bool isAuction;
//         uint256 auctionEndTime;
//         address highestBidder;
//         uint256 highestBid;
//         bool sold;
//     }

//     struct Offer {
//         address buyer;
//         uint256 price;
//         uint256 expirationTime;
//     }

//     struct PriceHistory {
//         uint256 timestamp;
//         uint256 price;
//         address seller;
//         address buyer;
//         PriceActionType actionType;
//     }

//     enum PriceActionType {
//         LISTING,
//         SALE,
//         AUCTION_BID,
//         AUCTION_END,
//         OFFER_ACCEPTED
//     }

//     enum SaleType {
//         ALL,
//         FIXED_PRICE,
//         AUCTION
//     }

//     enum SortOrder {
//         PRICE_LOW_TO_HIGH,
//         PRICE_HIGH_TO_LOW,
//         NEWEST_FIRST,
//         OLDEST_FIRST
//     }

//     uint256 private _itemIds;
//     uint256 private _itemsSold;
//     uint256 public constant AUCTION_DURATION = 7 days;
//     uint256 public constant MIN_AUCTION_INCREMENT = 0.01 ether;
//     uint256 public constant LISTING_PRICE = 0.0005 ether;
//     address public immutable factoryAddress;

//     mapping(uint256 => MarketItem) private _idToMarketItem;
//     mapping(uint256 => mapping(address => uint256))
//         private _auctionPendingReturns;
//     mapping(uint256 => Offer[]) private _itemOffers;
//     mapping(uint256 => PriceHistory[]) private _itemPriceHistory;

//     event MarketItemCreated(
//         uint256 indexed itemId,
//         address indexed nftContract,
//         uint256 indexed tokenId,
//         address seller,
//         address owner,
//         uint256 price,
//         bool isAuction,
//         uint256 auctionEndTime
//     );

//     event AuctionBid(
//         uint256 indexed itemId,
//         address indexed bidder,
//         uint256 bid
//     );

//     event AuctionEnded(uint256 indexed itemId, address winner, uint256 amount);

//     event OfferCreated(
//         uint256 indexed itemId,
//         address indexed buyer,
//         uint256 price,
//         uint256 expirationTime
//     );

//     event OfferAccepted(
//         uint256 indexed itemId,
//         address indexed buyer,
//         uint256 price
//     );

//     // Constructor
//     constructor(address _factoryAddress) {
//         factoryAddress = _factoryAddress;
//     }

//     // Function to add a price history entry
//     function _addPriceHistory(
//         uint256 itemId,
//         uint256 price,
//         address seller,
//         address buyer,
//         PriceActionType actionType
//     ) internal {
//         PriceHistory memory history = PriceHistory(
//             block.timestamp,
//             price,
//             seller,
//             buyer,
//             actionType
//         );
//         _itemPriceHistory[itemId].push(history);
//     }

//     // Create Market Item (Fixed Price)
//     function createMarketItem(
//         address collectionAddress,
//         uint256 tokenId,
//         uint256 price
//     ) external payable nonReentrant {
//         require(price > 0, "Price must be greater than 0");
//         console.log(msg.value);
//         require(msg.value == LISTING_PRICE, "Must pay listing price");

//         // Verify collection exists
//         NFTCollectionFactory factory = NFTCollectionFactory(factoryAddress);
//         (, , address nftContract, , , , , , ) = factory.collections(
//             collectionAddress
//         );

//         require(nftContract != address(0), "Collection does not exist");

//         // NFTCollection collection = NFTCollection(collectionAddress);

//         // collection.approveMarketplace(address(this));

//         console.log("collection");

//         // uint256 tokenId = collection.mint(tokenURI);

//         uint256 itemId = _itemIds++;

//         _idToMarketItem[itemId] = MarketItem(
//             itemId,
//             collectionAddress,
//             tokenId,
//             payable(msg.sender),
//             payable(address(0)),
//             price,
//             false,
//             0,
//             address(0),
//             0,
//             false
//         );

//         IERC721(collectionAddress).transferFrom(
//             msg.sender,
//             address(this),
//             tokenId
//         );
//         factory.updateCollectionStats(collectionAddress, price, false);

//         // Add price history for listing
//         _addPriceHistory(
//             itemId,
//             price,
//             msg.sender,
//             address(0),
//             PriceActionType.LISTING
//         );

//         emit MarketItemCreated(
//             itemId,
//             nftContract,
//             tokenId,
//             msg.sender,
//             address(0),
//             price,
//             false,
//             0
//         );
//     }

//     function getListingPrice() public pure returns (uint256) {
//         return LISTING_PRICE;
//     }

//     // Create market sale for fixed price items
//     function createMarketSale(
//         address collectionAddress,
//         uint256 itemId
//     ) external payable nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         uint256 price = item.price;
//         uint256 tokenId = item.tokenId;

//         require(!item.isAuction, "Cannot buy auction items directly");
//         require(msg.value == price, "Please submit the asking price");
//         require(!item.sold, "Item already sold");

//         item.seller.transfer(msg.value);
//         IERC721(collectionAddress).transferFrom(
//             address(this),
//             msg.sender,
//             tokenId
//         );
//         item.owner = payable(msg.sender);
//         item.sold = true;
//         _itemsSold++;

//         // Update collection stats
//         NFTCollectionFactory(factoryAddress).updateCollectionStats(
//             collectionAddress,
//             price,
//             true
//         );

//         // Add price history for sale
//         _addPriceHistory(
//             itemId,
//             price,
//             item.seller,
//             msg.sender,
//             PriceActionType.SALE
//         );

//         payable(owner()).transfer(LISTING_PRICE);
//     }

//     // Fetch all unsold market items
//     function fetchMarketItems() external view returns (MarketItem[] memory) {
//         uint256 itemCount = _itemIds;
//         uint256 unsoldItemCount = _itemIds - _itemsSold;
//         uint256 currentIndex = 0;

//         MarketItem[] memory items = new MarketItem[](unsoldItemCount);

//         for (uint256 i = 0; i < itemCount; i++) {
//             if (!_idToMarketItem[i].sold) {
//                 MarketItem storage currentItem = _idToMarketItem[i];
//                 items[currentIndex] = currentItem;
//                 currentIndex++;
//             }
//         }

//         return items;
//     }

//     // Fetch NFTs owned by msg.sender
//     function fetchMyNFTs() external view returns (MarketItem[] memory) {
//         uint256 totalItemCount = _itemIds;
//         uint256 itemCount = 0;
//         uint256 currentIndex = 0;

//         // First, count the number of items owned by msg.sender
//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].owner == msg.sender) {
//                 itemCount++;
//             }
//         }

//         MarketItem[] memory items = new MarketItem[](itemCount);

//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].owner == msg.sender) {
//                 MarketItem storage currentItem = _idToMarketItem[i];
//                 items[currentIndex] = currentItem;
//                 currentIndex++;
//             }
//         }

//         return items;
//     }

//     // Fetch NFTs listed by msg.sender
//     function fetchMyListedNFTs() external view returns (MarketItem[] memory) {
//         uint256 totalItemCount = _itemIds;
//         uint256 itemCount = 0;
//         uint256 currentIndex = 0;

//         // First, count the number of items listed by msg.sender
//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].seller == msg.sender) {
//                 itemCount++;
//             }
//         }

//         MarketItem[] memory items = new MarketItem[](itemCount);

//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].seller == msg.sender) {
//                 MarketItem storage currentItem = _idToMarketItem[i];
//                 items[currentIndex] = currentItem;
//                 currentIndex++;
//             }
//         }

//         return items;
//     }

//     // Fetch price history for an item
//     function fetchPriceHistory(
//         uint256 itemId
//     ) external view returns (PriceHistory[] memory) {
//         return _itemPriceHistory[itemId];
//     }

//     // Get price statistics for an item
//     function getItemPriceStats(
//         uint256 itemId
//     )
//         external
//         view
//         returns (
//             uint256 lowestPrice,
//             uint256 highestPrice,
//             uint256 averagePrice,
//             uint256 totalSales
//         )
//     {
//         PriceHistory[] memory history = _itemPriceHistory[itemId];
//         uint256 total = 0;
//         uint256 salesCount = 0;
//         lowestPrice = type(uint256).max;
//         highestPrice = 0;

//         for (uint256 i = 0; i < history.length; i++) {
//             // Only consider actual sales, not listings
//             if (
//                 history[i].actionType == PriceActionType.SALE ||
//                 history[i].actionType == PriceActionType.AUCTION_END ||
//                 history[i].actionType == PriceActionType.OFFER_ACCEPTED
//             ) {
//                 uint256 price = history[i].price;
//                 if (price < lowestPrice) {
//                     lowestPrice = price;
//                 }
//                 if (price > highestPrice) {
//                     highestPrice = price;
//                 }
//                 total += price;
//                 salesCount++;
//             }
//         }

//         averagePrice = salesCount > 0 ? total / salesCount : 0;
//         totalSales = salesCount;

//         if (lowestPrice == type(uint256).max) {
//             lowestPrice = 0;
//         }
//     }

//     // Create Auction
//     function createAuction(
//         address nftContract,
//         uint256 tokenId,
//         uint256 startingPrice
//     ) external payable nonReentrant {
//         require(startingPrice > 0, "Starting price must be greater than 0");
//         require(msg.value == LISTING_PRICE, "Must pay listing price");

//         uint256 itemId = _itemIds++;
//         uint256 auctionEnd = block.timestamp + AUCTION_DURATION;

//         _idToMarketItem[itemId] = MarketItem(
//             itemId,
//             nftContract,
//             tokenId,
//             payable(msg.sender),
//             payable(address(0)),
//             startingPrice,
//             true,
//             auctionEnd,
//             address(0),
//             0,
//             false
//         );

//         IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

//         emit MarketItemCreated(
//             itemId,
//             nftContract,
//             tokenId,
//             msg.sender,
//             address(0),
//             startingPrice,
//             true,
//             auctionEnd
//         );
//     }

//     // Place Bid
//     function placeBid(uint256 itemId) external payable nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         require(item.isAuction, "Item is not an auction");
//         require(block.timestamp < item.auctionEndTime, "Auction ended");
//         require(msg.value >= item.price + MIN_AUCTION_INCREMENT, "Bid too low");

//         if (item.highestBidder != address(0)) {
//             _auctionPendingReturns[itemId][item.highestBidder] += item
//                 .highestBid;
//         }

//         item.highestBidder = msg.sender;
//         item.highestBid = msg.value;

//         // Add price history for bid
//         _addPriceHistory(
//             itemId,
//             msg.value,
//             item.seller,
//             msg.sender,
//             PriceActionType.AUCTION_BID
//         );

//         emit AuctionBid(itemId, msg.sender, msg.value);
//     }

//     // End Auction
//     function endAuction(uint256 itemId) external nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         require(item.isAuction, "Not an auction");
//         require(block.timestamp >= item.auctionEndTime, "Auction not ended");
//         require(!item.sold, "Auction already ended");

//         item.sold = true;
//         item.owner = payable(item.highestBidder);
//         _itemsSold++;

//         if (item.highestBidder != address(0)) {
//             item.seller.transfer(item.highestBid);
//             IERC721(item.nftContract).transferFrom(
//                 address(this),
//                 item.highestBidder,
//                 item.tokenId
//             );
//         } else {
//             IERC721(item.nftContract).transferFrom(
//                 address(this),
//                 item.seller,
//                 item.tokenId
//             );
//         }

//         payable(owner()).transfer(LISTING_PRICE);

//         emit AuctionEnded(itemId, item.highestBidder, item.highestBid);
//     }

//     // Withdraw Bid
//     function withdrawBid(uint256 itemId) external nonReentrant {
//         uint256 amount = _auctionPendingReturns[itemId][msg.sender];
//         require(amount > 0, "No funds to withdraw");

//         _auctionPendingReturns[itemId][msg.sender] = 0;
//         payable(msg.sender).transfer(amount);
//     }

//     // Make Offer
//     function makeOffer(
//         uint256 itemId,
//         uint256 expirationTime
//     ) external payable nonReentrant {
//         require(msg.value > 0, "Offer must be greater than 0");
//         require(
//             expirationTime > block.timestamp,
//             "Expiration must be in future"
//         );

//         MarketItem storage item = _idToMarketItem[itemId];
//         require(!item.sold, "Item already sold");
//         require(!item.isAuction, "Cannot make offers on auctions");

//         Offer memory newOffer = Offer(msg.sender, msg.value, expirationTime);
//         _itemOffers[itemId].push(newOffer);

//         emit OfferCreated(itemId, msg.sender, msg.value, expirationTime);
//     }

//     // Accept Offer
//     function acceptOffer(
//         uint256 itemId,
//         uint256 offerIndex
//     ) external nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         require(msg.sender == item.seller, "Only seller can accept");
//         require(!item.sold, "Item already sold");

//         Offer memory offer = _itemOffers[itemId][offerIndex];
//         require(block.timestamp <= offer.expirationTime, "Offer expired");

//         item.sold = true;
//         item.owner = payable(offer.buyer);
//         _itemsSold++;

//         // Transfer NFT to buyer
//         IERC721(item.nftContract).transferFrom(
//             address(this),
//             offer.buyer,
//             item.tokenId
//         );

//         // Transfer payment to seller
//         payable(item.seller).transfer(offer.price);
//         payable(owner()).transfer(LISTING_PRICE);

//         // Refund other offers
//         for (uint i = 0; i < _itemOffers[itemId].length; i++) {
//             if (
//                 i != offerIndex &&
//                 block.timestamp <= _itemOffers[itemId][i].expirationTime
//             ) {
//                 payable(_itemOffers[itemId][i].buyer).transfer(
//                     _itemOffers[itemId][i].price
//                 );
//             }
//         }

//         emit OfferAccepted(itemId, offer.buyer, offer.price);
//     }

//     // View Functions
//     function fetchMarketItem(
//         uint256 itemId
//     ) external view returns (MarketItem memory) {
//         return _idToMarketItem[itemId];
//     }

//     function fetchItemOffers(
//         uint256 itemId
//     ) external view returns (Offer[] memory) {
//         return _itemOffers[itemId];
//     }

//     function fetchActiveAuctions() external view returns (MarketItem[] memory) {
//         uint256 itemCount = _itemIds;
//         uint256 activeCount = 0;

//         for (uint256 i = 0; i < itemCount; i++) {
//             if (
//                 _idToMarketItem[i].isAuction &&
//                 !_idToMarketItem[i].sold &&
//                 block.timestamp < _idToMarketItem[i].auctionEndTime
//             ) {
//                 activeCount++;
//             }
//         }

//         MarketItem[] memory items = new MarketItem[](activeCount);
//         uint256 currentIndex = 0;

//         for (uint256 i = 0; i < itemCount; i++) {
//             if (
//                 _idToMarketItem[i].isAuction &&
//                 !_idToMarketItem[i].sold &&
//                 block.timestamp < _idToMarketItem[i].auctionEndTime
//             ) {
//                 items[currentIndex] = _idToMarketItem[i];
//                 currentIndex++;
//             }
//         }
//         return items;
//     }

//     function _findPriceAtTime(
//         PriceHistory[] memory history,
//         uint256 targetTime
//     ) private pure returns (uint256) {
//         for (uint256 i = history.length; i > 0; i--) {
//             if (history[i - 1].timestamp <= targetTime) {
//                 return history[i - 1].price;
//             }
//         }
//         return 0;
//     }
// }

// contract NFTMarketplace is ReentrancyGuard, Ownable(msg.sender) {
//     using Strings for uint256;

//     struct MarketItem {
//         uint256 itemId;
//         address nftContract;
//         uint256 tokenId;
//         address payable seller;
//         address payable owner;
//         uint256 price;
//         bool isAuction;
//         uint256 auctionEndTime;
//         address highestBidder;
//         uint256 highestBid;
//         bool sold;
//     }

//     struct Offer {
//         address buyer;
//         uint256 price;
//         uint256 expirationTime;
//     }

//     struct PriceHistory {
//         uint256 timestamp;
//         uint256 price;
//         address seller;
//         address buyer;
//         PriceActionType actionType;
//     }

//     enum PriceActionType {
//         LISTING,
//         SALE,
//         AUCTION_BID,
//         AUCTION_END,
//         OFFER_ACCEPTED
//     }

//     enum SaleType {
//         ALL,
//         FIXED_PRICE,
//         AUCTION
//     }

//     enum SortOrder {
//         PRICE_LOW_TO_HIGH,
//         PRICE_HIGH_TO_LOW,
//         NEWEST_FIRST,
//         OLDEST_FIRST
//     }

//     uint256 private _itemIds;
//     uint256 private _itemsSold;
//     uint256 public constant AUCTION_DURATION = 7 days;
//     uint256 public constant MIN_AUCTION_INCREMENT = 0.01 ether;
//     uint256 public constant LISTING_PRICE = 0.0005 ether;
//     address public immutable factoryAddress;

//     mapping(uint256 => MarketItem) private _idToMarketItem;
//     mapping(uint256 => mapping(address => uint256))
//         private _auctionPendingReturns;
//     mapping(uint256 => Offer[]) private _itemOffers;
//     mapping(uint256 => PriceHistory[]) private _itemPriceHistory;

//     event MarketItemCreated(
//         uint256 indexed itemId,
//         address indexed nftContract,
//         uint256 indexed tokenId,
//         address seller,
//         address owner,
//         uint256 price,
//         bool isAuction,
//         uint256 auctionEndTime
//     );

//     event AuctionBid(
//         uint256 indexed itemId,
//         address indexed bidder,
//         uint256 bid
//     );

//     event AuctionEnded(uint256 indexed itemId, address winner, uint256 amount);

//     event OfferCreated(
//         uint256 indexed itemId,
//         address indexed buyer,
//         uint256 price,
//         uint256 expirationTime
//     );

//     event OfferAccepted(
//         uint256 indexed itemId,
//         address indexed buyer,
//         uint256 price
//     );

//     // Constructor
//     constructor(address _factoryAddress) {
//         factoryAddress = _factoryAddress;
//     }

//     // Function to add a price history entry
//     function _addPriceHistory(
//         uint256 itemId,
//         uint256 price,
//         address seller,
//         address buyer,
//         PriceActionType actionType
//     ) internal {
//         PriceHistory memory history = PriceHistory(
//             block.timestamp,
//             price,
//             seller,
//             buyer,
//             actionType
//         );
//         _itemPriceHistory[itemId].push(history);
//     }

//     // Create Market Item (Fixed Price)
//     function createMarketItem(
//         address collectionAddress,
//         uint256 tokenId,
//         uint256 price
//     ) external payable nonReentrant {
//         require(price > 0, "Price must be greater than 0");
//         console.log(msg.value);
//         require(msg.value == LISTING_PRICE, "Must pay listing price");

//         // Verify collection exists
//         NFTCollectionFactory factory = NFTCollectionFactory(factoryAddress);
//         (, , address nftContract, , , , , , ) = factory.collections(
//             collectionAddress
//         );

//         require(nftContract != address(0), "Collection does not exist");

//         // NFTCollection collection = NFTCollection(collectionAddress);

//         // collection.approveMarketplace(address(this));

//         console.log("collection");

//         // uint256 tokenId = collection.mint(tokenURI);

//         uint256 itemId = _itemIds++;

//         _idToMarketItem[itemId] = MarketItem(
//             itemId,
//             collectionAddress,
//             tokenId,
//             payable(msg.sender),
//             payable(address(0)),
//             price,
//             false,
//             0,
//             address(0),
//             0,
//             false
//         );

//         IERC721(collectionAddress).transferFrom(
//             msg.sender,
//             address(this),
//             tokenId
//         );
//         factory.updateCollectionStats(collectionAddress, price, false);

//         // Add price history for listing
//         _addPriceHistory(
//             itemId,
//             price,
//             msg.sender,
//             address(0),
//             PriceActionType.LISTING
//         );

//         emit MarketItemCreated(
//             itemId,
//             nftContract,
//             tokenId,
//             msg.sender,
//             address(0),
//             price,
//             false,
//             0
//         );
//     }

//     function getListingPrice() public pure returns (uint256) {
//         return LISTING_PRICE;
//     }

//     // Create market sale for fixed price items
//     function createMarketSale(
//         address collectionAddress,
//         uint256 itemId
//     ) external payable nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         uint256 price = item.price;
//         uint256 tokenId = item.tokenId;

//         require(!item.isAuction, "Cannot buy auction items directly");
//         require(msg.value == price, "Please submit the asking price");
//         require(!item.sold, "Item already sold");

//         item.seller.transfer(msg.value);
//         IERC721(collectionAddress).transferFrom(
//             address(this),
//             msg.sender,
//             tokenId
//         );
//         item.owner = payable(msg.sender);
//         item.sold = true;
//         _itemsSold++;

//         // Update collection stats
//         NFTCollectionFactory(factoryAddress).updateCollectionStats(
//             collectionAddress,
//             price,
//             true
//         );

//         // Add price history for sale
//         _addPriceHistory(
//             itemId,
//             price,
//             item.seller,
//             msg.sender,
//             PriceActionType.SALE
//         );

//         payable(owner()).transfer(LISTING_PRICE);
//     }

//     // Fetch all unsold market items
//     function fetchMarketItems() external view returns (MarketItem[] memory) {
//         uint256 itemCount = _itemIds;
//         uint256 unsoldItemCount = _itemIds - _itemsSold;
//         uint256 currentIndex = 0;

//         MarketItem[] memory items = new MarketItem[](unsoldItemCount);

//         for (uint256 i = 0; i < itemCount; i++) {
//             if (!_idToMarketItem[i].sold) {
//                 MarketItem storage currentItem = _idToMarketItem[i];
//                 items[currentIndex] = currentItem;
//                 currentIndex++;
//             }
//         }

//         return items;
//     }

//     // Fetch NFTs owned by msg.sender
//     function fetchMyNFTs() external view returns (MarketItem[] memory) {
//         uint256 totalItemCount = _itemIds;
//         uint256 itemCount = 0;
//         uint256 currentIndex = 0;

//         // First, count the number of items owned by msg.sender
//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].owner == msg.sender) {
//                 itemCount++;
//             }
//         }

//         MarketItem[] memory items = new MarketItem[](itemCount);

//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].owner == msg.sender) {
//                 MarketItem storage currentItem = _idToMarketItem[i];
//                 items[currentIndex] = currentItem;
//                 currentIndex++;
//             }
//         }

//         return items;
//     }

//     // Fetch NFTs listed by msg.sender
//     function fetchMyListedNFTs() external view returns (MarketItem[] memory) {
//         uint256 totalItemCount = _itemIds;
//         uint256 itemCount = 0;
//         uint256 currentIndex = 0;

//         // First, count the number of items listed by msg.sender
//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].seller == msg.sender) {
//                 itemCount++;
//             }
//         }

//         MarketItem[] memory items = new MarketItem[](itemCount);

//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].seller == msg.sender) {
//                 MarketItem storage currentItem = _idToMarketItem[i];
//                 items[currentIndex] = currentItem;
//                 currentIndex++;
//             }
//         }

//         return items;
//     }

//     // Fetch price history for an item
//     function fetchPriceHistory(
//         uint256 itemId
//     ) external view returns (PriceHistory[] memory) {
//         return _itemPriceHistory[itemId];
//     }

//     // Get price statistics for an item
//     function getItemPriceStats(
//         uint256 itemId
//     )
//         external
//         view
//         returns (
//             uint256 lowestPrice,
//             uint256 highestPrice,
//             uint256 averagePrice,
//             uint256 totalSales
//         )
//     {
//         PriceHistory[] memory history = _itemPriceHistory[itemId];
//         uint256 total = 0;
//         uint256 salesCount = 0;
//         lowestPrice = type(uint256).max;
//         highestPrice = 0;

//         for (uint256 i = 0; i < history.length; i++) {
//             // Only consider actual sales, not listings
//             if (
//                 history[i].actionType == PriceActionType.SALE ||
//                 history[i].actionType == PriceActionType.AUCTION_END ||
//                 history[i].actionType == PriceActionType.OFFER_ACCEPTED
//             ) {
//                 uint256 price = history[i].price;
//                 if (price < lowestPrice) {
//                     lowestPrice = price;
//                 }
//                 if (price > highestPrice) {
//                     highestPrice = price;
//                 }
//                 total += price;
//                 salesCount++;
//             }
//         }

//         averagePrice = salesCount > 0 ? total / salesCount : 0;
//         totalSales = salesCount;

//         if (lowestPrice == type(uint256).max) {
//             lowestPrice = 0;
//         }
//     }

//     // Create Auction
//     function createAuction(
//         address nftContract,
//         uint256 tokenId,
//         uint256 startingPrice
//     ) external payable nonReentrant {
//         require(startingPrice > 0, "Starting price must be greater than 0");
//         require(msg.value == LISTING_PRICE, "Must pay listing price");

//         uint256 itemId = _itemIds++;
//         uint256 auctionEnd = block.timestamp + AUCTION_DURATION;

//         _idToMarketItem[itemId] = MarketItem(
//             itemId,
//             nftContract,
//             tokenId,
//             payable(msg.sender),
//             payable(address(0)),
//             startingPrice,
//             true,
//             auctionEnd,
//             address(0),
//             0,
//             false
//         );

//         IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

//         emit MarketItemCreated(
//             itemId,
//             nftContract,
//             tokenId,
//             msg.sender,
//             address(0),
//             startingPrice,
//             true,
//             auctionEnd
//         );
//     }

//     // Place Bid
//     function placeBid(uint256 itemId) external payable nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         require(item.isAuction, "Item is not an auction");
//         require(block.timestamp < item.auctionEndTime, "Auction ended");
//         require(msg.value >= item.price + MIN_AUCTION_INCREMENT, "Bid too low");

//         if (item.highestBidder != address(0)) {
//             _auctionPendingReturns[itemId][item.highestBidder] += item
//                 .highestBid;
//         }

//         item.highestBidder = msg.sender;
//         item.highestBid = msg.value;

//         // Add price history for bid
//         _addPriceHistory(
//             itemId,
//             msg.value,
//             item.seller,
//             msg.sender,
//             PriceActionType.AUCTION_BID
//         );

//         emit AuctionBid(itemId, msg.sender, msg.value);
//     }

//     // End Auction
//     function endAuction(uint256 itemId) external nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         require(item.isAuction, "Not an auction");
//         require(block.timestamp >= item.auctionEndTime, "Auction not ended");
//         require(!item.sold, "Auction already ended");

//         item.sold = true;
//         item.owner = payable(item.highestBidder);
//         _itemsSold++;

//         if (item.highestBidder != address(0)) {
//             item.seller.transfer(item.highestBid);
//             IERC721(item.nftContract).transferFrom(
//                 address(this),
//                 item.highestBidder,
//                 item.tokenId
//             );
//         } else {
//             IERC721(item.nftContract).transferFrom(
//                 address(this),
//                 item.seller,
//                 item.tokenId
//             );
//         }

//         payable(owner()).transfer(LISTING_PRICE);

//         emit AuctionEnded(itemId, item.highestBidder, item.highestBid);
//     }

//     // Withdraw Bid
//     function withdrawBid(uint256 itemId) external nonReentrant {
//         uint256 amount = _auctionPendingReturns[itemId][msg.sender];
//         require(amount > 0, "No funds to withdraw");

//         _auctionPendingReturns[itemId][msg.sender] = 0;
//         payable(msg.sender).transfer(amount);
//     }

//     // Make Offer
//     function makeOffer(
//         uint256 itemId,
//         uint256 expirationTime
//     ) external payable nonReentrant {
//         require(msg.value > 0, "Offer must be greater than 0");
//         require(
//             expirationTime > block.timestamp,
//             "Expiration must be in future"
//         );

//         MarketItem storage item = _idToMarketItem[itemId];
//         require(!item.sold, "Item already sold");
//         require(!item.isAuction, "Cannot make offers on auctions");

//         Offer memory newOffer = Offer(msg.sender, msg.value, expirationTime);
//         _itemOffers[itemId].push(newOffer);

//         emit OfferCreated(itemId, msg.sender, msg.value, expirationTime);
//     }

//     // Accept Offer
//     function acceptOffer(
//         uint256 itemId,
//         uint256 offerIndex
//     ) external nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         require(msg.sender == item.seller, "Only seller can accept");
//         require(!item.sold, "Item already sold");

//         Offer memory offer = _itemOffers[itemId][offerIndex];
//         require(block.timestamp <= offer.expirationTime, "Offer expired");

//         item.sold = true;
//         item.owner = payable(offer.buyer);
//         _itemsSold++;

//         // Transfer NFT to buyer
//         IERC721(item.nftContract).transferFrom(
//             address(this),
//             offer.buyer,
//             item.tokenId
//         );

//         // Transfer payment to seller
//         payable(item.seller).transfer(offer.price);
//         payable(owner()).transfer(LISTING_PRICE);

//         // Refund other offers
//         for (uint i = 0; i < _itemOffers[itemId].length; i++) {
//             if (
//                 i != offerIndex &&
//                 block.timestamp <= _itemOffers[itemId][i].expirationTime
//             ) {
//                 payable(_itemOffers[itemId][i].buyer).transfer(
//                     _itemOffers[itemId][i].price
//                 );
//             }
//         }

//         emit OfferAccepted(itemId, offer.buyer, offer.price);
//     }

//     // View Functions
//     function fetchMarketItem(
//         uint256 itemId
//     ) external view returns (MarketItem memory) {
//         return _idToMarketItem[itemId];
//     }

//     function fetchItemOffers(
//         uint256 itemId
//     ) external view returns (Offer[] memory) {
//         return _itemOffers[itemId];
//     }

//     function fetchActiveAuctions() external view returns (MarketItem[] memory) {
//         uint256 itemCount = _itemIds;
//         uint256 activeCount = 0;

//         for (uint256 i = 0; i < itemCount; i++) {
//             if (
//                 _idToMarketItem[i].isAuction &&
//                 !_idToMarketItem[i].sold &&
//                 block.timestamp < _idToMarketItem[i].auctionEndTime
//             ) {
//                 activeCount++;
//             }
//         }

//         MarketItem[] memory items = new MarketItem[](activeCount);
//         uint256 currentIndex = 0;

//         for (uint256 i = 0; i < itemCount; i++) {
//             if (
//                 _idToMarketItem[i].isAuction &&
//                 !_idToMarketItem[i].sold &&
//                 block.timestamp < _idToMarketItem[i].auctionEndTime
//             ) {
//                 items[currentIndex] = _idToMarketItem[i];
//                 currentIndex++;
//             }
//         }
//         return items;
//     }

//     function _findPriceAtTime(
//         PriceHistory[] memory history,
//         uint256 targetTime
//     ) private pure returns (uint256) {
//         for (uint256 i = history.length; i > 0; i--) {
//             if (history[i - 1].timestamp <= targetTime) {
//                 return history[i - 1].price;
//             }
//         }
//         return 0;
//     }
// }

// contract NFTMarketplace is ReentrancyGuard, Ownable(msg.sender) {
//     using Strings for uint256;

//     struct MarketItem {
//         uint256 itemId;
//         address nftContract;
//         uint256 tokenId;
//         address payable seller;
//         address payable owner;
//         uint256 price;
//         bool isAuction;
//         uint256 auctionEndTime;
//         address highestBidder;
//         uint256 highestBid;
//         bool sold;
//     }

//     struct Offer {
//         address buyer;
//         uint256 price;
//         uint256 expirationTime;
//     }

//     struct PriceHistory {
//         uint256 timestamp;
//         uint256 price;
//         address seller;
//         address buyer;
//         PriceActionType actionType;
//     }

//     enum PriceActionType {
//         LISTING,
//         SALE,
//         AUCTION_BID,
//         AUCTION_END,
//         OFFER_ACCEPTED
//     }

//     enum SaleType {
//         ALL,
//         FIXED_PRICE,
//         AUCTION
//     }

//     enum SortOrder {
//         PRICE_LOW_TO_HIGH,
//         PRICE_HIGH_TO_LOW,
//         NEWEST_FIRST,
//         OLDEST_FIRST
//     }

//     uint256 private _itemIds;
//     uint256 private _itemsSold;
//     uint256 public constant AUCTION_DURATION = 7 days;
//     uint256 public constant MIN_AUCTION_INCREMENT = 0.01 ether;
//     uint256 public constant LISTING_PRICE = 0.0005 ether;
//     address public immutable factoryAddress;

//     mapping(uint256 => MarketItem) private _idToMarketItem;
//     mapping(uint256 => mapping(address => uint256))
//         private _auctionPendingReturns;
//     mapping(uint256 => Offer[]) private _itemOffers;
//     mapping(uint256 => PriceHistory[]) private _itemPriceHistory;

//     event MarketItemCreated(
//         uint256 indexed itemId,
//         address indexed nftContract,
//         uint256 indexed tokenId,
//         address seller,
//         address owner,
//         uint256 price,
//         bool isAuction,
//         uint256 auctionEndTime
//     );

//     event AuctionBid(
//         uint256 indexed itemId,
//         address indexed bidder,
//         uint256 bid
//     );

//     event AuctionEnded(uint256 indexed itemId, address winner, uint256 amount);

//     event OfferCreated(
//         uint256 indexed itemId,
//         address indexed buyer,
//         uint256 price,
//         uint256 expirationTime
//     );

//     event OfferAccepted(
//         uint256 indexed itemId,
//         address indexed buyer,
//         uint256 price
//     );

//     // Constructor
//     constructor(address _factoryAddress) {
//         factoryAddress = _factoryAddress;
//     }

//     // Function to add a price history entry
//     function _addPriceHistory(
//         uint256 itemId,
//         uint256 price,
//         address seller,
//         address buyer,
//         PriceActionType actionType
//     ) internal {
//         PriceHistory memory history = PriceHistory(
//             block.timestamp,
//             price,
//             seller,
//             buyer,
//             actionType
//         );
//         _itemPriceHistory[itemId].push(history);
//     }

//     // Create Market Item (Fixed Price)
//     function createMarketItem(
//         address collectionAddress,
//         uint256 tokenId,
//         uint256 price
//     ) external payable nonReentrant {
//         require(price > 0, "Price must be greater than 0");
//         console.log(msg.value);
//         require(msg.value == LISTING_PRICE, "Must pay listing price");

//         // Verify collection exists
//         NFTCollectionFactory factory = NFTCollectionFactory(factoryAddress);
//         (, , address nftContract, , , , , , ) = factory.collections(
//             collectionAddress
//         );

//         require(nftContract != address(0), "Collection does not exist");

//         // NFTCollection collection = NFTCollection(collectionAddress);

//         // collection.approveMarketplace(address(this));

//         console.log("collection");

//         // uint256 tokenId = collection.mint(tokenURI);

//         uint256 itemId = _itemIds++;

//         _idToMarketItem[itemId] = MarketItem(
//             itemId,
//             collectionAddress,
//             tokenId,
//             payable(msg.sender),
//             payable(address(0)),
//             price,
//             false,
//             0,
//             address(0),
//             0,
//             false
//         );

//         IERC721(collectionAddress).transferFrom(
//             msg.sender,
//             address(this),
//             tokenId
//         );
//         factory.updateCollectionStats(collectionAddress, price, false);

//         // Add price history for listing
//         _addPriceHistory(
//             itemId,
//             price,
//             msg.sender,
//             address(0),
//             PriceActionType.LISTING
//         );

//         emit MarketItemCreated(
//             itemId,
//             nftContract,
//             tokenId,
//             msg.sender,
//             address(0),
//             price,
//             false,
//             0
//         );
//     }

//     function getListingPrice() public pure returns (uint256) {
//         return LISTING_PRICE;
//     }

//     // Create market sale for fixed price items
//     function createMarketSale(
//         address collectionAddress,
//         uint256 itemId
//     ) external payable nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         uint256 price = item.price;
//         uint256 tokenId = item.tokenId;

//         require(!item.isAuction, "Cannot buy auction items directly");
//         require(msg.value == price, "Please submit the asking price");
//         require(!item.sold, "Item already sold");

//         item.seller.transfer(msg.value);
//         IERC721(collectionAddress).transferFrom(
//             address(this),
//             msg.sender,
//             tokenId
//         );
//         item.owner = payable(msg.sender);
//         item.sold = true;
//         _itemsSold++;

//         // Update collection stats
//         NFTCollectionFactory(factoryAddress).updateCollectionStats(
//             collectionAddress,
//             price,
//             true
//         );

//         // Add price history for sale
//         _addPriceHistory(
//             itemId,
//             price,
//             item.seller,
//             msg.sender,
//             PriceActionType.SALE
//         );

//         payable(owner()).transfer(LISTING_PRICE);
//     }

//     // Fetch all unsold market items
//     function fetchMarketItems() external view returns (MarketItem[] memory) {
//         uint256 itemCount = _itemIds;
//         uint256 unsoldItemCount = _itemIds - _itemsSold;
//         uint256 currentIndex = 0;

//         MarketItem[] memory items = new MarketItem[](unsoldItemCount);

//         for (uint256 i = 0; i < itemCount; i++) {
//             if (!_idToMarketItem[i].sold) {
//                 MarketItem storage currentItem = _idToMarketItem[i];
//                 items[currentIndex] = currentItem;
//                 currentIndex++;
//             }
//         }

//         return items;
//     }

//     // Fetch NFTs owned by msg.sender
//     function fetchMyNFTs() external view returns (MarketItem[] memory) {
//         uint256 totalItemCount = _itemIds;
//         uint256 itemCount = 0;
//         uint256 currentIndex = 0;

//         // First, count the number of items owned by msg.sender
//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].owner == msg.sender) {
//                 itemCount++;
//             }
//         }

//         MarketItem[] memory items = new MarketItem[](itemCount);

//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].owner == msg.sender) {
//                 MarketItem storage currentItem = _idToMarketItem[i];
//                 items[currentIndex] = currentItem;
//                 currentIndex++;
//             }
//         }

//         return items;
//     }

//     // Fetch NFTs listed by msg.sender
//     function fetchMyListedNFTs() external view returns (MarketItem[] memory) {
//         uint256 totalItemCount = _itemIds;
//         uint256 itemCount = 0;
//         uint256 currentIndex = 0;

//         // First, count the number of items listed by msg.sender
//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].seller == msg.sender) {
//                 itemCount++;
//             }
//         }

//         MarketItem[] memory items = new MarketItem[](itemCount);

//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].seller == msg.sender) {
//                 MarketItem storage currentItem = _idToMarketItem[i];
//                 items[currentIndex] = currentItem;
//                 currentIndex++;
//             }
//         }

//         return items;
//     }

//     // Fetch price history for an item
//     function fetchPriceHistory(
//         uint256 itemId
//     ) external view returns (PriceHistory[] memory) {
//         return _itemPriceHistory[itemId];
//     }

//     // Get price statistics for an item
//     function getItemPriceStats(
//         uint256 itemId
//     )
//         external
//         view
//         returns (
//             uint256 lowestPrice,
//             uint256 highestPrice,
//             uint256 averagePrice,
//             uint256 totalSales
//         )
//     {
//         PriceHistory[] memory history = _itemPriceHistory[itemId];
//         uint256 total = 0;
//         uint256 salesCount = 0;
//         lowestPrice = type(uint256).max;
//         highestPrice = 0;

//         for (uint256 i = 0; i < history.length; i++) {
//             // Only consider actual sales, not listings
//             if (
//                 history[i].actionType == PriceActionType.SALE ||
//                 history[i].actionType == PriceActionType.AUCTION_END ||
//                 history[i].actionType == PriceActionType.OFFER_ACCEPTED
//             ) {
//                 uint256 price = history[i].price;
//                 if (price < lowestPrice) {
//                     lowestPrice = price;
//                 }
//                 if (price > highestPrice) {
//                     highestPrice = price;
//                 }
//                 total += price;
//                 salesCount++;
//             }
//         }

//         averagePrice = salesCount > 0 ? total / salesCount : 0;
//         totalSales = salesCount;

//         if (lowestPrice == type(uint256).max) {
//             lowestPrice = 0;
//         }
//     }

//     // Create Auction
//     function createAuction(
//         address nftContract,
//         uint256 tokenId,
//         uint256 startingPrice
//     ) external payable nonReentrant {
//         require(startingPrice > 0, "Starting price must be greater than 0");
//         require(msg.value == LISTING_PRICE, "Must pay listing price");

//         uint256 itemId = _itemIds++;
//         uint256 auctionEnd = block.timestamp + AUCTION_DURATION;

//         _idToMarketItem[itemId] = MarketItem(
//             itemId,
//             nftContract,
//             tokenId,
//             payable(msg.sender),
//             payable(address(0)),
//             startingPrice,
//             true,
//             auctionEnd,
//             address(0),
//             0,
//             false
//         );

//         IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

//         emit MarketItemCreated(
//             itemId,
//             nftContract,
//             tokenId,
//             msg.sender,
//             address(0),
//             startingPrice,
//             true,
//             auctionEnd
//         );
//     }

//     // Place Bid
//     function placeBid(uint256 itemId) external payable nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         require(item.isAuction, "Item is not an auction");
//         require(block.timestamp < item.auctionEndTime, "Auction ended");
//         require(msg.value >= item.price + MIN_AUCTION_INCREMENT, "Bid too low");

//         if (item.highestBidder != address(0)) {
//             _auctionPendingReturns[itemId][item.highestBidder] += item
//                 .highestBid;
//         }

//         item.highestBidder = msg.sender;
//         item.highestBid = msg.value;

//         // Add price history for bid
//         _addPriceHistory(
//             itemId,
//             msg.value,
//             item.seller,
//             msg.sender,
//             PriceActionType.AUCTION_BID
//         );

//         emit AuctionBid(itemId, msg.sender, msg.value);
//     }

//     // End Auction
//     function endAuction(uint256 itemId) external nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         require(item.isAuction, "Not an auction");
//         require(block.timestamp >= item.auctionEndTime, "Auction not ended");
//         require(!item.sold, "Auction already ended");

//         item.sold = true;
//         item.owner = payable(item.highestBidder);
//         _itemsSold++;

//         if (item.highestBidder != address(0)) {
//             item.seller.transfer(item.highestBid);
//             IERC721(item.nftContract).transferFrom(
//                 address(this),
//                 item.highestBidder,
//                 item.tokenId
//             );
//         } else {
//             IERC721(item.nftContract).transferFrom(
//                 address(this),
//                 item.seller,
//                 item.tokenId
//             );
//         }

//         payable(owner()).transfer(LISTING_PRICE);

//         emit AuctionEnded(itemId, item.highestBidder, item.highestBid);
//     }

//     // Withdraw Bid
//     function withdrawBid(uint256 itemId) external nonReentrant {
//         uint256 amount = _auctionPendingReturns[itemId][msg.sender];
//         require(amount > 0, "No funds to withdraw");

//         _auctionPendingReturns[itemId][msg.sender] = 0;
//         payable(msg.sender).transfer(amount);
//     }

//     // Make Offer
//     function makeOffer(
//         uint256 itemId,
//         uint256 expirationTime
//     ) external payable nonReentrant {
//         require(msg.value > 0, "Offer must be greater than 0");
//         require(
//             expirationTime > block.timestamp,
//             "Expiration must be in future"
//         );

//         MarketItem storage item = _idToMarketItem[itemId];
//         require(!item.sold, "Item already sold");
//         require(!item.isAuction, "Cannot make offers on auctions");

//         Offer memory newOffer = Offer(msg.sender, msg.value, expirationTime);
//         _itemOffers[itemId].push(newOffer);

//         emit OfferCreated(itemId, msg.sender, msg.value, expirationTime);
//     }

//     // Accept Offer
//     function acceptOffer(
//         uint256 itemId,
//         uint256 offerIndex
//     ) external nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         require(msg.sender == item.seller, "Only seller can accept");
//         require(!item.sold, "Item already sold");

//         Offer memory offer = _itemOffers[itemId][offerIndex];
//         require(block.timestamp <= offer.expirationTime, "Offer expired");

//         item.sold = true;
//         item.owner = payable(offer.buyer);
//         _itemsSold++;

//         // Transfer NFT to buyer
//         IERC721(item.nftContract).transferFrom(
//             address(this),
//             offer.buyer,
//             item.tokenId
//         );

//         // Transfer payment to seller
//         payable(item.seller).transfer(offer.price);
//         payable(owner()).transfer(LISTING_PRICE);

//         // Refund other offers
//         for (uint i = 0; i < _itemOffers[itemId].length; i++) {
//             if (
//                 i != offerIndex &&
//                 block.timestamp <= _itemOffers[itemId][i].expirationTime
//             ) {
//                 payable(_itemOffers[itemId][i].buyer).transfer(
//                     _itemOffers[itemId][i].price
//                 );
//             }
//         }

//         emit OfferAccepted(itemId, offer.buyer, offer.price);
//     }

//     // View Functions
//     function fetchMarketItem(
//         uint256 itemId
//     ) external view returns (MarketItem memory) {
//         return _idToMarketItem[itemId];
//     }

//     function fetchItemOffers(
//         uint256 itemId
//     ) external view returns (Offer[] memory) {
//         return _itemOffers[itemId];
//     }

//     function fetchActiveAuctions() external view returns (MarketItem[] memory) {
//         uint256 itemCount = _itemIds;
//         uint256 activeCount = 0;

//         for (uint256 i = 0; i < itemCount; i++) {
//             if (
//                 _idToMarketItem[i].isAuction &&
//                 !_idToMarketItem[i].sold &&
//                 block.timestamp < _idToMarketItem[i].auctionEndTime
//             ) {
//                 activeCount++;
//             }
//         }

//         MarketItem[] memory items = new MarketItem[](activeCount);
//         uint256 currentIndex = 0;

//         for (uint256 i = 0; i < itemCount; i++) {
//             if (
//                 _idToMarketItem[i].isAuction &&
//                 !_idToMarketItem[i].sold &&
//                 block.timestamp < _idToMarketItem[i].auctionEndTime
//             ) {
//                 items[currentIndex] = _idToMarketItem[i];
//                 currentIndex++;
//             }
//         }
//         return items;
//     }

//     function _findPriceAtTime(
//         PriceHistory[] memory history,
//         uint256 targetTime
//     ) private pure returns (uint256) {
//         for (uint256 i = history.length; i > 0; i--) {
//             if (history[i - 1].timestamp <= targetTime) {
//                 return history[i - 1].price;
//             }
//         }
//         return 0;
//     }
// }

// contract NFTMarketplace is ReentrancyGuard, Ownable(msg.sender) {
//     using Strings for uint256;

//     struct MarketItem {
//         uint256 itemId;
//         address nftContract;
//         uint256 tokenId;
//         address payable seller;
//         address payable owner;
//         uint256 price;
//         bool isAuction;
//         uint256 auctionEndTime;
//         address highestBidder;
//         uint256 highestBid;
//         bool sold;
//     }

//     struct Offer {
//         address buyer;
//         uint256 price;
//         uint256 expirationTime;
//     }

//     struct PriceHistory {
//         uint256 timestamp;
//         uint256 price;
//         address seller;
//         address buyer;
//         PriceActionType actionType;
//     }

//     enum PriceActionType {
//         LISTING,
//         SALE,
//         AUCTION_BID,
//         AUCTION_END,
//         OFFER_ACCEPTED
//     }

//     enum SaleType {
//         ALL,
//         FIXED_PRICE,
//         AUCTION
//     }

//     enum SortOrder {
//         PRICE_LOW_TO_HIGH,
//         PRICE_HIGH_TO_LOW,
//         NEWEST_FIRST,
//         OLDEST_FIRST
//     }

//     uint256 private _itemIds;
//     uint256 private _itemsSold;
//     uint256 public constant AUCTION_DURATION = 7 days;
//     uint256 public constant MIN_AUCTION_INCREMENT = 0.01 ether;
//     uint256 public constant LISTING_PRICE = 0.0005 ether;
//     address public immutable factoryAddress;

//     mapping(uint256 => MarketItem) private _idToMarketItem;
//     mapping(uint256 => mapping(address => uint256))
//         private _auctionPendingReturns;
//     mapping(uint256 => Offer[]) private _itemOffers;
//     mapping(uint256 => PriceHistory[]) private _itemPriceHistory;

//     event MarketItemCreated(
//         uint256 indexed itemId,
//         address indexed nftContract,
//         uint256 indexed tokenId,
//         address seller,
//         address owner,
//         uint256 price,
//         bool isAuction,
//         uint256 auctionEndTime
//     );

//     event AuctionBid(
//         uint256 indexed itemId,
//         address indexed bidder,
//         uint256 bid
//     );

//     event AuctionEnded(uint256 indexed itemId, address winner, uint256 amount);

//     event OfferCreated(
//         uint256 indexed itemId,
//         address indexed buyer,
//         uint256 price,
//         uint256 expirationTime
//     );

//     event OfferAccepted(
//         uint256 indexed itemId,
//         address indexed buyer,
//         uint256 price
//     );

//     // Constructor
//     constructor(address _factoryAddress) {
//         factoryAddress = _factoryAddress;
//     }

//     // Function to add a price history entry
//     function _addPriceHistory(
//         uint256 itemId,
//         uint256 price,
//         address seller,
//         address buyer,
//         PriceActionType actionType
//     ) internal {
//         PriceHistory memory history = PriceHistory(
//             block.timestamp,
//             price,
//             seller,
//             buyer,
//             actionType
//         );
//         _itemPriceHistory[itemId].push(history);
//     }

//     // Create Market Item (Fixed Price)
//     function createMarketItem(
//         address collectionAddress,
//         uint256 tokenId,
//         uint256 price
//     ) external payable nonReentrant {
//         require(price > 0, "Price must be greater than 0");
//         console.log(msg.value);
//         require(msg.value == LISTING_PRICE, "Must pay listing price");

//         // Verify collection exists
//         NFTCollectionFactory factory = NFTCollectionFactory(factoryAddress);
//         (, , address nftContract, , , , , , ) = factory.collections(
//             collectionAddress
//         );

//         require(nftContract != address(0), "Collection does not exist");

//         // NFTCollection collection = NFTCollection(collectionAddress);

//         // collection.approveMarketplace(address(this));

//         console.log("collection");

//         // uint256 tokenId = collection.mint(tokenURI);

//         uint256 itemId = _itemIds++;

//         _idToMarketItem[itemId] = MarketItem(
//             itemId,
//             collectionAddress,
//             tokenId,
//             payable(msg.sender),
//             payable(address(0)),
//             price,
//             false,
//             0,
//             address(0),
//             0,
//             false
//         );

//         IERC721(collectionAddress).transferFrom(
//             msg.sender,
//             address(this),
//             tokenId
//         );
//         factory.updateCollectionStats(collectionAddress, price, false);

//         // Add price history for listing
//         _addPriceHistory(
//             itemId,
//             price,
//             msg.sender,
//             address(0),
//             PriceActionType.LISTING
//         );

//         emit MarketItemCreated(
//             itemId,
//             nftContract,
//             tokenId,
//             msg.sender,
//             address(0),
//             price,
//             false,
//             0
//         );
//     }

//     function getListingPrice() public pure returns (uint256) {
//         return LISTING_PRICE;
//     }

//     // Create market sale for fixed price items
//     function createMarketSale(
//         address collectionAddress,
//         uint256 itemId
//     ) external payable nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         uint256 price = item.price;
//         uint256 tokenId = item.tokenId;

//         require(!item.isAuction, "Cannot buy auction items directly");
//         require(msg.value == price, "Please submit the asking price");
//         require(!item.sold, "Item already sold");

//         item.seller.transfer(msg.value);
//         IERC721(collectionAddress).transferFrom(
//             address(this),
//             msg.sender,
//             tokenId
//         );
//         item.owner = payable(msg.sender);
//         item.sold = true;
//         _itemsSold++;

//         // Update collection stats
//         NFTCollectionFactory(factoryAddress).updateCollectionStats(
//             collectionAddress,
//             price,
//             true
//         );

//         // Add price history for sale
//         _addPriceHistory(
//             itemId,
//             price,
//             item.seller,
//             msg.sender,
//             PriceActionType.SALE
//         );

//         payable(owner()).transfer(LISTING_PRICE);
//     }

//     // Fetch all unsold market items
//     function fetchMarketItems() external view returns (MarketItem[] memory) {
//         uint256 itemCount = _itemIds;
//         uint256 unsoldItemCount = _itemIds - _itemsSold;
//         uint256 currentIndex = 0;

//         MarketItem[] memory items = new MarketItem[](unsoldItemCount);

//         for (uint256 i = 0; i < itemCount; i++) {
//             if (!_idToMarketItem[i].sold) {
//                 MarketItem storage currentItem = _idToMarketItem[i];
//                 items[currentIndex] = currentItem;
//                 currentIndex++;
//             }
//         }

//         return items;
//     }

//     // Fetch NFTs owned by msg.sender
//     function fetchMyNFTs() external view returns (MarketItem[] memory) {
//         uint256 totalItemCount = _itemIds;
//         uint256 itemCount = 0;
//         uint256 currentIndex = 0;

//         // First, count the number of items owned by msg.sender
//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].owner == msg.sender) {
//                 itemCount++;
//             }
//         }

//         MarketItem[] memory items = new MarketItem[](itemCount);

//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].owner == msg.sender) {
//                 MarketItem storage currentItem = _idToMarketItem[i];
//                 items[currentIndex] = currentItem;
//                 currentIndex++;
//             }
//         }

//         return items;
//     }

//     // Fetch NFTs listed by msg.sender
//     function fetchMyListedNFTs() external view returns (MarketItem[] memory) {
//         uint256 totalItemCount = _itemIds;
//         uint256 itemCount = 0;
//         uint256 currentIndex = 0;

//         // First, count the number of items listed by msg.sender
//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].seller == msg.sender) {
//                 itemCount++;
//             }
//         }

//         MarketItem[] memory items = new MarketItem[](itemCount);

//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].seller == msg.sender) {
//                 MarketItem storage currentItem = _idToMarketItem[i];
//                 items[currentIndex] = currentItem;
//                 currentIndex++;
//             }
//         }

//         return items;
//     }

//     // Fetch price history for an item
//     function fetchPriceHistory(
//         uint256 itemId
//     ) external view returns (PriceHistory[] memory) {
//         return _itemPriceHistory[itemId];
//     }

//     // Get price statistics for an item
//     function getItemPriceStats(
//         uint256 itemId
//     )
//         external
//         view
//         returns (
//             uint256 lowestPrice,
//             uint256 highestPrice,
//             uint256 averagePrice,
//             uint256 totalSales
//         )
//     {
//         PriceHistory[] memory history = _itemPriceHistory[itemId];
//         uint256 total = 0;
//         uint256 salesCount = 0;
//         lowestPrice = type(uint256).max;
//         highestPrice = 0;

//         for (uint256 i = 0; i < history.length; i++) {
//             // Only consider actual sales, not listings
//             if (
//                 history[i].actionType == PriceActionType.SALE ||
//                 history[i].actionType == PriceActionType.AUCTION_END ||
//                 history[i].actionType == PriceActionType.OFFER_ACCEPTED
//             ) {
//                 uint256 price = history[i].price;
//                 if (price < lowestPrice) {
//                     lowestPrice = price;
//                 }
//                 if (price > highestPrice) {
//                     highestPrice = price;
//                 }
//                 total += price;
//                 salesCount++;
//             }
//         }

//         averagePrice = salesCount > 0 ? total / salesCount : 0;
//         totalSales = salesCount;

//         if (lowestPrice == type(uint256).max) {
//             lowestPrice = 0;
//         }
//     }

//     // Create Auction
//     function createAuction(
//         address nftContract,
//         uint256 tokenId,
//         uint256 startingPrice
//     ) external payable nonReentrant {
//         require(startingPrice > 0, "Starting price must be greater than 0");
//         require(msg.value == LISTING_PRICE, "Must pay listing price");

//         uint256 itemId = _itemIds++;
//         uint256 auctionEnd = block.timestamp + AUCTION_DURATION;

//         _idToMarketItem[itemId] = MarketItem(
//             itemId,
//             nftContract,
//             tokenId,
//             payable(msg.sender),
//             payable(address(0)),
//             startingPrice,
//             true,
//             auctionEnd,
//             address(0),
//             0,
//             false
//         );

//         IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

//         emit MarketItemCreated(
//             itemId,
//             nftContract,
//             tokenId,
//             msg.sender,
//             address(0),
//             startingPrice,
//             true,
//             auctionEnd
//         );
//     }

//     // Place Bid
//     function placeBid(uint256 itemId) external payable nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         require(item.isAuction, "Item is not an auction");
//         require(block.timestamp < item.auctionEndTime, "Auction ended");
//         require(msg.value >= item.price + MIN_AUCTION_INCREMENT, "Bid too low");

//         if (item.highestBidder != address(0)) {
//             _auctionPendingReturns[itemId][item.highestBidder] += item
//                 .highestBid;
//         }

//         item.highestBidder = msg.sender;
//         item.highestBid = msg.value;

//         // Add price history for bid
//         _addPriceHistory(
//             itemId,
//             msg.value,
//             item.seller,
//             msg.sender,
//             PriceActionType.AUCTION_BID
//         );

//         emit AuctionBid(itemId, msg.sender, msg.value);
//     }

//     // End Auction
//     function endAuction(uint256 itemId) external nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         require(item.isAuction, "Not an auction");
//         require(block.timestamp >= item.auctionEndTime, "Auction not ended");
//         require(!item.sold, "Auction already ended");

//         item.sold = true;
//         item.owner = payable(item.highestBidder);
//         _itemsSold++;

//         if (item.highestBidder != address(0)) {
//             item.seller.transfer(item.highestBid);
//             IERC721(item.nftContract).transferFrom(
//                 address(this),
//                 item.highestBidder,
//                 item.tokenId
//             );
//         } else {
//             IERC721(item.nftContract).transferFrom(
//                 address(this),
//                 item.seller,
//                 item.tokenId
//             );
//         }

//         payable(owner()).transfer(LISTING_PRICE);

//         emit AuctionEnded(itemId, item.highestBidder, item.highestBid);
//     }

//     // Withdraw Bid
//     function withdrawBid(uint256 itemId) external nonReentrant {
//         uint256 amount = _auctionPendingReturns[itemId][msg.sender];
//         require(amount > 0, "No funds to withdraw");

//         _auctionPendingReturns[itemId][msg.sender] = 0;
//         payable(msg.sender).transfer(amount);
//     }

//     // Make Offer
//     function makeOffer(
//         uint256 itemId,
//         uint256 expirationTime
//     ) external payable nonReentrant {
//         require(msg.value > 0, "Offer must be greater than 0");
//         require(
//             expirationTime > block.timestamp,
//             "Expiration must be in future"
//         );

//         MarketItem storage item = _idToMarketItem[itemId];
//         require(!item.sold, "Item already sold");
//         require(!item.isAuction, "Cannot make offers on auctions");

//         Offer memory newOffer = Offer(msg.sender, msg.value, expirationTime);
//         _itemOffers[itemId].push(newOffer);

//         emit OfferCreated(itemId, msg.sender, msg.value, expirationTime);
//     }

//     // Accept Offer
//     function acceptOffer(
//         uint256 itemId,
//         uint256 offerIndex
//     ) external nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         require(msg.sender == item.seller, "Only seller can accept");
//         require(!item.sold, "Item already sold");

//         Offer memory offer = _itemOffers[itemId][offerIndex];
//         require(block.timestamp <= offer.expirationTime, "Offer expired");

//         item.sold = true;
//         item.owner = payable(offer.buyer);
//         _itemsSold++;

//         // Transfer NFT to buyer
//         IERC721(item.nftContract).transferFrom(
//             address(this),
//             offer.buyer,
//             item.tokenId
//         );

//         // Transfer payment to seller
//         payable(item.seller).transfer(offer.price);
//         payable(owner()).transfer(LISTING_PRICE);

//         // Refund other offers
//         for (uint i = 0; i < _itemOffers[itemId].length; i++) {
//             if (
//                 i != offerIndex &&
//                 block.timestamp <= _itemOffers[itemId][i].expirationTime
//             ) {
//                 payable(_itemOffers[itemId][i].buyer).transfer(
//                     _itemOffers[itemId][i].price
//                 );
//             }
//         }

//         emit OfferAccepted(itemId, offer.buyer, offer.price);
//     }

//     // View Functions
//     function fetchMarketItem(
//         uint256 itemId
//     ) external view returns (MarketItem memory) {
//         return _idToMarketItem[itemId];
//     }

//     function fetchItemOffers(
//         uint256 itemId
//     ) external view returns (Offer[] memory) {
//         return _itemOffers[itemId];
//     }

//     function fetchActiveAuctions() external view returns (MarketItem[] memory) {
//         uint256 itemCount = _itemIds;
//         uint256 activeCount = 0;

//         for (uint256 i = 0; i < itemCount; i++) {
//             if (
//                 _idToMarketItem[i].isAuction &&
//                 !_idToMarketItem[i].sold &&
//                 block.timestamp < _idToMarketItem[i].auctionEndTime
//             ) {
//                 activeCount++;
//             }
//         }

//         MarketItem[] memory items = new MarketItem[](activeCount);
//         uint256 currentIndex = 0;

//         for (uint256 i = 0; i < itemCount; i++) {
//             if (
//                 _idToMarketItem[i].isAuction &&
//                 !_idToMarketItem[i].sold &&
//                 block.timestamp < _idToMarketItem[i].auctionEndTime
//             ) {
//                 items[currentIndex] = _idToMarketItem[i];
//                 currentIndex++;
//             }
//         }
//         return items;
//     }

//     function _findPriceAtTime(
//         PriceHistory[] memory history,
//         uint256 targetTime
//     ) private pure returns (uint256) {
//         for (uint256 i = history.length; i > 0; i--) {
//             if (history[i - 1].timestamp <= targetTime) {
//                 return history[i - 1].price;
//             }
//         }
//         return 0;
//     }
// }

// contract NFTMarketplace is ReentrancyGuard, Ownable(msg.sender) {
//     using Strings for uint256;

//     struct MarketItem {
//         uint256 itemId;
//         address nftContract;
//         uint256 tokenId;
//         address payable seller;
//         address payable owner;
//         uint256 price;
//         bool isAuction;
//         uint256 auctionEndTime;
//         address highestBidder;
//         uint256 highestBid;
//         bool sold;
//     }

//     struct Offer {
//         address buyer;
//         uint256 price;
//         uint256 expirationTime;
//     }

//     struct PriceHistory {
//         uint256 timestamp;
//         uint256 price;
//         address seller;
//         address buyer;
//         PriceActionType actionType;
//     }

//     enum PriceActionType {
//         LISTING,
//         SALE,
//         AUCTION_BID,
//         AUCTION_END,
//         OFFER_ACCEPTED
//     }

//     enum SaleType {
//         ALL,
//         FIXED_PRICE,
//         AUCTION
//     }

//     enum SortOrder {
//         PRICE_LOW_TO_HIGH,
//         PRICE_HIGH_TO_LOW,
//         NEWEST_FIRST,
//         OLDEST_FIRST
//     }

//     uint256 private _itemIds;
//     uint256 private _itemsSold;
//     uint256 public constant AUCTION_DURATION = 7 days;
//     uint256 public constant MIN_AUCTION_INCREMENT = 0.01 ether;
//     uint256 public constant LISTING_PRICE = 0.0005 ether;
//     address public immutable factoryAddress;

//     mapping(uint256 => MarketItem) private _idToMarketItem;
//     mapping(uint256 => mapping(address => uint256))
//         private _auctionPendingReturns;
//     mapping(uint256 => Offer[]) private _itemOffers;
//     mapping(uint256 => PriceHistory[]) private _itemPriceHistory;

//     event MarketItemCreated(
//         uint256 indexed itemId,
//         address indexed nftContract,
//         uint256 indexed tokenId,
//         address seller,
//         address owner,
//         uint256 price,
//         bool isAuction,
//         uint256 auctionEndTime
//     );

//     event AuctionBid(
//         uint256 indexed itemId,
//         address indexed bidder,
//         uint256 bid
//     );

//     event AuctionEnded(uint256 indexed itemId, address winner, uint256 amount);

//     event OfferCreated(
//         uint256 indexed itemId,
//         address indexed buyer,
//         uint256 price,
//         uint256 expirationTime
//     );

//     event OfferAccepted(
//         uint256 indexed itemId,
//         address indexed buyer,
//         uint256 price
//     );

//     // Constructor
//     constructor(address _factoryAddress) {
//         factoryAddress = _factoryAddress;
//     }

//     // Function to add a price history entry
//     function _addPriceHistory(
//         uint256 itemId,
//         uint256 price,
//         address seller,
//         address buyer,
//         PriceActionType actionType
//     ) internal {
//         PriceHistory memory history = PriceHistory(
//             block.timestamp,
//             price,
//             seller,
//             buyer,
//             actionType
//         );
//         _itemPriceHistory[itemId].push(history);
//     }

//     // Create Market Item (Fixed Price)
//     function createMarketItem(
//         address collectionAddress,
//         uint256 tokenId,
//         uint256 price
//     ) external payable nonReentrant {
//         require(price > 0, "Price must be greater than 0");
//         console.log(msg.value);
//         require(msg.value == LISTING_PRICE, "Must pay listing price");

//         // Verify collection exists
//         NFTCollectionFactory factory = NFTCollectionFactory(factoryAddress);
//         (, , address nftContract, , , , , , ) = factory.collections(
//             collectionAddress
//         );

//         require(nftContract != address(0), "Collection does not exist");

//         // NFTCollection collection = NFTCollection(collectionAddress);

//         // collection.approveMarketplace(address(this));

//         console.log("collection");

//         // uint256 tokenId = collection.mint(tokenURI);

//         uint256 itemId = _itemIds++;

//         _idToMarketItem[itemId] = MarketItem(
//             itemId,
//             collectionAddress,
//             tokenId,
//             payable(msg.sender),
//             payable(address(0)),
//             price,
//             false,
//             0,
//             address(0),
//             0,
//             false
//         );

//         IERC721(collectionAddress).transferFrom(
//             msg.sender,
//             address(this),
//             tokenId
//         );
//         factory.updateCollectionStats(collectionAddress, price, false);

//         // Add price history for listing
//         _addPriceHistory(
//             itemId,
//             price,
//             msg.sender,
//             address(0),
//             PriceActionType.LISTING
//         );

//         emit MarketItemCreated(
//             itemId,
//             nftContract,
//             tokenId,
//             msg.sender,
//             address(0),
//             price,
//             false,
//             0
//         );
//     }

//     function getListingPrice() public pure returns (uint256) {
//         return LISTING_PRICE;
//     }

//     // Create market sale for fixed price items
//     function createMarketSale(
//         address collectionAddress,
//         uint256 itemId
//     ) external payable nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         uint256 price = item.price;
//         uint256 tokenId = item.tokenId;

//         require(!item.isAuction, "Cannot buy auction items directly");
//         require(msg.value == price, "Please submit the asking price");
//         require(!item.sold, "Item already sold");

//         item.seller.transfer(msg.value);
//         IERC721(collectionAddress).transferFrom(
//             address(this),
//             msg.sender,
//             tokenId
//         );
//         item.owner = payable(msg.sender);
//         item.sold = true;
//         _itemsSold++;

//         // Update collection stats
//         NFTCollectionFactory(factoryAddress).updateCollectionStats(
//             collectionAddress,
//             price,
//             true
//         );

//         // Add price history for sale
//         _addPriceHistory(
//             itemId,
//             price,
//             item.seller,
//             msg.sender,
//             PriceActionType.SALE
//         );

//         payable(owner()).transfer(LISTING_PRICE);
//     }

//     // Fetch all unsold market items
//     function fetchMarketItems() external view returns (MarketItem[] memory) {
//         uint256 itemCount = _itemIds;
//         uint256 unsoldItemCount = _itemIds - _itemsSold;
//         uint256 currentIndex = 0;

//         MarketItem[] memory items = new MarketItem[](unsoldItemCount);

//         for (uint256 i = 0; i < itemCount; i++) {
//             if (!_idToMarketItem[i].sold) {
//                 MarketItem storage currentItem = _idToMarketItem[i];
//                 items[currentIndex] = currentItem;
//                 currentIndex++;
//             }
//         }

//         return items;
//     }

//     // Fetch NFTs owned by msg.sender
//     function fetchMyNFTs() external view returns (MarketItem[] memory) {
//         uint256 totalItemCount = _itemIds;
//         uint256 itemCount = 0;
//         uint256 currentIndex = 0;

//         // First, count the number of items owned by msg.sender
//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].owner == msg.sender) {
//                 itemCount++;
//             }
//         }

//         MarketItem[] memory items = new MarketItem[](itemCount);

//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].owner == msg.sender) {
//                 MarketItem storage currentItem = _idToMarketItem[i];
//                 items[currentIndex] = currentItem;
//                 currentIndex++;
//             }
//         }

//         return items;
//     }

//     // Fetch NFTs listed by msg.sender
//     function fetchMyListedNFTs() external view returns (MarketItem[] memory) {
//         uint256 totalItemCount = _itemIds;
//         uint256 itemCount = 0;
//         uint256 currentIndex = 0;

//         // First, count the number of items listed by msg.sender
//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].seller == msg.sender) {
//                 itemCount++;
//             }
//         }

//         MarketItem[] memory items = new MarketItem[](itemCount);

//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].seller == msg.sender) {
//                 MarketItem storage currentItem = _idToMarketItem[i];
//                 items[currentIndex] = currentItem;
//                 currentIndex++;
//             }
//         }

//         return items;
//     }

//     // Fetch price history for an item
//     function fetchPriceHistory(
//         uint256 itemId
//     ) external view returns (PriceHistory[] memory) {
//         return _itemPriceHistory[itemId];
//     }

//     // Get price statistics for an item
//     function getItemPriceStats(
//         uint256 itemId
//     )
//         external
//         view
//         returns (
//             uint256 lowestPrice,
//             uint256 highestPrice,
//             uint256 averagePrice,
//             uint256 totalSales
//         )
//     {
//         PriceHistory[] memory history = _itemPriceHistory[itemId];
//         uint256 total = 0;
//         uint256 salesCount = 0;
//         lowestPrice = type(uint256).max;
//         highestPrice = 0;

//         for (uint256 i = 0; i < history.length; i++) {
//             // Only consider actual sales, not listings
//             if (
//                 history[i].actionType == PriceActionType.SALE ||
//                 history[i].actionType == PriceActionType.AUCTION_END ||
//                 history[i].actionType == PriceActionType.OFFER_ACCEPTED
//             ) {
//                 uint256 price = history[i].price;
//                 if (price < lowestPrice) {
//                     lowestPrice = price;
//                 }
//                 if (price > highestPrice) {
//                     highestPrice = price;
//                 }
//                 total += price;
//                 salesCount++;
//             }
//         }

//         averagePrice = salesCount > 0 ? total / salesCount : 0;
//         totalSales = salesCount;

//         if (lowestPrice == type(uint256).max) {
//             lowestPrice = 0;
//         }
//     }

//     // Create Auction
//     function createAuction(
//         address nftContract,
//         uint256 tokenId,
//         uint256 startingPrice
//     ) external payable nonReentrant {
//         require(startingPrice > 0, "Starting price must be greater than 0");
//         require(msg.value == LISTING_PRICE, "Must pay listing price");

//         uint256 itemId = _itemIds++;
//         uint256 auctionEnd = block.timestamp + AUCTION_DURATION;

//         _idToMarketItem[itemId] = MarketItem(
//             itemId,
//             nftContract,
//             tokenId,
//             payable(msg.sender),
//             payable(address(0)),
//             startingPrice,
//             true,
//             auctionEnd,
//             address(0),
//             0,
//             false
//         );

//         IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

//         emit MarketItemCreated(
//             itemId,
//             nftContract,
//             tokenId,
//             msg.sender,
//             address(0),
//             startingPrice,
//             true,
//             auctionEnd
//         );
//     }

//     // Place Bid
//     function placeBid(uint256 itemId) external payable nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         require(item.isAuction, "Item is not an auction");
//         require(block.timestamp < item.auctionEndTime, "Auction ended");
//         require(msg.value >= item.price + MIN_AUCTION_INCREMENT, "Bid too low");

//         if (item.highestBidder != address(0)) {
//             _auctionPendingReturns[itemId][item.highestBidder] += item
//                 .highestBid;
//         }

//         item.highestBidder = msg.sender;
//         item.highestBid = msg.value;

//         // Add price history for bid
//         _addPriceHistory(
//             itemId,
//             msg.value,
//             item.seller,
//             msg.sender,
//             PriceActionType.AUCTION_BID
//         );

//         emit AuctionBid(itemId, msg.sender, msg.value);
//     }

//     // End Auction
//     function endAuction(uint256 itemId) external nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         require(item.isAuction, "Not an auction");
//         require(block.timestamp >= item.auctionEndTime, "Auction not ended");
//         require(!item.sold, "Auction already ended");

//         item.sold = true;
//         item.owner = payable(item.highestBidder);
//         _itemsSold++;

//         if (item.highestBidder != address(0)) {
//             item.seller.transfer(item.highestBid);
//             IERC721(item.nftContract).transferFrom(
//                 address(this),
//                 item.highestBidder,
//                 item.tokenId
//             );
//         } else {
//             IERC721(item.nftContract).transferFrom(
//                 address(this),
//                 item.seller,
//                 item.tokenId
//             );
//         }

//         payable(owner()).transfer(LISTING_PRICE);

//         emit AuctionEnded(itemId, item.highestBidder, item.highestBid);
//     }

//     // Withdraw Bid
//     function withdrawBid(uint256 itemId) external nonReentrant {
//         uint256 amount = _auctionPendingReturns[itemId][msg.sender];
//         require(amount > 0, "No funds to withdraw");

//         _auctionPendingReturns[itemId][msg.sender] = 0;
//         payable(msg.sender).transfer(amount);
//     }

//     // Make Offer
//     function makeOffer(
//         uint256 itemId,
//         uint256 expirationTime
//     ) external payable nonReentrant {
//         require(msg.value > 0, "Offer must be greater than 0");
//         require(
//             expirationTime > block.timestamp,
//             "Expiration must be in future"
//         );

//         MarketItem storage item = _idToMarketItem[itemId];
//         require(!item.sold, "Item already sold");
//         require(!item.isAuction, "Cannot make offers on auctions");

//         Offer memory newOffer = Offer(msg.sender, msg.value, expirationTime);
//         _itemOffers[itemId].push(newOffer);

//         emit OfferCreated(itemId, msg.sender, msg.value, expirationTime);
//     }

//     // Accept Offer
//     function acceptOffer(
//         uint256 itemId,
//         uint256 offerIndex
//     ) external nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         require(msg.sender == item.seller, "Only seller can accept");
//         require(!item.sold, "Item already sold");

//         Offer memory offer = _itemOffers[itemId][offerIndex];
//         require(block.timestamp <= offer.expirationTime, "Offer expired");

//         item.sold = true;
//         item.owner = payable(offer.buyer);
//         _itemsSold++;

//         // Transfer NFT to buyer
//         IERC721(item.nftContract).transferFrom(
//             address(this),
//             offer.buyer,
//             item.tokenId
//         );

//         // Transfer payment to seller
//         payable(item.seller).transfer(offer.price);
//         payable(owner()).transfer(LISTING_PRICE);

//         // Refund other offers
//         for (uint i = 0; i < _itemOffers[itemId].length; i++) {
//             if (
//                 i != offerIndex &&
//                 block.timestamp <= _itemOffers[itemId][i].expirationTime
//             ) {
//                 payable(_itemOffers[itemId][i].buyer).transfer(
//                     _itemOffers[itemId][i].price
//                 );
//             }
//         }

//         emit OfferAccepted(itemId, offer.buyer, offer.price);
//     }

//     // View Functions
//     function fetchMarketItem(
//         uint256 itemId
//     ) external view returns (MarketItem memory) {
//         return _idToMarketItem[itemId];
//     }

//     function fetchItemOffers(
//         uint256 itemId
//     ) external view returns (Offer[] memory) {
//         return _itemOffers[itemId];
//     }

//     function fetchActiveAuctions() external view returns (MarketItem[] memory) {
//         uint256 itemCount = _itemIds;
//         uint256 activeCount = 0;

//         for (uint256 i = 0; i < itemCount; i++) {
//             if (
//                 _idToMarketItem[i].isAuction &&
//                 !_idToMarketItem[i].sold &&
//                 block.timestamp < _idToMarketItem[i].auctionEndTime
//             ) {
//                 activeCount++;
//             }
//         }

//         MarketItem[] memory items = new MarketItem[](activeCount);
//         uint256 currentIndex = 0;

//         for (uint256 i = 0; i < itemCount; i++) {
//             if (
//                 _idToMarketItem[i].isAuction &&
//                 !_idToMarketItem[i].sold &&
//                 block.timestamp < _idToMarketItem[i].auctionEndTime
//             ) {
//                 items[currentIndex] = _idToMarketItem[i];
//                 currentIndex++;
//             }
//         }
//         return items;
//     }

//     function _findPriceAtTime(
//         PriceHistory[] memory history,
//         uint256 targetTime
//     ) private pure returns (uint256) {
//         for (uint256 i = history.length; i > 0; i--) {
//             if (history[i - 1].timestamp <= targetTime) {
//                 return history[i - 1].price;
//             }
//         }
//         return 0;
//     }
// }

// contract NFTMarketplace is ReentrancyGuard, Ownable(msg.sender) {
//     using Strings for uint256;

//     struct MarketItem {
//         uint256 itemId;
//         address nftContract;
//         uint256 tokenId;
//         address payable seller;
//         address payable owner;
//         uint256 price;
//         bool isAuction;
//         uint256 auctionEndTime;
//         address highestBidder;
//         uint256 highestBid;
//         bool sold;
//     }

//     struct Offer {
//         address buyer;
//         uint256 price;
//         uint256 expirationTime;
//     }

//     struct PriceHistory {
//         uint256 timestamp;
//         uint256 price;
//         address seller;
//         address buyer;
//         PriceActionType actionType;
//     }

//     enum PriceActionType {
//         LISTING,
//         SALE,
//         AUCTION_BID,
//         AUCTION_END,
//         OFFER_ACCEPTED
//     }

//     enum SaleType {
//         ALL,
//         FIXED_PRICE,
//         AUCTION
//     }

//     enum SortOrder {
//         PRICE_LOW_TO_HIGH,
//         PRICE_HIGH_TO_LOW,
//         NEWEST_FIRST,
//         OLDEST_FIRST
//     }

//     uint256 private _itemIds;
//     uint256 private _itemsSold;
//     uint256 public constant AUCTION_DURATION = 7 days;
//     uint256 public constant MIN_AUCTION_INCREMENT = 0.01 ether;
//     uint256 public constant LISTING_PRICE = 0.0005 ether;
//     address public immutable factoryAddress;

//     mapping(uint256 => MarketItem) private _idToMarketItem;
//     mapping(uint256 => mapping(address => uint256))
//         private _auctionPendingReturns;
//     mapping(uint256 => Offer[]) private _itemOffers;
//     mapping(uint256 => PriceHistory[]) private _itemPriceHistory;

//     event MarketItemCreated(
//         uint256 indexed itemId,
//         address indexed nftContract,
//         uint256 indexed tokenId,
//         address seller,
//         address owner,
//         uint256 price,
//         bool isAuction,
//         uint256 auctionEndTime
//     );

//     event AuctionBid(
//         uint256 indexed itemId,
//         address indexed bidder,
//         uint256 bid
//     );

//     event AuctionEnded(uint256 indexed itemId, address winner, uint256 amount);

//     event OfferCreated(
//         uint256 indexed itemId,
//         address indexed buyer,
//         uint256 price,
//         uint256 expirationTime
//     );

//     event OfferAccepted(
//         uint256 indexed itemId,
//         address indexed buyer,
//         uint256 price
//     );

//     // Constructor
//     constructor(address _factoryAddress) {
//         factoryAddress = _factoryAddress;
//     }

//     // Function to add a price history entry
//     function _addPriceHistory(
//         uint256 itemId,
//         uint256 price,
//         address seller,
//         address buyer,
//         PriceActionType actionType
//     ) internal {
//         PriceHistory memory history = PriceHistory(
//             block.timestamp,
//             price,
//             seller,
//             buyer,
//             actionType
//         );
//         _itemPriceHistory[itemId].push(history);
//     }

//     // Create Market Item (Fixed Price)
//     function createMarketItem(
//         address collectionAddress,
//         uint256 tokenId,
//         uint256 price
//     ) external payable nonReentrant {
//         require(price > 0, "Price must be greater than 0");
//         console.log(msg.value);
//         require(msg.value == LISTING_PRICE, "Must pay listing price");

//         // Verify collection exists
//         NFTCollectionFactory factory = NFTCollectionFactory(factoryAddress);
//         (, , address nftContract, , , , , , ) = factory.collections(
//             collectionAddress
//         );

//         require(nftContract != address(0), "Collection does not exist");

//         // NFTCollection collection = NFTCollection(collectionAddress);

//         // collection.approveMarketplace(address(this));

//         console.log("collection");

//         // uint256 tokenId = collection.mint(tokenURI);

//         uint256 itemId = _itemIds++;

//         _idToMarketItem[itemId] = MarketItem(
//             itemId,
//             collectionAddress,
//             tokenId,
//             payable(msg.sender),
//             payable(address(0)),
//             price,
//             false,
//             0,
//             address(0),
//             0,
//             false
//         );

//         IERC721(collectionAddress).transferFrom(
//             msg.sender,
//             address(this),
//             tokenId
//         );
//         factory.updateCollectionStats(collectionAddress, price, false);

//         // Add price history for listing
//         _addPriceHistory(
//             itemId,
//             price,
//             msg.sender,
//             address(0),
//             PriceActionType.LISTING
//         );

//         emit MarketItemCreated(
//             itemId,
//             nftContract,
//             tokenId,
//             msg.sender,
//             address(0),
//             price,
//             false,
//             0
//         );
//     }

//     function getListingPrice() public pure returns (uint256) {
//         return LISTING_PRICE;
//     }

//     // Create market sale for fixed price items
//     function createMarketSale(
//         address collectionAddress,
//         uint256 itemId
//     ) external payable nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         uint256 price = item.price;
//         uint256 tokenId = item.tokenId;

//         require(!item.isAuction, "Cannot buy auction items directly");
//         require(msg.value == price, "Please submit the asking price");
//         require(!item.sold, "Item already sold");

//         item.seller.transfer(msg.value);
//         IERC721(collectionAddress).transferFrom(
//             address(this),
//             msg.sender,
//             tokenId
//         );
//         item.owner = payable(msg.sender);
//         item.sold = true;
//         _itemsSold++;

//         // Update collection stats
//         NFTCollectionFactory(factoryAddress).updateCollectionStats(
//             collectionAddress,
//             price,
//             true
//         );

//         // Add price history for sale
//         _addPriceHistory(
//             itemId,
//             price,
//             item.seller,
//             msg.sender,
//             PriceActionType.SALE
//         );

//         payable(owner()).transfer(LISTING_PRICE);
//     }

//     // Fetch all unsold market items
//     function fetchMarketItems() external view returns (MarketItem[] memory) {
//         uint256 itemCount = _itemIds;
//         uint256 unsoldItemCount = _itemIds - _itemsSold;
//         uint256 currentIndex = 0;

//         MarketItem[] memory items = new MarketItem[](unsoldItemCount);

//         for (uint256 i = 0; i < itemCount; i++) {
//             if (!_idToMarketItem[i].sold) {
//                 MarketItem storage currentItem = _idToMarketItem[i];
//                 items[currentIndex] = currentItem;
//                 currentIndex++;
//             }
//         }

//         return items;
//     }

//     // Fetch NFTs owned by msg.sender
//     function fetchMyNFTs() external view returns (MarketItem[] memory) {
//         uint256 totalItemCount = _itemIds;
//         uint256 itemCount = 0;
//         uint256 currentIndex = 0;

//         // First, count the number of items owned by msg.sender
//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].owner == msg.sender) {
//                 itemCount++;
//             }
//         }

//         MarketItem[] memory items = new MarketItem[](itemCount);

//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].owner == msg.sender) {
//                 MarketItem storage currentItem = _idToMarketItem[i];
//                 items[currentIndex] = currentItem;
//                 currentIndex++;
//             }
//         }

//         return items;
//     }

//     // Fetch NFTs listed by msg.sender
//     function fetchMyListedNFTs() external view returns (MarketItem[] memory) {
//         uint256 totalItemCount = _itemIds;
//         uint256 itemCount = 0;
//         uint256 currentIndex = 0;

//         // First, count the number of items listed by msg.sender
//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].seller == msg.sender) {
//                 itemCount++;
//             }
//         }

//         MarketItem[] memory items = new MarketItem[](itemCount);

//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].seller == msg.sender) {
//                 MarketItem storage currentItem = _idToMarketItem[i];
//                 items[currentIndex] = currentItem;
//                 currentIndex++;
//             }
//         }

//         return items;
//     }

//     // Fetch price history for an item
//     function fetchPriceHistory(
//         uint256 itemId
//     ) external view returns (PriceHistory[] memory) {
//         return _itemPriceHistory[itemId];
//     }

//     // Get price statistics for an item
//     function getItemPriceStats(
//         uint256 itemId
//     )
//         external
//         view
//         returns (
//             uint256 lowestPrice,
//             uint256 highestPrice,
//             uint256 averagePrice,
//             uint256 totalSales
//         )
//     {
//         PriceHistory[] memory history = _itemPriceHistory[itemId];
//         uint256 total = 0;
//         uint256 salesCount = 0;
//         lowestPrice = type(uint256).max;
//         highestPrice = 0;

//         for (uint256 i = 0; i < history.length; i++) {
//             // Only consider actual sales, not listings
//             if (
//                 history[i].actionType == PriceActionType.SALE ||
//                 history[i].actionType == PriceActionType.AUCTION_END ||
//                 history[i].actionType == PriceActionType.OFFER_ACCEPTED
//             ) {
//                 uint256 price = history[i].price;
//                 if (price < lowestPrice) {
//                     lowestPrice = price;
//                 }
//                 if (price > highestPrice) {
//                     highestPrice = price;
//                 }
//                 total += price;
//                 salesCount++;
//             }
//         }

//         averagePrice = salesCount > 0 ? total / salesCount : 0;
//         totalSales = salesCount;

//         if (lowestPrice == type(uint256).max) {
//             lowestPrice = 0;
//         }
//     }

//     // Create Auction
//     function createAuction(
//         address nftContract,
//         uint256 tokenId,
//         uint256 startingPrice
//     ) external payable nonReentrant {
//         require(startingPrice > 0, "Starting price must be greater than 0");
//         require(msg.value == LISTING_PRICE, "Must pay listing price");

//         uint256 itemId = _itemIds++;
//         uint256 auctionEnd = block.timestamp + AUCTION_DURATION;

//         _idToMarketItem[itemId] = MarketItem(
//             itemId,
//             nftContract,
//             tokenId,
//             payable(msg.sender),
//             payable(address(0)),
//             startingPrice,
//             true,
//             auctionEnd,
//             address(0),
//             0,
//             false
//         );

//         IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

//         emit MarketItemCreated(
//             itemId,
//             nftContract,
//             tokenId,
//             msg.sender,
//             address(0),
//             startingPrice,
//             true,
//             auctionEnd
//         );
//     }

//     // Place Bid
//     function placeBid(uint256 itemId) external payable nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         require(item.isAuction, "Item is not an auction");
//         require(block.timestamp < item.auctionEndTime, "Auction ended");
//         require(msg.value >= item.price + MIN_AUCTION_INCREMENT, "Bid too low");

//         if (item.highestBidder != address(0)) {
//             _auctionPendingReturns[itemId][item.highestBidder] += item
//                 .highestBid;
//         }

//         item.highestBidder = msg.sender;
//         item.highestBid = msg.value;

//         // Add price history for bid
//         _addPriceHistory(
//             itemId,
//             msg.value,
//             item.seller,
//             msg.sender,
//             PriceActionType.AUCTION_BID
//         );

//         emit AuctionBid(itemId, msg.sender, msg.value);
//     }

//     // End Auction
//     function endAuction(uint256 itemId) external nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         require(item.isAuction, "Not an auction");
//         require(block.timestamp >= item.auctionEndTime, "Auction not ended");
//         require(!item.sold, "Auction already ended");

//         item.sold = true;
//         item.owner = payable(item.highestBidder);
//         _itemsSold++;

//         if (item.highestBidder != address(0)) {
//             item.seller.transfer(item.highestBid);
//             IERC721(item.nftContract).transferFrom(
//                 address(this),
//                 item.highestBidder,
//                 item.tokenId
//             );
//         } else {
//             IERC721(item.nftContract).transferFrom(
//                 address(this),
//                 item.seller,
//                 item.tokenId
//             );
//         }

//         payable(owner()).transfer(LISTING_PRICE);

//         emit AuctionEnded(itemId, item.highestBidder, item.highestBid);
//     }

//     // Withdraw Bid
//     function withdrawBid(uint256 itemId) external nonReentrant {
//         uint256 amount = _auctionPendingReturns[itemId][msg.sender];
//         require(amount > 0, "No funds to withdraw");

//         _auctionPendingReturns[itemId][msg.sender] = 0;
//         payable(msg.sender).transfer(amount);
//     }

//     // Make Offer
//     function makeOffer(
//         uint256 itemId,
//         uint256 expirationTime
//     ) external payable nonReentrant {
//         require(msg.value > 0, "Offer must be greater than 0");
//         require(
//             expirationTime > block.timestamp,
//             "Expiration must be in future"
//         );

//         MarketItem storage item = _idToMarketItem[itemId];
//         require(!item.sold, "Item already sold");
//         require(!item.isAuction, "Cannot make offers on auctions");

//         Offer memory newOffer = Offer(msg.sender, msg.value, expirationTime);
//         _itemOffers[itemId].push(newOffer);

//         emit OfferCreated(itemId, msg.sender, msg.value, expirationTime);
//     }

//     // Accept Offer
//     function acceptOffer(
//         uint256 itemId,
//         uint256 offerIndex
//     ) external nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         require(msg.sender == item.seller, "Only seller can accept");
//         require(!item.sold, "Item already sold");

//         Offer memory offer = _itemOffers[itemId][offerIndex];
//         require(block.timestamp <= offer.expirationTime, "Offer expired");

//         item.sold = true;
//         item.owner = payable(offer.buyer);
//         _itemsSold++;

//         // Transfer NFT to buyer
//         IERC721(item.nftContract).transferFrom(
//             address(this),
//             offer.buyer,
//             item.tokenId
//         );

//         // Transfer payment to seller
//         payable(item.seller).transfer(offer.price);
//         payable(owner()).transfer(LISTING_PRICE);

//         // Refund other offers
//         for (uint i = 0; i < _itemOffers[itemId].length; i++) {
//             if (
//                 i != offerIndex &&
//                 block.timestamp <= _itemOffers[itemId][i].expirationTime
//             ) {
//                 payable(_itemOffers[itemId][i].buyer).transfer(
//                     _itemOffers[itemId][i].price
//                 );
//             }
//         }

//         emit OfferAccepted(itemId, offer.buyer, offer.price);
//     }

//     // View Functions
//     function fetchMarketItem(
//         uint256 itemId
//     ) external view returns (MarketItem memory) {
//         return _idToMarketItem[itemId];
//     }

//     function fetchItemOffers(
//         uint256 itemId
//     ) external view returns (Offer[] memory) {
//         return _itemOffers[itemId];
//     }

//     function fetchActiveAuctions() external view returns (MarketItem[] memory) {
//         uint256 itemCount = _itemIds;
//         uint256 activeCount = 0;

//         for (uint256 i = 0; i < itemCount; i++) {
//             if (
//                 _idToMarketItem[i].isAuction &&
//                 !_idToMarketItem[i].sold &&
//                 block.timestamp < _idToMarketItem[i].auctionEndTime
//             ) {
//                 activeCount++;
//             }
//         }

//         MarketItem[] memory items = new MarketItem[](activeCount);
//         uint256 currentIndex = 0;

//         for (uint256 i = 0; i < itemCount; i++) {
//             if (
//                 _idToMarketItem[i].isAuction &&
//                 !_idToMarketItem[i].sold &&
//                 block.timestamp < _idToMarketItem[i].auctionEndTime
//             ) {
//                 items[currentIndex] = _idToMarketItem[i];
//                 currentIndex++;
//             }
//         }
//         return items;
//     }

//     function _findPriceAtTime(
//         PriceHistory[] memory history,
//         uint256 targetTime
//     ) private pure returns (uint256) {
//         for (uint256 i = history.length; i > 0; i--) {
//             if (history[i - 1].timestamp <= targetTime) {
//                 return history[i - 1].price;
//             }
//         }
//         return 0;
//     }
// }

// contract NFTMarketplace is ReentrancyGuard, Ownable(msg.sender) {
//     using Strings for uint256;

//     struct MarketItem {
//         uint256 itemId;
//         address nftContract;
//         uint256 tokenId;
//         address payable seller;
//         address payable owner;
//         uint256 price;
//         bool isAuction;
//         uint256 auctionEndTime;
//         address highestBidder;
//         uint256 highestBid;
//         bool sold;
//     }

//     struct Offer {
//         address buyer;
//         uint256 price;
//         uint256 expirationTime;
//     }

//     struct PriceHistory {
//         uint256 timestamp;
//         uint256 price;
//         address seller;
//         address buyer;
//         PriceActionType actionType;
//     }

//     enum PriceActionType {
//         LISTING,
//         SALE,
//         AUCTION_BID,
//         AUCTION_END,
//         OFFER_ACCEPTED
//     }

//     enum SaleType {
//         ALL,
//         FIXED_PRICE,
//         AUCTION
//     }

//     enum SortOrder {
//         PRICE_LOW_TO_HIGH,
//         PRICE_HIGH_TO_LOW,
//         NEWEST_FIRST,
//         OLDEST_FIRST
//     }

//     uint256 private _itemIds;
//     uint256 private _itemsSold;
//     uint256 public constant AUCTION_DURATION = 7 days;
//     uint256 public constant MIN_AUCTION_INCREMENT = 0.01 ether;
//     uint256 public constant LISTING_PRICE = 0.0005 ether;
//     address public immutable factoryAddress;

//     mapping(uint256 => MarketItem) private _idToMarketItem;
//     mapping(uint256 => mapping(address => uint256))
//         private _auctionPendingReturns;
//     mapping(uint256 => Offer[]) private _itemOffers;
//     mapping(uint256 => PriceHistory[]) private _itemPriceHistory;

//     event MarketItemCreated(
//         uint256 indexed itemId,
//         address indexed nftContract,
//         uint256 indexed tokenId,
//         address seller,
//         address owner,
//         uint256 price,
//         bool isAuction,
//         uint256 auctionEndTime
//     );

//     event AuctionBid(
//         uint256 indexed itemId,
//         address indexed bidder,
//         uint256 bid
//     );

//     event AuctionEnded(uint256 indexed itemId, address winner, uint256 amount);

//     event OfferCreated(
//         uint256 indexed itemId,
//         address indexed buyer,
//         uint256 price,
//         uint256 expirationTime
//     );

//     event OfferAccepted(
//         uint256 indexed itemId,
//         address indexed buyer,
//         uint256 price
//     );

//     // Constructor
//     constructor(address _factoryAddress) {
//         factoryAddress = _factoryAddress;
//     }

//     // Function to add a price history entry
//     function _addPriceHistory(
//         uint256 itemId,
//         uint256 price,
//         address seller,
//         address buyer,
//         PriceActionType actionType
//     ) internal {
//         PriceHistory memory history = PriceHistory(
//             block.timestamp,
//             price,
//             seller,
//             buyer,
//             actionType
//         );
//         _itemPriceHistory[itemId].push(history);
//     }

//     // Create Market Item (Fixed Price)
//     function createMarketItem(
//         address collectionAddress,
//         uint256 tokenId,
//         uint256 price
//     ) external payable nonReentrant {
//         require(price > 0, "Price must be greater than 0");
//         console.log(msg.value);
//         require(msg.value == LISTING_PRICE, "Must pay listing price");

//         // Verify collection exists
//         NFTCollectionFactory factory = NFTCollectionFactory(factoryAddress);
//         (, , address nftContract, , , , , , ) = factory.collections(
//             collectionAddress
//         );

//         require(nftContract != address(0), "Collection does not exist");

//         // NFTCollection collection = NFTCollection(collectionAddress);

//         // collection.approveMarketplace(address(this));

//         console.log("collection");

//         // uint256 tokenId = collection.mint(tokenURI);

//         uint256 itemId = _itemIds++;

//         _idToMarketItem[itemId] = MarketItem(
//             itemId,
//             collectionAddress,
//             tokenId,
//             payable(msg.sender),
//             payable(address(0)),
//             price,
//             false,
//             0,
//             address(0),
//             0,
//             false
//         );

//         IERC721(collectionAddress).transferFrom(
//             msg.sender,
//             address(this),
//             tokenId
//         );
//         factory.updateCollectionStats(collectionAddress, price, false);

//         // Add price history for listing
//         _addPriceHistory(
//             itemId,
//             price,
//             msg.sender,
//             address(0),
//             PriceActionType.LISTING
//         );

//         emit MarketItemCreated(
//             itemId,
//             nftContract,
//             tokenId,
//             msg.sender,
//             address(0),
//             price,
//             false,
//             0
//         );
//     }

//     function getListingPrice() public pure returns (uint256) {
//         return LISTING_PRICE;
//     }

//     // Create market sale for fixed price items
//     function createMarketSale(
//         address collectionAddress,
//         uint256 itemId
//     ) external payable nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         uint256 price = item.price;
//         uint256 tokenId = item.tokenId;

//         require(!item.isAuction, "Cannot buy auction items directly");
//         require(msg.value == price, "Please submit the asking price");
//         require(!item.sold, "Item already sold");

//         item.seller.transfer(msg.value);
//         IERC721(collectionAddress).transferFrom(
//             address(this),
//             msg.sender,
//             tokenId
//         );
//         item.owner = payable(msg.sender);
//         item.sold = true;
//         _itemsSold++;

//         // Update collection stats
//         NFTCollectionFactory(factoryAddress).updateCollectionStats(
//             collectionAddress,
//             price,
//             true
//         );

//         // Add price history for sale
//         _addPriceHistory(
//             itemId,
//             price,
//             item.seller,
//             msg.sender,
//             PriceActionType.SALE
//         );

//         payable(owner()).transfer(LISTING_PRICE);
//     }

//     // Fetch all unsold market items
//     function fetchMarketItems() external view returns (MarketItem[] memory) {
//         uint256 itemCount = _itemIds;
//         uint256 unsoldItemCount = _itemIds - _itemsSold;
//         uint256 currentIndex = 0;

//         MarketItem[] memory items = new MarketItem[](unsoldItemCount);

//         for (uint256 i = 0; i < itemCount; i++) {
//             if (!_idToMarketItem[i].sold) {
//                 MarketItem storage currentItem = _idToMarketItem[i];
//                 items[currentIndex] = currentItem;
//                 currentIndex++;
//             }
//         }

//         return items;
//     }

//     // Fetch NFTs owned by msg.sender
//     function fetchMyNFTs() external view returns (MarketItem[] memory) {
//         uint256 totalItemCount = _itemIds;
//         uint256 itemCount = 0;
//         uint256 currentIndex = 0;

//         // First, count the number of items owned by msg.sender
//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].owner == msg.sender) {
//                 itemCount++;
//             }
//         }

//         MarketItem[] memory items = new MarketItem[](itemCount);

//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].owner == msg.sender) {
//                 MarketItem storage currentItem = _idToMarketItem[i];
//                 items[currentIndex] = currentItem;
//                 currentIndex++;
//             }
//         }

//         return items;
//     }

//     // Fetch NFTs listed by msg.sender
//     function fetchMyListedNFTs() external view returns (MarketItem[] memory) {
//         uint256 totalItemCount = _itemIds;
//         uint256 itemCount = 0;
//         uint256 currentIndex = 0;

//         // First, count the number of items listed by msg.sender
//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].seller == msg.sender) {
//                 itemCount++;
//             }
//         }

//         MarketItem[] memory items = new MarketItem[](itemCount);

//         for (uint256 i = 0; i < totalItemCount; i++) {
//             if (_idToMarketItem[i].seller == msg.sender) {
//                 MarketItem storage currentItem = _idToMarketItem[i];
//                 items[currentIndex] = currentItem;
//                 currentIndex++;
//             }
//         }

//         return items;
//     }

//     // Fetch price history for an item
//     function fetchPriceHistory(
//         uint256 itemId
//     ) external view returns (PriceHistory[] memory) {
//         return _itemPriceHistory[itemId];
//     }

//     // Get price statistics for an item
//     function getItemPriceStats(
//         uint256 itemId
//     )
//         external
//         view
//         returns (
//             uint256 lowestPrice,
//             uint256 highestPrice,
//             uint256 averagePrice,
//             uint256 totalSales
//         )
//     {
//         PriceHistory[] memory history = _itemPriceHistory[itemId];
//         uint256 total = 0;
//         uint256 salesCount = 0;
//         lowestPrice = type(uint256).max;
//         highestPrice = 0;

//         for (uint256 i = 0; i < history.length; i++) {
//             // Only consider actual sales, not listings
//             if (
//                 history[i].actionType == PriceActionType.SALE ||
//                 history[i].actionType == PriceActionType.AUCTION_END ||
//                 history[i].actionType == PriceActionType.OFFER_ACCEPTED
//             ) {
//                 uint256 price = history[i].price;
//                 if (price < lowestPrice) {
//                     lowestPrice = price;
//                 }
//                 if (price > highestPrice) {
//                     highestPrice = price;
//                 }
//                 total += price;
//                 salesCount++;
//             }
//         }

//         averagePrice = salesCount > 0 ? total / salesCount : 0;
//         totalSales = salesCount;

//         if (lowestPrice == type(uint256).max) {
//             lowestPrice = 0;
//         }
//     }

//     // Create Auction
//     function createAuction(
//         address nftContract,
//         uint256 tokenId,
//         uint256 startingPrice
//     ) external payable nonReentrant {
//         require(startingPrice > 0, "Starting price must be greater than 0");
//         require(msg.value == LISTING_PRICE, "Must pay listing price");

//         uint256 itemId = _itemIds++;
//         uint256 auctionEnd = block.timestamp + AUCTION_DURATION;

//         _idToMarketItem[itemId] = MarketItem(
//             itemId,
//             nftContract,
//             tokenId,
//             payable(msg.sender),
//             payable(address(0)),
//             startingPrice,
//             true,
//             auctionEnd,
//             address(0),
//             0,
//             false
//         );

//         IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

//         emit MarketItemCreated(
//             itemId,
//             nftContract,
//             tokenId,
//             msg.sender,
//             address(0),
//             startingPrice,
//             true,
//             auctionEnd
//         );
//     }

//     // Place Bid
//     function placeBid(uint256 itemId) external payable nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         require(item.isAuction, "Item is not an auction");
//         require(block.timestamp < item.auctionEndTime, "Auction ended");
//         require(msg.value >= item.price + MIN_AUCTION_INCREMENT, "Bid too low");

//         if (item.highestBidder != address(0)) {
//             _auctionPendingReturns[itemId][item.highestBidder] += item
//                 .highestBid;
//         }

//         item.highestBidder = msg.sender;
//         item.highestBid = msg.value;

//         // Add price history for bid
//         _addPriceHistory(
//             itemId,
//             msg.value,
//             item.seller,
//             msg.sender,
//             PriceActionType.AUCTION_BID
//         );

//         emit AuctionBid(itemId, msg.sender, msg.value);
//     }

//     // End Auction
//     function endAuction(uint256 itemId) external nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         require(item.isAuction, "Not an auction");
//         require(block.timestamp >= item.auctionEndTime, "Auction not ended");
//         require(!item.sold, "Auction already ended");

//         item.sold = true;
//         item.owner = payable(item.highestBidder);
//         _itemsSold++;

//         if (item.highestBidder != address(0)) {
//             item.seller.transfer(item.highestBid);
//             IERC721(item.nftContract).transferFrom(
//                 address(this),
//                 item.highestBidder,
//                 item.tokenId
//             );
//         } else {
//             IERC721(item.nftContract).transferFrom(
//                 address(this),
//                 item.seller,
//                 item.tokenId
//             );
//         }

//         payable(owner()).transfer(LISTING_PRICE);

//         emit AuctionEnded(itemId, item.highestBidder, item.highestBid);
//     }

//     // Withdraw Bid
//     function withdrawBid(uint256 itemId) external nonReentrant {
//         uint256 amount = _auctionPendingReturns[itemId][msg.sender];
//         require(amount > 0, "No funds to withdraw");

//         _auctionPendingReturns[itemId][msg.sender] = 0;
//         payable(msg.sender).transfer(amount);
//     }

//     // Make Offer
//     function makeOffer(
//         uint256 itemId,
//         uint256 expirationTime
//     ) external payable nonReentrant {
//         require(msg.value > 0, "Offer must be greater than 0");
//         require(
//             expirationTime > block.timestamp,
//             "Expiration must be in future"
//         );

//         MarketItem storage item = _idToMarketItem[itemId];
//         require(!item.sold, "Item already sold");
//         require(!item.isAuction, "Cannot make offers on auctions");

//         Offer memory newOffer = Offer(msg.sender, msg.value, expirationTime);
//         _itemOffers[itemId].push(newOffer);

//         emit OfferCreated(itemId, msg.sender, msg.value, expirationTime);
//     }

//     // Accept Offer
//     function acceptOffer(
//         uint256 itemId,
//         uint256 offerIndex
//     ) external nonReentrant {
//         MarketItem storage item = _idToMarketItem[itemId];
//         require(msg.sender == item.seller, "Only seller can accept");
//         require(!item.sold, "Item already sold");

//         Offer memory offer = _itemOffers[itemId][offerIndex];
//         require(block.timestamp <= offer.expirationTime, "Offer expired");

//         item.sold = true;
//         item.owner = payable(offer.buyer);
//         _itemsSold++;

//         // Transfer NFT to buyer
//         IERC721(item.nftContract).transferFrom(
//             address(this),
//             offer.buyer,
//             item.tokenId
//         );

//         // Transfer payment to seller
//         payable(item.seller).transfer(offer.price);
//         payable(owner()).transfer(LISTING_PRICE);

//         // Refund other offers
//         for (uint i = 0; i < _itemOffers[itemId].length; i++) {
//             if (
//                 i != offerIndex &&
//                 block.timestamp <= _itemOffers[itemId][i].expirationTime
//             ) {
//                 payable(_itemOffers[itemId][i].buyer).transfer(
//                     _itemOffers[itemId][i].price
//                 );
//             }
//         }

//         emit OfferAccepted(itemId, offer.buyer, offer.price);
//     }

//     // View Functions
//     function fetchMarketItem(
//         uint256 itemId
//     ) external view returns (MarketItem memory) {
//         return _idToMarketItem[itemId];
//     }

//     function fetchItemOffers(
//         uint256 itemId
//     ) external view returns (Offer[] memory) {
//         return _itemOffers[itemId];
//     }

//     function fetchActiveAuctions() external view returns (MarketItem[] memory) {
//         uint256 itemCount = _itemIds;
//         uint256 activeCount = 0;

//         for (uint256 i = 0; i < itemCount; i++) {
//             if (
//                 _idToMarketItem[i].isAuction &&
//                 !_idToMarketItem[i].sold &&
//                 block.timestamp < _idToMarketItem[i].auctionEndTime
//             ) {
//                 activeCount++;
//             }
//         }

//         MarketItem[] memory items = new MarketItem[](activeCount);
//         uint256 currentIndex = 0;

//         for (uint256 i = 0; i < itemCount; i++) {
//             if (
//                 _idToMarketItem[i].isAuction &&
//                 !_idToMarketItem[i].sold &&
//                 block.timestamp < _idToMarketItem[i].auctionEndTime
//             ) {
//                 items[currentIndex] = _idToMarketItem[i];
//                 currentIndex++;
//             }
//         }
//         return items;
//     }

//     function _findPriceAtTime(
//         PriceHistory[] memory history,
//         uint256 targetTime
//     ) private pure returns (uint256) {
//         for (uint256 i = history.length; i > 0; i--) {
//             if (history[i - 1].timestamp <= targetTime) {
//                 return history[i - 1].price;
//             }
//         }
//         return 0;
//     }
// }
