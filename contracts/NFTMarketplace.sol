// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./NFTCollection.sol";

contract NFTMarketplace is ReentrancyGuard, Pausable, Ownable {
    struct Collection {
        address collectionAddress;
        string name;
        string symbol;
        string category;
        address owner;
        bool isActive;
        uint256 createdAt;
        string baseURI;        
        uint256 totalSupply; 
    }

    struct CollectionDetails {
        Collection basic;
        uint256 floorPrice;
        uint256 totalVolume;
        uint256 ownerCount;
    }

    struct MarketItem {
        uint256 tokenId;
        address nftContract;
        address seller;
        address owner;
        uint256 price;
        bool isOnSale;
        uint256 auctionEndTime;
        address highestBidder;
        uint256 highestBid;
        bool isAuction;
        string tokenURI;  // Added tokenURI field
    }

    struct Offer {
        address buyer;
        uint256 price;
        uint256 timestamp;
    }

    // Category management
    string[] private categories;
    mapping(string => bool) private categoryExists;

    // Collection management
    mapping(address => Collection) private collections;
    address[] private collectionAddresses;
    mapping(string => address[]) private categoryToCollections;  // Added mapping for category-based collection lookup

    
    // Market items organized by collection
    mapping(address => mapping(uint256 => MarketItem)) private collectionToMarketItems;
    mapping(address => uint256[]) private collectionTokenIds;
    
    mapping(address => mapping(uint256 => mapping(address => uint256))) private pendingReturns;
    mapping(address => mapping(uint256 => Offer[])) private itemOffers;

    mapping(address => address[]) private userCreatedCollections;
    mapping(address => mapping(address => mapping(uint256 => bool))) private userPurchases; // user -> collection -> tokenId -> bool
    mapping(address => uint256) private userPurchaseCount;
    
    uint256 public listingFee = 0.0005 ether;

    event CollectionCreated(
        address indexed collectionAddress,
        string name,
        string symbol,
        string category,
        address indexed owner
    );

    event CategoryAdded(string category);

    event MarketItemCreated(
        address indexed collectionAddress,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price
    );

    event MarketItemSold(
        address indexed collectionAddress,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price
    );

    constructor() Ownable(msg.sender) {
        addCategory("Art");
        addCategory("Gaming");
        addCategory("Memberships");
        addCategory("Music");
        addCategory("PFPs");
        addCategory("Photography");
    }

    function addCategory(string memory category) public onlyOwner {
        require(!categoryExists[category], "Category already exists");
        categories.push(category);
        categoryExists[category] = true;
        emit CategoryAdded(category);
    }

    function getCategories() public view returns (string[] memory) {
        return categories;
    }

    
    function fetchUserCreatedCollections(address user) 
        public 
        view 
        returns (CollectionDetails[] memory) 
    {
        address[] memory userCollections = userCreatedCollections[user];
        CollectionDetails[] memory details = new CollectionDetails[](userCollections.length);
        
        for (uint256 i = 0; i < userCollections.length; i++) {
            details[i] = fetchCollectionDetails(userCollections[i]);
        }
        
        return details;
    }

   
    function fetchUserPurchasedItems(address user) 
        public 
        view 
        returns (MarketItem[] memory purchasedItems) 
    {
        uint256 totalItemCount = userPurchaseCount[user];
        uint256 currentIndex = 0;
        purchasedItems = new MarketItem[](totalItemCount);

        // Iterate through all collections
        for (uint256 i = 0; i < collectionAddresses.length; i++) {
            address collectionAddress = collectionAddresses[i];
            uint256[] memory tokenIds = collectionTokenIds[collectionAddress];
            
            // Check each token in the collection
            for (uint256 j = 0; j < tokenIds.length; j++) {
                uint256 tokenId = tokenIds[j];
                if (userPurchases[user][collectionAddress][tokenId]) {
                    purchasedItems[currentIndex] = collectionToMarketItems[collectionAddress][tokenId];
                    currentIndex++;
                }
            }
        }

        return purchasedItems;
    }

    function createCollection(
        string memory name,
        string memory symbol,
        string memory baseURI,
        string memory category
    ) public returns (address) {
        require(categoryExists[category], "Invalid category");
        
        address collectionOwner = msg.sender;

        NFTCollection newCollection = new NFTCollection(
            name,
            symbol,
            baseURI,
            address(this),
            category,
            collectionOwner
        );
        
        address collectionAddress = address(newCollection);
        
        collections[collectionAddress] = Collection({
            collectionAddress: collectionAddress,
            name: name,
            symbol: symbol,
            category: category,
            owner: collectionOwner,
            isActive: true,
            createdAt: block.timestamp,
            baseURI: baseURI,
            totalSupply: 0
        });
        
        collectionAddresses.push(collectionAddress);
        categoryToCollections[category].push(collectionAddress);
        
        emit CollectionCreated(
            collectionAddress,
            name,
            symbol,
            category,
            collectionOwner
        );

        userCreatedCollections[msg.sender].push(collectionAddress);

        return collectionAddress;
    }

    function createMarketItem(
        address collectionAddress,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        require(collections[collectionAddress].isActive, "Collection does not exist");
        require(price > 0, "Price must be greater than zero");
        require(msg.value == listingFee, "Must pay listing fee");

        // Get the token URI from the NFT contract
        string memory tokenURI = ERC721URIStorage(collectionAddress).tokenURI(tokenId);

        collectionToMarketItems[collectionAddress][tokenId] = MarketItem(
            tokenId,
            collectionAddress,
            msg.sender,
            address(0),
            price,
            true,
            0,
            address(0),
            0,
            false,
            tokenURI  // Store the tokenURI
        );

        collectionTokenIds[collectionAddress].push(tokenId);

        IERC721(collectionAddress).transferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated(
            collectionAddress,
            tokenId,
            msg.sender,
            address(0),
            price
        );
    }

    function fetchCollectionDetails(address collectionAddress) 
    public 
    view 
    returns (CollectionDetails memory) 
{
    require(collections[collectionAddress].isActive, "Collection does not exist");
    
    Collection memory basic = collections[collectionAddress];
    
    // Get collection statistics
    uint256 floorPrice = _getFloorPrice(collectionAddress);
    uint256 totalVolume = _getTotalVolume(collectionAddress);
    uint256 ownerCount = _getUniqueOwnerCount(collectionAddress);
    
    return CollectionDetails({
        basic: basic,
        floorPrice: floorPrice,
        totalVolume: totalVolume,
        ownerCount: ownerCount
    });
}

    function fetchCollections() public view returns (CollectionDetails[] memory) {
    uint256 collectionCount = collectionAddresses.length;
    CollectionDetails[] memory details = new CollectionDetails[](collectionCount);
    
    for (uint256 i = 0; i < collectionCount; i++) {
        address collectionAddress = collectionAddresses[i];
        details[i] = fetchCollectionDetails(collectionAddress);
    }
    
    return details;
}

function _getFloorPrice(address collectionAddress) private view returns (uint256) {
    uint256[] memory tokenIds = collectionTokenIds[collectionAddress];
    uint256 lowestPrice = type(uint256).max;
    
    for (uint256 i = 0; i < tokenIds.length; i++) {
        MarketItem memory item = collectionToMarketItems[collectionAddress][tokenIds[i]];
        if (item.isOnSale && item.price < lowestPrice) {
            lowestPrice = item.price;
        }
    }
    
    return lowestPrice == type(uint256).max ? 0 : lowestPrice;
}

function _getTotalVolume(address collectionAddress) private view returns (uint256) {
    // Implementation for calculating total trading volume
    return 0; 
}

function _getUniqueOwnerCount(address collectionAddress) private view returns (uint256) {
    // Implementation for counting unique owners
    return 0; // Placeholder
}

    function fetchCollectionItems(address collectionAddress) 
        public 
        view 
        returns (MarketItem[] memory) 
    {
        require(collections[collectionAddress].isActive, "Collection does not exist");
        
        uint256[] memory tokenIds = collectionTokenIds[collectionAddress];
        uint256 itemCount = tokenIds.length;
        
        MarketItem[] memory items = new MarketItem[](itemCount);
        
        for (uint256 i = 0; i < itemCount; i++) {
            uint256 tokenId = tokenIds[i];
            items[i] = collectionToMarketItems[collectionAddress][tokenId];
        }
        
        return items;
    }

    // Rest of the marketplace functions (buy, sell, auction, etc.) would be modified to use collectionAddress
    function createMarketSale(address collectionAddress, uint256 tokenId) 
        public 
        payable 
        nonReentrant 
    {
        MarketItem storage item = collectionToMarketItems[collectionAddress][tokenId];
        require(item.isOnSale, "Item is not on sale");
        require(!item.isAuction, "Item is on auction");
        require(msg.value == item.price, "Please submit the asking price");

        item.isOnSale = false;
        item.owner = msg.sender;
        
        payable(item.seller).transfer(msg.value);
        IERC721(collectionAddress).transferFrom(address(this), msg.sender, tokenId);

        userPurchases[msg.sender][collectionAddress][tokenId] = true;
        userPurchaseCount[msg.sender]++;
        
        emit MarketItemSold(
            collectionAddress,
            tokenId,
            item.seller,
            msg.sender,
            msg.value
        );
    }

    function createAuction(
        address collectionAddress,
        uint256 tokenId,
        uint256 startingPrice,
        uint256 duration
    ) public nonReentrant {
        MarketItem storage item = collectionToMarketItems[collectionAddress][tokenId];
        require(item.seller == msg.sender, "Only seller can start auction");
        require(!item.isAuction, "Already on auction");
        
        item.isAuction = true;
        item.price = startingPrice;
        item.auctionEndTime = block.timestamp + duration;
    }

    function placeBid(address collectionAddress, uint256 tokenId) 
        public 
        payable 
        nonReentrant 
    {
        MarketItem storage item = collectionToMarketItems[collectionAddress][tokenId];
        require(item.isAuction, "Not an auction");
        require(block.timestamp < item.auctionEndTime, "Auction ended");
        require(msg.value > item.highestBid, "Bid too low");

        if (item.highestBidder != address(0)) {
            pendingReturns[collectionAddress][tokenId][item.highestBidder] += item.highestBid;
        }

        item.highestBidder = msg.sender;
        item.highestBid = msg.value;
    }

    function makeOffer(address collectionAddress, uint256 tokenId) 
        public 
        payable 
        nonReentrant 
    {
        MarketItem storage item = collectionToMarketItems[collectionAddress][tokenId];
        require(item.isOnSale, "Item not on sale");
        require(!item.isAuction, "Item is on auction");
        require(msg.value > 0, "Offer must be greater than zero");

        itemOffers[collectionAddress][tokenId].push(Offer({
            buyer: msg.sender,
            price: msg.value,
            timestamp: block.timestamp
        }));

        emit OfferCreated(collectionAddress, msg.sender, msg.value);
    }

    function getCollectionDetails(address collectionAddress) 
        public 
        view 
        returns (Collection memory) 
    {
        require(collections[collectionAddress].isActive, "Collection does not exist");
        return collections[collectionAddress];
    }

    function fetchCollectionsByCategory(string memory category) 
        public 
        view 
        returns (Collection[] memory) 
    {
        require(categoryExists[category], "Category does not exist");
        
        address[] memory categoryCollections = categoryToCollections[category];
        Collection[] memory result = new Collection[](categoryCollections.length);
        
        for (uint256 i = 0; i < categoryCollections.length; i++) {
            result[i] = collections[categoryCollections[i]];
        }
        
        return result;
    }

    event OfferCreated(
        address indexed collectionAddress,
        address indexed buyer,
        uint256 price
    );
}
