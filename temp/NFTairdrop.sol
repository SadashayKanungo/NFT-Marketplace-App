// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract ProperPanda is ERC721URIStorage, EIP712, Ownable{
    using Counters for Counters.Counter;
    using ECDSA for bytes32;
    using Strings for uint256;


    Counters.Counter private _tokenIds; // tracks the token ids
    event TokenMinted(address owner, uint256 tokenId);

    /// Stores token Meta Data
    struct TokenExtraInfo {
        address minter;
        string metaDataURI;
    }

    ///mapping for token metadata
    mapping(uint256 => TokenExtraInfo) public TokenExtraInfos;
    //mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    //claimed bitmask
    mapping(uint256 => uint256) public nftClaimBitMask;

    //token metadata signer
    address SIGNER = 0xE86cc8E0fd53B912Dac2Ad68986Cee3e3A7B8d02;

    constructor() 
    ERC721("Proper Panda", "PROPER PANDA") 
    EIP712("Proper Panda", "1.0.0"){}

    ///@notice Mints new token with given details
    ///@dev Mints new token if caller has minter role
    ///@param _owner address of token owner
    ///@param _tokenDataURI token data uri
    ///@param _metaDataURI token meta data uri
    function mintItem(
        address _owner,
        string memory _tokenDataURI,
        string memory _metaDataURI
    ) public returns (uint256) {
        _tokenIds.increment();

        TokenExtraInfos[_tokenIds.current()] = TokenExtraInfo({
            minter: _owner,
            metaDataURI: _metaDataURI
        });

        uint256 newItemId = _tokenIds.current();
        _mint(_owner, newItemId);
        _setTokenURI(newItemId, _tokenDataURI);

        emit TokenMinted(_owner, newItemId);
        return newItemId;
    }


    ///@notice gives the original minter of token
    ///@param _tokenId Id of token
    ///@return address of original minter
    function getOriginalMinter(uint256 _tokenId) public view returns (address) {
        return TokenExtraInfos[_tokenId].minter;
    }

    ///@notice gives the metadata uri
    ///@param _tokenId Id of token
    ///@return string of metadata uri
    function getMetaDataURI(uint256 _tokenId) public view returns (string memory) {
        return TokenExtraInfos[_tokenId].metaDataURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    ///@notice user can claim the NFT 
    ///@param _account account to be minted 
    ///@param _nftIndex     nft index 
    ///@param _tokenDataURI token data uri uri for token
    ///@param _metaDataURI meta data uri for token 
    ///@param _signature   signature provided by the conta
   	function claimNFT(
        address _account, 
        uint256 _nftIndex,
        string memory _tokenDataURI, 
        string memory _metaDataURI, 
        bytes calldata _signature
    ) external {
        require(!isClaimed(_nftIndex), "NFT: Token already claimed!");

        require(_verify(_hash(_account, _nftIndex, _tokenDataURI, _metaDataURI), _signature), "NFT: Invalid Claiming!");
        _setClaimed(_nftIndex);
        _tokenIds.increment();
        TokenExtraInfos[_tokenIds.current()] = TokenExtraInfo({
            minter: _account,
            metaDataURI: _metaDataURI
        });

        uint256 newItemId = _tokenIds.current();
        _mint(_account, newItemId);
        _setTokenURI(newItemId, _tokenDataURI);

        emit TokenMinted(_account, newItemId);
	}

    //hash the data
    function _hash(address _account, uint256 _nftIndex, string memory _tokenDataURI, string memory _metaDataURI)
    internal view returns (bytes32)
    {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("NFT(address _account,uint256 _nftIndex,string _tokenDataURI,string _metaDataURI)"),
            _account,
            _nftIndex,
            _tokenDataURI,
            _metaDataURI
        )));
    }

    //verify with signature
    function _verify(bytes32 digest, bytes memory signature)
    internal view returns (bool)
    {
        return SignatureChecker.isValidSignatureNow(SIGNER, digest, signature);
    }

    function isClaimed(uint256 _nftIndex) public view returns (bool) {
        uint256 wordIndex = _nftIndex / 256;
        uint256 bitIndex = _nftIndex % 256;
        uint256 mask = 1 << bitIndex;
        return nftClaimBitMask[wordIndex] & mask == mask;
	  }

    function _setClaimed(uint256 _nftIndex) internal{
        uint256 wordIndex = _nftIndex / 256;
        uint256 bitIndex = _nftIndex % 256;
        uint256 mask = 1 << bitIndex;
        nftClaimBitMask[wordIndex] |= mask;
	  }

   
}