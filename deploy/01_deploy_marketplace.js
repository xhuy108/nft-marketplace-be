const { network } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  console.log("Deploying contracts with account:", deployer);

  const marketplace = await deploy("NFTMarketplace", {
    from: deployer,
    args: [],
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });

  console.log("NFTMarketplace deployed to:", marketplace.address);

  // Verify contract if not on localhost
  if (network.name !== "hardhat" && network.name !== "localhost") {
    try {
      await run("verify:verify", {
        address: marketplace.address,
        constructorArguments: [],
      });
    } catch (error) {
      if (error.message.toLowerCase().includes("already verified")) {
        console.log("Contract already verified!");
      } else {
        console.error("Error verifying contract:", error);
      }
    }
  }
};

module.exports.tags = ["all", "marketplace"];
