const hre = require("hardhat");
const fs = require("fs");

async function main() {
  // Get the network we're deploying to
  const network = await hre.ethers.provider.getNetwork();
  console.log(
    `Deploying to network: ${
      network.name
    } (chainId: ${network.chainId.toString()})`
  );

  // Deploy CategoryLib first
  console.log("Deploying CategoryLib...");
  const CategoryLib = await hre.ethers.getContractFactory("CategoryLib");
  const categoryLib = await CategoryLib.deploy();
  await categoryLib.waitForDeployment();
  const categoryLibAddress = await categoryLib.getAddress();
  console.log(`CategoryLib deployed to: ${categoryLibAddress}`);

  // Deploy StatsLib next
  console.log("Deploying StatsLib...");
  const StatsLib = await hre.ethers.getContractFactory("StatsLib");
  const statsLib = await StatsLib.deploy();
  await statsLib.waitForDeployment();
  const statsLibAddress = await statsLib.getAddress();
  console.log(`StatsLib deployed to: ${statsLibAddress}`);

  // Link libraries to NFTCollectionFactory
  console.log("Deploying NFTCollectionFactory...");
  const NFTCollectionFactory = await hre.ethers.getContractFactory(
    "NFTCollectionFactory",
    {
      libraries: {
        CategoryLib: categoryLibAddress,
        StatsLib: statsLibAddress,
      },
    }
  );
  const factory = await NFTCollectionFactory.deploy();
  await factory.waitForDeployment();
  const factoryAddress = await factory.getAddress();
  console.log(`NFTCollectionFactory deployed to: ${factoryAddress}`);

  // Deploy NFTMarketplace with factory address
  console.log("Deploying NFTMarketplace...");
  const NFTMarketplace = await hre.ethers.getContractFactory("NFTMarketplace");
  const marketplace = await NFTMarketplace.deploy(factoryAddress);
  await marketplace.waitForDeployment();
  const marketplaceAddress = await marketplace.getAddress();
  console.log(`NFTMarketplace deployed to: ${marketplaceAddress}`);

  // Wait for block confirmations
  console.log("Waiting for block confirmations...");
  await factory.deploymentTransaction().wait(5);
  await marketplace.deploymentTransaction().wait(5);

  // Verify contracts on Etherscan
  if (network.name !== "hardhat" && network.name !== "localhost") {
    console.log("Verifying contracts on Etherscan...");
    try {
      await hre.run("verify:verify", {
        address: factoryAddress,
        constructorArguments: [],
      });
      console.log("NFTCollectionFactory verified on Etherscan");

      await hre.run("verify:verify", {
        address: marketplaceAddress,
        constructorArguments: [factoryAddress],
      });
      console.log("NFTMarketplace verified on Etherscan");
    } catch (error) {
      if (error.message.includes("already verified")) {
        console.log("Contracts are already verified!");
      } else {
        console.error("Error verifying contracts:", error);
      }
    }
  }

  // Save deployment information
  const deploymentInfo = {
    network: network.name,
    chainId: network.chainId.toString(),
    categoryLibAddress: categoryLibAddress,
    statsLibAddress: statsLibAddress,
    factoryAddress: factoryAddress,
    marketplaceAddress: marketplaceAddress,
    deploymentDate: new Date().toISOString(),
    factoryDeploymentTxHash: factory.deploymentTransaction().hash,
    marketplaceDeploymentTxHash: marketplace.deploymentTransaction().hash,
    factoryBlockNumber: (
      await factory.deploymentTransaction().wait()
    ).blockNumber.toString(),
    marketplaceBlockNumber: (
      await marketplace.deploymentTransaction().wait()
    ).blockNumber.toString(),
  };

  // Create deployments directory structure
  const deploymentsDir = "./deployments";
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir);
  }

  const networkDir = `${deploymentsDir}/${network.name}`;
  if (!fs.existsSync(networkDir)) {
    fs.mkdirSync(networkDir);
  }

  // Save deployment info with timestamp
  const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
  const filename = `${networkDir}/deployment-${timestamp}.json`;
  fs.writeFileSync(filename, JSON.stringify(deploymentInfo, null, 2));
  fs.writeFileSync(
    `${networkDir}/latest.json`,
    JSON.stringify(deploymentInfo, null, 2)
  );

  // Save contract ABIs
  const factoryArtifact = require("../artifacts/contracts/NFTCollectionFactory.sol/NFTCollectionFactory.json");
  const marketplaceArtifact = require("../artifacts/contracts/NFTMarketplace.sol/NFTMarketplace.json");

  fs.writeFileSync(
    `${networkDir}/NFTCollectionFactory.json`,
    JSON.stringify(
      {
        address: factoryAddress,
        abi: factoryArtifact.abi,
        deploymentInfo,
      },
      null,
      2
    )
  );

  fs.writeFileSync(
    `${networkDir}/NFTMarketplace.json`,
    JSON.stringify(
      {
        address: marketplaceAddress,
        abi: marketplaceArtifact.abi,
        deploymentInfo,
      },
      null,
      2
    )
  );

  // Generate TypeChain typings if needed
  try {
    await hre.run("typechain");
    console.log("TypeChain typings generated successfully");
  } catch (error) {
    console.warn("Warning: TypeChain generation failed:", error.message);
  }

  console.log("\nDeployment Summary:");
  console.log("===================");
  console.log(`Network: ${network.name}`);
  console.log(`Chain ID: ${network.chainId.toString()}`);
  console.log(`NFTCollectionFactory: ${factoryAddress}`);
  console.log(`NFTMarketplace: ${marketplaceAddress}`);
  console.log(
    `Factory Transaction Hash: ${factory.deploymentTransaction().hash}`
  );
  console.log(
    `Marketplace Transaction Hash: ${marketplace.deploymentTransaction().hash}`
  );
  console.log(`Factory Block Number: ${deploymentInfo.factoryBlockNumber}`);
  console.log(
    `Marketplace Block Number: ${deploymentInfo.marketplaceBlockNumber}`
  );
  console.log("===================");

  // Return deployment info for testing purposes
  return deploymentInfo;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
