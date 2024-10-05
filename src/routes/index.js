const express = require("express");
const authRoutes = require("./api/v1/auth.route");
//const nftRoutes = require("./nfts");
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

// // Protected routes
// // router.use(`${API_VERSION}/nfts`, authenticateJWT, nftRoutes);
// // router.use(`${API_VERSION}/users`, authenticateJWT, userRoutes);
// // router.use(`${API_VERSION}/marketplace`, authenticateJWT, marketplaceRoutes);

// 404 handler
router.use((req, res, next) => {
  res.status(404).json({ error: "Not Found" });
});

module.exports = router;
