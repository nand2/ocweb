// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DBlogFactory} from "../src/DBlogFactory.sol";
import {DBlogFactoryToken} from "../src/DBlogFactoryToken.sol";
import {DBlogFactoryFrontend} from "../src/DBlogFactoryFrontend.sol";
import {DBlogFrontendLibrary} from "../src/DBlogFrontendLibrary.sol";
import {DBlogFrontend} from "../src/DBlogFrontend.sol";
import {DBlog} from "../src/DBlog.sol";
import {StorageBackendSSTORE2} from "../src/StorageBackendSSTORE2.sol";

// EthFS
import {FileStore, File} from "ethfs/FileStore.sol";

// ENS
import {ENSRegistry} from "ens-contracts/registry/ENSRegistry.sol";
import {ReverseRegistrar} from "ens-contracts/reverseRegistrar/ReverseRegistrar.sol";
import {Root} from "ens-contracts/root/Root.sol";
import {BaseRegistrarImplementation} from "ens-contracts/ethregistrar/BaseRegistrarImplementation.sol";
import {DummyOracle} from "ens-contracts/ethregistrar/DummyOracle.sol";
import {ExponentialPremiumPriceOracle} from "ens-contracts/ethregistrar/ExponentialPremiumPriceOracle.sol";
import {AggregatorInterface} from "ens-contracts/ethregistrar/StablePriceOracle.sol";
import {StaticMetadataService} from "ens-contracts/wrapper/StaticMetadataService.sol";
import {NameWrapper} from "ens-contracts/wrapper/NameWrapper.sol";
import {IMetadataService} from "ens-contracts/wrapper/IMetadataService.sol";
import {ETHRegistrarController} from "ens-contracts/ethregistrar/ETHRegistrarController.sol";
import {OwnedResolver} from "ens-contracts/resolvers/OwnedResolver.sol";
import {ExtendedDNSResolver} from "ens-contracts/resolvers/profiles/ExtendedDNSResolver.sol";
import {PublicResolver} from "ens-contracts/resolvers/PublicResolver.sol";
import {IPriceOracle} from "ens-contracts/ethregistrar/IPriceOracle.sol";

// EthStorage
import {TestEthStorageContractKZG} from "storage-contracts-v1/TestEthStorageContractKZG.sol";
import {StorageContract} from "storage-contracts-v1/StorageContract.sol";

