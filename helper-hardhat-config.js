const networkConfig = {
  31337: {
    name: "localhost",
  },
  11155111: {
    name: "sepolia",
    blockConfirmations: 6,
  },
};

const developmentChains = ["hardhat", "localhost"];

module.exports = {
  networkConfig,
  developmentChains,
};
