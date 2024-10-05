const { createServer } = require("http");
const { Server } = require("socket.io");
const mongoose = require("mongoose");
const logger = require("./utils/logger");
//const socketHandlers = require("./socketHandlers");

const dotenv = require("dotenv");
dotenv.config();

const config = require("./config");

const app = require("./app");

const httpServer = createServer(app);

const io = new Server(httpServer, {
  cors: {
    origin: config.app.corsOrigin,
    methods: ["GET", "POST"],
  },
});

// // Socket.io
// io.on("connection", socketHandlers);
// Start server
const PORT = config.app.port;
httpServer.listen(PORT, () => {
  logger.info(`Server running in ${process.env.NODE_ENV} mode on port ${PORT}`);
});

// Graceful shutdown
process.on("SIGTERM", () => {
  logger.info("SIGTERM signal received. Closing HTTP server.");
  httpServer.close(() => {
    logger.info("HTTP server closed.");
    // Close database connection
    mongoose.connection.close(false, () => {
      logger.info("MongoDB connection closed.");
      process.exit(0);
    });
  });
});

// Unhandled promise rejections
process.on("unhandledRejection", (reason, promise) => {
  logger.error("Unhandled Rejection at:", promise, "reason:", reason);
  // Close server & exit process
  httpServer.close(() => process.exit(1));
});
