// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "hardhat/console.sol";

contract NFTCollection is ERC721URIStorage {
    address public immutable creator;
    address public immutable factory;
    uint256 private _nextTokenId;
    string public collectionURI;

    event NFTMinted(
        uint256 indexed tokenId,
        address indexed creator,
        string tokenURI
    );

    event CollectionMetadataUpdated(
        address indexed collection,
        string newCollectionURI
    );

    error OnlyCreator();
    error OnlyFactory();
    error InvalidTokenURI();

    constructor(
        string memory name,
        string memory symbol,
        address _creator,
        string memory _collectionURI
    ) ERC721(name, symbol) {
        creator = _creator;
        factory = msg.sender;
        collectionURI = _collectionURI;
    }

    modifier onlyCreator() {
        if (msg.sender != creator) revert OnlyCreator();
        _;
    }

    modifier onlyFactory() {
        if (msg.sender != factory) revert OnlyFactory();
        _;
    }

    function mint(string memory tokenURI) external returns (uint256) {
        console.log("sender");
        console.log(msg.sender);
        console.log("creator");
        console.log(creator);
        require(msg.sender == creator, "Only creator can mint");
        if (bytes(tokenURI).length == 0) revert InvalidTokenURI();
        uint256 tokenId = _nextTokenId++;
        // _safeMint(creator, tokenId);

        _safeMint(creator, tokenId);

        _setTokenURI(tokenId, tokenURI);
        emit NFTMinted(tokenId, creator, tokenURI);
        return tokenId;
    }

    function approveMarketplace(address marketplace) external {
        // This will approve the marketplace for all tokens owned by the caller
        setApprovalForAll(marketplace, true);
    }

    function updateCollectionURI(string calldata newCollectionURI) external {
        // require(msg.sender == creator, "Only creator can update metadata");
        collectionURI = newCollectionURI;
        emit CollectionMetadataUpdated(address(this), newCollectionURI);
    }

    function getCollectionInfo()
        external
        view
        returns (address _creator, string memory _collectionURI)
    {
        return (creator, collectionURI);
    }
}
