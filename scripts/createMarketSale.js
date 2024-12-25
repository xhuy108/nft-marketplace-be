// scripts/createMarketSale.js
const { ethers } = require("hardhat");

async function main() {
  // Get accounts
  const [seller, buyer] = await ethers.getSigners();
  console.log("Buyer account:", buyer.address);

  // Contract addresses - replace with your deployed addresses
  const MARKETPLACE_ADDRESS = "0x0B306BF915C4d645ff596e518fAf3F9669b97016";

  // Get the marketplace contract
  const marketplace = await ethers.getContractAt(
    "NFTMarketplace",
    MARKETPLACE_ADDRESS,
    buyer // Connect with buyer's account
  );

  // Fetch all collections
  const collections = await marketplace.fetchCollections();
  const collectionAddress =
    collections[collections.length - 1].collectionAddress; // Get the latest collection
  console.log("Collection address:", collectionAddress);

  // Fetch collection items
  const items = await marketplace.fetchCollectionItems(collectionAddress);
  console.log("Available items in collection:", items);

  //   // Get the first available item (for demonstration)
  //   const item = items[0];
  //   if (!item) {
  //     console.log("No items available for sale");
  //     return;
  //   }

  //   if (!item.isOnSale) {
  //     console.log("Item is not for sale");
  //     return;
  //   }

  //   // Check if buyer has enough balance
  //   const buyerBalance = await ethers.provider.getBalance(buyer.address);
  //   if (buyerBalance < item.price) {
  //     console.log("Insufficient balance to buy item");
  //     return;
  //   }

  //   // Check if buyer is not the seller
  //   if (item.seller === buyer.address) {
  //     console.log("Buyer cannot be the seller");
  //     return;
  //   }

  //   console.log("Buying item:", {
  //     tokenId: item.tokenId,
  //     price: ethers.formatEther(item.price),
  //     seller: item.seller,
  //   });

  //   // Create market sale
  //   console.log("Creating market sale...");
  //   const createSaleTx = await marketplace.createMarketSale(
  //     collectionAddress,
  //     item.tokenId,
  //     { value: item.price }
  //   );
  //   await createSaleTx.wait();
  //   console.log("Market sale completed!");

  //   // Verify the purchase
  //   const collection = await ethers.getContractAt(
  //     "NFTCollection",
  //     collectionAddress
  //   );
  //   const newOwner = await collection.ownerOf(item.tokenId);
  //   console.log("New owner of token:", newOwner);
  //   console.log("Expected owner (buyer):", buyer.address);
  //   console.log("Sale successful:", newOwner === buyer.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
