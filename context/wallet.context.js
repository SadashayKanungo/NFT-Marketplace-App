import { ethers } from 'ethers'
import Web3Modal from "web3modal"
import {
  nftmarketaddress, nftaddress, tokenaddress
} from '../config'

import NFTAbi from '../artifacts/contracts/NFT.sol/NFT.json'
import MarketAbi from '../artifacts/contracts/NFTMarket.sol/NFTMarket.json'

export async function getProvider() {
  const web3Modal = new Web3Modal({
    network: "hardhat",
    cacheProvider: true,
  })

  const connection = await web3Modal.connect()
  const provider = new ethers.providers.Web3Provider(connection)
  console.log("fetched", provider)
  return provider

}

const parseSaleItem = async (i) => {
  //console.log("parsing", i);
  const [tokenId, tokenUri, seller, sellingPrice, forSale] = i
  //const meta = await axios.get(tokenUri)
  let item = {
    type: "Sale",
    tokenId: tokenId.toNumber(),
    seller: seller,
    sellingPrice : ethers.utils.formatEther(sellingPrice._hex.toString()),
    //owner: i.owner, Not returned by smart contract
    //image: meta.data.image,
    tokenUri
  }
  return item
}
const parseAuctionItem = async (i) => {
  //console.log("parsing", i);
  const [tokenId, tokenUri, seller, startingPrice, expiresAt, currentBidPrice, currentBidder, bidPrices, bidders, onAuction] = i
  //const meta = await axios.get(tokenUri)
  let item = {
    type: "Auction",
    tokenId: tokenId.toNumber(),
    seller,
    startingPrice : ethers.utils.formatEther(startingPrice._hex.toString()),
    expiresAt: new Date(expiresAt * 1000),
    currentBidPrice: ethers.utils.formatEther(currentBidPrice._hex.toString()),
    currentBidder,
    bidPrices: bidPrices.map((bp) => ethers.utils.formatEther(bp._hex.toString())),
    bidders,
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
  // Allow marketplace to use all of user's NFTs
  // Call this function when user makes a new account on the website
  approveMarketplace: async function (signer) {
    const nftContract = new ethers.Contract(nftaddress, NFTAbi.abi, provider)
    const data = await nftContract.setApprovalForAll(nftmarketaddress, true);
    return data;
  },

  // Load user's NFTs
  loadMyNFTs: async function (provider) {
    const nftContract = new ethers.Contract(nftaddress, NFTAbi.abi, provider)
    const data = await nftContract.getMyNfts()
    console.log(data);
    return data;
  },

  // Create a new NFT for the user
  mintNFT : async function (signer, tokenUri, metadataUri, royaltyPercent) {
    const nftContract = new ethers.Contract(nftaddress, NFTAbi.abi, signer)
    const ownerAddress = await signer.getAddress()
    const data = await nftContract.mintItem(ownerAddress, tokenUri, metadataUri, royaltyPercent)
    console.log(data);
    return data;
  },

  // Load NFTs that user has set to sell/auction on marketplace
  loadMyItems: async function (signer) {
    const marketContract = new ethers.Contract(nftmarketaddress, MarketAbi.abi, signer)
    
    const SaleData = await marketContract.fetchMySalesItems()
    const SaleItems = await Promise.all(SaleData.map(async i => {const parsed = await parseSaleItem(i); return parsed;}))

    const AuctionData = await marketContract.fetchMyAuctionsItems()
    const AuctionItems = await Promise.all(AuctionData.map(async i => {const parsed = await parseAuctionItem(i); return parsed;}))

    const items = SaleItems.concat(AuctionItems)
    return items;
  },

  // Load All NFTs that are available on marketplace for sale/auction
  loadAllNFTs: async function (provider) {
    const marketContract = new ethers.Contract(nftmarketaddress, MarketAbi.abi, provider)

    const SaleData = await marketContract.fetchSalesItems()
    const SaleItems = await Promise.all(SaleData.map(async i => {const parsed = await parseSaleItem(i); return parsed;}))

    const AuctionData = await marketContract.fetchAuctionsItems()
    const AuctionItems = await Promise.all(AuctionData.map(async i => {const parsed = await parseAuctionItem(i); return parsed;}))

    const items = SaleItems.concat(AuctionItems)
    console.log("fetched", items);
    return items;
  },

  // Set one of user's NFTs to sell on marketplace
  createSale : async function (signer, nftId, nftPrice) {
    const marketContract = new ethers.Contract(nftmarketaddress, MarketAbi.abi, signer)
    const data = await marketContract.setNftToSell(nftId, ethers.utils.parseEther(nftPrice.toString()))
    console.log(data);
  },

  // Set one of user's NFTs to sell on marketplace
  createAuction : async function (signer, nftId, auctionStartPrice, auctionExpiryTime) {
    const marketContract = new ethers.Contract(nftmarketaddress, MarketAbi.abi, signer)
    const data = await marketContract.setNftToAuction(nftId, ethers.utils.parseEther(auctionStartPrice.toString()), auctionExpiryTime, {from : signer.getAddress()})
    console.log(data);
  },

  // Load ownership history of an NFT
  loadHistory : async function (provider, tokenId) {
    const nftContract = new ethers.Contract(nftaddress, NFTAbi.abi, provider)
    const data = await nftContract.getHistory(tokenId)
    const history = await Promise.all(data.map(async i => {const parsed = await parseHistory(i); return parsed;}))
    return history;
  }
  // getMyNfts - Loop on getByTokenID
  // AuctionBids - Not storing all bids, only highest
}
