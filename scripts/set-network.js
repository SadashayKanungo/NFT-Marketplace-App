const fs = require("fs")
const envFile = `${__dirname}/../.env`

function replaceBlockChainNetworkRPC(rpc_address){
    const rpcRegex = /BLOCKCHAIN_NETWORK_RPC=\*+/gm
    const existingEnvData = fs.readFileSync(envFile,'utf-8')
    const newData = existingEnvData.replace(rpcRegex,`BLOCKCHAIN_NETWORK_RPC=${rpc_address}/`)
    const data = fs.writeFileSync(envFile, newData)
    return true
}

if(process.env.CLIENT_URL && process.env.CLIENT_URL.startsWith("https://")){
    replaceBlockChainNetworkRPC(process.env.CLIENT_URL)
}else{
    console.log("Network not Set")
}