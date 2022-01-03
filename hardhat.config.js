require("dotenv").config();
require("@nomiclabs/hardhat-waffle");


module.exports = {
  networks:{
    hardhat:{
      chainId: 1337,
    },
    mumbai:{
      url:`https://polygon-mumbai.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
      accounts:[process.env.ADMIN_WALLET_PRIVATE_KEY]
    },
    mainnet:{
      url:`https://polygon-mainnet.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
      accounts:[process.env.ADMIN_WALLET_PRIVATE_KEY]
    },
    getblocks_testnet:{
      url:'https://bsc.getblock.io/testnet/?api_key=44c34b4d-bfa0-45ff-9314-e6390ee329e7',
      accounts:[process.env.ADMIN_WALLET_PRIVATE_KEY]
    }
  },
  solidity: "0.8.4",
};
