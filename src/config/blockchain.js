import Web3, { utils } from "web3";
import HDWalletProvider from "@truffle/hdwallet-provider";
import { warn } from "../utils/logger";

const {
  INFURA_PROJECT_ID,
  NETWORK,
  MNEMONIC,
  CONTRACT_ADDRESS,
  GAS_PRICE_GWEI,
  GAS_LIMIT,
  CHAIN_ID,
  RETRY_ATTEMPTS,
  RETRY_INTERVAL,
} = process.env;

let provider;
let web3;

const getProvider = () => {
  if (!provider) {
    provider = new HDWalletProvider({
      mnemonic: MNEMONIC,
      providerOrUrl: `https://${NETWORK}.infura.io/v3/${INFURA_PROJECT_ID}`,
      addressIndex: 0,
      numberOfAddresses: 1,
      shareNonce: true,
      derivationPath: "m/44'/60'/0'/0/",
    });
  }
  return provider;
};

const getWeb3 = () => {
  if (!web3) {
    web3 = new Web3(getProvider());
    web3.eth.extend({
      methods: [
        {
          name: "chainId",
          call: "eth_chainId",
          outputFormatter: web3.utils.hexToNumber,
        },
      ],
    });
  }
  return web3;
};

const getGasPrice = async () => {
  const gasPrice = await getWeb3().eth.getGasPrice();
  return utils.toBN(Math.min(gasPrice, utils.toWei(GAS_PRICE_GWEI, "gwei")));
};

const sendTransaction = async (tx) => {
  let attempts = 0;
  while (attempts < RETRY_ATTEMPTS) {
    try {
      const receipt = await getWeb3().eth.sendTransaction(tx);
      return receipt;
    } catch (error) {
      warn(
        `Transaction failed. Attempt ${
          attempts + 1
        }/${RETRY_ATTEMPTS}. Error: ${error.message}`
      );
      attempts++;
      if (attempts >= RETRY_ATTEMPTS) {
        throw error;
      }
      await new Promise((resolve) => setTimeout(resolve, RETRY_INTERVAL));
    }
  }
};

export default {
  getWeb3,
  getGasPrice,
  sendTransaction,
  CONTRACT_ADDRESS,
  GAS_LIMIT: parseInt(GAS_LIMIT),
  CHAIN_ID: parseInt(CHAIN_ID),
};
