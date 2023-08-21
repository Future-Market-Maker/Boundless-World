require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require('hardhat-contract-sizer');

const { PRIVATE_KEY, SMARTCHAIN_API_KEY, MUMBAI_API_KEY, POLYGONSCAN_API_KEY } = require('./secret.json');

module.exports = {
  
  solidity: {
  version: "0.8.18",
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
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      // url: "https://data-seed-prebsc-1-s2.binance.org:8545/",
      // url: "https://bsc-testnet.public.blastapi.io",
      chainId: 97,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    polygonMumbai: {
      // url: `https://matic-mumbai.chainstacklabs.com`,
      // url: `https://rpc.ankr.com/polygon_mumbai`,
      url: `https://polygon-mumbai.blockpi.network/v1/rpc/public`,
      accounts: [`0x${PRIVATE_KEY}`],
      chainId: 80001,
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
