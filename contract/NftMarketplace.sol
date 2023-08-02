//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NftMarketplace is ReentrancyGuard{

    struct Listing {
        uint256 price;
        address seller;
    }
    // mappings
    mapping(address => mapping(uint256 => Listing)) private s_listings;
    mapping(address => uint256) private s_proceeds;

    // functions
    // 1. List NFT
    // 2. Buy Nft
    // 3. Update Nft
    // 4. withdraw proceeds 
    // 5. Cancnel listing

    // Define own errors
    error AlreadyListed(address nftAddress,uint256 tokenId);
    error PriceMustBeAboveZero();
    error NotApprovedForMarketPlace();
    error NotListed(address nftAddress,uint256 tokenId);
    error PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
    error NoProceeds();

    // events
    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        address indexed tokenId,
        uint256 price
    );

    event ItemCanceled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );


    // modiefiers
    modifier isOwner(address nftAddress, uint256 tokenId, address spender){
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (spender != owner) {
            revert NotOwner(); 
        }
        _;
    }

    modifier notListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_listings[nftAddress][toeknId];
        if (listing.price > 0) {
            revert AlreadyListed(nftAddres, tokenId);
        }
        _;
    }

    modifier isListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.prive < 0 ) {
            revert NotListed(nftAddress, tokenId);
        }
        _;
    }

    function listItem(address nftAddress, uint256 tokenId, uint256 price) external notListed(nftAddress, tokenId) isOwner(nftAddress, tokenId, msg.sender){
        // fist os all, check the price
        if (price < 0) {
            revert PriceMustBeAboveZero();
        }

        // approve token for marketplace
        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId) != address(this)) {
            revert NotApprovedForMarketPlace();
        }
        // update listings
        s_listings[nftAddress][tokenId] = Listing(price, msg.sender);
        // emit event
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }

    function cancelListing(address nftAddress, uint256 tokenId) external isOwner(nftAddress, tokenId, msg.sender) isListed( nftAddress, tokenId) {
        delete(s_listings[nftAddress][tokenId]);
        // emit an event
        emit ItemCancelled(msg.sender, nftAddress, tokenId);
    }

    function buyItem(address nftAddress, uint256 tokenId) external isOwner(nftAddress, tokenId, msg.sender) isListed(nftAddress, tokenId){
        Listing memory listedItem = s_listings[nftAddress][tokenId];
        if (msg.value <= listedItem.price){
            revert PriceNotMet(nftAddress, tokenId, listedItem.price);
        }
        // updating proceeds
        s_proceeds[listedItem.seller] += msg.value;
        // delete the nft from market place
        delete(s_listings[nftAddress][tokenId]);
        // have the user withdraw the proceeds
        IER721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);

        emit ItemBought(msg.sender, nftAddress, tokenId, listeditem.price);

    }

    function updateListing(address nftAddress, uint256 tokenId, uint256 newPrice) external isListed(nftAddress, tokenId) isOwner(nftAddress, tokenId, msg.sender) {
        // check the value of new price and erevert it if it is below zero
        if (newPrice <= 0) {
            revert PriceMustBeAboveZero();
        }
        //otherwise
        //set the price into the new price
        s_listings[nftAddress][tokenId].price = newPrice;
        //after doing all of this, emit an event
        // uing itemlisted() because we are listing the nft again , but with new price
        emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
    }

    function withdrawProceeds() external {
        uint256 proceeds = s_proceeds[msg.sender];
        if (proceeds <= 0) {
            revert NoProceeds();
        }
        s_proceeds[msg.sender] = 0;
        (bool, success, ) = payable(msg.sender).call{value: proceeds}("");
        require(success, "Transfer failed");
    }

    // Getter functions
    function getListing(address nftAddress, uint256 tokenId) external view returns (Listing memory) {
        return s_listings[nftAddress][tokenId];
    }

    function getProceeds(address seller) external view returns (uint256){
        return s_proceeds[seller];
    }

}