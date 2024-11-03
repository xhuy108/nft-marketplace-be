// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

// Collection Contract
contract NFTCollection is ERC721URIStorage {
    address public creator;
    uint256 private _nextTokenId;
    
    event NFTMinted(
        uint256 indexed tokenId,
        address indexed creator,
        string tokenURI
    );

    constructor(
        string memory name,
        string memory symbol,
        address _creator
    ) ERC721(name, symbol) {
        creator = _creator;
    }

    function mint(string memory tokenURI) 
        external 
        returns (uint256) 
    {
        require(msg.sender == creator, "Only creator can mint");
        uint256 tokenId = _nextTokenId++;
        _safeMint(creator, tokenId);
        _setTokenURI(tokenId, tokenURI);
        
        emit NFTMinted(tokenId, creator, tokenURI);
        return tokenId;
    }
}

