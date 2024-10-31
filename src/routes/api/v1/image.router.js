const express = require('express');
const router = express.Router();
const ImageController = require('../../../controllers/images.controller')

router.post('/upload', ImageController.uploadImages);
router.post('/remove', ImageController.deleteImages)
module.exports = router