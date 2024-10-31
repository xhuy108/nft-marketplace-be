const CollectionServices = require('../services/collection.service')

const createCollection = async (req, res) => {
    try {
        const { name, description, creator, category, listNfts } = req.body
        if (!name || !description || !creator || !category || !listNfts) {
            return res.status(200).json({
                status: "ERR",
                message: "The input is required"
            })
        }


        const respone = await CollectionServices.createCollection(req.body)
        return res.status(200).json(respone)
    }
    catch (e) {
        return res.status(404).json({
            messge: e
        })
    }
}

const updateCollection = async (req, res) => {
    try {
        const { id } = req.params

        const respone = await CollectionServices.updateCollection(id, req.body)
        return res.status(200).json(respone)
    }
    catch (e) {
        return res.status(404).json({
            messge: e
        })
    }
}

const getAllCollection = async (req, res) => {
    try {
        const { limit, page, sort } = req.query
        const respone = await CollectionServices.getAllCollection(Number(limit) || 8, Number(page) || 1, sort)
        return res.status(200).json(respone)
    }
    catch (e) {
        return res.status(404).json({
            messge: e
        })
    }
}

const getDetailCollection = async (req, res) => {
    try {
        const { id } = req.params
        const respone = await CollectionServices.getCollection(id)
        return res.status(200).json(respone)
    }
    catch (e) {
        return res.status(404).json({
            messge: e
        })
    }
}


module.exports = {
    createCollection,
    getAllCollection,
    getDetailCollection,
    updateCollection,
}