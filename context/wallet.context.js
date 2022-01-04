import React, { useContext, useEffect, useState } from "react";
import { ethers } from 'ethers'
import Web3Modal from "web3modal"


import {
  nftmarketaddress, nftaddress, tokenaddress
} from '../config'

import Market from '../artifacts/contracts/NFTMarket.sol/NFTMarket.json'
import NFT from '../artifacts/contracts/NFT.sol/NFT.json'

import Fortmatic from "fortmatic";
import WalletConnectProvider from "@walletconnect/web3-provider";
import WalletLink from 'walletlink'

export const WalletContext = React.createContext()

export const WalletProvider = ({ children }) => {

  const [wallet, setWallet] = useState(null)

  async function getProvider() {
    // const web3Modal = new Web3Modal({
    //     network: "mainnet",
    //     cacheProvider: true,
    //     providerOptions:{
    //         injected: {
    //             display: {
    //               logo: "data:image/gif;base64,INSERT_BASE64_STRING",
    //               name: "Injected",
    //               description: "Connect with the provider in your Browser"
    //             },
    //             package: null
    //         },
    //         walletconnect: {
    //             package: WalletConnectProvider, // required
    //             options: {
    //               infuraId:  process.env.INFURA_PROJECT_ID
    //             }
    //         },
    //         fortmatic: {
    //             package: Fortmatic, // required
    //             options: {
    //               key: "pk_test_391E26A3B43A3350" // required
    //             }
    //         },
    //         'custom-coinbase': {
    //             display: {
    //               logo: 'images/coinbase.svg', 
    //               name: 'Coinbase',
    //               description: 'Scan with WalletLink to connect',
    //             },
    //             options: {
    //               appName: 'app', 
    //               networkUrl: `https://mainnet.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
    //               chainId: 1337,
    //             },
    //             package: WalletLink,
    //             connector: async (_, options) => {
    //               const { appName, networkUrl, chainId } = options
    //               const walletLink = new WalletLink({
    //                 appName
    //               });
    //               const provider = walletLink.makeWeb3Provider(networkUrl, chainId);
    //               await provider.enable();
    //               return provider;
    //             },
    //         }
    //     }
    // })

    const web3Modal = new Web3Modal({
      network: "mainnet",
      cacheProvider: true,
    })

    const connection = await web3Modal.connect()
    const provider = new ethers.providers.Web3Provider(connection)
    // const signer = provider.getSigner()

    setWallet(provider)
    return provider

  }

  useEffect(() => {

    // (async function(){
    //   await getProvider()
    // })()

  }, [])

  const marketplace = {
  loadMyNFTs: async function (provider) {
    const marketContract = new ethers.Contract(nftmarketaddress, MarketAbi, provider)
    const tokenContract = new ethers.Contract(nftaddress, NFTAbi, provider)
    
    const SaleData = await marketContract.fetchMySalesItems({from : provider.getAddress()})
    const SaleItems = await Promise.all(SaleData.map(async i => {
      const tokenUri = await tokenContract.tokenURI(i.tokenId)
      //const meta = await axios.get(tokenUri)
      let price = ethers.utils.formatEther(i.sellingPrice._hex.toString())
      let item = {
        price,
        tokenId: i.tokenId.toNumber(),
        seller: i.seller,
        //owner: i.owner, Not returned by smart contract
        //image: meta.data.image,
        tokenUri
      }
      return item
    }))

    const AuctionData = await marketContract.fetchMyAuctionsItems({from : provider.getAddress()})
    const AuctionItems = await Promise.all(AuctionData.map(async i => {
      const tokenUri = await tokenContract.tokenURI(i.tokenId)
      //const meta = await axios.get(tokenUri)
      let price = ethers.utils.formatEther(i.sellingPrice._hex.toString())
      let item = {
        price,
        tokenId: i.tokenId.toNumber(),
        seller: i.seller,
        //owner: i.owner, Not returned by smart contract
        //image: meta.data.image,
        tokenUri
      }
      return item
    }))
    const items = SaleItems.concat(AuctionItems)
    console.log("fetched", items);
    return items;
  },

  loadAllNFTs: async function (provider) {
    const marketContract = new ethers.Contract(nftmarketaddress, MarketAbi, provider)
    const tokenContract = new ethers.Contract(nftaddress, NFTAbi, provider)

    const SaleData = await marketContract.fetchSalesItems()
    console.log("data", SaleData);
    const SaleItems = await Promise.all(SaleData.map(async i => {
      const tokenUri = await tokenContract.tokenURI(i.tokenId)
      //const meta = await axios.get(tokenUri)
      console.log("price", i.sellingPrice._hex.toString());

      let price = ethers.utils.formatEther(i.sellingPrice._hex.toString())
      let item = {
        price,
        tokenId: i.tokenId.toNumber(),
        seller: i.seller,
        //owner: i.owner, Not returned by smart contract
        //image: meta.data.image,
        tokenUri
      }
      return item
    }))
    console.log("saleitems", SaleItems);

    const AuctionData = await marketContract.fetchAuctionsItems()
    const AuctionItems = await Promise.all(AuctionData.map(async i => {
      const tokenUri = await tokenContract.tokenURI(i.tokenId)
      //const meta = await axios.get(tokenUri)
      let price = ethers.utils.formatEther(i.sellingPrice._hex.toString())
      let item = {
        price,
        tokenId: i.tokenId.toNumber(),
        seller: i.seller,
        //owner: i.owner, Not returned by smart contract
        //image: meta.data.image,
        tokenUri
      }
      return item
    }))
    const items = SaleItems.concat(AuctionItems)
    console.log("fetched", items);
    return items;
  },

  createSale : async function (signer, nftId, nftPrice) {
    const marketContract = new ethers.Contract(nftmarketaddress, MarketAbi, signer)
    //const tokenContract = new ethers.Contract(nftaddress, NFTAbi, provider)
    const data = await marketContract.setNftForSell(nftId, nftPrice, {from : signer.getAddress()})
    console.log(data);
  },

  createAuction : async function (signer, nftId, auctionStartPrice, auctionExpiryTime) {
    const marketContract = new ethers.Contract(nftmarketaddress, MarketAbi, signer)
    //const tokenContract = new ethers.Contract(nftaddress, NFTAbi, provider)
    const data = await marketContract.setNftForAuction(nftId, auctionStartPrice, auctionExpiryTime, {from : signer.getAddress()})
    console.log(data);
  }

  // getMyNfts - Loop on getByTokenID
  // NFTHistory - Not storing history
  // AuctionBids - Not storing all bids, only highest
}

  return (
    <WalletContext.Provider value={[wallet, getProvider, marketplace]}>
      {children}
    </WalletContext.Provider>
  )
}