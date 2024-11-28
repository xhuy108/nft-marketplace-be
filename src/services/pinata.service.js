const pinata = require("../config/pinata");

class PinataService {
  async uploadImage(fileBuffer, fileName) {
    try {
      const options = {
        pinataMetadata: {
          name: fileName,
        },
      };

      const result = await pinata.pinFileToIPFS(fileBuffer, options);
      return `ipfs://${result.IpfsHash}`;
    } catch (error) {
      console.error("Pinata upload error:", error);
      throw new Error(`Failed to upload to IPFS: ${error.message}`);
    }
  }

  async uploadMetadata(metadata) {
    try {
      const options = {
        pinataMetadata: {
          name: `${metadata.name}-metadata`,
        },
      };

      const result = await pinata.pinJSONToIPFS(metadata, options);
      return `ipfs://${result.IpfsHash}`;
    } catch (error) {
      console.error("Pinata metadata upload error:", error);
      throw new Error(`Failed to upload metadata to IPFS: ${error.message}`);
    }
  }
}

module.exports = new PinataService();
