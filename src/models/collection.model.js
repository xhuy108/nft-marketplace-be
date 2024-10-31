const mongoose = require("mongoose");

const collectionSchema = new mongoose.Schema(
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
        creator: {
            type: mongoose.Schema.ObjectId,
            ref: "User",
            required: true,
        },
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
        listNfts: [
            {
                type: mongoose.Schema.ObjectId,
                ref: "NFT",
            },
        ],
    },
    {
        timestamps: true,
        toJSON: { virtuals: true },
        toObject: { virtuals: true },
    }
);

const Collection = mongoose.model("Collection", collectionSchema);
module.exports = Collection;