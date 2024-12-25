// const ethers = require("ethers");
// require("dotenv").config();

// async function main() {
//   try {
//     // Create provider
//     const provider = new ethers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL);

//     // Create wallet
//     const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

//     // Get wallet address
//     const address = await wallet.getAddress();

//     // Get balance
//     const balance = await provider.getBalance(address);

//     console.log("Connection Test Results:");
//     console.log("----------------------");
//     console.log("Network:", await provider.getNetwork());
//     console.log("Wallet Address:", address);
//     console.log("Balance:", ethers.formatEther(balance), "ETH");

//     if (balance === BigInt(0)) {
//       console.log(
//         "\n⚠️ WARNING: Your wallet has no Sepolia ETH. Please get some from a faucet."
//       );
//     }
//   } catch (error) {
//     console.error("Error:", error.message);
//     console.log("\nTroubleshooting Tips:");
//     console.log("1. Check if your .env file exists and has the correct values");
//     console.log("2. Verify your Infura URL format");
//     console.log("3. Make sure your private key is correct");
//     console.log("4. Ensure you have an internet connection");
//   }
// }

// main()
//   .then(() => process.exit(0))
//   .catch((error) => {
//     console.error(error);
//     process.exit(1);
//   });
