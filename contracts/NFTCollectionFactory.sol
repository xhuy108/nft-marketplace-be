// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./NFTCollection.sol";

// Collection Factory Contract
contract NFTCollectionFactory is Ownable(msg.sender) {
    struct Collection {
        string name;
        string symbol;
        address collectionAddress;
        address creator;
        bool isVerified;
    }

    mapping(address => Collection) public collections;
    mapping(address => address[]) public creatorCollections;
    
    event CollectionCreated(
        address indexed collectionAddress,
        string name,
        string symbol,
        address indexed creator
    );
    
    event CollectionVerified(address indexed collectionAddress);


    function createCollection(
        string memory name,
        string memory symbol
    ) external returns (address) {
        NFTCollection newCollection = new NFTCollection(
            name,
            symbol,
            msg.sender
        );
        
        address collectionAddress = address(newCollection);
        collections[collectionAddress] = Collection(
            name,
            symbol,
            collectionAddress,
            msg.sender,
            false
        );
        
        creatorCollections[msg.sender].push(collectionAddress);
        
        emit CollectionCreated(
            collectionAddress,
            name,
            symbol,
            msg.sender
        );
        
        return collectionAddress;
    }

    function verifyCollection(address collectionAddress) external onlyOwner {
        collections[collectionAddress].isVerified = true;
        emit CollectionVerified(collectionAddress);
    }

    function getCreatorCollections(address creator) 
        external 
        view 
        returns (address[] memory) 
    {
        return creatorCollections[creator];
    }
}