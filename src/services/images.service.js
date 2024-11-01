const cloudinary = require('../config/cloudinary');

const uploadImages = (images) => {
    return new Promise(async (resolve, reject) => {
        try {
            let resultImage = []

            for (let image of images) {
                await cloudinary.uploader.upload(`data:image/png;base64,${image}`, { folder: 'nft-marketplace' }, (error, result) => {
                    if (error) {
                        reject(error);
                    }
                    if (result) {
                        resultImage.push(
                            // publicId: result.public_id,
                            // url: result.url
                            result.url
                        )
                    }
                });


            }
            resolve({
                status: "OK",
                message: "success",
                data: resultImage,
            })


        }
        catch (e) {
            console.error(e);
            reject(e)
        }
    })
}

const deleteImages = (publicId) => {
    return new Promise(async (resolve, reject) => {
        try {

            const result = await cloudinary.uploader.destroy(publicId);
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

module.exports = {
    uploadImages,
    deleteImages
}