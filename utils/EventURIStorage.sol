// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

abstract contract EventURIStorage is ERC721 {

    string public Name;
    string public Location;
    string public Date;
    string public Description;

    struct DataURI{
        string Image;
        string Used;  
        bool Verify;
    }

    mapping (uint256 => DataURI) _dataURIs;

    constructor(string memory _name, string memory _location, string memory _date, string memory _description){
        Name = _name;
        Location = _location;
        Date = _date;
        Description = _description;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        DataURI memory data = _dataURIs[tokenId];

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "', Name,
                        '","description": "A ticket for your upcomming event", "image": "', data.Image,
                        '","attributes": [ { "trait_type": "Date", "value": ',
                        Date,
                        '}, { "trait_type": "Location", "value": ',
                        Location,
                        '}, { "trait_type": "Used", "value": ',
                        data.Used,
                        "} ]}"
                    )

                )
            )
        );

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function _setTokenURI(uint256 tokenId, string memory _image) internal virtual {
        require(_exists(tokenId), "Token ID does not exist");
        _dataURIs[tokenId].Image = _image;
        _dataURIs[tokenId].Used = "No used";
    }

    function checkInTokenURI(uint256 tokenId, string memory _image) internal virtual {
        require(_exists(tokenId), "Token ID does not exist");
        _dataURIs[tokenId].Image = _image;
        _dataURIs[tokenId].Used = "Used";
        _dataURIs[tokenId].Verify = true;

    }

    function checkDataUri(uint256 _tokenId) internal virtual returns (bool) {
        return _dataURIs[_tokenId].Verify;
        
    }

    
}