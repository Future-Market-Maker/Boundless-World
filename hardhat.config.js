require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require('hardhat-contract-sizer');

const { PRIVATE_KEY, SMARTCHAIN_API_KEY } = require('./secret.json');


module.exports = {
  
  solidity: {
  version: "0.5.16",
  settings: {
    optimizer: {
      enabled: true
    }
   }
  },

  defaultNetwork: "testnet",

  networks: {
    testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      gasPrice: 20000000000,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    mainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      gasPrice: 20000000000,
      accounts: [`0x${PRIVATE_KEY}`]
    }
  },

  etherscan: {
    apiKey: {
      // binance smart chain
      testnet: `${SMARTCHAIN_API_KEY}`,
      mainnet: `${SMARTCHAIN_API_KEY}`
    }
  },

  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
  },
};
