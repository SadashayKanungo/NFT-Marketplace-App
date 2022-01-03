// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds; // tracks the token ids
    event TokenMinted(address owner, uint256 tokenId);

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


    constructor() ERC721("GameItem", "ITM") {}

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

        emit TokenMinted(_owner, newItemId);
        return newItemId;
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

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}