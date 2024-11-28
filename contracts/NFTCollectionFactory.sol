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
        for(uint i = 0; i < defaults.length; i++) {
            categoryStorage.addCategory(defaults[i]);
            emit CategoryAdded(defaults[i]);
        }
    }

    function setMarketplaceAddress(address _marketplaceAddress) external onlyOwner {
        if(_marketplaceAddress == address(0)) revert InvalidMarketplace();
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

        emit CollectionCreated(collectionAddress, name, symbol, msg.sender, category);
        return collectionAddress;
    }

    function getCollectionsByCategory(string calldata category) 
        external 
        view 
        returns (Collection[] memory) 
    {
        address[] storage categoryAddresses = categoryStorage.categoryCollections[category];
        Collection[] memory result = new Collection[](categoryAddresses.length);
        
        for (uint256 i = 0; i < categoryAddresses.length; i++) {
            result[i] = collections[categoryAddresses[i]];
        }
        
        return result;
    }

    function getTrendingCollectionsByCategory(string calldata category, uint256 limit)
        external
        view
        returns (Collection[] memory)
    {
        if(limit == 0 || limit > 100) revert InvalidLimit();

        address[] storage categoryAddresses = categoryStorage.categoryCollections[category];
        uint256 resultCount = limit > categoryAddresses.length ? categoryAddresses.length : limit;
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
        if(msg.sender != marketplaceAddress) revert OnlyMarketplace();

        Collection storage collection = collections[collectionAddress];
        StatsLib.CollectionStats storage stats = collectionStats[collectionAddress];

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
    function getAllCollections() external view returns (Collection[] memory result) {
        result = new Collection[](allCollections.length);
        for (uint256 i = 0; i < allCollections.length; i++) {
            result[i] = collections[allCollections[i]];
        }
    }

    function getCreatorCollections(address creator) 
        external 
        view 
        returns (Collection[] memory result) 
    {
        if(creator == address(0)) revert InvalidAddress();
        address[] storage creatorAddrs = creatorCollections[creator];
        result = new Collection[](creatorAddrs.length);
        
        for (uint256 i = 0; i < creatorAddrs.length; i++) {
            result[i] = collections[creatorAddrs[i]];
        }
    }

    function verifyCollection(address collectionAddress) external onlyOwner {
        if(collectionAddress == address(0)) revert InvalidAddress();
        collections[collectionAddress].isVerified = true;
        emit CollectionVerified(collectionAddress);
    }
}