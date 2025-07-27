//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // If we are on a local Anvil, we deploy the mocks
    // Else, grab the existing address from the live network

    MockV3Aggregator mockPriceFeed;
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed; // ETH/USD pricefeed address
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 42161) {
            activeNetworkConfig = getArbitrumEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory mainnetConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 // ETH/USD on Ethereum Mainnet
        });
        return mainnetConfig;
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getArbitrumEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory arbitrumConfig = NetworkConfig({
            priceFeed: 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612
        });
        return arbitrumConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
    if (activeNetworkConfig.priceFeed != address(0)) {
        return activeNetworkConfig;
    }

    // 1. Deploy the mocks
    vm.startBroadcast();
    mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
    vm.stopBroadcast();

    // 2. Return the mock address
    NetworkConfig memory anvilConfig = NetworkConfig({
        priceFeed: address(mockPriceFeed) // ✅ use correct mock address
    });

    activeNetworkConfig = anvilConfig; // ✅ set for reuse later
    return anvilConfig;
}
}