contract DBlogFactoryScript is Script {
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
        }
        string memory domain = vm.envString("DOMAIN");


        vm.startBroadcast();

        // Get ENS nameWrapper (will deploy ENS and register domain name if necessary)
        (NameWrapper nameWrapper, BaseRegistrarImplementation baseRegistrar, ETHRegistrarController ethRegistrarController) = registerDomainAndGetEnsContracts(targetChain, domain);

        // Get ETHFS filestore
        FileStore store = getFileStore(targetChain);
        console.log("FileStore: ", vm.toString(address(store)));
        // Add the IBM font
        if(targetChain == TargetChain.LOCAL) {
            bytes memory fileContents = vm.readFileBinary("assets/IBMPlexMono-Regular.woff2.base64");
            (address fontFilePointer, ) = store.createFile("IBMPlexMono-Regular.woff2", string(fileContents));
        }

        // Get EthStorage
        TestEthStorageContractKZG ethStorage = getEthStorage(targetChain);

        DBlogFactory factory;
        {
            // Create the factory frontend
            DBlogFactoryFrontend factoryFrontend = new DBlogFactoryFrontend();

            // Create the factory token
            DBlogFactoryToken factoryToken = new DBlogFactoryToken();

            // Create the dblog frontend library
            DBlogFrontendLibrary blogFrontendLibrary = new DBlogFrontendLibrary();

            // Create the blog and blogFrontend implementations
            DBlog blogImplementation = new DBlog();
            DBlogFrontend blogFrontendImplementation = new DBlogFrontend();

            // Deploying the blog factory
            factory = new DBlogFactory(DBlogFactory.ConstructorParams({
                topdomain: "eth",
                domain: domain,
                factoryFrontend: factoryFrontend,
                factoryToken: factoryToken,
                blogImplementation: blogImplementation,
                blogFrontendImplementation: blogFrontendImplementation,
                blogFrontendLibrary: blogFrontendLibrary,
                ensNameWrapper: nameWrapper,
                ensEthRegistrarController: ethRegistrarController,
                ensBaseRegistrar: baseRegistrar,
                ethfsFileStore: store
            }));

            console.log("DBlogFactory: ", address(factory));
            console.log("DBlogFactoryToken: ", address(factoryToken));
            console.log("DBlogFactoryFrontend: ", address(factoryFrontend));
            console.log("DBlogFrontendLibrary: ", address(blogFrontendLibrary));
            console.log("DBlogImplementation: ", address(blogImplementation));
            console.log("DBlogFrontendImplementation: ", address(blogFrontendImplementation));

            // Printing the web3:// address of the factory frontend
            string memory web3FactoryFrontendAddress = string.concat("web3://", vm.toString(address(factory.factoryFrontend())));
            if(block.chainid > 1) {
                web3FactoryFrontendAddress = string.concat(web3FactoryFrontendAddress, ":", vm.toString(block.chainid));
            }
            console.log("web3:// factory frontend: ", web3FactoryFrontendAddress);

            // Printing the web3:// address of the factory contract
            string memory web3FactoryAddress = string.concat("web3://", vm.toString(address(factory)));
            if(block.chainid > 1) {
                web3FactoryAddress = string.concat(web3FactoryAddress, ":", vm.toString(block.chainid));
            }
            console.log("web3:// factory: ", web3FactoryAddress);
        }

        // Add the SSTORE2 storage backend
        {
            StorageBackendSSTORE2 storageBackend = new StorageBackendSSTORE2();
            factory.addStorageBackend(storageBackend);
        }

        // Set the ENS resolver of dblog.eth to the contract
        if(targetChain == TargetChain.SEPOLIA || targetChain == TargetChain.HOLESKY || targetChain == TargetChain.MAINNET || targetChain == TargetChain.LOCAL) {
            bytes32 topdomainNamehash = keccak256(abi.encodePacked(bytes32(0x0), keccak256(abi.encodePacked("eth"))));
            bytes32 dblogDomainNamehash = keccak256(abi.encodePacked(topdomainNamehash, keccak256(abi.encodePacked(domain))));
            nameWrapper.setResolver(dblogDomainNamehash, address(factory));
        }

        // Transferring dblog.eth to the factory
        if(targetChain == TargetChain.SEPOLIA || targetChain == TargetChain.HOLESKY || targetChain == TargetChain.MAINNET || targetChain == TargetChain.LOCAL) {
            bytes32 topdomainNamehash = keccak256(abi.encodePacked(bytes32(0x0), keccak256(abi.encodePacked("eth"))));
            bytes32 dblogDomainNamehash = keccak256(abi.encodePacked(topdomainNamehash, keccak256(abi.encodePacked(domain))));

            nameWrapper.safeTransferFrom(msg.sender, address(factory), uint(dblogDomainNamehash), 1, "");
            // Testnet: Temporary testing (double checking we can fetch back the domain)
            if(targetChain != TargetChain.MAINNET) {
                factory.testnetSendBackDomain();
                nameWrapper.safeTransferFrom(msg.sender, address(factory), uint(dblogDomainNamehash), 1, "");
            }
        }

        // Adding the main blog
        factory.addBlog{value: factory.getSubdomainFee()}(string.concat(vm.envString("PRODUCT_NAME"), " news"), string.concat("Latest news about the ", domain, ".eth platform"), domain);
        string memory web3BlogFrontendAddress = string.concat("web3://", vm.toString(address(factory.blogs(0).frontend())));
        if(block.chainid > 1) {
            web3BlogFrontendAddress = string.concat(web3BlogFrontendAddress, ":", vm.toString(block.chainid));
        }
        console.log("web3://dblog.dblog.eth frontend: ", web3BlogFrontendAddress);

        string memory web3BlogAddress = string.concat("web3://", vm.toString(address(factory.blogs(0))));
        if(block.chainid > 1) {
            web3BlogAddress = string.concat(web3BlogAddress, ":", vm.toString(block.chainid));
        }
        console.log("web3://dblog.dblog.eth: ", web3BlogAddress);

        vm.stopBroadcast();
    }


    /**
     * Optionally register domain, get some ENS contracts
     * Target chain:
     * - local: Deploy ENS, register domain, returns the name wrapper
     * - sepolia : Register test domain, return the name wrapper
     * - mainnet : Return the name wrapper
     */
    function registerDomainAndGetEnsContracts(TargetChain targetChain, string memory domain) public returns (NameWrapper, BaseRegistrarImplementation, ETHRegistrarController) {
        NameWrapper nameWrapper;
        BaseRegistrarImplementation registrar;
        ETHRegistrarController registrarController;

        // Local chain : deploy ENS
        if(targetChain == TargetChain.LOCAL){
            ENSRegistry registry;
            PublicResolver publicResolver;
            
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
        }
        // Sepolia: Get ENS holesky addresses
        else if(targetChain == TargetChain.HOLESKY) {
            nameWrapper = NameWrapper(0xab50971078225D365994dc1Edcb9b7FD72Bb4862);
            registrar = BaseRegistrarImplementation(0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85);
            registrarController = ETHRegistrarController(0x179Be112b24Ad4cFC392eF8924DfA08C20Ad8583);
        }
        // Mainnet: Get ENS mainnet addresses
        else if(targetChain == TargetChain.MAINNET) {
            nameWrapper = NameWrapper(0xD4416b13d2b3a9aBae7AcD5D6C2BbDBE25686401);
            registrar = BaseRegistrarImplementation(0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85);
            registrarController = ETHRegistrarController(0x253553366Da8546fC250F225fe3d25d0C782303b);
        }


        // Local : Register dblog.eth
        if(targetChain == TargetChain.LOCAL) {
            bytes[] memory data = new bytes[](0);
            bytes32 commitment = registrarController.makeCommitment(domain, msg.sender, 365 * 24 * 3600, 0x00, address(0x0), data, false, 0);
            registrarController.commit(commitment);
            registrarController.register{value: 0.05 ether}(domain, msg.sender, 365 * 24 * 3600, 0x00, address(0x0), data, false, 0);
        }

        return (nameWrapper, registrar, registrarController);
    }

    /**
     * Optionally deploy FileStore, get FileStore address
     * Target chain:
     * - local: Deploy FileStore, return the address
     * - sepolia : Return the address
     * - mainnet : Return the address
     */
    function getFileStore(TargetChain targetChain) public returns (FileStore) {
        FileStore store;
        
        // Local: Deploy new filestore
        if(targetChain == TargetChain.LOCAL) {
            store = new FileStore(address(0x4e59b44847b379578588920cA78FbF26c0B4956C));
        }
        // Sepolia : Get existing value
        else if(targetChain == TargetChain.SEPOLIA) {
            store = FileStore(0xFe1411d6864592549AdE050215482e4385dFa0FB);
        }
        // Holesky : Get existing value
        else if(targetChain == TargetChain.HOLESKY) {
            store = FileStore(0xFe1411d6864592549AdE050215482e4385dFa0FB);
        }
        // Mainnet : Get existing value
        else if(targetChain == TargetChain.MAINNET) {
            store = FileStore(0xFe1411d6864592549AdE050215482e4385dFa0FB);
        }
        // Base : Get existing value
        else if(targetChain == TargetChain.BASE) {
            store = FileStore(0xFe1411d6864592549AdE050215482e4385dFa0FB);
        }
        // Base Sepolia : Get existing value
        else if(targetChain == TargetChain.BASE_SEPOLIA) {
            store = FileStore(0xFe1411d6864592549AdE050215482e4385dFa0FB);
        }
        
        return store;
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
}
