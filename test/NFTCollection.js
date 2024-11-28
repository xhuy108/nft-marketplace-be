const { expect } = require("chai");
const { ethers } = require("hardhat");
const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("NFTCollection", function () {
  let NFTCollection;
  let nftCollection;
  let owner;
  let creator;
  let addr1;
  let addr2;

  beforeEach(async function () {
    [owner, creator, addr1, addr2] = await ethers.getSigners();
    NFTCollection = await ethers.getContractFactory("NFTCollection");
    nftCollection = await NFTCollection.deploy(
      "TestNFT",
      "TNFT",
      creator.address
    );
    await nftCollection.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the correct name and symbol", async function () {
      expect(await nftCollection.name()).to.equal("TestNFT");
      expect(await nftCollection.symbol()).to.equal("TNFT");
    });

    it("Should set the correct creator", async function () {
      expect(await nftCollection.creator()).to.equal(creator.address);
    });
  });

  describe("Minting", function () {
    const tokenURI = "ipfs://QmTest";

    it("Should allow creator to mint NFTs", async function () {
      await expect(nftCollection.connect(creator).mint(tokenURI))
        .to.emit(nftCollection, "NFTMinted")
        .withArgs(0, creator.address, tokenURI);
      expect(await nftCollection.ownerOf(0)).to.equal(creator.address);
      expect(await nftCollection.tokenURI(0)).to.equal(tokenURI);
    });

    it("Should increment token IDs correctly", async function () {
      await nftCollection.connect(creator).mint(tokenURI);
      await nftCollection.connect(creator).mint(tokenURI + "2");
      expect(await nftCollection.ownerOf(0)).to.equal(creator.address);
      expect(await nftCollection.ownerOf(1)).to.equal(creator.address);
    });

    it("Should not allow non-creator to mint", async function () {
      await expect(
        nftCollection.connect(addr1).mint(tokenURI)
      ).to.be.revertedWith("Only creator can mint");
    });
  });

  async function deployNFTCollectionFixture() {
    const [owner, creator, addr1, addr2] = await ethers.getSigners();
    const NFTCollection = await ethers.getContractFactory("NFTCollection");
    const nftCollection = await NFTCollection.deploy(
      "TestNFT",
      "TNFT",
      creator.address
    );
    await nftCollection.waitForDeployment();
    return { NFTCollection, nftCollection, owner, creator, addr1, addr2 };
  }

  describe("Token URI", function () {
    it("Should revert when querying URI for non-existent token", async function () {
      const { nftCollection } = await loadFixture(deployNFTCollectionFixture);
      await expect(nftCollection.tokenURI(99)).to.be.revertedWithCustomError(
        nftCollection,
        "ERC721NonexistentToken"
      );
    });
  });
});
