// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import { LibStrings } from "./library/LibStrings.sol";
import "./OCWebsite/OCWebsite.sol";
import "./OCWebsite/ClonableOCWebsite.sol";
import "./OCWebsite/ClonableWebsiteVersionViewer.sol";
import "./OCWebsiteFactoryToken.sol";
import "./interfaces/IStorageBackend.sol";
import "./interfaces/IVersionableWebsite.sol";

interface IFactoryExtension {
  function getName() external view returns (string memory);
}

contract OCWebsiteFactory is ERC721Enumerable {
    OCWebsite public website;
    OCWebsiteFactoryToken public immutable factoryToken;

    ClonableOCWebsite public immutable websiteImplementation;

    OCWebsite[] public websites;
    mapping(OCWebsite=> uint) public websiteToIndex;
    event WebsiteCreated(uint indexed websiteId, address website);
    
    ClonableWebsiteVersionViewer public websiteVersionViewerImplementation;

    string public topdomain;
    string public domain;

    // VersionableWebsite plugins
    IVersionableWebsitePlugin[] public websiteAvailablePlugins;
    IVersionableWebsitePlugin[] public newWebsiteDefaultPlugins;
 
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
        ClonableWebsiteVersionViewer websiteVersionViewerImplementation;
    }
    constructor(ConstructorParams memory _params) ERC721("OCWebsite", "OCW") {
        owner = _params.owner;

        topdomain = _params.topdomain;
        domain = _params.domain;

        factoryToken = _params.factoryToken;
        websiteImplementation = _params.websiteImplementation;
        websiteVersionViewerImplementation = _params.websiteVersionViewerImplementation;

        // Adding some backlinks
        factoryToken.setWebsiteFactory(this);
    }

    function setWebsite(OCWebsite _website) public onlyOwner {
        website = _website;
    }

    /**
     * Mint a new website
     */
    function mintWebsite() public payable returns(ClonableOCWebsite) {

        ClonableOCWebsite newWebsite = ClonableOCWebsite(Clones.clone(address(websiteImplementation)));

        newWebsite.initialize(msg.sender, address(this), websiteVersionViewerImplementation, newWebsiteDefaultPlugins);
        websites.push(newWebsite);
        websiteToIndex[newWebsite] = websites.length - 1;

        // Mint an ERC721 token
        _safeMint(msg.sender, websites.length - 1);

        emit WebsiteCreated(websites.length - 1, address(newWebsite));

        return newWebsite;
    }



    //
    // Website plugins
    //

    function addWebsitePlugin(IVersionableWebsitePlugin plugin, bool addAsNewWebsiteDefaultPlugin) public onlyOwner {
        // Make sure it is not inserted yet
        for(uint i = 0; i < websiteAvailablePlugins.length; i++) {
            require(address(websiteAvailablePlugins[i]) != address(plugin), "Plugin already added");
        }

        websiteAvailablePlugins.push(plugin);
        if(addAsNewWebsiteDefaultPlugin) {
            newWebsiteDefaultPlugins.push(plugin);
        }
    }

    struct IVersionableWebsitePluginWithInfos {
        IVersionableWebsitePlugin plugin;
        IVersionableWebsitePlugin.Infos infos;
        bool interfaceValid;
        bool isDefaultPlugin;
    }
    function getWebsitePlugins(bytes4[] memory interfaceFilters) public view returns (IVersionableWebsitePluginWithInfos[] memory) {
        IVersionableWebsitePluginWithInfos[] memory plugins = new IVersionableWebsitePluginWithInfos[](websiteAvailablePlugins.length);

        for(uint i = 0; i < websiteAvailablePlugins.length; i++) {
            // Is interface supported?
            bool interfaceValid = (interfaceFilters.length == 0);
            for(uint j = 0; j < interfaceFilters.length; j++) {
                if(websiteAvailablePlugins[i].supportsInterface(interfaceFilters[j])) {
                    interfaceValid = true;
                    break;
                }
            }

            // Is it a default plugin?
            bool isDefaultPlugin = false;
            for(uint j = 0; j < newWebsiteDefaultPlugins.length; j++) {
                if(address(websiteAvailablePlugins[i]) == address(newWebsiteDefaultPlugins[j])) {
                    isDefaultPlugin = true;
                    break;
                }
            }

            plugins[i] = IVersionableWebsitePluginWithInfos({
                plugin: websiteAvailablePlugins[i],
                infos: websiteAvailablePlugins[i].infos(),
                interfaceValid: interfaceValid,
                isDefaultPlugin: isDefaultPlugin
            });
        }

        return plugins;
    }

    function removeWebsitePlugin(IVersionableWebsitePlugin plugin) public onlyOwner {
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
