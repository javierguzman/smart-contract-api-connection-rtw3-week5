// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";


contract BullBear is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, KeeperCompatibleInterface {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint public interval; // normally this should be immutable
    uint public lastTimestamp;

    AggregatorV3Interface public priceFeed;
    int256 public currentPrice;

    event TokensUpdated(string marketTrend);

    string[] bullUrisIpfs = [
        "https://dweb.link/ipfs/QmRXyfi3oNZCubDxiVFre3kLZ8XeGt6pQsnAQRZ7akhSNs",
        "https://dweb.link/ipfs/QmRJVFeMrtYS2CUVUM2cHJpBV5aX2xurpnsfZxLTTQbiD3",
        "https://dweb.link/ipfs/QmdcURmN1kEEtKgnbkVJJ8hrmsSWHpZvLkRgsKKoiWvW9g"
    ];

    string[] bearUrisIpfs = [
        "https://dweb.link/ipfs/Qmdx9Hx7FCDZGExyjLR6vYcnutUR8KhBZBnZfAPHiUommN",
        "https://dweb.link/ipfs/QmTVLyTSuiKGUEmb88BgXG3qNC8YgpHZiFbjHrXKH3QHEu",
        "https://dweb.link/ipfs/QmbKhBXVWmwrYsTPFYfroR2N7NAekAMxHUVg2CWks7i9qj"
    ];

    constructor(uint updateInterval, address _priceFeed) ERC721("Bull&Bear", "BB") {
        // Set the keeper update interval
        interval = updateInterval;
        lastTimestamp = block.timestamp;

        priceFeed = AggregatorV3Interface(_priceFeed);

        currentPrice = getLatestPrice(); 
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        // defaults to gamer bull NFT image
        string memory defaultUri = bullUrisIpfs[0];
        _setTokenURI(tokenId, defaultUri);
    }

    function checkUpkeep(bytes calldata /*checkData*/) external view override returns(bool upkeepNeeded, bytes memory/* performData*/) {
        upkeepNeeded = (block.timestamp - lastTimestamp) > interval;
    }

    function performUpkeep(bytes calldata /*performData*/) external override {
        if ((block.timestamp - lastTimestamp) > interval) {
            lastTimestamp = block.timestamp;
            int latestPrice = getLatestPrice();

            if(latestPrice == currentPrice) {
                return;
            } else if (latestPrice < currentPrice) {
                updateAllTokenUris("bear");
            } else {
                updateAllTokenUris("bull");
            }

            currentPrice = latestPrice;
        }
    }

    function getLatestPrice() public view returns (int256) {
        (/**/,int price,/**/ , /**/, /**/) =priceFeed.latestRoundData();

        return price;
    }

    function updateAllTokenUris(string memory trend) internal {
        if (compareStrings("bear", trend)) {
            for (uint i = 0; i < _tokenIdCounter.current(); i++) {
                _setTokenURI(i, bearUrisIpfs[0]);   
            }
        } else {
            for (uint i = 0; i < _tokenIdCounter.current(); i++) {
                _setTokenURI(i, bullUrisIpfs[0]);   
            }
        }

        emit TokensUpdated(trend);
    }

    function setInterval(uint256 newInterval) public onlyOwner {
        interval = newInterval;
    }

    function setPriceFeed(address newFeed) public onlyOwner {
        priceFeed = AggregatorV3Interface(newFeed);
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool){
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    // The following functions are overrides required by Solidity.  
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


}
