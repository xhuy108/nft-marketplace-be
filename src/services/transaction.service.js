const Transaction = require('../models/transactions.model')
const NFT = require('../models/nft.model')
const createTransaction = (newTransaction) => {
    return new Promise(async (resolve, reject) => {
        try {
            const { nft, seller, buyer, transaction_hash, status, price } = newTransaction
            const createTransaction = await Transaction.create({
                nft,
                seller,
                buyer,
                transaction_hash,
                status,
                price
            })

            const updateNft = await NFT.findOne({ _id: nft._id })
            await updateNft.transferOwnership(buyer._id, price)
            if (createTransaction) {
                resolve({
                    status: "OK",
                    message: "success",
                    data: createTransaction
                })
            }
        }
        catch (e) {
            console.error(e);
            reject(e)
        }
    })
}

const getAllTransaction = (limit, page, sort) => {
    return new Promise(async (resolve, reject) => {
        try {
            let sortObj = {}
            if (sort) {
                sortObj[sort[1]] = sort[0]
            }
            else {
                sortObj = {
                    createdAt: -1,
                    updatedAt: -1
                }
            }

            const totalTransaction = await Transaction.find({})

            const allTransaction = await Transaction.find({}).limit(limit).skip((page - 1) * limit).sort(sortObj)
                .populate('nft')
                .populate('seller')
                .populate('buyler')
            resolve({
                status: "OK",
                message: "success",
                data: allTransaction,
                total: totalTransaction.length,
                pageCurrent: page,
                totalPage: Math.ceil(totalTransaction.length / limit)
            })


        }
        catch (e) {
            console.error(e);
            reject(e)
        }
    })
}

const getTransaction = (transactionId) => {
    return new Promise(async (resolve, reject) => {
        try {

            const transaction = await Transaction.findOne({ _id: transactionId })
                .populate('nft')
                .populate('seller')
                .populate('buyler')

            resolve({
                status: "OK",
                message: "success",
                data: transaction,
            })
        }
        catch (e) {
            console.error(e);
            reject(e)
        }
    })
}

const updateTransaction = (transactionId, obj) => {
    return new Promise(async (resolve, reject) => {
        try {
            const updateTransaction = await Transaction.findOneAndUpdate({ _id: transactionId }, obj, { new: true })

            resolve({
                status: "OK",
                message: "success",
                data: updateTransaction
            })


        }
        catch (e) {
            console.error(e);
            reject(e)
        }
    })
}


module.exports = {
    createTransaction,
    getAllTransaction,
    getTransaction,
    updateTransaction,

}