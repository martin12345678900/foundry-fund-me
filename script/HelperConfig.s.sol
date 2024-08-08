// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Script } from "forge-std/Script.sol";
import { MockV3Aggregator } from "../test/mocks/MockV3Aggregator.sol";


contract HelperConfig is Script {

    struct NetworkConfig {
        address priceFeed;
    }

    NetworkConfig public activeNetworkConfig;
    
    uint8 public constant DEMICALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    constructor() {
        // If we are on Sepolia Chain
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        // If we are on local anvil chain
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory) {
        return NetworkConfig({ priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306 });
    }

    function getOrCreateAnvilEthConfig() public returns(NetworkConfig memory) {
        // Means we already have deployed the network config helper contract
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast();

        // Mock the PriceFeed contract
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DEMICALS, INITIAL_PRICE);
        
        vm.stopBroadcast();

        // Return it's address
        return NetworkConfig({ priceFeed: address(mockPriceFeed) });
    }

}