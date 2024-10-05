const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const crypto = require("crypto");
const User = require("../models/user.model");
const Token = require("../models/nft.model");
const emailService = require("./email.service");
const config = require("../config");
const { AppError } = require("../middlewares/error.middleware");

const registerUser = async (userData) => {
  const { username, email, password, walletAddress } = userData;

  const existingUser = await User.findOne({ $or: [{ email }, { username }] });
  if (existingUser) {
    throw new AppError(400, "Username or email already exists");
  }

  const user = new User({ username, email, password, walletAddress });
  await user.save();

  return user;
};

const loginUser = async ({ email, password }) => {
  const user = await User.findOne({ email });
  if (!user) {
    throw new AppError(401, "Invalid credentials");
  }

  const isMatch = await user.comparePassword(password);
  if (!isMatch) {
    throw new AppError(401, "Invalid credentials");
  }

  const token = generateToken(user);
  const refreshToken = generateRefreshToken(user);

  user.refreshToken = refreshToken;
  await user.save();

  return { user, token, refreshToken };
};

const logoutUser = async (user, token) => {
  user.refreshToken = null;
  await user.save();
  await Token.findOneAndDelete({ userId: user._id, token });
};

const refreshUserToken = async (refreshToken) => {
  try {
    const decoded = jwt.verify(refreshToken, config.jwt.refreshSecret);
    const user = await User.findById(decoded.id);

    if (!user || user.refreshToken !== refreshToken) {
      throw new AppError(401, "Invalid refresh token");
    }

    const newToken = generateToken(user);
    return { user, token: newToken };
  } catch (error) {
    throw new AppError(401, "Invalid refresh token");
  }
};

const generateToken = (user) => {
  return jwt.sign({ id: user._id, role: user.role }, config.jwt.secret, {
    expiresIn: config.jwt.expiresIn,
  });
};

const generateRefreshToken = (user) => {
  return jwt.sign({ id: user._id }, config.jwt.refreshSecret, {
    expiresIn: config.jwt.refreshExpiresIn,
  });
};

const updateLastLogin = async (userId) => {
  const user = await User.findByIdAndUpdate(userId, { lastLogin: new Date() });
  if (!user) {
    throw new AppError(404, "User not found");
  }
};

const initiatePasswordReset = async (email) => {
  const user = await User.findOne({ email });
  if (!user) {
    // We don't want to reveal if the email exists or not
    return;
  }

  const resetToken = crypto.randomBytes(32).toString("hex");
  const hash = await bcrypt.hash(resetToken, 10);

  await Token.findOneAndDelete({ userId: user._id, type: "passwordReset" });
  await new Token({
    userId: user._id,
    token: hash,
    type: "passwordReset",
    expiresAt: Date.now() + 3600000, // 1 hour
  }).save();

  const resetLink = `${config.clientUrl}/reset-password?token=${resetToken}&id=${user._id}`;
  await emailService.sendPasswordResetEmail(user.email, resetLink);
};

const resetPassword = async (resetToken, newPassword) => {
  const passwordResetToken = await Token.findOne({ type: "passwordReset" });

  if (!passwordResetToken) {
    throw new AppError(400, "Invalid or expired password reset token");
  }

  const isValid = await bcrypt.compare(resetToken, passwordResetToken.token);

  if (!isValid) {
    throw new AppError(400, "Invalid or expired password reset token");
  }

  const user = await User.findById(passwordResetToken.userId);
  if (!user) {
    throw new AppError(404, "User not found");
  }

  user.password = newPassword;
  await user.save();

  await Token.findByIdAndDelete(passwordResetToken._id);
};

const sendWelcomeEmail = async (email) => {
  try {
    await emailService.sendWelcomeEmail(email);
  } catch (error) {
    // Log the error but don't throw, as this shouldn't break the registration process
    console.error("Failed to send welcome email:", error);
  }
};

module.exports = {
  registerUser,
  loginUser,
  logoutUser,
  refreshUserToken,
  updateLastLogin,
  initiatePasswordReset,
  resetPassword,
  sendWelcomeEmail,
};
