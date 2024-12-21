const express = require("express");
const router = express.Router();
const multer = require("multer");
const upload = multer({ storage: multer.memoryStorage() });
const NFTController = require("../../../controllers/nft.controler");
// const { authenticateUser } = require("../middlewares/auth.middleware");

router.post(
  "/:collectionAddress/mint",
  upload.single("image"),
  NFTController.mintNFT
);

// router.get(
//   "/:collectionAddress+:tokenId",
//   NFTController.getNFTMetadata
// );

module.exports = router;
