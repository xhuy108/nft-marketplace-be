const TransactionController = require('../../../controllers/transaction.controller')
const express = require('express');
const router = express.Router();

router.post('/createTransaction', TransactionController.createTransaction);
router.get('/get-all', TransactionController.getAllTransaction);
router.get('/get-details/:id', TransactionController.getDetailTransaction)
router.put('/update/:id', TransactionController.updateTransaction)
module.exports = router