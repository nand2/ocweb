// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Script, console } from "forge-std/Script.sol";

// Openzeappelin Upgrade plugin
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { Options } from "openzeppelin-foundry-upgrades/Options.sol";
import { DefenderOptions } from "openzeppelin-foundry-upgrades/Options.sol";
import { TxOverrides } from "openzeppelin-foundry-upgrades/Options.sol";

import { IStorageBackend } from "../src/interfaces/IStorageBackend.sol";
import { CompressionAlgorithm } from "../src/interfaces/IFileInfos.sol";
import { KeyValue } from "../src/interfaces/IDecentralizedApp.sol";

import { OCWebsiteFactory } from "../src/OCWebsiteFactory.sol";
// import { OCWebsiteFactoryV2 } from "../src/OCWebsiteFactoryV2.sol";
import { OCWebsiteFactoryToken } from "../src/OCWebsiteFactoryToken.sol";
import { OCWebsite } from "../src/OCWebsite/OCWebsite.sol";
import { ClonableOCWebsite } from "../src/OCWebsite/ClonableOCWebsite.sol";
import { ClonableWebsiteVersionViewer } from "../src/OCWebsite/ClonableWebsiteVersionViewer.sol";
import { StorageBackendSSTORE2 } from "../src/OCWebsite/storageBackends/StorageBackendSSTORE2.sol";
import { StorageBackendEthStorage } from "../src/OCWebsite/storageBackends/StorageBackendEthStorage.sol";
import { LibStrings } from "../src/library/LibStrings.sol";
import { InjectedVariablesPlugin } from "../src/OCWebsite/plugins/InjectedVariablesPlugin.sol";
import { ProxiedWebsitesPlugin } from "../src/OCWebsite/plugins/ProxiedWebsitesPlugin.sol";
import { StaticFrontendPlugin } from "../src/OCWebsite/plugins/StaticFrontendPlugin.sol";
import { IVersionableWebsite } from "../src/interfaces/IVersionableWebsite.sol";
import { OCWebAdminPlugin } from "../src/OCWebsite/plugins/OCWebAdminPlugin.sol";

contract UpdateFactoryClonableWebsiteScript is Script {
    enum TargetChain{ LOCAL, SEPOLIA, HOLESKY, MAINNET, BASE_SEPOLIA, BASE, OPTIMISM }

    function setUp() public {}

    function run() public {
        // Environment variables
        TargetChain targetChain = TargetChain.LOCAL;
        {
            string memory targetChainString = vm.envString("TARGET_CHAIN");
            if(keccak256(abi.encodePacked(vm.envString("TARGET_CHAIN"))) == keccak256(abi.encodePacked("local"))) {
                targetChain = TargetChain.LOCAL;
            } else if(keccak256(abi.encodePacked(vm.envString("TARGET_CHAIN"))) == keccak256(abi.encodePacked("sepolia"))) {
                targetChain = TargetChain.SEPOLIA;
            } else if(keccak256(abi.encodePacked(vm.envString("TARGET_CHAIN"))) == keccak256(abi.encodePacked("holesky"))) {
                targetChain = TargetChain.HOLESKY;
            } else if(keccak256(abi.encodePacked(vm.envString("TARGET_CHAIN"))) == keccak256(abi.encodePacked("mainnet"))) {
                targetChain = TargetChain.MAINNET;
            } else if(keccak256(abi.encodePacked(vm.envString("TARGET_CHAIN"))) == keccak256(abi.encodePacked("base-sepolia"))) {
                targetChain = TargetChain.BASE_SEPOLIA;
            } else if(keccak256(abi.encodePacked(vm.envString("TARGET_CHAIN"))) == keccak256(abi.encodePacked("base"))) {
                targetChain = TargetChain.BASE;
            } else if(keccak256(abi.encodePacked(vm.envString("TARGET_CHAIN"))) == keccak256(abi.encodePacked("optimism"))) {
                targetChain = TargetChain.OPTIMISM;
            }
            else {
                console.log("Unknown target chain: ", targetChainString);
                return;
            }
        }
        OCWebsiteFactory factory = OCWebsiteFactory(vm.envAddress("OCWEBSITE_FACTORY_ADDRESS"));

        vm.startBroadcast();

        // Create the new cloneable OCWebsite implementation
        ClonableOCWebsite newImplementation = new ClonableOCWebsite();

        // Ensure that is IVersionableWebsiteInterfaceId and 
        // IVersionableWebsiteInterfaceImplementationVersion are different that the current implementation
        ClonableOCWebsite currentImplementation = factory.websiteImplementation();
        if(newImplementation.IVersionableWebsiteInterfaceId() == currentImplementation.IVersionableWebsiteInterfaceId() &&
            newImplementation.IVersionableWebsiteInterfaceImplementationVersion() == currentImplementation.IVersionableWebsiteInterfaceImplementationVersion()) {
            console.log("Error: The new implementation has the same interface id and implementation version as the current implementation");
            vm.stopBroadcast();
            return;
        }

        // Set the new implementation
        factory.setWebsiteImplementation(newImplementation);

        vm.stopBroadcast();
    }
}