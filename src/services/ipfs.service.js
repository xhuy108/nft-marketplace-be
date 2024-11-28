// class IPFSService {
//   constructor() {
//     // Option 1: Using IPFS HTTP Client
//     // this.ipfs = create({
//     //   host: "ipfs.infura.io",
//     //   port: 5001,
//     //   protocol: "https",
//     //   headers: {
//     //     authorization: `Basic ${Buffer.from(
//     //       process.env.INFURA_IPFS_PROJECT_ID +
//     //         ":" +
//     //         process.env.INFURA_IPFS_PROJECT_SECRET
//     //     ).toString("base64")}`,
//     //   },
//     // });

//     // Option 2: Using Pinata
//     this.pinataApiKey = process.env.PINATA_API_KEY;
//     this.pinataSecretKey = process.env.PINATA_SECRET_KEY;
//   }

//   async uploadToIPFS(data) {
//     try {
//       // If data is a Buffer (for images)
//       if (Buffer.isBuffer(data)) {
//         return await this._uploadFileToIPFS(data);
//       }
//       // If data is JSON metadata
//       else if (typeof data === "string" || typeof data === "object") {
//         return await this._uploadJSONToIPFS(data);
//       }
//       throw new Error("Unsupported data type for IPFS upload");
//     } catch (error) {
//       throw new Error(`IPFS Upload Error: ${error.message}`);
//     }
//   }

//   async _uploadFileToIPFS(fileBuffer) {
//     try {
//       // Option 1: Using IPFS HTTP Client
//       //   const result = await this.ipfs.add(fileBuffer);
//       //   return result.path;

//       // Option 2: Using Pinata

//       const formData = new FormData();
//       formData.append("file", fileBuffer, {
//         filename: "nft-image.png",
//       });

//       const response = await axios.post(
//         "https://api.pinata.cloud/pinning/pinFileToIPFS",
//         formData,
//         {
//           maxBodyLength: Infinity,
//           headers: {
//             "Content-Type": `multipart/form-data; boundary=${formData._boundary}`,
//             pinata_api_key: this.pinataApiKey,
//             pinata_secret_api_key: this.pinataSecretKey,
//           },
//         }
//       );

//       return response.data.IpfsHash;
//     } catch (error) {
//       throw new Error(`File Upload Error: ${error.message}`);
//     }
//   }

//   async _uploadJSONToIPFS(jsonData) {
//     try {
//       // Option 1: Using IPFS HTTP Client
//       //   const data = JSON.stringify(jsonData);
//       //   const result = await this.ipfs.add(data);
//       //   return result.path;

//       // Option 2: Using Pinata

//       const response = await axios.post(
//         "https://api.pinata.cloud/pinning/pinJSONToIPFS",
//         jsonData,
//         {
//           headers: {
//             pinata_api_key: this.pinataApiKey,
//             pinata_secret_api_key: this.pinataSecretKey,
//           },
//         }
//       );

//       return response.data.IpfsHash;
//     } catch (error) {
//       throw new Error(`JSON Upload Error: ${error.message}`);
//     }
//   }
// }

// module.exports = new IPFSService();
