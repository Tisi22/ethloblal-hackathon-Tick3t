// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Event.sol";

contract Tick3t is Ownable{

    
    struct EventBalances {
    bool deployed;
    uint totalSales; // This is in wei
    }

    // We keep track of deployed events to ensure that callers are all deployed events.
    mapping(address => address[]) public eventsPerAddress;



    event NewEvent(address indexed eventOwner, address indexed newEventAddress);

    constructor(){
    }

    function createEvent(string memory name, string memory location, string memory date, string memory _ima, uint256 _maxSupp, uint256 _pri, string memory _description) public returns (address) {

        Event createEvent = new Event(name, location, date, _ima, _maxSupp, _pri, msg.sender, _description);
        address newEvent = address(createEvent);

        eventsPerAddress[msg.sender].push(newEvent);

        // trigger event
        emit NewEvent(msg.sender, newEvent);
        return newEvent;
    }

    function withdraw() public onlyOwner  {

        uint256 amount = address(this).balance;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function getEventsPerAddress(address adr) public view returns (address[] memory){
        return eventsPerAddress[adr];
    }

    // Function to receive value. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}