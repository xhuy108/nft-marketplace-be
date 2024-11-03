const NFTService = require("../services/nft.service");
const { validateNFTInput } = require("../middlewares/validation.middleware");

class NFTController {
  async mintNFT(req, res) {
    try {
      const { collectionAddress } = req.params;
      const nftData = req.body;
      const creatorAddress = req.user.address; // Assuming you have auth middleware

      // Validate input
      const validationError = validateNFTInput(nftData);
      if (validationError) {
        return res.status(400).json({ error: validationError });
      }

      // Process file upload if exists
      if (req.file) {
        nftData.image = req.file.buffer;
      }

      const result = await NFTService.mintNFT(
        collectionAddress,
        nftData,
        creatorAddress
      );

      res.status(201).json(result);
    } catch (error) {
      console.error("Mint NFT Error:", error);
      res.status(500).json({ error: error.message });
    }
  }

  async getNFTMetadata(req, res) {
    try {
      const { collectionAddress, tokenId } = req.params;
      const metadata = await NFTService.getNFTMetadata(
        collectionAddress,
        tokenId
      );
      res.json(metadata);
    } catch (error) {
      res.status(404).json({ error: error.message });
    }
  }
}

module.exports = new NFTController();
