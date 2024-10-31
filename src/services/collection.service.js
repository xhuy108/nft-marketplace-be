const Collection = require('../models/collection.model')

const createCollection = (newCollection) => {
    return new Promise(async (resolve, reject) => {
        try {
            const { name, description, creator, category, listNfts } = newCollection
            const createCollection = await Collection.create({
                name,
                description,
                creator,
                category,
                listNfts
            })

            if (createCollection) {
                resolve({
                    status: "OK",
                    message: "success",
                    data: createCollection
                })
            }
        }
        catch (e) {
            console.error(e);
            reject(e)
        }
    })
}

const getAllCollection = (limit, page, sort) => {
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

            const totalCollection = await Collection.find({})

            const allCollection = await Collection.find({}).limit(limit).skip((page - 1) * limit).sort(sortObj)
                .populate('creator')
                .populate({
                    path: 'listNfts',
                    populate: [
                        { path: 'creator' },
                        { path: 'owner' },
                        { path: 'saleHistory', populate: ['seller', 'buyer'] }, // Populate version, size, and color
                    ],
                })

            resolve({
                status: "OK",
                message: "success",
                data: allCollection,
                total: totalCollection.length,
                pageCurrent: page,
                totalPage: Math.ceil(totalCollection.length / limit)
            })


        }
        catch (e) {
            console.error(e);
            reject(e)
        }
    })
}

const getCollection = (collectionId) => {
    return new Promise(async (resolve, reject) => {
        try {

            const collection = await Collection.findOne({ _id: collectionId })
                .populate('creator')
                .populate({
                    path: 'listNfts',
                    populate: [
                        { path: 'creator' },
                        { path: 'owner' },
                        { path: 'saleHistory', populate: ['seller', 'buyer'] }, // Populate version, size, and color
                    ],
                })

            resolve({
                status: "OK",
                message: "success",
                data: collection,
            })
        }
        catch (e) {
            console.error(e);
            reject(e)
        }
    })
}

const updateCollection = (collectionId, obj) => {
    return new Promise(async (resolve, reject) => {
        try {
            const updateCollection = await Collection.findOneAndUpdate({ _id: collectionId }, obj, { new: true })

            resolve({
                status: "OK",
                message: "success",
                data: updateCollection
            })


        }
        catch (e) {
            console.error(e);
            reject(e)
        }
    })
}


module.exports = {
    createCollection,
    getAllCollection,
    getCollection,
    updateCollection,

}