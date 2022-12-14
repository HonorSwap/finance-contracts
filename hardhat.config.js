require("@nomicfoundation/hardhat-toolbox");

const {privateKey} =require("./secrets.json");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "localhost",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
      gas:2100000,
      gasPrice:8000000000
    },
    hardhat: {
    },
    testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      chainId: 97,
      gasPrice: 20000000000,
      accounts: [privateKey]
    },
    matic: {
      url: "https://rpc-mumbai.maticvigil.com",
      chainId: 80001,
      accounts: [privateKey]
    },
    mainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      gasPrice: 20000000000,
      accounts: [privateKey]
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  solidity: {
    compilers: [     
      {
        version: "0.6.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 999999,
          },
        },
      },
      {
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 5000,
          },
        },
      },
      {
        version: "0.8.4",
        settings: {
          optimizer: {
            enabled: true,
            runs: 5000,
          },
        },
      },
      
    ],
  },
  etherscan: {
    apiKey: "WUZCWJ657G2GHFNXZ9H7K9NCUI89HVQI6F",
 }
};
