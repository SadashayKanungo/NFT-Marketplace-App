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
  const nfts = await marketplace.loadMyNFTs(provider)
  console.log(nfts)
}

const testFetchAllNfts = async () => {
  const nfts = await marketplace.loadAllNFTs(provider)
  console.log(nfts)
}


  return (
    <div className="App">
      <header className="App-header">
        <h1> MARKET APP TESTING </h1>
        <button onClick={testFetchMyNfts}> Fetch My NFTs</button><br></br>
        <button onClick={testFetchAllNfts}> Fetch All NFTs</button><br></br>
        <button> Set NFT to Sale</button><br></br>
        <button> Set NFT to Auction</button><br></br>
      </header>
    </div>
  );
}

export default App;
