// scripts/createMarketItem.js
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Creating market item with account:", deployer.address);

  // Replace with your deployed marketplace address
  const MARKETPLACE_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

  const marketplace = await ethers.getContractAt(
    "NFTMarketplace",
    MARKETPLACE_ADDRESS
  );

  console.log("Using marketplace at address:", marketplace.address);

  // Create collection
  console.log("Creating new collection...");
  const createCollectionTx = await marketplace.createCollection(
    "NFT Collection",
    "MNC",
    "ipfs://QmQ4uN6aPnaMSktcajD1m9U6rnrrgYGVWN6bDi24NXED1p",
    "Art"
  );
  await createCollectionTx.wait();

  // Get the newly created collection
  const collections = await marketplace.fetchCollections();
  const collectionAddress =
    collections[collections.length - 1].collectionAddress; // Get the latest collection
  console.log("Collection created at:", collectionAddress);

  // Get the collection contract
  const collection = await ethers.getContractAt(
    "NFTCollection",
    collectionAddress
  );

  // Mint NFT
  console.log("Minting NFT...");
  const mintTx = await collection.mint(
    deployer.address,
    "ipfs://your-token-uri"
  );
  await mintTx.wait();
  const tokenId = 1; // First token will be ID 1
  console.log("Minted NFT with tokenId:", tokenId);

  // Approve marketplace to transfer the NFT
  console.log("Approving marketplace...");
  const approveTx = await collection.approve(MARKETPLACE_ADDRESS, tokenId);
  await approveTx.wait();

  // List the NFT on the marketplace
  const price = ethers.parseEther("0.1"); // 0.1 ETH
  const listingFee = await marketplace.listingFee();

  console.log("Creating market item...");
  const createMarketItemTx = await marketplace.createMarketItem(
    collectionAddress,
    tokenId,
    price,
    { value: listingFee }
  );
  await createMarketItemTx.wait();
  console.log("Market item created successfully!");

  // Verify the item was created
  const items = await marketplace.fetchCollectionItems(collectionAddress);
  console.log("Collection items:", items);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
