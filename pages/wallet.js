import { useContext, useEffect, useState } from 'react'
import { WalletProvider, WalletContext } from '../context/wallet.context'

export default function WalletPage(){

    const [wallet, getWallet, marketplace] = useContext(WalletContext)

    useEffect(()=>{

        (async ()=>{
            await getWallet();
            if(wallet){
                const signer = wallet.getSigner()
                console.log("Signer: ", signer)
                console.log("NFTs: ", await marketplace.loadNFTs(wallet, signer))
            }
            console.log("Wallet: ", wallet) 
            
        })()
       

    },[])

    return (
        <p>
            Hello World
        </p>
    )
}