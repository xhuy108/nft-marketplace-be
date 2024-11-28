const pinataSDK = require("@pinata/sdk");
require("dotenv").config();

const pinata = new pinataSDK(
  process.env.PINATA_API_KEY,
  process.env.PINATA_SECRET_KEY
);

module.exports = pinata;
