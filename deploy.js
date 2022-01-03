const readline = require('readline').createInterface({
    input: process.stdin,
    output: process.stdout
})

const available_command = {
    'deploy:mumbai':'You are deploying contract to MATIC Mumbai TESTNet, \nHave you checked and confirmed all values in .env file? (y/n)',
    'deploy:mainnet':'Attention: You are deploying contract to MATIC MainNET, Have you checked and confirmed all values in .env file? (y/n)'
}

if(
    process.argv && 
    process.argv[2] && 
    Object.keys(available_command).indexOf(process.argv[2]) != -1
    ){

        readline.question(available_command[process.argv[2]], inp => {
            if(inp == "y"){
                console.log('Deploying Now...')
            }else{
                console.log('It seems you have not completed.')
                process.exit(1)
            }
            readline.close()
        })
        
}

