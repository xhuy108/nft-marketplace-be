// scripts/interact.js
const { ethers } = require("hardhat");

async function main() {
  const [deployer, buyer] = await ethers.getSigners();
  console.log("Interacting with contracts with account:", deployer.address);

  try {
    // Get the deployed marketplace contract - UPDATE THIS ADDRESS
    const MARKETPLACE_ADDRESS = "0x5eb3Bc0a489C5A8288765d2336659EbCA68FCd00"; // Your newly deployed address
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

    // Create another collection to test multiple collections
    console.log("\nCreating second test collection...");
    const createCollection2Tx = await marketplace.createCollection(
      "Test Collection 2",
      "TEST2",
      "ipfs://QmQ4uN6aPnaMSktcajD1m9U6rnrrgYGVWN6bDi24NXED1p",
      "Gaming"
    );
    await createCollection2Tx.wait();

    // Fetch user created collection
    console.log("\nFetching collections created by deployer...");
    const userCollections = await marketplace.fetchUserCreatedCollections(
      deployer.address
    );
    console.log(`Total collections created by user: ${userCollections.length}`);

    // Log each user collection's details
    console.log("\nUser Created Collections:");
    userCollections.forEach((collection, index) => {
      console.log(`\nCollection ${index + 1}:`);
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
      console.log(
        "- Created At:",
        new Date(Number(collection.basic.createdAt) * 1000).toLocaleString()
      );
    });

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

    // Check initial total supply before minting
    console.log("\nChecking initial total supply...");
    const initialCollection = await marketplace.getCollectionDetails(
      nftContractAddress
    );
    console.log(
      "Initial total supply:",
      initialCollection.totalSupply.toString()
    );

    // Mint first NFT
    console.log("\nMinting first NFT...");
    const mintTx1 = await nftContract.mint(
      deployer.address,
      "ipfs://QmaFuGuPyjK5aB7DK2GpZid4rwPmmvwECEaqyYJkhqNo6B"
    );
    const mintReceipt1 = await mintTx1.wait();
    console.log("First NFT minted, transaction:", mintReceipt1.hash);

    // Check total supply after first mint
    const collectionAfterFirstMint = await marketplace.getCollectionDetails(
      nftContractAddress
    );
    console.log(
      "Total supply after first mint:",
      collectionAfterFirstMint.totalSupply.toString()
    );

    // Mint second NFT
    console.log("\nMinting second NFT...");
    const mintTx2 = await nftContract.mint(
      deployer.address,
      "ipfs://QmaFuGuPyjK5aB7DK2GpZid4rwPmmvwECEaqyYJkhqNo6B"
    );
    const mintReceipt2 = await mintTx2.wait();
    console.log("Second NFT minted, transaction:", mintReceipt2.hash);

    // Check total supply after second mint
    const collectionAfterSecondMint = await marketplace.getCollectionDetails(
      nftContractAddress
    );
    console.log(
      "Total supply after second mint:",
      collectionAfterSecondMint.totalSupply.toString()
    );

    // Verify total supply consistency
    const nftContractTotalSupply = await nftContract.totalSupply();
    console.log("\nVerifying total supply consistency:");
    console.log(
      "NFT Contract total supply:",
      nftContractTotalSupply.toString()
    );
    console.log(
      "Marketplace collection total supply:",
      collectionAfterSecondMint.totalSupply.toString()
    );

    if (
      nftContractTotalSupply.toString() !==
      collectionAfterSecondMint.totalSupply.toString()
    ) {
      throw new Error(
        "Total supply mismatch between NFT contract and marketplace!"
      );
    }
    console.log(
      "✅ Total supply is consistent between NFT contract and marketplace"
    );

    // Verify NFT ownership
    const firstTokenId = 1;
    const secondTokenId = 2;
    const firstTokenOwner = await nftContract.ownerOf(firstTokenId);
    const secondTokenOwner = await nftContract.ownerOf(secondTokenId);
    console.log("First NFT owner:", firstTokenOwner);
    console.log("Second NFT owner:", secondTokenOwner);

    // Approve marketplace
    console.log("\nApproving marketplace...");
    console.log("NFT Contract:", nftContractAddress);
    console.log("Marketplace Address:", marketplaceAddress);
    console.log("Token ID:", firstTokenId);

    const approveTx = await nftContract.approve(
      marketplaceAddress,
      firstTokenId
    );
    const approveReceipt = await approveTx.wait();
    console.log("Marketplace approved, transaction:", approveReceipt.hash);

    // Verify approval
    const approved = await nftContract.getApproved(firstTokenId);
    console.log("Approved address:", approved);

    // Create market item
    console.log("\nCreating market item...");
    const listingFee = await marketplace.listingFee();
    console.log("Listing fee:", ethers.formatEther(listingFee), "ETH");

    const createMarketItemTx = await marketplace.createMarketItem(
      collectionAddress,
      firstTokenId,
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

    console.log("\nMaking purchase with buyer account...");
    const purchaseTx = await marketplace
      .connect(buyer)
      .createMarketSale(collectionAddress, firstTokenId, {
        value: ethers.parseEther("0.1"),
      });
    const purchaseReceipt = await purchaseTx.wait();
    console.log("Purchase successful, transaction:", purchaseReceipt.hash);

    // Verify new owner
    const newOwner = await nftContract.ownerOf(firstTokenId);
    console.log("New NFT owner:", newOwner);
    console.log("Buyer address:", buyer.address);

    // Get user's purchased items
    console.log("\nFetching buyer's purchased items...");
    const purchasedItems = await marketplace.fetchUserPurchasedItems(
      buyer.address
    );
    console.log("Total items purchased by buyer:", purchasedItems.length);

    // Display purchased items details
    purchasedItems.forEach((item, index) => {
      console.log(`\nPurchased Item ${index + 1}:`);
      console.log("- Collection Address:", item.nftContract);
      console.log("- Token ID:", item.tokenId.toString());
      console.log("- Price Paid:", ethers.formatEther(item.price), "ETH");
      console.log("- Token URI:", item.tokenURI);
    });

    // Test search functionality
    console.log("\n=== Testing Search Functionality ===");

    // 1. Basic Search by Name
    console.log("\nTesting basic search by name 'Test'...");
    const basicSearchResults = await marketplace.searchCollections("Test");
    console.log(
      "Basic search results:",
      formatSearchResults(basicSearchResults)
    );

    // 2. Search with empty string (should return all collections)
    console.log("\nTesting search with empty string...");
    const allCollectionsResults = await marketplace.searchCollections("");
    console.log(
      "All collections search results:",
      formatSearchResults(allCollectionsResults)
    );

    // 3. Search by Symbol
    console.log("\nTesting search by symbol 'TEST'...");
    const symbolSearchResults = await marketplace.searchCollections("TEST");
    console.log(
      "Symbol search results:",
      formatSearchResults(symbolSearchResults)
    );

    console.log("\n==== Testing Search Functionality ====");

    try {
      console.log("\nVerifying search function existence...");
      const contractCode = await ethers.provider.getCode(marketplaceAddress);
      console.log("Contract deployed at:", marketplaceAddress);

      // Test collection search
      console.log("\n1. Testing basic collection search...");

      // First, let's log all collections to verify they exist
      console.log("\nVerifying existing collections...");
      const allCollections = await marketplace.fetchCollections();
      console.log("Total collections available:", allCollections.length);

      // Test case-insensitive search for "test"
      console.log("\n2. Searching for collections with 'Test'");
      const searchResults = await marketplace.fetchCollectionsByCategory("Art");
      console.log("\nSearch results:", searchResults.length);

      if (searchResults.length > 0) {
        searchResults.forEach((result, index) => {
          console.log(`\nResult ${index + 1}:`);
          console.log("- Collection Address:", result.collectionAddress);
          console.log("- Name:", result.name);
          console.log("- Symbol:", result.symbol);
          console.log("- Category:", result.category);
          console.log("- Total Supply:", result.totalSupply);
        });
      } else {
        console.log("No collections found matching the search criteria");
      }

      // Try searching by category
      console.log("\n3. Testing category-specific search...");
      const artCollections = await marketplace.fetchCollectionsByCategory(
        "Art"
      );
      console.log("\nArt category collections:", artCollections.length);

      if (artCollections.length > 0) {
        artCollections.forEach((collection, index) => {
          console.log(`\nArt Collection ${index + 1}:`);
          console.log("- Name:", collection.name);
          console.log("- Category:", collection.category);
          console.log("- Total Supply:", collection.totalSupply);
        });
      } else {
        console.log("No Art collections found");
      }
    } catch (error) {
      console.error("\nError during search testing:");
      if (error.reason) console.error("Reason:", error.reason);
      if (error.data) console.error("Error data:", error.data);
      console.error(error);
    }
  } catch (error) {
    console.error("\nError during interaction:");
    if (error.reason) console.error("Reason:", error.reason);
    if (error.data) console.error("Error data:", error.data);
    console.error(error);
  }
}

function formatSearchResults(results) {
  return results.map((result) => ({
    address: result.collectionAddress,
    name: result.name,
    symbol: result.symbol,
    category: result.category,
    totalSupply: result.totalSupply.toString(),
    floorPrice: ethers.formatEther(result.floorPrice),
    isActive: result.isActive,
  }));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
