const logger = require("../utils/logger");

class AppError extends Error {
  constructor(statusCode, message, isOperational = true, stack = "") {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = isOperational;
    if (stack) {
      this.stack = stack;
    } else {
      Error.captureStackTrace(this, this.constructor);
    }
  }
}

const errorMiddleware = (err, req, res, next) => {
  err.statusCode = err.statusCode || 500;
  err.message = err.message || "Internal Server Error";

  // Log the error
  logger.error({
    error: {
      message: err.message,
      stack: err.stack,
      statusCode: err.statusCode,
    },
    requestInfo: {
      method: req.method,
      url: req.originalUrl,
      ip: req.ip,
      userId: req.user ? req.user.id : "unauthenticated",
    },
  });

  // Specific error handling
  if (err.name === "ValidationError") {
    const errors = Object.values(err.errors).map((el) => el.message);
    err = new AppError(400, `Invalid input data. ${errors.join(". ")}`);
  }

  if (err.code === 11000) {
    const value = err.errmsg.match(/(["'])(\\?.)*?\1/)[0];
    err = new AppError(
      400,
      `Duplicate field value: ${value}. Please use another value!`
    );
  }

  if (err.name === "JsonWebTokenError") {
    err = new AppError(401, "Invalid token. Please log in again!");
  }

  if (err.name === "TokenExpiredError") {
    err = new AppError(401, "Your token has expired! Please log in again.");
  }

  // Send error response
  if (process.env.NODE_ENV === "development") {
    sendErrorDev(err, res);
  } else if (process.env.NODE_ENV === "production") {
    sendErrorProd(err, res);
  }
};

const sendErrorDev = (err, res) => {
  res.status(err.statusCode).json({
    status: "error",
    error: err,
    message: err.message,
    stack: err.stack,
  });
};

const sendErrorProd = (err, res) => {
  // Operational, trusted error: send message to client
  if (err.isOperational) {
    res.status(err.statusCode).json({
      status: "error",
      message: err.message,
    });
  }
  // Programming or other unknown error: don't leak error details
  else {
    // Log error
    logger.error("ERROR 💥", err);

    // Send generic message
    res.status(500).json({
      status: "error",
      message: "Something went very wrong!",
    });
  }
};

module.exports = {
  AppError,
  errorMiddleware,
};
