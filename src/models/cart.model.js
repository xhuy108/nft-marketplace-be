const mongoose = require("mongoose");
const cartSchema = new mongoose.Schema(
    {
        nft: {
            type: mongoose.Schema.ObjectId,
            ref: "NFT",
        },
        user: {
            type: mongoose.Schema.ObjectId,
            ref: "User",
        },
    },
    {
        timestamps: true,
        toJSON: { virtuals: true },
        toObject: { virtuals: true },
    }
);

const Cart = mongoose.model("Cart", cartSchema);
module.exports = Cart;