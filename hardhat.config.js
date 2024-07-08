/** @type import('hardhat/config').HardhatUserConfig */
// import "@nomiclabs/hardhat-etherscan";
// import "@nomiclabs/hardhat-ethers";

// import "@nomicfoundation/hardhat-verify";
// import "@openzeppelin/hardhat-upgrades";

require("@nomiclabs/hardhat-etherscan")
require("@nomiclabs/hardhat-ethers")

require("@openzeppelin/hardhat-upgrades")
require("dotenv/config")
// import 'dotenv/config'
console.log(process.env) // remove this after you've confirmed it is working

const PRIVATE_KEY = process.env.PRIVATE_KEY;

module.exports = {
    defaultNetwork: "bsctestnet",
    networks: {
        hardhat: {
        },
        opbnb: {
          url: "https://opbnb-testnet-rpc.bnbchain.org/",
          chainId: 5611, // Replace with the correct chainId for the "opbnb" network
          accounts: [PRIVATE_KEY], // Add private keys or mnemonics of accounts to use for deployment
          gasPrice: 20000000000,
        },
        bsctestnet:{
            url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
                chainId: 97,
              accounts: [PRIVATE_KEY],
              gasPrice: 5000000000
            
          }
    },
    solidity: {
        compilers: [
            {
                version: "0.8.21",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                    evmVersion: 'london'
                }
            },
            {
                version: "0.8.14",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    }
                }
            },
            {
                version: "0.8.9",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    }
                }
            },
            {
                version: "0.8.8",
                settings: {
                    optimizer: {
                        enabled: false,
                        runs: 200,
                    }
                }
            },
            {
                version: "0.8.7",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    }
                }
            },
            {
                version: "0.8.4",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    }
                }
            },
            {
                version: "0.8.1",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 100,
                    }
                }
            },
            {
                version: "0.8.0",
                settings: {
                    optimizer: {
                        enabled: false,
                        runs: 200,
                    }
                }
            },
            {
                version: "0.7.0",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    }
                }
            },
            {
                version: "0.6.12",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    }
                }
            },
            {
                version: "0.6.2",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    }
                }
            }
        ]
    },
    etherscan: {
      apiKey: {
        opbnb: "WAMTXC2GI6B5U99SED99R8MGUACPVF52ZS",
        bsctestnet:"HG9W9GWY155QYMCHTKDIEUQJ6RBEHQ67DB"
      },
      customChains: [
        {
          network: "opbnb",
          chainId: 5611, // Replace with the correct chainId for the "opbnb" network
          urls: {
            apiURL: "https://open-platform.nodereal.io/3cefd5ddd4674d3f88755e483abbdea4/op-bnb-testnet/contract/",
            browserURL: "https://opbnbscan.com/",
          },
        },
        {
            network: "bsctestnet",
            chainId: 97, // Replace with the correct chainId for the "opbnb" network
            urls: {
              apiURL: "https://api-testnet.bscscan.com/api",
              browserURL: "https://testnet.bscscan.com/",
            },
          },
      ],
    },
    paths: {
        sources: "./contracts",
        tests: "./test",
        cache: "./cache",
        artifacts: "./artifacts"
    },
    mocha: {
        timeout: 20000
    }
};