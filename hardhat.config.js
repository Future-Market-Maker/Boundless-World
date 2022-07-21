require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require('hardhat-contract-sizer');

const { PRIVATE_KEY, SMARTCHAIN_API_KEY } = require('./secret.json');


module.exports = {
  
  solidity: {
  version: "0.8.15",
  settings: {
    optimizer: {
      enabled: true
    }
   }
  },

  defaultNetwork: "bscTestnet",

  networks: {
    bscTestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      gasPrice: 20000000000,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    bsc: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      gasPrice: 20000000000,
      accounts: [`0x${PRIVATE_KEY}`]
    }
  },

  etherscan: {
    apiKey: {
      // binance smart chain
      bscTestnet: `${SMARTCHAIN_API_KEY}`,
      bsc: `${SMARTCHAIN_API_KEY}`
    }
  },

  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
  },
};
