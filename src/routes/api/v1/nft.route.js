const NFTController = require('../../../controllers/nft.controller')
const express = require('express');
const router = express.Router();

router.get('/test', NFTController.test);
router.post('/createNFT', NFTController.createNFT);
router.get('/get-all', NFTController.getAllNFT);
router.get('/get-details/:id', NFTController.getDetailNFT)
router.put('/update/:id', NFTController.updateNFT)
router.put('/like/:id', NFTController.likeNFT)
router.put('/list/:id', NFTController.listNFT)
router.put('/updatePrice/:id', NFTController.updatePrice)
module.exports = router