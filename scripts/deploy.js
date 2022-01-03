
const hardhat = require("hardhat");
const fs = require("fs")

function replaceEnvWithNFTAddress(token_address, nft_address, nft_market_address){
    const envFile = `${__dirname}/../.env`

    const nftAddressRegex = /NFT_ADDRESS=\*+/gm
    const nftMarketAddressRegex = /NFT_MARKET_ADDRESS=\*+/gm
    const tokenAddressRegex = /TOKEN_ADDRESS=\*+/gm

    const existingEnvData = fs.readFileSync(envFile,'utf-8')

    let newData = existingEnvData

    if(process.env.RPC_URL){
      
      /** Force Replace Variables */
      console.log('Updating BLOCKCHAIN_NETWORK_RPC, NFT_ADDRESS, NFT_MARKET_ADDRESS')
      newData = newData.replace(/BLOCKCHAIN_NETWORK_RPC=.*/gm,`BLOCKCHAIN_NETWORK_RPC=${process.env.RPC_URL}`)
      newData = newData.replace(tokenAddressRegex,`TOKEN_ADDRESS=${token_address}`)
      newData = newData.replace(nftAddressRegex,`NFT_ADDRESS=${nft_address}`)
      newData = newData.replace(nftMarketAddressRegex,`NFT_MARKET_ADDRESS=${nft_market_address}`)
      
    }else{
      
      /** Replace Variable with **** */
      newData = newData.replace(tokenAddressRegex,`TOKEN_ADDRESS=${token_address}`)
      newData = newData.replace(nftAddressRegex,`NFT_ADDRESS=${nft_address}`)
      newData = newData.replace(nftMarketAddressRegex,`NFT_MARKET_ADDRESS=${nft_market_address}`)

    }

    const data = fs.writeFileSync(envFile, newData)
    return true
}


async function main() {

  const TokenX = await hardhat.ethers.getContractFactory("TOKENX");
  const tokenX = await TokenX.deploy();
  await tokenX.deployed();
  console.log("ERC20 Token Deployed To:", tokenX.address);

  const NFT = await hardhat.ethers.getContractFactory("NFT")
  const nft = await NFT.deploy()
  await nft.deployed()
  console.log("NFT deplyed to:", nft.address)

  const NFTMarket = await hardhat.ethers.getContractFactory("NFTMarket");
  const nftMarket = await NFTMarket.deploy(nft.address, tokenX.address);
  await nftMarket.deployed();
  console.log("NFTMarket deployed to:", nftMarket.address);

  replaceEnvWithNFTAddress(tokenX.address, nft.address, nftMarket.address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
