// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import { SafeMath } from "./libraries/SafeMath.sol";
import "./utils/EventURIStorage.sol";
import "./utils/EventOwnable.sol";

contract Event is ERC721, EventURIStorage, EventOwnable {

    uint256 public maxSupply;
    string public image;
    uint256 public maxTicketsPerWallet;
    uint256 tokenId;
    uint256 public price;   //Wei

    address payable public tick3t;

    mapping (address => uint256) ticketsPerWallet;
    mapping (address => bool) authorized;

    modifier Authorized()
    {
        require(authorized[msg.sender]);
        _;
    } 
    
    constructor (string memory name, string memory location, string memory date, string memory _image, uint256 _maxSupply, uint256 _price, address owner, string memory description) ERC721("Tick3t", "T3t") EventURIStorage(name, location, date, description) EventOwnable(owner) {
        image = _image;
        tokenId = 1;
        maxSupply = _maxSupply;
        maxTicketsPerWallet = 2;
        price = _price;
        authorized[owner] = true;
        tick3t = payable(msg.sender);
    }

    function safeMint() payable public {
        require(msg.value >= price, "Not enough value sent");
        require(tokenId <= maxSupply, "All tickets have been sold");
        require(ticketsPerWallet[msg.sender] < maxTicketsPerWallet, "You have bougth the maximum of tickets per wallet allowed");

        tick3t.transfer(SafeMath.div(SafeMath.mul(1, msg.value),100));
       
        ticketsPerWallet[msg.sender]++;
        tokenId ++;
        _safeMint(msg.sender, tokenId-1);
        _setTokenURI(tokenId-1, image);
    }

    function checkInTicket(uint256 _tokenId, string memory _image) public Authorized {
        require(!checkDataUri(_tokenId), "Ticket has already checked in" );
        checkInTokenURI(_tokenId, _image);
    }

    function setAuthorized(address adr, bool auth) public onlyOwner {
        authorized[adr] = auth;
    }

    function setImage(string memory _image) public onlyOwner {
        image = _image;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setMaxTicketsPerWallet(uint256 _maxTicketsPerWallet) public onlyOwner {
        maxTicketsPerWallet = _maxTicketsPerWallet;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function totalSupply() public view returns(uint256){
        return tokenId-1;
    }

    function withdraw() public onlyOwner  {

        uint256 amount = address(this).balance;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721, EventURIStorage)
        returns (string memory)
    {
        return super.tokenURI(_tokenId);
    }

    // Function to receive value. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}