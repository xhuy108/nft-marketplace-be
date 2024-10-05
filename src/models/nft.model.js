const mongoose = require("mongoose");
const slugify = require("slugify");

const NFTSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, "Please provide a name for the NFT"],
      trim: true,
      maxlength: [100, "Name cannot be more than 100 characters"],
    },
    description: {
      type: String,
      required: [true, "Please provide a description for the NFT"],
      maxlength: [1000, "Description cannot be more than 1000 characters"],
    },
    image: {
      type: String,
      required: [true, "Please provide an image URL for the NFT"],
    },
    creator: {
      type: mongoose.Schema.ObjectId,
      ref: "User",
      required: true,
    },
    owner: {
      type: mongoose.Schema.ObjectId,
      ref: "User",
      required: true,
    },
    price: {
      type: Number,
      required: [true, "Please provide a price for the NFT"],
      min: [0, "Price must be a positive number"],
    },
    currency: {
      type: String,
      required: [true, "Please specify the currency"],
      enum: ["ETH", "MATIC", "BNB"], // Add more as needed
      default: "ETH",
    },
    tokenId: {
      type: String,
      required: [true, "Token ID is required"],
      unique: true,
    },
    contractAddress: {
      type: String,
      required: [true, "Contract address is required"],
    },
    blockchain: {
      type: String,
      required: [true, "Please specify the blockchain"],
      enum: ["Ethereum", "Polygon", "Binance Smart Chain"], // Add more as needed
      default: "Ethereum",
    },
    metadataURI: {
      type: String,
      required: [true, "Metadata URI is required"],
    },
    royalties: {
      type: Number,
      min: 0,
      max: 100,
      default: 0,
    },
    isListed: {
      type: Boolean,
      default: false,
    },
    tags: [
      {
        type: String,
        lowercase: true,
        trim: true,
      },
    ],
    category: {
      type: String,
      required: [true, "Please specify a category"],
      enum: [
        "Art",
        "Music",
        "Video",
        "Collectible",
        "Virtual Real Estate",
        "Gaming",
        "Memes",
        "Other",
      ],
    },
    attributes: [
      {
        trait_type: String,
        value: mongoose.Schema.Types.Mixed,
      },
    ],
    views: {
      type: Number,
      default: 0,
    },
    likes: [
      {
        type: mongoose.Schema.ObjectId,
        ref: "User",
      },
    ],
    saleHistory: [
      {
        seller: {
          type: mongoose.Schema.ObjectId,
          ref: "User",
        },
        buyer: {
          type: mongoose.Schema.ObjectId,
          ref: "User",
        },
        price: Number,
        date: {
          type: Date,
          default: Date.now,
        },
      },
    ],
    slug: String,
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Virtual for formatted price
NFTSchema.virtual("formattedPrice").get(function () {
  return `${this.price} ${this.currency}`;
});

// Index for better query performance
NFTSchema.index({ name: "text", description: "text" });
NFTSchema.index({ creator: 1, owner: 1, price: 1, isListed: 1 });

// Pre-save middleware to create slug
NFTSchema.pre("save", function (next) {
  this.slug = slugify(this.name, { lower: true });
  next();
});

// Static method to get trending NFTs
NFTSchema.statics.getTrendingNFTs = function (limit = 10) {
  return this.find({ isListed: true })
    .sort("-views -likes")
    .limit(limit)
    .populate("creator", "username profileImage")
    .populate("owner", "username profileImage");
};

// Method to transfer ownership
NFTSchema.methods.transferOwnership = async function (newOwnerId, price) {
  const oldOwnerId = this.owner;
  this.owner = newOwnerId;
  this.isListed = false;
  this.saleHistory.push({
    seller: oldOwnerId,
    buyer: newOwnerId,
    price: price,
  });
  await this.save();
};

// Method to toggle like
NFTSchema.methods.toggleLike = async function (userId) {
  if (this.likes.includes(userId)) {
    this.likes = this.likes.filter((id) => id.toString() !== userId.toString());
  } else {
    this.likes.push(userId);
  }
  await this.save();
};

// Method to increment view count
NFTSchema.methods.incrementViews = async function () {
  this.views += 1;
  await this.save();
};

// Method to update price
NFTSchema.methods.updatePrice = async function (newPrice) {
  if (newPrice < 0) {
    throw new Error("Price must be a positive number");
  }
  this.price = newPrice;
  await this.save();
};

// Method to toggle listing status
NFTSchema.methods.toggleListing = async function () {
  this.isListed = !this.isListed;
  await this.save();
};

const NFT = mongoose.model("NFT", NFTSchema);

module.exports = NFT;
