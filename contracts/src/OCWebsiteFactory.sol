// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import { LibStrings } from "./library/LibStrings.sol";
import "./OCWebsite/OCWebsite.sol";
import "./OCWebsite/ClonableOCWebsite.sol";
import "./OCWebsite/ClonableFrontendVersionViewer.sol";
import "./OCWebsiteFactoryToken.sol";
import "./interfaces/IStorageBackend.sol";
import "./interfaces/IStorageBackendLibrary.sol";
import "./interfaces/IVersionableStaticWebsite.sol";

interface IFactoryExtension {
  function getName() external view returns (string memory);
}

contract OCWebsiteFactory is ERC721Enumerable, IStorageBackendLibrary {
    OCWebsite public website;
    OCWebsiteFactoryToken public immutable factoryToken;

    ClonableOCWebsite public immutable websiteImplementation;

    OCWebsite[] public websites;
    mapping(OCWebsite=> uint) public websiteToIndex;
    event WebsiteCreated(uint indexed websiteId, address website);
    
    ClonableFrontendVersionViewer public frontendVersionViewerImplementation;

    string public topdomain;
    string public domain;

    // VersionableStaticWebsite plugins
    IVersionableStaticWebsitePlugin[] public websiteAvailablePlugins;
    IVersionableStaticWebsitePlugin[] public newWebsiteDefaultPlugins;

    // Storage backends
    IStorageBackend[] public storageBackends;
 
    // The owner of the factory
    address public owner;

    // For possible future extensions : a listing of extension contracts
    IFactoryExtension[] public extensions;


    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }


    /**
     * 
     * @param _topdomain eth
     * @param _domain dblog
     */
    struct ConstructorParams {
        address owner;
        string topdomain;
        string domain;
        OCWebsiteFactoryToken factoryToken;
        ClonableOCWebsite websiteImplementation;
        ClonableFrontendVersionViewer frontendVersionViewerImplementation;
    }
    constructor(ConstructorParams memory _params) ERC721("OCWebsite", "OCW") {
        owner = _params.owner;

        topdomain = _params.topdomain;
        domain = _params.domain;

        factoryToken = _params.factoryToken;
        websiteImplementation = _params.websiteImplementation;
        frontendVersionViewerImplementation = _params.frontendVersionViewerImplementation;

        // Adding some backlinks
        factoryToken.setWebsiteFactory(this);
    }

    function setWebsite(OCWebsite _website) public onlyOwner {
        website = _website;
    }

    /**
     * Add a new website
     * @param firstFrontendVersionStorageBackend The storage backend for the first frontend version. Can be null.
     */
    function mintWebsite(IStorageBackend firstFrontendVersionStorageBackend) public payable returns(ClonableOCWebsite) {

        ClonableOCWebsite newWebsite = ClonableOCWebsite(Clones.clone(address(websiteImplementation)));

        if(address(firstFrontendVersionStorageBackend) == address(0) && storageBackends.length > 0) {
            firstFrontendVersionStorageBackend = storageBackends[0];
        }

        newWebsite.initialize(msg.sender, address(this), frontendVersionViewerImplementation, firstFrontendVersionStorageBackend, newWebsiteDefaultPlugins);
        websites.push(newWebsite);
        websiteToIndex[newWebsite] = websites.length - 1;

        // Mint an ERC721 token
        _safeMint(msg.sender, websites.length - 1);

        emit WebsiteCreated(websites.length - 1, address(newWebsite));

        return newWebsite;
    }




    //
    // Storage backends
    //

    function addStorageBackend(IStorageBackend storageBackend) public onlyOwner {
        // Make sure it is not inserted yet
        // Make sure name is unique
        for(uint i = 0; i < storageBackends.length; i++) {
            require(address(storageBackends[i]) != address(storageBackend), "Storage backend already added");
            require(LibStrings.compare(storageBackends[i].name(), storageBackend.name()) == false, "Storage backend name already used");
        }

        storageBackends.push(storageBackend);
    }

    function getStorageBackends() public view returns (IStorageBackendWithName[] memory) {
        IStorageBackendWithName[] memory backends = new IStorageBackendWithName[](storageBackends.length);
        for(uint i = 0; i < storageBackends.length; i++) {
            backends[i] = IStorageBackendWithName({
                storageBackend: storageBackends[i],
                name: storageBackends[i].name()
            });
        }

        return backends;
    }

    function getStorageBackendByName(string memory name) public view returns (IStorageBackend) {
        bool found = false;
        uint index = 0;
        for(uint i = 0; i < storageBackends.length; i++) {
            if(LibStrings.compare(storageBackends[i].name(), name)) {
                index = i;
                found = true;
            }
        }
        require(found, "Storage backend not found");

        return storageBackends[index];
    }


    //
    // Website plugins
    //

    function addWebsitePlugin(IVersionableStaticWebsitePlugin plugin, bool addAsNewWebsiteDefaultPlugin) public onlyOwner {
        // Make sure it is not inserted yet
        for(uint i = 0; i < websiteAvailablePlugins.length; i++) {
            require(address(websiteAvailablePlugins[i]) != address(plugin), "Plugin already added");
        }

        websiteAvailablePlugins.push(plugin);
        if(addAsNewWebsiteDefaultPlugin) {
            newWebsiteDefaultPlugins.push(plugin);
        }
    }

    struct IVersionableStaticWebsitePluginWithInfos {
        IVersionableStaticWebsitePlugin plugin;
        IVersionableStaticWebsitePlugin.Infos infos;
        bool isDefaultPlugin;
    }
    function getWebsitePlugins() public view returns (IVersionableStaticWebsitePluginWithInfos[] memory) {
        IVersionableStaticWebsitePluginWithInfos[] memory plugins = new IVersionableStaticWebsitePluginWithInfos[](websiteAvailablePlugins.length);
        for(uint i = 0; i < websiteAvailablePlugins.length; i++) {
            plugins[i] = IVersionableStaticWebsitePluginWithInfos({
                plugin: websiteAvailablePlugins[i],
                infos: websiteAvailablePlugins[i].infos(),
                isDefaultPlugin: false
            });
        }

        for(uint i = 0; i < newWebsiteDefaultPlugins.length; i++) {
            for(uint j = 0; j < plugins.length; j++) {
                if(address(plugins[j].plugin) == address(newWebsiteDefaultPlugins[i])) {
                    plugins[j].isDefaultPlugin = true;
                }
            }
        }

        return plugins;
    }

    function removeWebsitePlugin(IVersionableStaticWebsitePlugin plugin) public onlyOwner {
        for(uint i = 0; i < websiteAvailablePlugins.length; i++) {
            if(address(websiteAvailablePlugins[i]) == address(plugin)) {
                websiteAvailablePlugins[i] = websiteAvailablePlugins[websiteAvailablePlugins.length - 1];
                websiteAvailablePlugins.pop();
                return;
            }
        }
        for(uint i = 0; i < newWebsiteDefaultPlugins.length; i++) {
            if(address(newWebsiteDefaultPlugins[i]) == address(plugin)) {
                newWebsiteDefaultPlugins[i] = newWebsiteDefaultPlugins[newWebsiteDefaultPlugins.length - 1];
                newWebsiteDefaultPlugins.pop();
                return;
            }
        }
    }


    //
    // ERC721
    //

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        // Update the owner of the website, when moving the token (not minting)
        if(from != address(0)) {
            for(uint i = 0; i < batchSize; i++) {
                OCWebsite userWebsite = websites[firstTokenId + i];
                userWebsite.transferOwnership(to);
            }
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(tokenId < websites.length, "Token does not exist");

        return factoryToken.tokenURI(tokenId);
    }

    function tokenSVG(uint tokenId) public view returns (string memory) {
        require(tokenId < websites.length, "Token does not exist");

        return factoryToken.tokenSVG(tokenId);
    }

    function tokenSVGTemplate() public view returns (string memory) {
        return factoryToken.tokenSVGByVars("{addressPart1}", "{addressPart2}");
    }

    struct DetailedToken {
        uint tokenId;
        address contractAddress;
    }
    function detailedTokensOfOwner(address user) public view returns (DetailedToken[] memory tokens) {
        uint tokenCount = balanceOf(user);
        tokens = new DetailedToken[](tokenCount);
        for(uint i = 0; i < tokenCount; i++) {
            uint tokenId = tokenOfOwnerByIndex(user, i);
            tokens[i] = DetailedToken({
                tokenId: tokenId,
                contractAddress: address(websites[tokenId])
            });
        }

        return tokens;
    }


    //
    // Admin
    //

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function addExtension(IFactoryExtension _extension) public onlyOwner {
        require(address(_extension) != address(0), "Extension address cannot be 0");

        for(uint i = 0; i < extensions.length; i++) {
            require(address(extensions[i]) != address(_extension), "Extension already added");
            require(LibStrings.compare(extensions[i].getName(), _extension.getName()) == false, "Extension name already used");
        }

        extensions.push(_extension);
    }

    struct ExtensionInfo {
        string name;
        address extensionAddress;
    }
    function getExtensions() public view returns (ExtensionInfo[] memory) {
        ExtensionInfo[] memory infos = new ExtensionInfo[](extensions.length);
        for(uint i = 0; i < extensions.length; i++) {
            infos[i] = ExtensionInfo({
                name: extensions[i].getName(),
                extensionAddress: address(extensions[i])
            });
        }

        return infos;
    }

}
