require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require('hardhat-contract-sizer');

const { PRIVATE_KEY, SMARTCHAIN_API_KEY, MUMBAI_API_KEY, POLYGONSCAN_API_KEY } = require('./secret.json');

module.exports = {
  
  solidity: {
  version: "0.8.15",
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,
    }
   }
  },

  networks: {
    bsc: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    bscTestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    polygonMumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${MUMBAI_API_KEY}`,
      accounts: [`0x${PRIVATE_KEY}`],
    },
  },

  etherscan: {
    apiKey: {
      bsc: `${SMARTCHAIN_API_KEY}`,
      bscTestnet: `${SMARTCHAIN_API_KEY}`,
      polygonMumbai: `${POLYGONSCAN_API_KEY}`,  
    }
  },

  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
  },
};
