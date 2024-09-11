const mongoose = require("mongoose");
const logger = require("../utils/logger");
const dotenv = require("dotenv");

dotenv.config();

const { MONGO_USERNAME, MONGO_PASSWORD, NODE_ENV } = process.env;

const options = {
  autoIndex: NODE_ENV === "development",
  connectTimeoutMS: 10000,
  socketTimeoutMS: 45000,
  family: 4,
};

const uri = `mongodb+srv://${MONGO_USERNAME}:${MONGO_PASSWORD}@cluster0.uzy9p.mongodb.net/test?retryWrites=true&w=majority&appName=Cluster0`;

const connect = async () => {
  try {
    await mongoose.connect(uri, options);
    logger.info("MongoDB connected successfully");

    mongoose.connection.on("error", (err) => {
      logger.error(`MongoDB connection error: ${err}`);
    });

    mongoose.connection.on("disconnected", () => {
      logger.warn("MongoDB disconnected. Attempting to reconnect...");
      setTimeout(connect, 5000);
    });

    process.on("SIGINT", async () => {
      await mongoose.connection.close();
      logger.info("MongoDB connection closed due to app termination");
      process.exit(0);
    });
  } catch (err) {
    logger.error(`MongoDB connection error: ${err}`);
    process.exit(1);
  }
};

connect();

module.exports = {
  connect,
  uri,
  options,
};
