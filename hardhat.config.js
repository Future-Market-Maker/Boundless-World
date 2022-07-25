require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require('hardhat-contract-sizer');

const { PRIVATE_KEY, SMARTCHAIN_API_KEY, ETHERSCAN_API_KEY } = require('./secret.json');


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
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161`,
      accounts: [`0x${PRIVATE_KEY}`],
    },
  },

  etherscan: {
    apiKey: {
      bsc: `${SMARTCHAIN_API_KEY}`,
      bscTestnet: `${SMARTCHAIN_API_KEY}`,
      rinkeby: `${ETHERSCAN_API_KEY}`,
    }
  },

  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
  },
};
