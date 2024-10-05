const dotenv = require("dotenv");
const path = require("path");

// Load environment variables from .env file
dotenv.config({ path: path.join(__dirname, "../.env") });

const env = process.env.NODE_ENV || "development";

const development = {
  env: "development",
  app: {
    port: parseInt(process.env.DEV_APP_PORT) || 3000,
    jwtSecret: process.env.DEV_JWT_SECRET,
    jwtExpirationInterval: process.env.DEV_JWT_EXPIRATION_MINUTES || 30,
    corsOrigin: process.env.DEV_CORS_ORIGIN || "http://localhost:3000",
  },
  db: {
    uri: process.env.DEV_MONGODB_URI,
    options: {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      useCreateIndex: true,
      useFindAndModify: false,
    },
  },
  blockchain: {
    providerUrl: process.env.DEV_BLOCKCHAIN_PROVIDER_URL,
    networkId: parseInt(process.env.DEV_NETWORK_ID) || 1337,
    gasPrice: process.env.DEV_GAS_PRICE || "20000000000", // 20 gwei
    gasLimit: parseInt(process.env.DEV_GAS_LIMIT) || 6721975,
    contractAddress: process.env.DEV_CONTRACT_ADDRESS,
  },
  ipfs: {
    host: process.env.DEV_IPFS_HOST || "ipfs.infura.io",
    port: parseInt(process.env.DEV_IPFS_PORT) || 5001,
    protocol: process.env.DEV_IPFS_PROTOCOL || "https",
  },
  email: {
    smtp: {
      host: process.env.DEV_SMTP_HOST,
      port: parseInt(process.env.DEV_SMTP_PORT) || 587,
      auth: {
        user: process.env.DEV_SMTP_USERNAME,
        pass: process.env.DEV_SMTP_PASSWORD,
      },
    },
    secure: process.env.EMAIL_SECURE === "true",
    from: process.env.DEV_EMAIL_FROM,
    clientUrl: process.env.CLIENT_URL,
  },
  logging: {
    level: process.env.DEV_LOG_LEVEL || "debug",
    filename: process.env.DEV_LOG_FILENAME || "app.log",
  },
};

const test = {
  env: "test",
  app: {
    port: parseInt(process.env.TEST_APP_PORT) || 3001,
    jwtSecret: process.env.TEST_JWT_SECRET,
    jwtExpirationInterval: process.env.TEST_JWT_EXPIRATION_MINUTES || 30,
    corsOrigin: process.env.TEST_CORS_ORIGIN || "http://localhost:3001",
  },
  db: {
    uri: process.env.TEST_MONGODB_URI,
    options: {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      useCreateIndex: true,
      useFindAndModify: false,
    },
  },
  blockchain: {
    providerUrl: process.env.TEST_BLOCKCHAIN_PROVIDER_URL,
    networkId: parseInt(process.env.TEST_NETWORK_ID) || 1337,
    gasPrice: process.env.TEST_GAS_PRICE || "20000000000", // 20 gwei
    gasLimit: parseInt(process.env.TEST_GAS_LIMIT) || 6721975,
    contractAddress: process.env.TEST_CONTRACT_ADDRESS,
  },
  ipfs: {
    host: process.env.TEST_IPFS_HOST || "ipfs.infura.io",
    port: parseInt(process.env.TEST_IPFS_PORT) || 5001,
    protocol: process.env.TEST_IPFS_PROTOCOL || "https",
  },
  email: {
    smtp: {
      host: process.env.TEST_SMTP_HOST,
      port: parseInt(process.env.TEST_SMTP_PORT) || 587,
      auth: {
        user: process.env.TEST_SMTP_USERNAME,
        pass: process.env.TEST_SMTP_PASSWORD,
      },
    },
    from: process.env.TEST_EMAIL_FROM,
  },
  logging: {
    level: process.env.TEST_LOG_LEVEL || "debug",
    filename: process.env.TEST_LOG_FILENAME || "test.log",
  },
};

const production = {
  env: "production",
  app: {
    port: parseInt(process.env.PROD_APP_PORT) || 3000,
    jwtSecret: process.env.PROD_JWT_SECRET,
    jwtExpirationInterval: process.env.PROD_JWT_EXPIRATION_MINUTES || 30,
    corsOrigin: process.env.PROD_CORS_ORIGIN,
  },
  db: {
    uri: process.env.PROD_MONGODB_URI,
    options: {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      useCreateIndex: true,
      useFindAndModify: false,
    },
  },
  blockchain: {
    providerUrl: process.env.PROD_BLOCKCHAIN_PROVIDER_URL,
    networkId: parseInt(process.env.PROD_NETWORK_ID) || 1, // Ethereum mainnet
    gasPrice: process.env.PROD_GAS_PRICE || "20000000000", // 20 gwei
    gasLimit: parseInt(process.env.PROD_GAS_LIMIT) || 6721975,
    contractAddress: process.env.PROD_CONTRACT_ADDRESS,
  },
  ipfs: {
    host: process.env.PROD_IPFS_HOST || "ipfs.infura.io",
    port: parseInt(process.env.PROD_IPFS_PORT) || 5001,
    protocol: process.env.PROD_IPFS_PROTOCOL || "https",
  },
  email: {
    smtp: {
      host: process.env.PROD_SMTP_HOST,
      port: parseInt(process.env.PROD_SMTP_PORT) || 587,
      auth: {
        user: process.env.PROD_SMTP_USERNAME,
        pass: process.env.PROD_SMTP_PASSWORD,
      },
    },
    from: process.env.PROD_EMAIL_FROM,
  },
  logging: {
    level: process.env.PROD_LOG_LEVEL || "info",
    filename: process.env.PROD_LOG_FILENAME || "app.log",
  },
};

const config = {
  development,
  test,
  production,
};

module.exports = config[env];
