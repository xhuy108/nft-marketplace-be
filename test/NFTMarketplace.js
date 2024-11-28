const { expect } = require("chai");
const { ethers } = require("hardhat");
const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");

describe("NFT Marketplace", function () {
  // Base test fixture to deploy contracts
  async function deployMarketplaceFixture() {
    const [owner, creator1, creator2, buyer1, buyer2] =
      await ethers.getSigners();

    // Deploy Factory first
    const NFTCollectionFactory = await ethers.getContractFactory(
      "NFTCollectionFactory"
    );
    const factory = await NFTCollectionFactory.deploy();
    await factory.waitForDeployment();

    // Deploy Marketplace with factory address
    const NFTMarketplace = await ethers.getContractFactory("NFTMarketplace");
    const marketplace = await NFTMarketplace.deploy(await factory.getAddress());
    await marketplace.waitForDeployment();

    // Set marketplace address in factory
    await factory.setMarketplaceAddress(await marketplace.getAddress());

    return {
      factory,
      marketplace,
      owner,
      creator1,
      creator2,
      buyer1,
      buyer2,
    };
  }

  describe("Listing Operations", function () {
    // Helper to create collection and mint NFT
    async function setupNFTForListing() {
      const { factory, marketplace, creator1 } = await loadFixture(
        deployMarketplaceFixture
      );

      // Create collection
      const tx = await factory
        .connect(creator1)
        .createCollection("Test Collection", "TEST", "art");
      const receipt = await tx.wait();
      const event = receipt.logs.find(
        (log) => log.fragment?.name === "CollectionCreated"
      );
      const collectionAddress = event.args[0];

      // Get collection instance
      const NFTCollection = await ethers.getContractFactory("NFTCollection");
      const collection = NFTCollection.attach(collectionAddress);

      // Mint NFT
      await collection.connect(creator1).mint("ipfs://testURI");

      // Approve marketplace
      await collection
        .connect(creator1)
        .approve(await marketplace.getAddress(), 0);

      return { factory, marketplace, collection, creator1, collectionAddress };
    }

    it("Should list NFT for fixed price sale", async function () {
      const { marketplace, creator1, collectionAddress } =
        await setupNFTForListing();

      const listingPrice = await marketplace.getListingPrice();
      const salePrice = ethers.parseEther("1.0");

      // List NFT
      const tx = await marketplace.connect(creator1).createMarketItem(
        collectionAddress,
        0, // tokenId
        salePrice,
        { value: listingPrice }
      );

      await expect(tx).to.emit(marketplace, "MarketItemCreated").withArgs(
        0, // itemId
        collectionAddress,
        0, // tokenId
        creator1.address,
        ethers.ZeroAddress,
        salePrice,
        false, // isAuction
        0 // auctionEndTime
      );
    });

    it("Should fail listing without paying listing fee", async function () {
      const { marketplace, creator1, collectionAddress } =
        await setupNFTForListing();

      await expect(
        marketplace
          .connect(creator1)
          .createMarketItem(collectionAddress, 0, ethers.parseEther("1.0"), {
            value: 0,
          })
      ).to.be.revertedWith("Must pay listing price");
    });
  });

  describe("Purchase Operations", function () {
    async function setupListedNFT() {
      const setup = await setupNFTForListing();
      const { marketplace, creator1, collectionAddress } = setup;

      const listingPrice = await marketplace.getListingPrice();
      const salePrice = ethers.parseEther("1.0");

      await marketplace
        .connect(creator1)
        .createMarketItem(collectionAddress, 0, salePrice, {
          value: listingPrice,
        });

      return { ...setup, salePrice };
    }

    it("Should execute purchase", async function () {
      const {
        marketplace,
        creator1,
        buyer1,
        collectionAddress,
        collection,
        salePrice,
      } = await loadFixture(setupListedNFT);

      const purchaseTx = await marketplace
        .connect(buyer1)
        .createMarketSale(collectionAddress, 0, { value: salePrice });

      // Verify ownership transfer
      expect(await collection.ownerOf(0)).to.equal(buyer1.address);

      // Verify payment transfer
      await expect(purchaseTx).to.changeEtherBalances(
        [buyer1, creator1],
        [-salePrice, salePrice]
      );
    });

    it("Should fail purchase with wrong price", async function () {
      const { marketplace, buyer1, collectionAddress, salePrice } =
        await loadFixture(setupListedNFT);

      await expect(
        marketplace.connect(buyer1).createMarketSale(collectionAddress, 0, {
          value: salePrice - ethers.parseEther("0.1"),
        })
      ).to.be.revertedWith("Please submit the asking price");
    });
  });

  describe("Auction Operations", function () {
    async function setupAuction() {
      const setup = await setupNFTForListing();
      const { marketplace, creator1, collectionAddress } = setup;

      const listingPrice = await marketplace.getListingPrice();
      const startingPrice = ethers.parseEther("1.0");

      await marketplace
        .connect(creator1)
        .createAuction(collectionAddress, 0, startingPrice, {
          value: listingPrice,
        });

      return { ...setup, startingPrice };
    }

    it("Should place valid bid", async function () {
      const { marketplace, buyer1, startingPrice } = await loadFixture(
        setupAuction
      );

      const bidAmount = startingPrice + ethers.parseEther("0.1");

      await expect(
        marketplace.connect(buyer1).placeBid(0, { value: bidAmount })
      )
        .to.emit(marketplace, "AuctionBid")
        .withArgs(0, buyer1.address, bidAmount);
    });

    it("Should refund previous bidder when outbid", async function () {
      const { marketplace, buyer1, buyer2, startingPrice } = await loadFixture(
        setupAuction
      );

      // First bid
      const firstBid = startingPrice + ethers.parseEther("0.1");
      await marketplace.connect(buyer1).placeBid(0, { value: firstBid });

      // Second higher bid
      const secondBid = firstBid + ethers.parseEther("0.1");
      await expect(
        marketplace.connect(buyer2).placeBid(0, { value: secondBid })
      ).to.changeEtherBalance(buyer1, firstBid);
    });

    it("Should end auction successfully", async function () {
      const { marketplace, creator1, buyer1, collection } =
        await setupAuction();

      // Place bid
      const bidAmount = ethers.parseEther("1.5");
      await marketplace.connect(buyer1).placeBid(0, { value: bidAmount });

      // Fast forward time
      await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]); // 7 days
      await ethers.provider.send("evm_mine");

      // End auction
      await expect(marketplace.endAuction(0))
        .to.emit(marketplace, "AuctionEnded")
        .withArgs(0, buyer1.address, bidAmount);

      // Verify ownership transfer
      expect(await collection.ownerOf(0)).to.equal(buyer1.address);
    });
  });

  describe("Market Item Queries", function () {
    it("Should fetch market items correctly", async function () {
      const { marketplace, creator1, collectionAddress } =
        await setupListedNFT();

      const items = await marketplace.fetchMarketItems();
      expect(items.length).to.equal(1);
      expect(items[0].nftContract).to.equal(collectionAddress);
      expect(items[0].seller).to.equal(creator1.address);
    });

    it("Should fetch price history", async function () {
      const { marketplace, creator1, buyer1, collectionAddress, salePrice } =
        await setupListedNFT();

      // Make purchase to create price history
      await marketplace
        .connect(buyer1)
        .createMarketSale(collectionAddress, 0, { value: salePrice });

      const history = await marketplace.fetchPriceHistory(0);
      expect(history.length).to.be.greaterThan(0);
      expect(history[0].price).to.equal(salePrice);
    });
  });

  describe("Offer System", function () {
    it("Should make and accept offer", async function () {
      const { marketplace, creator1, buyer1, collection } =
        await setupListedNFT();

      const offerPrice = ethers.parseEther("0.8");
      const expirationTime = Math.floor(Date.now() / 1000) + 86400; // 24 hours

      // Make offer
      await expect(
        marketplace
          .connect(buyer1)
          .makeOffer(0, expirationTime, { value: offerPrice })
      )
        .to.emit(marketplace, "OfferCreated")
        .withArgs(0, buyer1.address, offerPrice, expirationTime);

      // Accept offer
      await expect(marketplace.connect(creator1).acceptOffer(0, 0))
        .to.emit(marketplace, "OfferAccepted")
        .withArgs(0, buyer1.address, offerPrice);

      // Verify ownership transfer
      expect(await collection.ownerOf(0)).to.equal(buyer1.address);
    });
  });
});
