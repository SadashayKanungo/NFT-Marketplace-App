const { ethers } = require('ethers');

signData = async () => {
  const provider = new ethers.providers.JsonRpcProvider(
    'http://127.0.0.1:8545'
  );

  const signer = new ethers.Wallet(
    '0xdf57089febbacf7ba0bc227dafbffa9fc08a93fdc68e1e42411a14efcf23656e',
    provider
  );

  console.log('Signer is ', signer);
  const signature = await signer._signTypedData(
    //Domain
    {
      name: 'NFT',
      version: '1.0.0',
      chainId: 1337,
      verifyingContract: '0x73511669fd4dE447feD18BB79bAFeAC93aB7F31f',
    },
    //Types
    {
      NFT: [
        { name: '_account', type: 'address' },
        { name: '_nftIndex', type: 'uint256' },
        // { name: '_tokenDataURI', type: 'string' },
        // { name: '_metaDataURI', type: 'string' },
      ],
    },
    // Value
    {
      _account: '0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199',
      _nftIndex: '1',
      // _tokenDataURI: 'yourtokendatauri',
      // _metaDataURI: 'yourmetadatauri',
    }
  );
  console.log('Signature is ', signature);
};

signData();
