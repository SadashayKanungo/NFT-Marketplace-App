import {useState, useEffect} from 'react';
import './App.css';

import { getProvider, marketplace } from './wallet.context'

function App() {

  let [provider, setProvider] = useState()
  let [signer, setSigner] = useState()

  useEffect(() => {
    console.log("Wallet:", provider, signer)
    async function fetchProvider(){
        let p = provider
        if(!p){
          const pro = await getProvider();
          const sig = pro.getSigner();
          setProvider(pro);
          setSigner(sig);
        }
    }
    fetchProvider();
}, [])

const testFetchMyNfts = async () => {
  const nfts = await marketplace.loadMyNFTs(signer)
  console.log(nfts)
}

const testFetchAllNfts = async () => {
  const nfts = await marketplace.loadAllNFTs(provider)
  console.log(nfts)
}

const testMintNFT = async () => {
  const response = await marketplace.mintNFT(signer, "thisistesttokenuri", "thisistestmetadatauri", 5)
  console.log(response)
}

const testNFTSale = async () => {
  const response = await marketplace.createSale(signer, 4, 1)
  console.log(response)
}

const testNFTAuction = async () => {
  const response = await marketplace.createAuction(signer, 5, 1, 300)
  console.log(response)
}

const testNFTHistory = async () => {
  const response = await marketplace.loadHistory(provider, 1,)
  console.log(response)
}

  return (
    <div className="App">
      <header className="App-header">
        <h1> MARKET APP TESTING </h1>
        <button onClick={testFetchMyNfts}> Fetch My NFTs</button><br></br>
        <button onClick={testFetchAllNfts}> Fetch All NFTs</button><br></br>
        <button onClick={testMintNFT}> Mint New NFT</button><br></br>
        <button onClick={testNFTSale}> Set NFT to Sale</button><br></br>
        <button onClick={testNFTAuction}> Set NFT to Auction</button><br></br>
        <button onClick={testNFTHistory}> Load NFT Ownership History</button><br></br>
      </header>
    </div>
  );
}

export default App;
