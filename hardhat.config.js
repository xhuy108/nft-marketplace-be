require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200, // Optimize for 200 runs
        details: {
          yul: true,
          yulDetails: {
            stackAllocation: true,
            optimizerSteps: "dhfoDgvulfnTUtnIf", // Aggressive optimization
          },
        },
      },
      viaIR: true,
    },
  },
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545/",
      chainId: 31337,
      // gas: "auto", // Let Hardhat estimate gas automatically
      // gasPrice: "auto", // Automatic gas price
      // blockGasLimit: 3000000000, // Increased block gas limit
      // allowUnlimitedContractSize: true, // Remove contract size restrictions
      // timeout: 1800000, // Increased timeout (30 minutes)
      // accounts: {
      //   mnemonic: "test test test test test test test test test test test junk", // Default hardhat mnemonic
      //   accountsBalance: "10000000000000000000000", // 10000 ETH
      // },
    },
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  mocha: {
    timeout: 100000, // Increased mocha timeout
  },
};
