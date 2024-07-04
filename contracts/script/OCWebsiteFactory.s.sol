// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Script, console } from "forge-std/Script.sol";

// ENS
import { ENSRegistry } from "ens-contracts/registry/ENSRegistry.sol";
import { ReverseRegistrar } from "ens-contracts/reverseRegistrar/ReverseRegistrar.sol";
import { Root } from "ens-contracts/root/Root.sol";
import { BaseRegistrarImplementation } from "ens-contracts/ethregistrar/BaseRegistrarImplementation.sol";
import { DummyOracle } from "ens-contracts/ethregistrar/DummyOracle.sol";
import { ExponentialPremiumPriceOracle } from "ens-contracts/ethregistrar/ExponentialPremiumPriceOracle.sol";
import { AggregatorInterface } from "ens-contracts/ethregistrar/StablePriceOracle.sol";
import { StaticMetadataService } from "ens-contracts/wrapper/StaticMetadataService.sol";
import { NameWrapper } from "ens-contracts/wrapper/NameWrapper.sol";
import { IMetadataService } from "ens-contracts/wrapper/IMetadataService.sol";
import { ETHRegistrarController } from "ens-contracts/ethregistrar/ETHRegistrarController.sol";
import { OwnedResolver } from "ens-contracts/resolvers/OwnedResolver.sol";
import { ExtendedDNSResolver } from "ens-contracts/resolvers/profiles/ExtendedDNSResolver.sol";
import { PublicResolver } from "ens-contracts/resolvers/PublicResolver.sol";
import { IPriceOracle } from "ens-contracts/ethregistrar/IPriceOracle.sol";

// EthStorage
import { TestEthStorageContractKZG } from "storage-contracts-v1/TestEthStorageContractKZG.sol";
import { StorageContract } from "storage-contracts-v1/StorageContract.sol";

import { IFrontendLibrary } from "../src/interfaces/IFrontendLibrary.sol";
import { IStorageBackend } from "../src/interfaces/IStorageBackend.sol";
import { CompressionAlgorithm } from "../src/interfaces/IFileInfos.sol";
import { KeyValue } from "../src/interfaces/IDecentralizedApp.sol";

import { OCWebsiteFactory } from "../src/OCWebsiteFactory.sol";
import { OCWebsiteFactoryToken } from "../src/OCWebsiteFactoryToken.sol";
import { OCWebsite } from "../src/OCWebsite/OCWebsite.sol";
import { ClonableOCWebsite } from "../src/OCWebsite/ClonableOCWebsite.sol";
import { ClonableFrontendVersionViewer } from "../src/OCWebsite/ClonableFrontendVersionViewer.sol";
import { StorageBackendSSTORE2 } from "../src/OCWebsite/storageBackends/StorageBackendSSTORE2.sol";

