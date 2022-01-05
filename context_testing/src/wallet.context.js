import { ethers } from 'ethers'
import Web3Modal from "web3modal"
import {
  nftmarketaddress, nftaddress, tokenaddress
} from './config'

import MarketAbi from './abi/NFTMarket.json'
import NFTAbi from './abi/NFT.json'

export async function getProvider() {
  const web3Modal = new Web3Modal({
    network: "mainnet",
    cacheProvider: true,
  })

  const connection = await web3Modal.connect()
  const provider = new ethers.providers.Web3Provider(connection)
  console.log("fetched", provider)
  return provider

}

const parseItem = async (i) => {
  //console.log("parsing", i);
  const [tokenId, tokenUri, seller, sellingPrice, forSale] = i
  //const meta = await axios.get(tokenUri)
  let item = {
    tokenId: tokenId.toNumber(),
    seller: seller,
    price : ethers.utils.formatEther(sellingPrice._hex.toString()),
    //owner: i.owner, Not returned by smart contract
    //image: meta.data.image,
    tokenUri
  }
  return item
}
const parseHistory = async (i) => {
  console.log("parsing", i);
  const [owner,value] = i
  //const meta = await axios.get(tokenUri)
  let item = {
    owner,
    value : ethers.utils.formatEther(value._hex.toString()),
  }
  return item
}

export const marketplace = {
  loadMyNFTs: async function (signer) {
    const marketContract = new ethers.Contract(nftmarketaddress, MarketAbi, signer)
    
    const SaleData = await marketContract.fetchMySalesItems()
    const SaleItems = await Promise.all(SaleData.map(async i => {const parsed = await parseItem(i); return parsed;}))

    const AuctionData = await marketContract.fetchMyAuctionsItems()
    const AuctionItems = await Promise.all(AuctionData.map(async i => {const parsed = await parseItem(i); return parsed;}))

    const items = SaleItems.concat(AuctionItems)
    return items;
  },

  loadAllNFTs: async function (provider) {
    const marketContract = new ethers.Contract(nftmarketaddress, MarketAbi, provider)

    const SaleData = await marketContract.fetchSalesItems()
    const SaleItems = await Promise.all(SaleData.map(async i => {const parsed = await parseItem(i); return parsed;}))

    const AuctionData = await marketContract.fetchAuctionsItems()
    const AuctionItems = await Promise.all(AuctionData.map(async i => {const parsed = await parseItem(i); return parsed;}))

    const items = SaleItems.concat(AuctionItems)
    console.log("fetched", items);
    return items;
  },

  createSale : async function (signer, nftId, nftPrice) {
    const marketContract = new ethers.Contract(nftmarketaddress, MarketAbi, signer)
    const data = await marketContract.setNftToSell(nftId, ethers.utils.parseEther(nftPrice.toString()))
    console.log(data);
  },

  createAuction : async function (signer, nftId, auctionStartPrice, auctionExpiryTime) {
    const marketContract = new ethers.Contract(nftmarketaddress, MarketAbi, signer)
    const data = await marketContract.setNftToAuction(nftId, ethers.utils.parseEther(auctionStartPrice.toString()), auctionExpiryTime, {from : signer.getAddress()})
    console.log(data);
  },

  mintNFT : async function (signer, tokenUri, metadataUri, royaltyPercent) {
    const nftContract = new ethers.Contract(nftaddress, NFTAbi, signer)
    const ownerAddress = await signer.getAddress()
    const data = await nftContract.mintItem(ownerAddress, tokenUri, metadataUri, royaltyPercent)
    console.log(data);
  },

  loadHistory : async function (provider, tokenId) {
    const nftContract = new ethers.Contract(nftaddress, NFTAbi, provider)
    const data = await nftContract.getHistory(tokenId)
    const history = await Promise.all(data.map(async i => {const parsed = await parseHistory(i); return parsed;}))
    return history;
  }
  // getMyNfts - Loop on getByTokenID
  // AuctionBids - Not storing all bids, only highest
}
