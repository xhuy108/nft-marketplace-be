const express = require("express");
// const { body, validationResult } = require("express-validator");
// const rateLimit = require("express-rate-limit");
// const authController = require("../controllers/authController");
// const { asyncHandler } = require("../utils/asyncHandler");
// const { AppError } = require("../middleware/errorMiddleware");

const router = express.Router();

// Rate limiting
// const loginLimiter = rateLimit({
//   windowMs: 15 * 60 * 1000, // 15 minutes
//   max: 5, // limit each IP to 5 requests per windowMs
//   message: "Too many login attempts, please try again after 15 minutes",
// });

// // Validation middleware
// const validateRegistration = [
//   body("username")
//     .trim()
//     .isLength({ min: 3 })
//     .escape()
//     .withMessage("Username must be at least 3 characters long"),
//   body("email")
//     .isEmail()
//     .normalizeEmail()
//     .withMessage("Must be a valid email address"),
//   body("password")
//     .isLength({ min: 8 })
//     .withMessage("Password must be at least 8 characters long"),
// ];

// const validateLogin = [
//   body("email")
//     .isEmail()
//     .normalizeEmail()
//     .withMessage("Must be a valid email address"),
//   body("password").notEmpty().withMessage("Password is required"),
// ];

// Routes
router.get("/", async (req, res, next) => {
  res.status(200).json({ message: "Welcome to the API" });
});

// router.post(
//   "/register",
//   validateRegistration,
//   asyncHandler(async (req, res, next) => {
//     const errors = validationResult(req);
//     if (!errors.isEmpty()) {
//       return next(new AppError(400, errors.array()));
//     }
//     await authController.register(req, res);
//   })
// );

// router.post(
//   "/login",
//   loginLimiter,
//   validateLogin,
//   asyncHandler(async (req, res, next) => {
//     const errors = validationResult(req);
//     if (!errors.isEmpty()) {
//       return next(new AppError(400, errors.array()));
//     }
//     await authController.login(req, res);
//   })
// );

// router.post("/logout", authController.logout);

// router.post(
//   "/refresh-token",
//   asyncHandler(async (req, res) => {
//     await authController.refreshToken(req, res);
//   })
// );

// router.post(
//   "/forgot-password",
//   asyncHandler(async (req, res) => {
//     await authController.forgotPassword(req, res);
//   })
// );

// router.post(
//   "/reset-password/:token",
//   asyncHandler(async (req, res) => {
//     await authController.resetPassword(req, res);
//   })
// );

module.exports = router;