contract OCWebsiteFactoryScript is Script {
    enum TargetChain{ LOCAL, SEPOLIA, HOLESKY, MAINNET, BASE_SEPOLIA, BASE }

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
            }
            else {
                console.log("Unknown target chain: ", targetChainString);
                return;
            }

            // Checking that the short name is known
            string memory shortName = getChainShortName(targetChain);
            if(bytes(shortName).length == 0) {
                console.log("Unknown short name for chain ", targetChainString);
                return;
            }
        }
        string memory domain = vm.envString("DOMAIN");


        vm.startBroadcast();

        // Get ENS nameWrapper (will deploy ENS and register domain name if necessary)
        (NameWrapper nameWrapper, BaseRegistrarImplementation baseRegistrar, ETHRegistrarController ethRegistrarController, PublicResolver publicResolver) = registerDomainAndGetEnsContracts(targetChain, domain);

        // Get EthStorage
        TestEthStorageContractKZG ethStorage = getEthStorage(targetChain);

        OCWebsiteFactory factory;
        {
            // Create the factory token
            OCWebsiteFactoryToken factoryToken = new OCWebsiteFactoryToken(vm.readFileBinary("assets/IBMPlexMono-Regular-subset.woff2"));

            // Create the website implementations
            ClonableOCWebsite websiteImplementation = new ClonableOCWebsite();

            // Create the frontend version viewer implementation
            ClonableFrontendVersionViewer frontendVersionViewerImplementation = new ClonableFrontendVersionViewer();

            // Deploying the blog factory
            // {salt: bytes32(vm.envBytes("CONTRACT_SALT"))}
            factory = new OCWebsiteFactory(OCWebsiteFactory.ConstructorParams({
                owner: msg.sender,
                topdomain: "eth",
                domain: domain,
                factoryToken: factoryToken,
                websiteImplementation: websiteImplementation,
                frontendVersionViewerImplementation: frontendVersionViewerImplementation
            }));

            // Transfer the website implementation ownership to the factory
            // Not strictly necessary, but let's be sure it stays never changed
            websiteImplementation.transferOwnership(address(factory));

            // Add the SSTORE2 storage backend
            {
                StorageBackendSSTORE2 storageBackend = new StorageBackendSSTORE2();
                factory.addStorageBackend(storageBackend);
            }

            // Create a website from the factory, to use as frontend for the factory itself
            OCWebsite factoryFrontend = factory.mintWebsite(IStorageBackend(address(0)));
            // Add the factory contract address to the frontend
            factoryFrontend.addStaticContractAddressToFrontend(0, string.concat("factory-", getChainShortName(targetChain)), address(factory), block.chainid);
            // Testing: Add hardcoded factory for sepolia && holesky
            factoryFrontend.addStaticContractAddressToFrontend(0, string.concat("factory-", "holesky"), 0xFE98Da931c7E15473344bf5Cfc4AB86f1fC4C831, 17000);
            // factoryFrontend.addStaticContractAddressToFrontend(0, string.concat("factory-", "sep"), 0x9f0678BAa0b104d6be803aE8F53ed1e67F148c07, 11155111);

            // // Add internal redirect to index.html, for 404 handling, and #/ handling
            // string[] memory internalRedirect = new string[](1);
            // internalRedirect[0] = "index.html";
            // factoryFrontend.setGlobalInternalRedirect(internalRedirect, new KeyValue[](0));
            // Set the website as the factory frontend
            factory.setWebsite(factoryFrontend);

            
            

            console.log("OCWebsiteFactory: ", address(factory));
            console.log("OCWebsiteFactoryToken: ", address(factoryToken));
            console.log("OCWebsiteFactory frontend: ", address(factoryFrontend));
            console.log("OCWebsite implementation: ", address(websiteImplementation));

            // Printing the web3:// address of the factory frontend
            string memory web3FactoryWebsiteAddress = string.concat("web3://", vm.toString(address(factory.website())));
            if(block.chainid > 1) {
                web3FactoryWebsiteAddress = string.concat(web3FactoryWebsiteAddress, ":", vm.toString(block.chainid));
            }
            console.log("web3:// factory website: ", web3FactoryWebsiteAddress);

            // Printing the web3:// address of the factory contract
            string memory web3FactoryAddress = string.concat("web3://", vm.toString(address(factory)));
            if(block.chainid > 1) {
                web3FactoryAddress = string.concat(web3FactoryAddress, ":", vm.toString(block.chainid));
            }
            console.log("web3:// factory: ", web3FactoryAddress);

            // If local, point the domain to the factory website
            if(targetChain == TargetChain.LOCAL) {
                bytes32 topdomainNamehash = keccak256(abi.encodePacked(bytes32(0x0), keccak256(abi.encodePacked("eth"))));
                bytes32 domainNamehash = keccak256(abi.encodePacked(topdomainNamehash, keccak256(abi.encodePacked(domain))));
                nameWrapper.setRecord(domainNamehash, msg.sender, address(publicResolver), 365 * 24 * 3600);
                publicResolver.setAddr(domainNamehash, address(factory.website()));
            }

            // If local, send some ETH to a testing account
            if(targetChain == TargetChain.LOCAL) {
                payable(0xAafA7E1FBE681de12D41Ef9a5d5206A96963390e).transfer(3 ether);
            }
        }

        vm.stopBroadcast();
    }


    /**
     * Optionally register domain, get some ENS contracts
     * Target chain:
     * - local: Deploy ENS, register domain, returns the name wrapper
     * - sepolia : Register test domain, return the name wrapper
     * - mainnet : Return the name wrapper
     */
    function registerDomainAndGetEnsContracts(TargetChain targetChain, string memory domain) public returns (NameWrapper, BaseRegistrarImplementation, ETHRegistrarController, PublicResolver) {
        NameWrapper nameWrapper;
        BaseRegistrarImplementation registrar;
        ETHRegistrarController registrarController;
        PublicResolver publicResolver;

        // Local chain : deploy ENS
        if(targetChain == TargetChain.LOCAL){
            ENSRegistry registry;
            
            bytes32 topdomainNamehash = keccak256(abi.encodePacked(bytes32(0x0), keccak256(abi.encodePacked("eth"))));

            // ENS registry
            registry = new ENSRegistry();
            console.log("ENS registry: ", vm.toString(address(registry)));
            console.log("ENS registry owner: ", vm.toString(registry.owner(0x0)));
        
            // Root
            Root root = new Root(registry);
            console.log("Root: ", vm.toString(address(root)));
            registry.setOwner(0x0, address(root));
            root.setController(msg.sender, true);
            
            // ENS reverse registrar
            ReverseRegistrar reverseRegistrar = new ReverseRegistrar(registry);
            console.log("Reverse registrar: ", vm.toString(address(reverseRegistrar)));
            root.setSubnodeOwner(keccak256(abi.encodePacked("reverse")), msg.sender);
            registry.setSubnodeOwner(keccak256(abi.encodePacked(bytes32(0x0), keccak256(abi.encodePacked("reverse")))), keccak256(abi.encodePacked("addr")), address(reverseRegistrar));
            
            // Base registrar implementation
            registrar = new BaseRegistrarImplementation(registry, topdomainNamehash);
            root.setSubnodeOwner(keccak256(abi.encodePacked("eth")), address(registrar));
            console.log("Base registrar: ", vm.toString(address(registrar)));
            
            ExponentialPremiumPriceOracle priceOracle;
            {
                // Dummy price oracle
                DummyOracle oracle = new DummyOracle(160000000000);
                console.log("Dummy oracle: ", vm.toString(address(oracle)));

                // Exponential price oracle
                uint256[] memory rentPrices = new uint256[](5);
                rentPrices[0] = 0;
                rentPrices[1] = 0;
                rentPrices[2] = 20294266869609;
                rentPrices[3] = 5073566717402;
                rentPrices[4] = 158548959919;
                priceOracle = new ExponentialPremiumPriceOracle(AggregatorInterface(address(oracle)), rentPrices, 100000000000000000000000000, 21);
                console.log("Exponential price oracle: ", vm.toString(address(priceOracle)));
            }

            {
                // Static metadata service
                StaticMetadataService metadata = new StaticMetadataService("http://localhost:8080/name/0x{id}");
                console.log("Static metadata service: ", vm.toString(address(metadata)));

                // Name wrapper
                nameWrapper = new NameWrapper(registry, registrar, IMetadataService(address(metadata)));
                console.log("Name wrapper: ", vm.toString(address(nameWrapper)));
                registrar.addController(address(nameWrapper));
            }

            // Eth Registrar controller
            registrarController = new ETHRegistrarController(registrar, priceOracle, 0 /** min commitment age normally to 60, put it to 0 for fast registration testing */, 86400, reverseRegistrar, nameWrapper, registry);
            console.log("ETH registrar controller: ", vm.toString(address(registrarController)));
            nameWrapper.setController(address(registrarController), true);
            reverseRegistrar.setController(address(registrarController), true);
            console.log("Eth resolver: ", vm.toString(registry.resolver(topdomainNamehash)));

            {
                // Eth owned resolver
                OwnedResolver ethOwnedResolver = new OwnedResolver();
                console.log("Eth resolver: ", vm.toString(address(ethOwnedResolver)));
                registrar.setResolver(address(ethOwnedResolver));
                console.log("Registry: Eth resolver: ", vm.toString(registry.resolver(topdomainNamehash)));

                // Extended resolver
                ExtendedDNSResolver extendedResolver = new ExtendedDNSResolver();
                console.log("Extended resolver: ", vm.toString(address(extendedResolver)));

                // Public resolver
                publicResolver = new PublicResolver(registry, nameWrapper, address(registrarController), address(reverseRegistrar));
                console.log("Public resolver: ", vm.toString(address(publicResolver)));
                reverseRegistrar.setDefaultResolver(address(publicResolver));
            }

            // TODO: call ethOwnedResolver.setInterface()
        }
        // Sepolia: Get ENS sepolia addresses
        else if(targetChain == TargetChain.SEPOLIA) {
            nameWrapper = NameWrapper(0x0635513f179D50A207757E05759CbD106d7dFcE8);
            registrar = BaseRegistrarImplementation(0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85);
            registrarController = ETHRegistrarController(0xFED6a969AaA60E4961FCD3EBF1A2e8913ac65B72);
            publicResolver = PublicResolver(0x231b0Ee14048e9dCcD1d247744d114a4EB5E8E63);
        }
        // Sepolia: Get ENS holesky addresses
        else if(targetChain == TargetChain.HOLESKY) {
            nameWrapper = NameWrapper(0xab50971078225D365994dc1Edcb9b7FD72Bb4862);
            registrar = BaseRegistrarImplementation(0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85);
            registrarController = ETHRegistrarController(0x179Be112b24Ad4cFC392eF8924DfA08C20Ad8583);
            publicResolver = PublicResolver(0x9010A27463717360cAD99CEA8bD39b8705CCA238);
        }
        // Mainnet: Get ENS mainnet addresses
        else if(targetChain == TargetChain.MAINNET) {
            nameWrapper = NameWrapper(0xD4416b13d2b3a9aBae7AcD5D6C2BbDBE25686401);
            registrar = BaseRegistrarImplementation(0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85);
            registrarController = ETHRegistrarController(0x253553366Da8546fC250F225fe3d25d0C782303b);
            publicResolver = PublicResolver(0x231b0Ee14048e9dCcD1d247744d114a4EB5E8E63);
        }


        // Local : Register domain
        if(targetChain == TargetChain.LOCAL) {
            bytes[] memory data = new bytes[](0);
            bytes32 commitment = registrarController.makeCommitment(domain, msg.sender, 365 * 24 * 3600, 0x00, address(0x0), data, false, 0);
            registrarController.commit(commitment);
            registrarController.register{value: 0.05 ether}(domain, msg.sender, 365 * 24 * 3600, 0x00, address(0x0), data, false, 0);
        }

        return (nameWrapper, registrar, registrarController, publicResolver);
    }

    struct Config {
        uint256 maxKvSizeBits;
        uint256 shardSizeBits;
        uint256 randomChecks;
        uint256 minimumDiff;
        uint256 cutoff;
        uint256 diffAdjDivisor;
        uint256 treasuryShare; // 10000 = 1.0
    }
    function getEthStorage(TargetChain targetChain) public returns (TestEthStorageContractKZG) {
        TestEthStorageContractKZG ethStorageContract;

        // Local: Deploy an ethstorage contract
        if(targetChain == TargetChain.LOCAL) {
            ethStorageContract = new TestEthStorageContractKZG();
            StorageContract.Config memory ethStorageConfig = StorageContract.Config({
                maxKvSizeBits: 17, // maxKvSizeBits, 131072
                shardSizeBits: 39, // shardSizeBits ~ 512G
                randomChecks: 2, // randomChecks
                minimumDiff: 4718592000, // minimumDiff 5 * 3 * 3600 * 1024 * 1024 / 12 = 4718592000 for 5 replicas that can have 1M IOs in one epoch
                cutoff: 7200, // cutoff = 2/3 * target internal (3 hours), 3 * 3600 * 2/3
                diffAdjDivisor: 32, // diffAdjDivisor
                treasuryShare: 100 // treasuryShare, means 1%
            });
            ethStorageContract.initialize(
                ethStorageConfig,
                block.timestamp, // startTime
                1500000000000000, // storageCost - 1,500,000Gwei forever per blob - https://ethresear.ch/t/ethstorage-scaling-ethereum-storage-via-l2-and-da/14223/6#incentivization-for-storing-m-physical-replicas-1
                340282366367469178095360967382638002176, // dcfFactor, it mean 0.95 for yearly discount
                1048576, // nonceLimit 1024 * 1024 = 1M samples and finish sampling in 1.3s with IO rate 6144 MB/s: 4k * 2(random checks) / 6144 = 1.3s
                msg.sender, // treasury
                3145728000000000000000, // prepaidAmount - 50% * 2^39 / 131072 * 1500000Gwei, it also means 3145 ETH for half of the shard
                msg.sender // owner
                );
            // Send some eth into the storage contract to give reward for empty mining
            ethStorageContract.sendValue{value: 0.01 ether}();
        }
        // Sepolia : Get existing value
        else if(targetChain == TargetChain.SEPOLIA) {
            ethStorageContract = TestEthStorageContractKZG(0x804C520d3c084C805E37A35E90057Ac32831F96f);
        }
        // Holesky && mainnet: Not there yet

        console.log("EthStorage: ", vm.toString(address(ethStorageContract)));

        return ethStorageContract;
    }

    function getChainShortName(TargetChain targetChain) public pure returns (string memory) {
        if(targetChain == TargetChain.LOCAL) {
            return "hardhat";
        } else if(targetChain == TargetChain.SEPOLIA) {
            return "sep";
        } else if(targetChain == TargetChain.HOLESKY) {
            return "holesky";
        } else if(targetChain == TargetChain.MAINNET) {
            return "eth";
        } else if(targetChain == TargetChain.BASE_SEPOLIA) {
            return "basesep";
        } else if(targetChain == TargetChain.BASE) {
            return "base";
        }
    }
}
