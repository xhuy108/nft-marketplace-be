const express = require("express");
const authRoutes = require("./api/v1/auth.route");
const collectionRoutes = require("./api/v1/collection.route");

// const nftRoutes = require("./api/v1/nft.route");
// const collectionRoutes = require("./api/v1/collection.route");
//const userRoutes = require("./users");
//const marketplaceRoutes = require("./marketplace");
//const { authenticateJWT } = require("../middleware/auth");

const router = express.Router();

// Health check route
router.get("/health", (req, res) => {
  res.status(200).json({ status: "OK", message: "Server is running" });
});

// API version prefix
const API_VERSION = "/api/v1";

// Public routes
router.use(`${API_VERSION}/auth`, authRoutes);
router.use(`${API_VERSION}/collections`, collectionRoutes);

// router.use(`${API_VERSION}/nfts`, nftRoutes);
// router.use(`${API_VERSION}/collection`, collectionRoutes);


// 404 handler
router.use((req, res, next) => {
  res.status(404).json({ error: "Not Found" });
});

module.exports = router;
