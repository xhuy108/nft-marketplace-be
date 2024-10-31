const CollectionController = require('../../../controllers/collection.controller')
const express = require('express');
const router = express.Router();

router.post('/createCollection', CollectionController.createCollection);
router.get('/get-all', CollectionController.getAllCollection);
router.get('/get-details/:id', CollectionController.getDetailCollection)
router.put('/update/:id', CollectionController.updateCollection)
module.exports = router