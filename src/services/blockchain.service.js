const Web3 = require("web3");
const config = require("../config/blockchain");
const logger = require("../utils/logger");

class BlockchainService {
  constructor() {
    this.web3 = new Web3(new Web3.providers.HttpProvider(config.providerUrl));
    this.contractAbi = require("../contracts/NFTMarketplace.json").abi;
    this.contractAddress = config.contractAddress;
    this.contract = new this.web3.eth.Contract(
      this.contractAbi,
      this.contractAddress
    );
  }

  async mintNFT(tokenId, ipfsHash, creatorAddress) {
    try {
      const nonce = await this.web3.eth.getTransactionCount(
        config.ownerAddress,
        "latest"
      );
      const gasPrice = await this.web3.eth.getGasPrice();
      const gasLimit = 500000;

      const tx = {
        from: config.ownerAddress,
        to: this.contractAddress,
        nonce: nonce,
        gasPrice: gasPrice,
        gasLimit: gasLimit,
        data: this.contract.methods
          .mintNFT(creatorAddress, tokenId, ipfsHash)
          .encodeABI(),
      };

      const signedTx = await this.web3.eth.accounts.signTransaction(
        tx,
        config.ownerPrivateKey
      );
      const receipt = await this.web3.eth.sendSignedTransaction(
        signedTx.rawTransaction
      );

      logger.info(`NFT minted: ${receipt.transactionHash}`);
      return receipt.transactionHash;
    } catch (error) {
      logger.error("Error minting NFT:", error);
      throw error;
    }
  }

  async transferNFT(fromAddress, toAddress, tokenId) {
    try {
      const nonce = await this.web3.eth.getTransactionCount(
        fromAddress,
        "latest"
      );
      const gasPrice = await this.web3.eth.getGasPrice();
      const gasLimit = 500000;

      const tx = {
        from: fromAddress,
        to: this.contractAddress,
        nonce: nonce,
        gasPrice: gasPrice,
        gasLimit: gasLimit,
        data: this.contract.methods
          .transferFrom(fromAddress, toAddress, tokenId)
          .encodeABI(),
      };

      const signedTx = await this.web3.eth.accounts.signTransaction(
        tx,
        config.userPrivateKey
      );
      const receipt = await this.web3.eth.sendSignedTransaction(
        signedTx.rawTransaction
      );

      logger.info(`NFT transferred: ${receipt.transactionHash}`);
      return receipt.transactionHash;
    } catch (error) {
      logger.error("Error transferring NFT:", error);
      throw error;
    }
  }

  // Additional methods like getNFTOwner, getNFTMetadata, etc. would go here
}

module.exports = new BlockchainService();
