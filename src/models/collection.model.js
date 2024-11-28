const mongoose = require("mongoose");

const CollectionSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, "Collection name is required"],
      trim: true,
    },
    symbol: {
      type: String,
      required: [true, "Collection symbol is required"],
      trim: true,
    },
    description: { type: String },
    contractAddress: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
    },
    creator: {
      type: String,
      required: true,
      lowercase: true,
    },
    category: {
      type: String,
      required: [true, "Category is required"],
      enum: ["art", "gaming", "music", "sports", "photography"],
    },
    isVerified: {
      type: Boolean,
      default: false,
    },
    profileImage: { type: String },
    bannerImage: { type: String },
    websiteUrl: { type: String },
    discordUrl: { type: String },
    twitterUrl: { type: String },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Collection", CollectionSchema);
