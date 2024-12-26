const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTMarketplace", function () {
  let NFTMarketplace,
    nftMarketplace,
    NFTCollection,
    nftCollection,
    owner,
    addr1,
    addr2;

  beforeEach(async function () {
    NFTMarketplace = await ethers.getContractFactory("NFTMarketplace");
    NFTCollection = await ethers.getContractFactory("NFTCollection");

    [owner, addr1, addr2, _] = await ethers.getSigners();

    nftMarketplace = await NFTMarketplace.deploy();
    await nftMarketplace.waitForDeployment();

    nftCollection = await NFTCollection.deploy();
    await nftCollection.waitForDeployment();
  });

  it("Should create a market item", async function () {
    const tokenURI = "https://example.com/nft";
    await nftCollection.mintNFT(addr1.address, tokenURI);
    const tokenId = 1;

    await nftCollection.connect(addr1).approve(nftMarketplace.target, tokenId);
    const listingFee = await nftMarketplace.getListingFee();

    await nftMarketplace
      .connect(addr1)
      .createMarketItem(nftCollection.target, tokenId, ethers.parseEther("1"), {
        value: listingFee,
      });

    // Change from getMarketItem to fetchMarketItem (assuming this is the correct function name in your contract)
    const marketItem = await nftMarketplace.fetchMarketItem(tokenId);

    expect(marketItem.itemId).to.equal(tokenId);
    expect(marketItem.nftContract).to.equal(nftCollection.target);
    expect(marketItem.tokenId).to.equal(tokenId);
    expect(marketItem.seller).to.equal(addr1.address);
    expect(marketItem.owner).to.equal(ethers.ZeroAddress);
    expect(marketItem.price).to.equal(ethers.parseEther("1"));
    expect(marketItem.sold).to.equal(false);
  });

  it("Should execute market sale", async function () {
    const tokenURI = "https://example.com/nft";
    await nftCollection.mintNFT(addr1.address, tokenURI);
    const tokenId = 1;

    await nftCollection.connect(addr1).approve(nftMarketplace.target, tokenId);
    const listingFee = await nftMarketplace.getListingFee();

    await nftMarketplace
      .connect(addr1)
      .createMarketItem(nftCollection.target, tokenId, ethers.parseEther("1"), {
        value: listingFee,
      });

    // Execute sale
    await nftMarketplace
      .connect(addr2)
      .purchaseMarketItem(nftCollection.target, tokenId, {
        value: ethers.parseEther("1"),
      });

    // Change from getMarketItem to fetchMarketItem
    const marketItem = await nftMarketplace.fetchMarketItem(tokenId);
    expect(marketItem.owner).to.equal(addr2.address);
    expect(marketItem.sold).to.equal(true);
  });

  it("Should revert if price is not met", async function () {
    const tokenURI = "https://example.com/nft";
    await nftCollection.mintNFT(addr1.address, tokenURI);
    const tokenId = 1;

    await nftCollection.connect(addr1).approve(nftMarketplace.target, tokenId);
    const listingFee = await nftMarketplace.getListingFee();

    await nftMarketplace
      .connect(addr1)
      .createMarketItem(nftCollection.target, tokenId, ethers.parseEther("1"), {
        value: listingFee,
      });

    await expect(
      nftMarketplace
        .connect(addr2)
        .purchaseMarketItem(nftCollection.target, tokenId, {
          value: ethers.parseEther("0.5"),
        })
    ).to.be.revertedWith("Please submit asking price");
  });
});
