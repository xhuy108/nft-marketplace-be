const ethers = require("ethers");
const NFTCollection = require("../../artifacts/contracts/NFTCollection.sol/NFTCollection.json");
const NFT = require("../models/nft.model");
const { uploadToIPFS } = require("./ipfs.service");

class NFTService {
  constructor() {
    this.provider = new ethers.providers.JsonRpcProvider(
      process.env.SEPOLIA_RPC_URL
    );
    this.signer = new ethers.Wallet(process.env.PRIVATE_KEY, this.provider);
  }

  async mintNFT(collectionAddress, nftData, creatorAddress) {
    try {
      // 1. Validate collection ownership
      const collectionContract = new ethers.Contract(
        collectionAddress,
        NFTCollection.abi,
        this.signer
      );

      const creator = await collectionContract.creator();
      if (creator.toLowerCase() !== creatorAddress.toLowerCase()) {
        throw new Error("Only collection creator can mint NFTs");
      }

      // 2. Upload image to IPFS
      const imageHash = await uploadToIPFS(nftData.image);

      // 3. Create and upload metadata
      const metadata = {
        name: nftData.name,
        description: nftData.description,
        image: `ipfs://${imageHash}`,
        attributes: nftData.attributes || [],
        external_url: nftData.external_url,
        background_color: nftData.background_color,
        animation_url: nftData.animation_url,
      };

      const metadataHash = await uploadToIPFS(metadata);
      const tokenURI = `ipfs://${metadataHash}`;

      // 4. Mint NFT
      const tx = await collectionContract.mint(tokenURI);
      const receipt = await tx.wait();

      // 5. Get tokenId from event
      const event = receipt.events.find((e) => e.event === "NFTMinted");
      const tokenId = event.args.tokenId.toNumber();

      // 6. Save NFT data to database
      const nft = new NFT({
        tokenId,
        name: nftData.name,
        description: nftData.description,
        image: `ipfs://${imageHash}`,
        collectionAddress,
        creator: creatorAddress,
        tokenURI,
        metadata,
      });

      await nft.save();

      return {
        success: true,
        tokenId,
        tokenURI,
        transactionHash: receipt.transactionHash,
        nft,
      };
    } catch (error) {
      throw new Error(`Failed to mint NFT: ${error.message}`);
    }
  }

  async getNFTMetadata(collectionAddress, tokenId) {
    try {
      const nft = await NFT.findOne({ collectionAddress, tokenId });
      if (!nft) {
        throw new Error("NFT not found");
      }
      return nft;
    } catch (error) {
      throw new Error(`Failed to get NFT metadata: ${error.message}`);
    }
  }
}

module.exports = new NFTService();
