import { useEffect, useState } from 'react'
import { ethers } from 'ethers'
import { create as ipfsHttpClient } from 'ipfs-http-client'
// import { Notification, toaster } from 'rsuite';
import Web3Modal from 'web3modal'

import {
    nftaddress, 
    nftmarketaddress,
    IPFS_BASE_URL
} from "../config"

import NFT from '../artifacts/contracts/NFT.sol/NFT.json'
import NFTMarket from '../artifacts/contracts/NFTMarket.sol/NFTMarket.json'
import { useRouter } from 'next/router'

const client = ipfsHttpClient(`https://ipfs.infura.io:5001/api/v0`)

export default function CreateItem(){
    const [fileUrl, setFileUrl] = useState("ipfs://")
    const [loading, setLoading] = useState(false)
    const [err, setErr] = useState(null)

    const [formInput, updateFormInput] = useState({
        price:'',
        name: '',
        description:''
    })

    const router = useRouter()

    async function onChange(e){
        const file = e.target.files[0]
        try{

            const added = await client.add(
                file, 
                {
                    process: (prog) => console.log(`received: ${prog}`)
                }
            )
            const url = `${IPFS_BASE_URL}${added.path}`
            setFileUrl(url)

        }catch(e){
            console.error(e)
            setErr(e.message)
        }
    }

    async function createItem(){
        const {name, description, price} = formInput
        if(!name || !description
            || !price 
            // || !fileUrl
        ) return setErr('Name, Description, File and Price are Required!')

        const data = JSON.stringify({
            name, 
            description, 
            // image: fileUrl
        })

        try{
            setLoading(true)
            const added = await client.add(data)
            const url = `${IPFS_BASE_URL}${added.path}`
            console.log("Creating Sale with URL:", url)
            createSale(url)

        }catch(e){
            setLoading(false)
            console.error('Error Creating:', e)
            setErr(e.message)
        }
    } 

    async function createSale(url){
        const web3Modal = new Web3Modal()
        const connection = await web3Modal.connect()
        const provider = new ethers.providers.Web3Provider(connection)
        const signer = provider.getSigner()

        let contract = new ethers.Contract(nftaddress, NFT.abi, signer)

        /** Create Token on the Blockchain Network */
        let txn = await contract.createToken(url)
        let tx = await txn.wait();

        console.log("ETH_TXN:", txn)
        console.log("ETH_TX:", tx)

        try{
            let event = tx.events[0]    
            let value = event.args[2]
            let itemId = value.toNumber()

            const price = ethers.utils.parseUnits(formInput.price, 'ether')
            contract = new ethers.Contract(nftmarketaddress, NFTMarket.abi, signer)
            let listingPrice = await contract.getListingPrice()
            listingPrice = listingPrice.toString()

            /** List the created Asset on our NFT marketplace */
            txn = await contract.createMarketItem(
                nftaddress, itemId, price, {value: listingPrice}
            )

            await txn.wait()
            router.push("/")

        }catch(e){
            setErr('NFT Market OR NFT is not deployed yet')
            console.error(e)
        }
    }


    return(
        <div className="flex justify-center">
            <div className="w-1/2 flex flex-col pb-12">
                <input
                    placeholder="Asset Name"
                    className="mt-2 border rounded p-4"
                    onChange={e => updateFormInput({...formInput, name: e.target.value})} 
                />
                <textarea
                    placeholder="Asset Details"
                    className="mt-2 border rounded p-4"
                    onChange={e => updateFormInput({...formInput, description: e.target.value})} 
                />
                <input
                    placeholder="Asset Price in Matic"
                    className="mt-2 border rounded p-4"
                    onChange={e => updateFormInput({...formInput, price: e.target.value})} 
                />
                <input 
                    type="file"
                    name="Asset"
                    className="my-4"
                    onChange={onChange}
                />
                {
                    fileUrl && (
                        <img className="rounded mt-4" width="350" src={fileUrl} />
                    )
                }
                {!loading ? (
                    <button
                        className="font-bold mt-4 bg-pink-500 text-white rounded p-4 shadow-lg"
                        onClick={createItem}
                    >
                        Create Digital Asset
                    </button>) : (
                        <button
                            className="font-bold mt-4 bg-pink-500 text-white rounded p-4 shadow-lg"
                            onClick={createItem}
                        >
                            Create Digital Asset
                        </button>
                        // <button
                        //     className="font-bold mt-4 bg-pink-500 text-white rounded p-4 shadow-lg"
                        // >
                        //     Please Wait
                        // </button>
                    )
                }
                {err && (
                    <div>{err}</div>
                )}
                

            </div>
        </div>
    )

}