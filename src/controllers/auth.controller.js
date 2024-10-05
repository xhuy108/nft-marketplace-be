const authService = require("../services/auth.service");
// const {
//   registerValidator,
//   loginValidator,
//   resetPasswordValidator,
// } = require("../validators/authValidator");
const { AppError } = require("../middlewares/errorMiddleware");

const register = async (req, res, next) => {
  try {
    // const { error } = registerValidator.validate(req.body);
    // if (error) {
    //   throw new AppError(400, error.details[0].message);
    // } 

    const user = await authService.registerUser(req.body);
    const token = authService.generateToken(user);

    await authService.sendWelcomeEmail(user.email);

    res.status(201).json({
      status: "success",
      data: {
        user: { id: user._id, username: user.username, email: user.email },
        token,
      },
    });
  } catch (error) {
    next(error);
  }
};

const login = async (req, res, next) => {
  try {
    // const { error } = loginValidator.validate(req.body);
    // if (error) {
    //   throw new AppError(400, error.details[0].message);
    // }

    const { user, token } = await authService.loginUser(req.body);

    await authService.updateLastLogin(user._id);

    res.json({
      status: "success",
      data: {
        user: { id: user._id, username: user.username, email: user.email },
        token,
      },
    });
  } catch (error) {
    next(error);
  }
};

const logout = async (req, res, next) => {
  try {
    await authService.logoutUser(req.user, req.token);
    res.json({ status: "success", message: "Logged out successfully" });
  } catch (error) {
    next(error);
  }
};

const refreshToken = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      throw new AppError(400, "Refresh token is required");
    }
    const { user, token } = await authService.refreshUserToken(refreshToken);
    res.json({
      status: "success",
      data: {
        user: { id: user._id, username: user.username, email: user.email },
        token,
      },
    });
  } catch (error) {
    next(error);
  }
};

const forgotPassword = async (req, res, next) => {
  try {
    const { email } = req.body;
    if (!email) {
      throw new AppError(400, "Email is required");
    }
    await authService.initiatePasswordReset(email);
    res.json({ status: "success", message: "Password reset email sent" });
  } catch (error) {
    next(error);
  }
};

const resetPassword = async (req, res, next) => {
  try {
    const { error } = resetPasswordValidator.validate(req.body);
    if (error) {
      throw new AppError(400, error.details[0].message);
    }

    const { token, newPassword } = req.body;
    await authService.resetPassword(token, newPassword);
    res.json({ status: "success", message: "Password reset successful" });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  register,
  login,
  logout,
  refreshToken,
  forgotPassword,
  resetPassword,
};
