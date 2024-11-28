const { ethers } = require("ethers");
require("dotenv").config();
const {
  IPFS_PROJECT_ID,
  PRIVATE_KEY,
  // MNEMONIC,
  // CONTRACT_ADDRESS,
  // GAS_PRICE_GWEI,
  // GAS_LIMIT,
  // CHAIN_ID,
  // RETRY_ATTEMPTS,
  // RETRY_INTERVAL,
} = process.env;
const NFTCollectionFactory = require("../../artifacts/contracts/NFTMarketplace.sol/NFTMarketplace.json");

// Connect to the Ethereum network via Infura
const provider = new ethers.InfuraProvider("sepolia", IPFS_PROJECT_ID);

// Load your MetaMask wallet
const signer = new ethers.Wallet(PRIVATE_KEY, provider);

// Specify the ERC-20 contract address and ABI
const contractAddress = "0x2869A503f4A7F6fC18326e2d3e98412acAc31Fd9";
const contractABI = NFTCollectionFactory.abi;

console.log(contractABI);

// Connect to the ERC-20 contract
const contractInstance = new ethers.Contract(
  contractAddress,
  contractABI,
  signer
);

const express = require("express");
const app = express();

app.use(express.json());

app.get("/", async (req, res) => {
  try {
    const item = await contractInstance.fetchMarketItems();
    res.send(item);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

const PORT = 3000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

// Example: Get the balance of the connected wallet
// async function getBalance() {
//   const balance = await contractInstance.getAddress();
//   console.log(`Balance: ${balance}`);
// }

// // Example: Transfer ERC-20 tokens to another address
// async function transferTokens(toAddress, amount) {
//   const tx = await erc20Contract.transfer(toAddress, amount);
//   await tx.wait();
//   console.log(`Tokens transferred to ${toAddress}`);
// }

// // Example: Approve spending of ERC-20 tokens by another address
// async function approveSpending(spenderAddress, amount) {
//   const tx = await erc20Contract.approve(spenderAddress, amount);
//   await tx.wait();
//   console.log(`Approved spending by ${spenderAddress}`);
// }

// Call your functions
// getBalance();
