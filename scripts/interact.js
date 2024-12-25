// scripts/interact.js
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Interacting with contracts with account:", deployer.address);

  try {
    // Get the deployed marketplace contract - UPDATE THIS ADDRESS
    const MARKETPLACE_ADDRESS = "0x0B306BF915C4d645ff596e518fAf3F9669b97016"; // Your newly deployed address
    const Marketplace = await ethers.getContractFactory("NFTMarketplace");
    const marketplace = Marketplace.attach(MARKETPLACE_ADDRESS);
    const marketplaceAddress = await marketplace.getAddress();

    console.log("Using marketplace at address:", marketplaceAddress);

    // First check available categories
    console.log("\nFetching categories...");
    const categories = await marketplace.getCategories();
    console.log("Available categories:", categories);

    // Create a test collection
    console.log("\nCreating new collection...");
    const createCollectionTx = await marketplace.createCollection(
      "Test Collection",
      "TEST",
      "ipfs://QmQ4uN6aPnaMSktcajD1m9U6rnrrgYGVWN6bDi24NXED1p",
      "Art"
    );

    console.log("Waiting for collection creation transaction...");
    const receipt = await createCollectionTx.wait();
    console.log("Transaction receipt:", receipt.hash);

    // Get collections after creation
    console.log("\nFetching collections...");
    const collections = await marketplace.fetchCollections();
    console.log("Total collections found:", collections.length);

    if (collections.length === 0) {
      throw new Error("No collections found after creation");
    }

    // Log each collection's details
    for (let i = 0; i < collections.length; i++) {
      const collection = collections[i];
      console.log(`\nCollection ${i + 1}:`);
      console.log("- Address:", collection.basic.collectionAddress);
      console.log("- Name:", collection.basic.name);
      console.log("- Symbol:", collection.basic.symbol);
      console.log("- Category:", collection.basic.category);
      console.log("- Base URI:", collection.basic.baseURI);
      console.log("- Floor Price:", ethers.formatEther(collection.floorPrice));
      console.log(
        "- Total Volume:",
        ethers.formatEther(collection.totalVolume)
      );
      console.log("- Owner Count:", collection.ownerCount.toString());
    }

    // Use the last created collection
    const lastCollection = collections[collections.length - 1];
    if (
      !lastCollection ||
      !lastCollection.basic ||
      !lastCollection.basic.collectionAddress
    ) {
      throw new Error("Invalid collection data");
    }

    const collectionAddress = lastCollection.basic.collectionAddress;
    console.log("\nUsing collection at address:", collectionAddress);

    // Verify the collection address is valid
    if (!ethers.isAddress(collectionAddress)) {
      throw new Error("Invalid collection address");
    }

    // Get NFT contract
    const NFTCollection = await ethers.getContractFactory("NFTCollection");
    const nftContract = NFTCollection.attach(collectionAddress);
    const nftContractAddress = await nftContract.getAddress();
    console.log("NFT Contract attached at:", nftContractAddress);

    // Verify the contract exists at the address
    const code = await ethers.provider.getCode(collectionAddress);
    if (code === "0x") {
      throw new Error("No contract found at the collection address");
    }

    // Mint an NFT
    console.log("\nMinting NFT...");
    const mintTx = await nftContract.mint(
      deployer.address,
      "ipfs://QmaFuGuPyjK5aB7DK2GpZid4rwPmmvwECEaqyYJkhqNo6B"
    );
    const mintReceipt = await mintTx.wait();
    console.log("NFT minted, transaction:", mintReceipt.hash);

    // Verify NFT ownership
    const tokenId = 1; // Assuming this is the first NFT
    const owner = await nftContract.ownerOf(tokenId);
    console.log("NFT owner:", owner);

    // Approve marketplace
    console.log("\nApproving marketplace...");
    console.log("NFT Contract:", nftContractAddress);
    console.log("Marketplace Address:", marketplaceAddress);
    console.log("Token ID:", tokenId);

    const approveTx = await nftContract.approve(marketplaceAddress, tokenId);
    const approveReceipt = await approveTx.wait();
    console.log("Marketplace approved, transaction:", approveReceipt.hash);

    // Verify approval
    const approved = await nftContract.getApproved(tokenId);
    console.log("Approved address:", approved);

    // Create market item
    console.log("\nCreating market item...");
    const listingFee = await marketplace.listingFee();
    console.log("Listing fee:", ethers.formatEther(listingFee), "ETH");

    const createMarketItemTx = await marketplace.createMarketItem(
      collectionAddress,
      tokenId,
      ethers.parseEther("0.1"),
      { value: listingFee }
    );
    const marketItemReceipt = await createMarketItemTx.wait();
    console.log("Market item created, transaction:", marketItemReceipt.hash);

    // Fetch and display market items
    console.log("\nFetching collection items...");
    const items = await marketplace.fetchCollectionItems(collectionAddress);
    console.log("Market items found:", items.length);

    items.forEach((item, index) => {
      console.log(`\nItem ${index + 1}:`);
      console.log("- Token ID:", item.tokenId.toString());
      console.log("- Token Uri:", item.tokenURI);
      console.log("- Price:", ethers.formatEther(item.price));
      console.log("- Seller:", item.seller);
      console.log("- Is on sale:", item.isOnSale);
    });
  } catch (error) {
    console.error("\nError during interaction:");
    if (error.reason) console.error("Reason:", error.reason);
    if (error.data) console.error("Error data:", error.data);
    console.error(error);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
