const NFT = require('../models/nft.model')

const test = () => {
    return new Promise(async (resolve, reject) => {
        try {
            resolve({
                status: "OK",
                message: "success",
                data: "Chao 123"
            })


        }
        catch (e) {
            console.error(e);
            reject(e)
        }
    })
}

const createNFT = (newNFT) => {
    return new Promise(async (resolve, reject) => {
        try {
            // const { name, description, image, creator, owner, price, currency, tokenId, contractAddress, blockchain, metadataURI, tags, category, attributes, likes, saleHistory } = newNFT
            // const createNFT = await NFT.create({
            //     name,
            //     description,
            //     image,
            //     creator,
            //     owner,
            //     price,
            //     currency,
            //     tokenId,
            //     contractAddress,
            //     blockchain,
            //     metadataURI,
            //     tags,
            //     category,
            //     attributes,
            //     likes,
            //     saleHistory
            // })
            const { name, description, image, price, currency, tokenId, contractAddress, blockchain, metadataURI, tags, category, attributes, likes, saleHistory } = newNFT
            const createNFT = await NFT.create({
                name,
                description,
                image,
                price,
                currency,
                tokenId,
                contractAddress,
                blockchain,
                metadataURI,
                tags,
                category,
                attributes,
                likes,
                saleHistory
            })
            if (createNFT) {
                resolve({
                    status: "OK",
                    message: "success",
                    data: createNFT
                })
            }
        }
        catch (e) {
            console.error(e);
            reject(e)
        }
    })
}

const getAllNFT = (limit, page, sort) => {
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

            const totalNFT = await NFT.find({})

            const allNFT = await NFT.find({}).limit(limit).skip((page - 1) * limit).sort(sortObj)
                .populate('creator')
                .populate('owner')
                .populate({
                    path: 'saleHistory',
                    populate: [
                        { path: 'seller' },
                        { path: 'buyer' },
                    ],
                })


            resolve({
                status: "OK",
                message: "success",
                data: allNFT,
                total: totalNFT.length,
                pageCurrent: page,
                totalPage: Math.ceil(totalNFT.length / limit)
            })


        }
        catch (e) {
            console.error(e);
            reject(e)
        }
    })
}

const getNFT = (nftId) => {
    return new Promise(async (resolve, reject) => {
        try {

            const nft = await NFT.findOne({ _id: nftId })
                .populate('creator')
                .populate('owner')
                .populate({
                    path: 'saleHistory',
                    populate: [
                        { path: 'seller' },
                        { path: 'buyer' },
                    ],
                })
            await nft.incrementViews()
            resolve({
                status: "OK",
                message: "success",
                data: nft,
            })
        }
        catch (e) {
            console.error(e);
            reject(e)
        }
    })
}

const updateNFT = (nftId, obj) => {
    return new Promise(async (resolve, reject) => {
        try {
            const updateNFT = await NFT.findOneAndUpdate({ _id: nftId }, obj, { new: true })

            resolve({
                status: "OK",
                message: "success",
                data: updateNFT
            })


        }
        catch (e) {
            console.error(e);
            reject(e)
        }
    })
}

const likeNFT = (nftId, userId) => {
    return new Promise(async (resolve, reject) => {
        try {
            const nft = await NFT.findById(nftId);
            await nft.toggleLike(userId);

            resolve({
                status: "OK",
                message: "success",
            })


        }
        catch (e) {
            console.error(e);
            reject(e)
        }
    })
}

const listNFT = (nftId) => {
    return new Promise(async (resolve, reject) => {
        try {
            const nft = await NFT.findById(nftId);
            await nft.toggleListing();

            resolve({
                status: "OK",
                message: "success",
            })


        }
        catch (e) {
            console.error(e);
            reject(e)
        }
    })
}

const updatePrice = (nftId, newPrice) => {
    return new Promise(async (resolve, reject) => {
        try {
            const nft = await NFT.findById(nftId);
            await nft.updatePrice(newPrice);

            resolve({
                status: "OK",
                message: "success",
                data: nft
            })


        }
        catch (e) {
            console.error(e);
            reject(e)
        }
    })
}
module.exports = {
    test,
    createNFT,
    getAllNFT,
    getNFT,
    updateNFT,
    likeNFT,
    listNFT,
    updatePrice
}