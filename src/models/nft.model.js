const mongoose = require("mongoose");

const NFTSchema = new mongoose.Schema({
  tokenId: {
    type: Number,
    required: true,
    unique: true,
  },
  name: {
    type: String,
    required: true,
  },
  description: String,
  image: String,
  collectionAddress: {
    type: String,
    required: true,
  },
  creator: {
    type: String,
    required: true,
  },
  tokenURI: {
    type: String,
    required: true,
  },
  metadata: {
    type: Object,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model("NFT", NFTSchema);
