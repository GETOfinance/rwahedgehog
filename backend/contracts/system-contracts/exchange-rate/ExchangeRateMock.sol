// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.0 <0.9.0;

import "./SelfFunding.sol";
// Direct implementation without external interfaces

contract ExchangeRateMock is SelfFunding {

    event TinyBars(uint256 tinybars);
    event TinyCents(uint256 tinycents);
    event ExchangeRateUpdated(uint256 newRate, address updater);
    event ExternalRateRequested(uint256 requestId);

    // Exchange rate from external source (scaled by 1e6)
    uint256 public externalExchangeRate;
    uint256 public lastUpdateTime;
    uint256 private requestCounter;

    // Authorized rate updaters
    mapping(address => bool) public authorizedUpdaters;
    address public admin;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    modifier onlyAuthorizedUpdater() {
        require(authorizedUpdaters[msg.sender] || msg.sender == admin, "Not authorized");
        _;
    }

    constructor() {
        admin = msg.sender;
        lastUpdateTime = block.timestamp;
        requestCounter = 1;
        // Set initial rate (example: $0.05 per HBAR)
        externalExchangeRate = 50000; // 0.05 * 1e6
    }

    function addAuthorizedUpdater(address updater) external onlyAdmin {
        authorizedUpdaters[updater] = true;
    }

    function removeAuthorizedUpdater(address updater) external onlyAdmin {
        authorizedUpdaters[updater] = false;
    }

    function requestExchangeRateUpdate() external onlyAuthorizedUpdater {
        uint256 requestId = requestCounter++;
        emit ExternalRateRequested(requestId);
        // In a real implementation, this would trigger an off-chain process
        // to fetch the current HBAR/USD rate and call updateExchangeRate
    }

    function updateExchangeRate(uint256 newRate) external onlyAuthorizedUpdater {
        require(newRate > 0, "Invalid rate");
        externalExchangeRate = newRate;
        lastUpdateTime = block.timestamp;
        emit ExchangeRateUpdated(newRate, msg.sender);
    }

    function convertTinycentsToTinybars(uint256 tineycents) external returns (uint256 tinybars) {
        // If we have an external rate and it's recent (less than 1 hour old), use it for more accurate conversion
        if (externalExchangeRate > 0 && (block.timestamp - lastUpdateTime) < 3600) {
            // Custom conversion using the external rate
            // tineycents is in 1/100 USD, externalExchangeRate is HBAR price * 1e6
            // tinybars is in 1e-8 HBAR
            tinybars = (tineycents * 1e8 * 1e6) / (externalExchangeRate * 100);
        } else {
            // Fall back to the system contract
            tinybars = tinycentsToTinybars(tineycents);
        }
        emit TinyBars(tinybars);
    }

    function convertTinybarsToTinycents(uint256 tinybars) external returns (uint256 tineycents) {
        // If we have an external rate and it's recent (less than 1 hour old), use it for more accurate conversion
        if (externalExchangeRate > 0 && (block.timestamp - lastUpdateTime) < 3600) {
            // Custom conversion using the external rate
            // tinybars is in 1e-8 HBAR, externalExchangeRate is HBAR price * 1e6
            // tineycents is in 1/100 USD
            tineycents = (tinybars * externalExchangeRate * 100) / (1e8 * 1e6);
        } else {
            // Fall back to the system contract
            tineycents = tinybarsToTinycents(tinybars);
        }
        emit TinyCents(tineycents);
    }

    function getExternalExchangeRate() external view returns (uint256, uint256) {
        return (externalExchangeRate, lastUpdateTime);
    }

    function isExternalRateValid() external view returns (bool) {
        return externalExchangeRate > 0 && (block.timestamp - lastUpdateTime) < 3600;
    }
}