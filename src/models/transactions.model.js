const mongoose = require("mongoose");

const transactionSchema = new mongoose.Schema(
    {
        nft: {
            type: mongoose.Schema.ObjectId,
            ref: "NFT",
        },
        seller: {
            type: mongoose.Schema.ObjectId,
            ref: "User",
        },
        buyer: {
            type: mongoose.Schema.ObjectId,
            ref: "User",
        },
        transaction_hash: {
            type: String,
            required: [true, "Please provide hash for transaction"],
        },
        status: String,
        price: Number,
    },
    {
        timestamps: true,
        toJSON: { virtuals: true },
        toObject: { virtuals: true },
    }
);

const Transaction = mongoose.model("Transaction", transactionSchema);
module.exports = Transaction;