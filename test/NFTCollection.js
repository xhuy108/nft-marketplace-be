const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTCollection", function () {
  let NFTCollection, nftCollection, owner, addr1, addr2;

  beforeEach(async function () {
    NFTCollection = await ethers.getContractFactory("NFTCollection");
    [owner, addr1, addr2, _] = await ethers.getSigners();
    nftCollection = await NFTCollection.deploy();
    await nftCollection.waitForDeployment();
  });

  it("Should mint a new NFT", async function () {
    const tokenURI = "https://example.com/nft";
    await nftCollection.mintNFT(addr1.address, tokenURI);

    const tokenId = 1;
    expect(await nftCollection.ownerOf(tokenId)).to.equal(addr1.address);
    expect(await nftCollection.tokenURI(tokenId)).to.equal(tokenURI);
  });

  it("Should emit NFTMinted event", async function () {
    const tokenURI = "https://example.com/nft";
    await expect(nftCollection.mintNFT(addr1.address, tokenURI))
      .to.emit(nftCollection, "NFTMinted")
      .withArgs(1, addr1.address, tokenURI);
  });

  it("Should not allow non-owner to mint NFT", async function () {
    const tokenURI = "https://example.com/nft";
    await expect(nftCollection.connect(addr1).mintNFT(addr1.address, tokenURI))
      .to.be.reverted; // Check for any revert reason
  });
});
