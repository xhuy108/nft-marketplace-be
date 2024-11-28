const { ethers } = require("ethers");
const Collection = require("../models/collection.model");
const NFTCollectionFactory = require("../../artifacts/contracts/NFTCollectionFactory.sol/NFTCollectionFactory.json");
const { AppError } = require("../middlewares/error.middleware");

class CollectionService {
  constructor() {
    this.provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
    this.factoryContract = new ethers.Contract(
      process.env.FACTORY_ADDRESS,
      NFTCollectionFactory.abi,
      this.provider
    );
  }

  async createCollection(data, userAddress) {
    try {
      // Create collection on blockchain
      const signer = new ethers.Wallet(process.env.PRIVATE_KEY, this.provider);
      const factoryWithSigner = this.factoryContract.connect(signer);

      const tx = await factoryWithSigner.createCollection(
        data.name,
        data.symbol,
        data.category
      );
      const receipt = await tx.wait();

      const event = receipt.logs.find(
        (log) =>
          factoryWithSigner.interface.parseLog(log)?.name ===
          "CollectionCreated"
      );

      if (!event) {
        throw new AppError(500, "Collection creation event not found");
      }

      const parsedEvent = factoryWithSigner.interface.parseLog(event);
      const collectionAddress = parsedEvent.args.collectionAddress;

      // Save collection to database
      const collection = new Collection({
        name: data.name,
        symbol: data.symbol,
        description: data.description,
        contractAddress: collectionAddress,
        creator: userAddress,
        category: data.category,
        websiteUrl: data.websiteUrl,
        discordUrl: data.discordUrl,
        twitterUrl: data.twitterUrl,
      });

      await collection.save();
      return collection;
    } catch (error) {
      throw new AppError(500, `Failed to create collection: ${error.message}`);
    }
  }

  async getAllCollections(query = {}) {
    try {
      const collections = await Collection.find(query)
        .sort({ createdAt: -1 })
        .select("-__v");
      return collections;
    } catch (error) {
      throw new AppError(500, `Failed to fetch collections: ${error.message}`);
    }
  }
}

module.exports = new CollectionService();
