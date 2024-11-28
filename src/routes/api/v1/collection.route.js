const express = require("express");
const router = express.Router();
const {
  createCollection,
  getAllCollections,
} = require("../../../controllers/collection.controller");
const { authenticate } = require("../../../middlewares/auth.middleware");

router.route("/").post(authenticate, createCollection).get(getAllCollections);

module.exports = router;
