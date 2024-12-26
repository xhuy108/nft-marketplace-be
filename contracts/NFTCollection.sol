// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IMarketplace {
    function updateCollectionTotalSupply(address collection) external;
}

contract NFTCollection is ERC721URIStorage, Ownable {
    uint256 private _tokenIds;
    string public baseURI;
    address public marketplaceAddress;
    string public category;  
    
    constructor(
        string memory name,
        string memory symbol,
        string memory _baseURI,
        address _marketplaceAddress,
        string memory _category,  
        address initialOwner
    ) ERC721(name, symbol) Ownable(initialOwner) {
        baseURI = _baseURI;
        marketplaceAddress = _marketplaceAddress;
        category = _category;  // Set the category
    }

    function mint(address to, string memory tokenURI) public onlyOwner returns (uint256) {
        _tokenIds++;
        uint256 newTokenId = _tokenIds;
        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        IMarketplace(marketplaceAddress).updateCollectionTotalSupply(address(this));

        return newTokenId;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds;
    }
}
