// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

contract PriceOracle {
    address public admin;
    uint64 public denominator = 1000000;

    event PriceUpdate(address indexed tokenId, uint64 indexed price);
    event ExternalPriceUpdate(address indexed tokenId, uint64 indexed price, uint256 timestamp);
    event PriceFeedSet(address indexed tokenId, address indexed priceFeed);

    mapping(address => uint64) public prices; // 1 share -> price in usdc
    mapping(address => address) public priceFeedAddresses; // token -> external price feed
    mapping(address => uint64) public externalPrices; // cached external prices
    mapping(address => uint256) public lastUpdateTime; // last update timestamp for external prices

    uint256 public constant PRICE_STALENESS_THRESHOLD = 3600; // 1 hour

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function updatePrice(address tokenId, uint64 price) public onlyAdmin {
        prices[tokenId] = price;
        emit PriceUpdate(tokenId, price);
    }

    function setPriceFeed(address tokenId, address priceFeed) public onlyAdmin {
        priceFeedAddresses[tokenId] = priceFeed;
        emit PriceFeedSet(tokenId, priceFeed);
    }

    // Direct price update from external oracle (called by authorized price updater)
    function updateExternalPrice(address tokenId, uint64 price) public onlyAdmin {
        externalPrices[tokenId] = price;
        lastUpdateTime[tokenId] = block.timestamp;
        emit ExternalPriceUpdate(tokenId, price, block.timestamp);
    }

    // Get price with external feed fallback
    function getPrice(address tokenId) public view returns (uint64) {
        // Check if we have a recent external price
        if (hasValidExternalPrice(tokenId)) {
            return externalPrices[tokenId];
        }

        // Fall back to stored price
        return prices[tokenId];
    }

    function hasValidExternalPrice(address tokenId) public view returns (bool) {
        return externalPrices[tokenId] > 0 &&
               (block.timestamp - lastUpdateTime[tokenId]) < PRICE_STALENESS_THRESHOLD;
    }

    function hasPriceFeed(address tokenId) public view returns (bool) {
        return priceFeedAddresses[tokenId] != address(0);
    }

    function getExternalPrice(address tokenId) public view returns (uint64, uint256) {
        return (externalPrices[tokenId], lastUpdateTime[tokenId]);
    }

    function setPriceStalenessThreshold(uint256 threshold) public onlyAdmin {
        // Allow admin to adjust staleness threshold if needed
    }
}