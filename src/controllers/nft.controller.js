const NFTServices = require('../services/nft.service')

const test = async (req, res) => {
    try {

        const respone = await NFTServices.test()
        return res.status(200).json(respone)
    }
    catch (e) {
        return res.status(404).json({
            messge: e
        })
    }
}

const createNFT = async (req, res) => {
    try {
        // const { name, description, image, creator, owner, price, currency, tokenId, contractAddress, blockchain, tags, category, attributes, likes, saleHistory } = req.body
        // if (!name || !description || !image || !creator || !owner || !price || !currency || !tokenId || !contractAddress || !blockchain || !category) {
        //     return res.status(200).json({
        //         status: "ERR",
        //         message: "The input is required"
        //     })
        // }

        const { name, description, image, price, currency, tokenId, contractAddress, blockchain, category } = req.body
        if (!name || !description || !image || !price || !currency || !tokenId || !contractAddress || !blockchain || !category) {
            return res.status(200).json({
                status: "ERR",
                message: "The input is required"
            })
        }
        const respone = await NFTServices.createNFT(req.body)
        return res.status(200).json(respone)
    }
    catch (e) {
        return res.status(404).json({
            messge: e
        })
    }
}

const updateNFT = async (req, res) => {
    try {
        const { id } = req.params

        const respone = await NFTServices.updateNFT(id, req.body)
        return res.status(200).json(respone)
    }
    catch (e) {
        return res.status(404).json({
            messge: e
        })
    }
}

const getAllNFT = async (req, res) => {
    try {
        const { limit, page, sort } = req.query
        const respone = await NFTServices.getAllNFT(Number(limit) || 8, Number(page) || 1, sort)
        return res.status(200).json(respone)
    }
    catch (e) {
        return res.status(404).json({
            messge: e
        })
    }
}

const getDetailNFT = async (req, res) => {
    try {
        const { id } = req.params
        const respone = await NFTServices.getNFT(id)
        return res.status(200).json(respone)
    }
    catch (e) {
        return res.status(404).json({
            messge: e
        })
    }
}

const likeNFT = async (req, res) => {
    try {
        const { id } = req.params
        const { userId } = req.body
        const respone = await NFTServices.likeNFT(id, userId)
        return res.status(200).json(respone)
    }
    catch (e) {
        return res.status(404).json({
            messge: e
        })
    }
}

const listNFT = async (req, res) => {
    try {
        const { id } = req.params
        const respone = await NFTServices.listNFT(id)
        return res.status(200).json(respone)
    }
    catch (e) {
        return res.status(404).json({
            messge: e
        })
    }
}

const updatePrice = async (req, res) => {
    try {
        const { id } = req.params
        const { newPrice } = req.body
        const respone = await NFTServices.updatePrice(id, newPrice)
        return res.status(200).json(respone)
    }
    catch (e) {
        return res.status(404).json({
            messge: e
        })
    }
}

module.exports = {
    test,
    createNFT,
    getAllNFT,
    getDetailNFT,
    updateNFT,
    likeNFT,
    listNFT,
    updatePrice
}