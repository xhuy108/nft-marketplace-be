const TransactionServices = require('../services/transaction.service')

const createTransaction = async (req, res) => {
    try {
        const { nft, seller, buyer, transaction_hash, price } = req.body
        if (!nft || !seller || !buyer || !transaction_hash || !price) {
            return res.status(200).json({
                status: "ERR",
                message: "The input is required"
            })
        }


        const respone = await TransactionServices.createTransaction(req.body)
        return res.status(200).json(respone)
    }
    catch (e) {
        return res.status(404).json({
            messge: e
        })
    }
}

const updateTransaction = async (req, res) => {
    try {
        const { id } = req.params

        const respone = await TransactionServices.updateTransaction(id, req.body)
        return res.status(200).json(respone)
    }
    catch (e) {
        return res.status(404).json({
            messge: e
        })
    }
}

const getAllTransaction = async (req, res) => {
    try {
        const { limit, page, sort } = req.query
        const respone = await TransactionServices.getAllTransaction(Number(limit) || 8, Number(page) || 1, sort)
        return res.status(200).json(respone)
    }
    catch (e) {
        return res.status(404).json({
            messge: e
        })
    }
}

const getDetailTransaction = async (req, res) => {
    try {
        const { id } = req.params
        const respone = await TransactionServices.getTransaction(id)
        return res.status(200).json(respone)
    }
    catch (e) {
        return res.status(404).json({
            messge: e
        })
    }
}


module.exports = {
    createTransaction,
    getAllTransaction,
    getDetailTransaction,
    updateTransaction,
}