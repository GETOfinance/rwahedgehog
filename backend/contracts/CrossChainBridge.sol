// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "./system-contracts/hedera-token-service/HederaTokenService.sol";
import "./system-contracts/HederaResponseCodes.sol";

contract CrossChainBridge is HederaTokenService {
    mapping(uint256 => bool) public supportedChains; // chainId -> supported
    mapping(address => bool) public supportedTokens;
    mapping(bytes32 => bool) public processedTransfers; // transferId -> processed

    uint256 private transferCounter;

    event TokensSent(bytes32 indexed transferId, uint256 destinationChain, address indexed receiver, address indexed token, uint256 amount);
    event TokensReceived(bytes32 indexed transferId, uint256 sourceChain, address indexed sender, address indexed token, uint256 amount);
    event ChainSupportUpdated(uint256 chainId, bool supported);
    event TokenSupportUpdated(address token, bool supported);
    event BridgeOperatorUpdated(address operator, bool authorized);

    mapping(address => bool) public bridgeOperators;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    modifier onlyBridgeOperator() {
        require(bridgeOperators[msg.sender] || msg.sender == admin, "Not authorized");
        _;
    }

    modifier onlySupportedChain(uint256 chainId) {
        require(supportedChains[chainId], "Chain not supported");
        _;
    }

    modifier onlySupportedToken(address token) {
        require(supportedTokens[token], "Token not supported");
        _;
    }

    constructor() {
        admin = msg.sender;
        transferCounter = 1;
    }
    
    function addSupportedChain(uint256 chainId) external onlyAdmin {
        supportedChains[chainId] = true;
        emit ChainSupportUpdated(chainId, true);
    }

    function removeSupportedChain(uint256 chainId) external onlyAdmin {
        supportedChains[chainId] = false;
        emit ChainSupportUpdated(chainId, false);
    }

    function addSupportedToken(address token) external onlyAdmin {
        supportedTokens[token] = true;
        emit TokenSupportUpdated(token, true);
    }

    function removeSupportedToken(address token) external onlyAdmin {
        supportedTokens[token] = false;
        emit TokenSupportUpdated(token, false);
    }

    function addBridgeOperator(address operator) external onlyAdmin {
        bridgeOperators[operator] = true;
        emit BridgeOperatorUpdated(operator, true);
    }

    function removeBridgeOperator(address operator) external onlyAdmin {
        bridgeOperators[operator] = false;
        emit BridgeOperatorUpdated(operator, false);
    }
    
    // Lock tokens for cross-chain transfer
    function lockTokensForTransfer(
        uint256 destinationChain,
        address receiver,
        address token,
        uint256 amount
    ) external onlySupportedChain(destinationChain) onlySupportedToken(token) {

        // Transfer tokens from sender to this contract (lock them)
        int responseCode = HederaTokenService.transferFrom(token, msg.sender, address(this), amount);
        require(responseCode == HederaResponseCodes.SUCCESS, "Token transfer failed");

        // Generate transfer ID
        bytes32 transferId = keccak256(abi.encodePacked(
            block.timestamp,
            msg.sender,
            receiver,
            token,
            amount,
            transferCounter++
        ));

        emit TokensSent(transferId, destinationChain, receiver, token, amount);
    }
    
    // Release tokens from cross-chain transfer (called by bridge operators)
    function releaseTokensFromTransfer(
        bytes32 transferId,
        uint256 sourceChain,
        address sender,
        address receiver,
        address token,
        uint256 amount
    ) external onlyBridgeOperator onlySupportedToken(token) {

        require(!processedTransfers[transferId], "Transfer already processed");
        processedTransfers[transferId] = true;

        // Release tokens to the receiver
        int responseCode = HederaTokenService.transferFrom(token, address(this), receiver, amount);
        require(responseCode == HederaResponseCodes.SUCCESS, "Token release failed");

        emit TokensReceived(transferId, sourceChain, sender, token, amount);
    }
    
    // Emergency function to withdraw tokens
    function emergencyWithdraw(address token, uint256 amount, address to) external onlyAdmin {
        int responseCode = HederaTokenService.transferFrom(token, address(this), to, amount);
        require(responseCode == HederaResponseCodes.SUCCESS, "Emergency withdrawal failed");
    }

    // Get locked token balance
    function getLockedBalance(address token) external view returns (uint256) {
        // This would need to be implemented based on your token balance tracking
        return 0; // Placeholder
    }

    // Check if a chain is supported
    function isChainSupported(uint256 chainId) external view returns (bool) {
        return supportedChains[chainId];
    }

    // Check if a token is supported
    function isTokenSupported(address token) external view returns (bool) {
        return supportedTokens[token];
    }

    // Check if a transfer has been processed
    function isTransferProcessed(bytes32 transferId) external view returns (bool) {
        return processedTransfers[transferId];
    }

    // Get transfer counter
    function getTransferCounter() external view returns (uint256) {
        return transferCounter;
    }
}
