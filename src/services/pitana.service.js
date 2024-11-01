const axios = require('axios');
const { PINATA_API_KEY, PINATA_SECRET_API_KEY } = process.env;
const uploadToPinata = async (metadata, fileName) => {
    const url = `https://api.pinata.cloud/pinning/pinJSONToIPFS`;
    // const pinataPayload = {
    //     pinataMetadata: {
    //         name: fileName || 'default-file-name' // Sử dụng tên tùy chọn hoặc đặt tên mặc định
    //     },
    //     pinataContent: metadata
    // };

    const payload = {
        pinataMetadata: {
            name: fileName || 'default-file-name' // Đặt tên file hoặc tên mặc định
        },
        pinataContent: metadata // Nội dung metadata của file
    };
    try {
        // const response = await axios.post(url, pinataPayload, {
        //     headers: {
        //         pinata_api_key: PINATA_API_KEY,
        //         pinata_secret_api_key: PINATA_SECRET_API_KEY,
        //         'Content-Type': 'application/json'
        //     }
        // });

        const response = await axios.post(url, payload, {
            headers: {
                'pinata_api_key': PINATA_API_KEY,
                'pinata_secret_api_key': PINATA_SECRET_API_KEY,
                'Content-Type': 'application/json'
            }
        });
        return `https://gateway.pinata.cloud/ipfs/${response.data.IpfsHash}`;

    } catch (error) {
        console.error("Pinata upload error:", error);
        throw new Error("Failed to upload to Pinata");
    }
};

module.exports = uploadToPinata;
