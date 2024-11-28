const { expect } = require("chai");
const { ethers } = require("hardhat");
const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("NFTCollectionFactory", function () {
  let NFTCollectionFactory;
  let factory;
  let owner;
  let creator1;
  let creator2;

  beforeEach(async function () {
    [owner, creator1, creator2] = await ethers.getSigners();

    NFTCollectionFactory = await ethers.getContractFactory(
      "NFTCollectionFactory"
    );
    factory = await NFTCollectionFactory.deploy();
    await factory.waitForDeployment();
  });

  async function deployFactoryFixture() {
    const [owner, creator1, creator2] = await ethers.getSigners();
    const NFTCollectionFactory = await ethers.getContractFactory(
      "NFTCollectionFactory"
    );
    const factory = await NFTCollectionFactory.deploy();
    await factory.waitForDeployment();
    return { NFTCollectionFactory, factory, owner, creator1, creator2 };
  }

  describe("Categories", function () {
    it("Should initialize with default categories", async function () {
      expect(await factory.validCategories("art")).to.be.true;
      expect(await factory.validCategories("gaming")).to.be.true;
      expect(await factory.validCategories("music")).to.be.true;
      expect(await factory.validCategories("sports")).to.be.true;
      expect(await factory.validCategories("photography")).to.be.true;
    });

    it("Should allow owner to add new categories", async function () {
      await expect(factory.addCategory("collectibles"))
        .to.emit(factory, "CategoryAdded")
        .withArgs("collectibles");

      expect(await factory.validCategories("collectibles")).to.be.true;
    });

    it("Should not allow adding duplicate categories", async function () {
      await expect(factory.addCategory("art")).to.be.revertedWith(
        "Category already exists"
      );
    });

    it("Should allow owner to remove categories", async function () {
      await expect(factory.removeCategory("art"))
        .to.emit(factory, "CategoryRemoved")
        .withArgs("art");

      expect(await factory.validCategories("art")).to.be.false;
    });

    it("Should not allow non-owner to add categories", async function () {
      const { factory, creator1 } = await loadFixture(deployFactoryFixture);

      await expect(factory.connect(creator1).addCategory("test"))
        .to.be.revertedWithCustomError(factory, "OwnableUnauthorizedAccount")
        .withArgs(creator1.address);
    });
  });

  describe("Collection Creation", function () {
    it("Should create a new collection with valid category", async function () {
      const { factory, creator1 } = await loadFixture(deployFactoryFixture);

      const createTx = await factory
        .connect(creator1)
        .createCollection("TestNFT", "TNFT", "art");
      const receipt = await createTx.wait();

      const event = receipt.logs.find((log) => {
        try {
          const parsedLog = factory.interface.parseLog(log);
          return parsedLog?.name === "CollectionCreated";
        } catch {
          return false;
        }
      });

      expect(event).to.not.be.undefined;
      const parsedEvent = factory.interface.parseLog(event);

      expect(parsedEvent.args.name).to.equal("TestNFT");
      expect(parsedEvent.args.symbol).to.equal("TNFT");
      expect(parsedEvent.args.creator).to.equal(creator1.address);
      expect(parsedEvent.args.category).to.equal("art");
    });
  });

  describe("Collection Stats", function () {
    async function createCollectionFixture() {
      const { factory, creator1 } = await loadFixture(deployFactoryFixture);

      const tx = await factory
        .connect(creator1)
        .createCollection("TestNFT", "TNFT", "art");
      const receipt = await tx.wait();

      const event = receipt.logs.find((log) => {
        try {
          const parsedLog = factory.interface.parseLog(log);
          return parsedLog?.name === "CollectionCreated";
        } catch {
          return false;
        }
      });

      const parsedEvent = factory.interface.parseLog(event);
      const collectionAddress = parsedEvent.args.collectionAddress;

      return { factory, creator1, collectionAddress };
    }

    it("Should update collection stats correctly", async function () {
      const { factory, collectionAddress } = await loadFixture(
        createCollectionFixture
      );

      await factory.updateCollectionStats(
        collectionAddress,
        ethers.parseEther("1"),
        true
      );

      const collection = await factory.collections(collectionAddress);
      expect(collection.floorPrice).to.equal(ethers.parseEther("1"));
      expect(collection.totalSales).to.equal(1n);
      expect(collection.sales24h).to.equal(1n);
    });

    it("Should only allow owner to update stats", async function () {
      const { factory, creator1, collectionAddress } = await loadFixture(
        createCollectionFixture
      );

      await expect(
        factory
          .connect(creator1)
          .updateCollectionStats(
            collectionAddress,
            ethers.parseEther("1"),
            true
          )
      ).to.be.revertedWith("Only marketplace can update stats");
    });
  });

  describe("Collection Queries", function () {
    beforeEach(async function () {
      await factory.connect(creator1).createCollection("Test1", "T1", "art");
      await factory.connect(creator2).createCollection("Test2", "T2", "art");
    });

    it("Should get all collections", async function () {
      const collections = await factory.getAllCollections();
      expect(collections.length).to.equal(2);
    });

    it("Should get collections by category", async function () {
      const artCollections = await factory.getCollectionsByCategory("art");
      expect(artCollections.length).to.equal(2);
    });

    it("Should get creator collections", async function () {
      const creator1Collections = await factory.getCreatorCollections(
        creator1.address
      );
      expect(creator1Collections.length).to.equal(1);
    });

    it("Should get trending collections with correct limit", async function () {
      const trending = await factory.getTrendingCollectionsByCategory("art", 5);
      expect(trending.length).to.be.lte(5);
    });
  });
});
