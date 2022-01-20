// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NFT is ERC721URIStorage, EIP712, Ownable{
    using Counters for Counters.Counter;
    using ECDSA for bytes32;
    using Strings for uint256;

    Counters.Counter private _tokenIds; // tracks the token ids
    event TokenMinted(address owner, uint256 tokenId);

    // Stores Ownership history Data
    struct HistoryItem{
        address owner;
        uint256 value;
    }

    /// Stores token Meta Data
    struct TokenExtraInfo {
        address minter;
        string metaDataURI;
        uint256 royaltyPercentage;
    }

    /// mapping for token metadata
    mapping(uint256 => TokenExtraInfo) public TokenExtraInfos;
    //  mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    // mapping for Ownership history
    mapping(uint256 => HistoryItem[]) public TokenHistory;
    // mapping for NFT balance
    mapping(address => uint256[]) public TokenBalance;
    //claimed bitmask
    mapping(uint256 => uint256) public nftClaimBitMask;

    //token metadata signer
    //address SIGNER = address(0xE86cc8E0fd53B912Dac2Ad68986Cee3e3A7B8d02);
    address SIGNER = address(0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199);


    constructor() ERC721("GameItem", "ITM")
        EIP712("NFT", "1.0.0"){}

    ///@notice Mints new token with given details
    ///@dev Mints new token if caller has minter role
    ///@param _owner address of token owner
    ///@param _tokenDataURI token data uri
    ///@param _metaDataURI token meta data uri
    ///@param _royaltyPercentage percentage of royalty specified by the original minter
    function mintItem(
        address _owner,
        string memory _tokenDataURI,
        string memory _metaDataURI,
        uint256 _royaltyPercentage
    ) public returns (uint256) {
        require(
            _royaltyPercentage >= 0 && _royaltyPercentage <= 10,
            "Royalty Percentage out of limits. Must be integer between 0 and 10"
        );

        _tokenIds.increment();

        TokenExtraInfos[_tokenIds.current()] = TokenExtraInfo({
            minter: _owner,
            metaDataURI: _metaDataURI,
            royaltyPercentage: _royaltyPercentage
        });

        uint256 newItemId = _tokenIds.current();
        _mint(_owner, newItemId);
        _setTokenURI(newItemId, _tokenDataURI);
        
        _tokenURIs[newItemId] = _tokenDataURI;
        TokenBalance[_owner].push(newItemId);

        emit TokenMinted(_owner, newItemId);
        return newItemId;
    }


    function addOwner( uint256 _tokenId, address _from, address _to, uint256 _value) public returns (HistoryItem[] memory) {
        uint256[] storage fromBal = TokenBalance[_from];
        for(uint256 index = 0; index<fromBal.length; index++){
            if(fromBal[index] == _tokenId){
                fromBal[index] = fromBal[fromBal.length-1];
                fromBal.pop();
            }
        }
        TokenBalance[_from] = fromBal;
        TokenBalance[_to].push(_tokenId);
        
        HistoryItem memory newOwner = HistoryItem({
            owner: _to, 
            value: _value
        });
        TokenHistory[_tokenId].push(newOwner);
        return TokenHistory[_tokenId];
    }

    function HistoryNos(uint256 _tokenId) public view returns (uint256) {
        return TokenHistory[_tokenId].length;
    } 
    function getHistory(uint256 _tokenId) public view returns (HistoryItem[] memory) {
        return TokenHistory[_tokenId];
    }
    // Overloading previous function to use pagination
    // One page has maximum of 10 items. Page numbers start form 0.
    function getHistory(uint256 _tokenId, uint256 _pageIndex) public view returns (HistoryItem[] memory) {
        HistoryItem[] storage history = TokenHistory[_tokenId];
        uint256 start = _pageIndex*10;
        require(start <= history.length, "Page Index out of range");

        uint256 length = history.length-start < 10 ? history.length-start : 10;
        HistoryItem[] memory historyPage = new HistoryItem[](length);
        for(uint256 i=0; i<length; i++){
            historyPage[i] = history[start+i];
        }
        return historyPage;
    }

    ///@notice gives the original minter of token
    ///@param _tokenId Id of token
    ///@return address of original minter
    function getOriginalMinter(uint256 _tokenId) public view returns (address) {
        return TokenExtraInfos[_tokenId].minter;
    }

    ///@notice gives the Royalty Percentage of token
    ///@param _tokenId Id of token
    ///@return integer value of royalty percentage
    function getRoyaltyPercentage(uint256 _tokenId) public view returns (uint256) {
        return TokenExtraInfos[_tokenId].royaltyPercentage;
    }

    ///@notice gives the metadata uri
    ///@param _tokenId Id of token
    ///@return string of metadata uri
    function getMetaDataURI(uint256 _tokenId) public view returns (string memory) {
        return TokenExtraInfos[_tokenId].metaDataURI;
    }

    function getMyNfts() public view returns(string[] memory){
        uint256[] storage ids = TokenBalance[msg.sender];
        string[] memory uris = new string[](ids.length);
        for(uint256 i=0; i<ids.length; i++){
            uris[i] = _tokenURIs[ids[i]];
        }
        return uris;
    }
    // Overloading previous function to use pagination
    // One page has maximum of 10 items. Page numbers start form 0. 
    function getMyNfts(uint256 _pageIndex) public view returns(string[] memory){
        uint256[] storage ids = TokenBalance[msg.sender];
        uint256 start = _pageIndex*10;
        require(start <= ids.length, "Page Index out of range");

        uint256 length = ids.length-start < 10 ? ids.length-start : 10;
        string[] memory uris = new string[](length);
        for(uint256 i=0; i<length; i++){
            uris[i] = _tokenURIs[ids[start+i]];
        }
        return uris;
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

        require(_verify(_hash(_account, _nftIndex), _signature), "NFT: Invalid Claiming!");
        _setClaimed(_nftIndex);
        _tokenIds.increment();
        TokenExtraInfos[_tokenIds.current()] = TokenExtraInfo({
            minter: _account,
            metaDataURI: _metaDataURI,
            royaltyPercentage: 0
        });

        uint256 newItemId = _tokenIds.current();
        _mint(_account, newItemId);
        _setTokenURI(newItemId, _tokenDataURI);

        emit TokenMinted(_account, newItemId);
	}

    //hash the data
    function _hash(address _account, uint256 _nftIndex)
    internal view returns (bytes32)
    {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("NFT(address _account,uint256 _nftIndex)"),
            _account,
            _nftIndex
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