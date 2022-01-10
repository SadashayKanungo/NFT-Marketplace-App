// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.3;

import "./NFT.sol";
import "./TOKENX.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title MarketPlace Contract that regulates NFT contract/token
/// @notice This Contract is used to set NFT tokens to Aution and Sale
/// @dev Uses safeMath library for all calulations and holds crypto/tokens uring auction
contract NFTMarket is Ownable {
    using SafeMath for uint256;

    event SaleCreated(uint256 indexed tokenId, uint256 sellingPrice);
    event AuctionCreated(uint256 indexed tokenId, uint256 startingPrice);
    event BidCreated(
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 bidAmount
    );
    event AuctionCancelled(uint256 indexed tokenId);
    event SellCancelled(uint256 indexed tokenId);

    NFT nftContract; //contract address for NFT
    address payable public marketPlaceOwner; //address of marketPlace owner, gets commissions on each sales
    uint256 public minimunBidPer10000; // minimum bid amount to be set

    //Token Contract 
    TOKENX tradeToken;

    //Auction details
    struct Auction {
        uint256 tokenId;
        string tokenUri;
        address seller;
        uint256 startingPrice;
        uint256 expiresAt; //auction expiry date.
        uint256 currentBidPrice; //Current max bidding price
        address currentBidder; //Current max bidder
        uint256[] bidPrices; //Array of all bid prices in sequence
        address[] bidders; //Array of all bidders in sequence
        bool onAuction;
        //bool royaltySupport; //royalty support 
    }


    //Sale Details
    struct Sale {
        uint256 tokenId;
        string tokenUri;
        address seller;
        uint256 sellingPrice;
        bool onSale;
        //bool royaltySupport; //royalty support 
    }

    mapping(uint256 => Sale) public TokenSales; //tokenIdToSell
    mapping(uint256 => Auction) public TokenAuctions; // tokenIdToAuction
    Sale[] public saleItems; //Sales token for sales
    Auction[] public auctionItems; //Auction token for sales

    ///@param _nftContract Contract Address of NFT
    ///@dev sets deployer as marketplace owner and init minimum bid percent to 2.5%
    constructor(address _nftContract, address _token) {
        nftContract = NFT(_nftContract); //nftContract could be deployed from here
        tradeToken = TOKENX(payable(_token));
        marketPlaceOwner = payable (msg.sender);
        minimunBidPer10000 = 250; // 2.5% minimunBid at initial
    }

    ///@notice check if caller is tokenOwner of given tokenID
    ///@param _tokenId tokenId of NFT
    modifier IsTokenOwner(uint256 _tokenId) {
        require(
            nftContract.ownerOf(_tokenId) == msg.sender,
            "MarketPlace: Caller is not the owner of this token"
        );
        _;
    }


    ///@dev checks if amount is greater that 10000
    modifier checkPrice(uint256 _amount) {
        require(
            _amount > 10000,
            "MarketPlace: Amount should be minimum 10000 wei"
        );
        _;
    }

    ///@dev sets given account as marketplace owner
    ///@param _account address of marketplace owner to  be set
    function setMarketPlaceOwner(address _account) public onlyOwner{
        marketPlaceOwner = payable(_account);
    }


    ///@notice set NFT to sale
    ///@dev allows token owner to palce their token to sale
    ///@param _tokenId TokenId of NFT
    ///@param _sellingPrice selling price of token
    /// _royaltySupport royalty support 
    function setNftToSell(uint256 _tokenId, uint256 _sellingPrice /*, bool _royaltySupport*/)
        public
        IsTokenOwner(_tokenId)
        checkPrice(_sellingPrice)
    {
        require(
            nftContract.isApprovedForAll(msg.sender, address(this)),
            "MarketPlace: Minter need to approve marketplace as its token operator"
        );
        require(
            TokenSales[_tokenId].onSale == false,
            "MarketPlace: Token already on Sale"
        );
        require(
            TokenAuctions[_tokenId].onAuction == false,
            "MarketPlace: Token already set for Auction"
        );
        require(
            nftContract.isApprovedForAll(msg.sender, address(this)),
            "MarketPlace: Minter need to approve marketplace as its token operator"
        );

        string memory _tokenUri = nftContract.tokenURI(_tokenId);

        //set nft id for sale
        saleItems.push( Sale({
            tokenId: _tokenId,
            tokenUri: _tokenUri,
            seller: msg.sender,
            sellingPrice: _sellingPrice,
            onSale: true 
            //royaltySupport: _royaltySupport
        }));

        TokenSales[_tokenId] = Sale({
            tokenId: _tokenId,
            tokenUri: _tokenUri,
            seller: msg.sender,
            sellingPrice: _sellingPrice,
            onSale: true 
            //royaltySupport: _royaltySupport
        });

        emit SaleCreated(_tokenId, _sellingPrice);
    }

    ///@notice Set NFT for Auction
    ///@dev allows token owner to place their token to Auction
    ///@param _tokenId TokenId of NFT
    ///@param _startingPrice starting price of token
    ///@param _expiresIn Expiry timestamp of auction
    /// _royaltySupport royalty support for Auction
    function setNftToAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _expiresIn
        //bool _royaltySupport
    ) public IsTokenOwner(_tokenId) checkPrice(_startingPrice) {
        uint256 _expiresAt = block.timestamp + _expiresIn;
        require(
            nftContract.isApprovedForAll(msg.sender, address(this)),
            "MarketPlace: Minter need to approve marketplace as its token operator"
        );
        require(
            _expiresAt > block.timestamp,
            "MarketPlace: Invalid token Expiry date"
        );

        require(
            TokenSales[_tokenId].onSale == false,
            "MarketPlace: Token already set for Sale"
        );
        require(
            TokenAuctions[_tokenId].onAuction == false,
            "MarketPlace: Token already on Auction"
        );
        require(
            nftContract.isApprovedForAll(msg.sender, address(this)),
            "MarketPlace: Minter need to approve marketplace as its token operator"
        );

        string memory _tokenUri = nftContract.tokenURI(_tokenId);

        
        //set nft to auction
        auctionItems.push( Auction({
            tokenId: _tokenId,
            tokenUri: _tokenUri,
            seller: msg.sender,
            startingPrice: _startingPrice,
            expiresAt: _expiresAt,
            currentBidPrice: 0,
            currentBidder: address(0),
            bidPrices: new uint256[](0),
            bidders: new address[](0),
            onAuction: true
            //royaltySupport: _royaltySupport
        }));

        TokenAuctions[_tokenId] = Auction({
            tokenId: _tokenId,
            tokenUri: _tokenUri,
            seller: msg.sender,
            startingPrice: _startingPrice,
            expiresAt: _expiresAt,
            currentBidPrice: 0,
            currentBidder: address(0),
            bidPrices: new uint256[](0),
            bidders: new address[](0),
            onAuction: true
            //royaltySupport: _royaltySupport
        });

        emit AuctionCreated(_tokenId, _startingPrice);
    }

    ///@notice bid an amount to given tokenId
    ///@dev holds bid amount of the bidder and set it as current bidder if bid amount is higher than previous bidder
    ///@param _tokenId TokenId of NFT
    ///@param _tokenAmount Total token to auction for
    function bidForAuction(uint256 _tokenId, uint256 _tokenAmount) public {
        Auction storage act = TokenAuctions[_tokenId];
        require(
            act.onAuction == true && act.expiresAt > block.timestamp,
            "MarketPlace: Token expired from auction"
        );

        require(
            _tokenAmount >= act.startingPrice,
            "MarketPlace: Bid amount is lower than startingPrice"
        );
        if (act.currentBidPrice != 0) {
            require(
                _tokenAmount >=
                    (act.currentBidPrice +
                        cutPer10000(minimunBidPer10000, act.currentBidPrice)),
                "MarketPlace: Bid Amount is less than minimunBid required"
            );
        }

        address currentBidder = act.currentBidder;
        uint256 prevBidPrice = act.currentBidPrice;
        act.currentBidPrice = 0;
        //add the current bid amount 
        tradeToken.transferFrom(msg.sender, address(this), _tokenAmount);
        //return the previous tokens to the bidder

        if(currentBidder != address(0))
            tradeToken.transfer(currentBidder, prevBidPrice);
            
        //update
        act.currentBidPrice = _tokenAmount;
        act.currentBidder = msg.sender;

        // act.bidPrices.push(_tokenAmount);
        // act.bidders.push(msg.sender);

        for(uint256 i=0; i<auctionItems.length; i++){
            if(auctionItems[i].tokenId == _tokenId){
                auctionItems[i].currentBidPrice = _tokenAmount;
                auctionItems[i].currentBidder = msg.sender;
                auctionItems[i].bidPrices.push(_tokenAmount);
                auctionItems[i].bidders.push(msg.sender);
                break;
            }
            continue;
        }

        emit BidCreated(_tokenId, msg.sender, _tokenAmount);
    }

    ///@notice cancel ongoing auction
    ///@dev stops the ongoing auction and if bidder exists refund the bidders amount
    ///@param _tokenId TokenId of NFT
    function cancelAuction(uint256 _tokenId)
        public
        IsTokenOwner(_tokenId)
    {
        Auction storage act = TokenAuctions[_tokenId];

        act.onAuction = false;
        if (act.currentBidder != address(0)) {
            address currentBidder = act.currentBidder;
            uint256 bidPrice = act.currentBidPrice;
            act.currentBidPrice = 0;

            tradeToken.transfer(currentBidder, bidPrice);
        }

        //remove the item from the auction
        removeNftIdFromAuction(_tokenId);

        emit AuctionCancelled(_tokenId);
    }

    ///@notice cancel ongoing sale
    ///@dev stops the ongoing sale
    ///@param _tokenId TokenId of NFT
    function cancelSell(uint256 _tokenId) public IsTokenOwner(_tokenId) {
        Sale storage sale = TokenSales[_tokenId];

        sale.onSale = false;
        sale.sellingPrice = 0;

        //remove the item from sale
        removeNftIdFromSale(_tokenId);

        emit SellCancelled(_tokenId);
    }

    ///@notice claim the NFT once the bidder wins an auction
    ///@dev tranfer nft token to highest bidder and divide the commission to token minter and marketplace owner
    ///@param _tokenId TokenId of NFT
    function claimNft(uint256 _tokenId) public {
        Auction storage act = TokenAuctions[_tokenId];
        require(
            msg.sender == act.currentBidder,
            "MarketPlace: Caller is not a highest bidder"
        );
        require(
            act.expiresAt < block.timestamp,
            "MarketPlace: Token still on auction"
        );

        address  tokenOwner = act.seller;
        address  minter = nftContract.getOriginalMinter(_tokenId);
        uint256 royaltyPercentage = nftContract.getRoyaltyPercentage(_tokenId);

        act.onAuction = false;
        (
            uint256 _minterCommision,
            uint256 _marketPlaceCommission,
            uint256 _remainings
        ) = calculateCommissions(act.currentBidPrice, royaltyPercentage); // calculate commissions
        //transfer commissions
        
        nftContract.transferFrom(tokenOwner, msg.sender, _tokenId);

        // adding new owner to nft's history
        nftContract.addOwner(_tokenId, msg.sender, act.currentBidPrice);

        act.currentBidPrice = 0;
        //transfer marketplace commision 
        tradeToken.transfer(marketPlaceOwner, _marketPlaceCommission);
        //transfer remainings to token owner
        tradeToken.transfer(tokenOwner, _remainings);
        if(_minterCommision > 0){
            //transfer minter comission
            tradeToken.transfer(minter, _minterCommision);
        }

        // if(act.royaltySupport){
        //     //transfer minter comission
        //     tradeToken.transfer(minter, _minterCommision);
        // }else{
        //     //transfer minter commision to token owner
        //     tradeToken.transfer(tokenOwner, _minterCommision);
        // }

        //remove the item from auction
        removeNftIdFromAuction(_tokenId);
    }

    ///@notice buy the nft placed on sale
    ///@dev tranfer nft token to buyer and divide the commission to token minter and marketplace owner
    ///@param _tokenId TokenId of NFT
    ///@param _tokenAmount Token Amount with which you buy nft
    function buyNft(uint256 _tokenId, uint256 _tokenAmount) public {
        Sale storage sale = TokenSales[_tokenId];
        require(sale.onSale, "MarketPlace: Token is not on Sale");
        require(
            _tokenAmount == sale.sellingPrice,
            "MarketPlace: Not Enough value to buy token"
        );
        
        address  tokenOwner = nftContract.ownerOf(_tokenId);
        address minter = nftContract.getOriginalMinter(_tokenId);
        uint256 royaltyPercentage = nftContract.getRoyaltyPercentage(_tokenId);

        sale.onSale = false;
        (
            uint256 _minterCommision,
            uint256 _marketPlaceCommission,
            uint256 _remainings
        ) = calculateCommissions(sale.sellingPrice, royaltyPercentage); // calculate commissions
        
        nftContract.transferFrom(tokenOwner, msg.sender, _tokenId);

        // adding new owner to nft's history
        nftContract.addOwner(_tokenId, msg.sender, sale.sellingPrice);
        
        sale.sellingPrice = 0;
        //transfer marketplace owner commissions
        tradeToken.transferFrom(msg.sender, marketPlaceOwner, _marketPlaceCommission);
        //transfer remainings to token owner
        tradeToken.transferFrom(msg.sender, tokenOwner, _remainings);
        if(_minterCommision > 0){
            //transfer minterCommision to minter
            tradeToken.transferFrom(msg.sender, minter, _minterCommision);
        }
        
        
        // if(sale.royaltySupport){
        //     //transfer minter commission
        //     tradeToken.transferFrom(msg.sender, minter, _minterCommision);
        // }else{
        //     //transfer the commision to token seller
        //     tradeToken.transferFrom(msg.sender, tokenOwner, _minterCommision);
        // }

        //remove item from sale
        removeNftIdFromSale(_tokenId);
    }

    ///@notice change the minimum bid percent
    ///@param _minBidPer10000 minimun bid amount per 10000
    function setMinimumBidPercent(uint256 _minBidPer10000) public onlyOwner {
        require(
            _minBidPer10000 < 10000,
            "MarketPlace: minimun Bid cannot be more that 100%"
        );
        minimunBidPer10000 = _minBidPer10000;
    }

    function removeNftIdFromSale(uint256 _tokenId) internal{
        for(uint256 i=0; i<saleItems.length; i++){
            if(saleItems[i].tokenId ==_tokenId){
                saleItems[i] = saleItems[saleItems.length-1];
                saleItems.pop();
                return;
            }
            
        }
    }

    function removeNftIdFromAuction(uint256 _tokenId) internal{
        for(uint256 i=0; i<auctionItems.length; i++){
            if(auctionItems[i].tokenId ==_tokenId){
                auctionItems[i] = auctionItems[auctionItems.length-1];
                auctionItems.pop();
                return;
            }
        }
    }

    ///@notice calculates the required commissions
    ///@dev deducts the minter and marketplace commission and returns the result
    ///@param _amount total amount from which commission is to be deducted
    ///@return _minterCommision commision given to minter
    ///@return _marketPlaceCommission commission given to marketplace owner
    ///@return _remainings after deducting commission
    function calculateCommissions(uint256 _amount, uint256 _royaltyPercentage)
        internal
        pure
        returns (
            uint256 _minterCommision,
            uint256 _marketPlaceCommission,
            uint256 _remainings
        )
    {
        uint256 minterCommision = cutPer10000(_royaltyPercentage * 100, _amount); //10% of total
        uint256 marketPlaceCommission = cutPer10000(250, _amount); //2.5% of total
        return (
            minterCommision,
            marketPlaceCommission,
            _amount.sub(minterCommision).sub(marketPlaceCommission)
        );
    }

    ///@notice calculate percent amount for given percent and total
    ///@dev calculates the cut per 10000 fo the given total
    ///@param _cut cut to be caculated per 10000, i.e percentAmount * 100
    ///@param _total total amount from which cut is to be calculated
    function cutPer10000(uint256 _cut, uint256 _total)
        internal
        pure
        returns (uint256)
    {
        uint256 cutAmount = _total.mul(_cut).div(10000);
        return cutAmount;
    }

    //fetchers
    // sales
    function fetchSalesItems() public view returns (Sale[] memory){
        return saleItems;
    }

    function fetchMySalesItems() public view returns (Sale[] memory){
        uint256 myNos = 0;
        for(uint256 i=0;i<saleItems.length;i++){
            Sale memory sale = saleItems[i];
            if(sale.seller == msg.sender){
                myNos++;
            }
        }

        Sale[] memory sales = new Sale[](myNos);
        for(uint256 i=0;i<saleItems.length;i++){
            Sale memory sale = saleItems[i];
            if(sale.seller == msg.sender){
                myNos--;
                sales[myNos] = sale;
            }
        }
        return sales;
    }


    //auctions
    function fetchAuctionsItems() public view returns(Auction[] memory){
        return auctionItems;
    }

    function fetchMyAuctionsItems() public view returns(Auction[]  memory){
        uint256 myNos = 0;
        for(uint256 i=0;i<auctionItems.length;i++){
            Auction memory auction = auctionItems[i];
            if(auction.seller == msg.sender){
                myNos++;
            }
        }
        
        Auction[] memory auctions = new Auction[](myNos);
        for(uint256 i=0;i<auctionItems.length;i++){
            Auction memory auction = auctionItems[i];
            if(auction.seller == msg.sender){
                myNos--;
                auctions[myNos] = auction;
            }
        }
        return auctions;
    }
}