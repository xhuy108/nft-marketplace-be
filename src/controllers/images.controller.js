const ImageServices = require('../services/images.service')

const uploadImages = async (req, res) => {
    try {
        const { images } = req.body


        const respone = await ImageServices.uploadImages(images)
        return res.status(200).json(respone)
    }
    catch (e) {
        return res.status(404).json({
            messge: e
        })
    }
}

const deleteImages = async (req, res) => {
    try {
        const { publicId } = req.body
        const respone = await ImageServices.deleteImages(publicId)
        return res.status(200).json(respone)
    }
    catch (e) {
        return res.status(404).json({
            messge: e
        })
    }
}

module.exports = {
    uploadImages,
    deleteImages
}