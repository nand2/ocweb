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
    // The ocweb.eth frontend website
    OCWebsite public website;
    // The contract handing the generation of the ERC721 token images
    OCWebsiteFactoryToken public factoryToken;

    // The contract that will be cloned to create new websites
    ClonableOCWebsite public websiteImplementation;

    // Created websites
    OCWebsite[] public websites;
    mapping(OCWebsite => uint) public websiteToIndex;
    event WebsiteCreated(uint indexed websiteId, address website);
    
    ClonableWebsiteVersionViewer public websiteVersionViewerImplementation;

    string public topdomain;
    string public domain;
    string public domain2;
    mapping(OCWebsite => string) public websiteToSubdomain;
    mapping(bytes32 => OCWebsite) public subdomainNameHashToWebsite;

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
     * @param _domain ocweb
     * @param _domain2 <chainShortName>
     */
    struct ConstructorParams {
        address owner;
        string topdomain;
        string domain;
        string domain2;
        OCWebsiteFactoryToken factoryToken;
        ClonableOCWebsite websiteImplementation;
        ClonableWebsiteVersionViewer websiteVersionViewerImplementation;
    }
    constructor(ConstructorParams memory _params) ERC721("OCWebsite", "OCW") {
        owner = _params.owner;

        topdomain = _params.topdomain;
        domain = _params.domain;
        domain2 = _params.domain2;

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
    function mintWebsite(string memory subdomain) public payable returns(ClonableOCWebsite) {

        // Subdomain: Valid and available?
        (bool isValidAndAvailable, string memory reason) = isSubdomainValidAndAvailable(subdomain);
        require(isValidAndAvailable, reason);

        ClonableOCWebsite newWebsite = ClonableOCWebsite(Clones.clone(address(websiteImplementation)));

        newWebsite.initialize(msg.sender, address(this), websiteVersionViewerImplementation, newWebsiteDefaultPlugins);
        websites.push(newWebsite);
        websiteToIndex[newWebsite] = websites.length - 1;

        // Subdomain: Adding the website -> subdomain mapping
        websiteToSubdomain[newWebsite] = subdomain;
        // Subdomain: Adding the namehash -> website mapping for our custom resolver
        bytes32 subdomainNameHash = computeSubdomainNameHash(subdomain);
        subdomainNameHashToWebsite[subdomainNameHash] = newWebsite;

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
    // Handle subdomains
    //

    /**
     * Is a subdomain valid and available? If false, the reason is given, to be used by frontends.
     */
    function isSubdomainValidAndAvailable(string memory subdomain) public view returns (bool result, string memory reason) {
        (result, reason) = isSubdomainValid(subdomain);
        if (!result) {
            return (result, reason);
        }

        bytes32 subdomainNameHash = computeSubdomainNameHash(subdomain);
        if (address(subdomainNameHashToWebsite[subdomainNameHash]) != address(0)) {
            return (false, "Subdomain is already used");
        }

        return (true, "");
    }

    /**
     * Is a subdomain valid? If false, the reason is given, to be used by frontends.
     * Ideally we should use the same normalization as ENS (ENSIP-15) but we aim at a very
     * light frontend that will not be often updated (if ever), so we will use a simple
     * and restrictive set of rules : a-z, 0-9, - chars, min 3 chars, max 20 chars
     */
    function isSubdomainValid(string memory subdomain) public pure returns (bool, string memory) {
        bytes memory b = bytes(subdomain);
        
        if(b.length < 3) {
            return (false, "Subdomain is too short (min 3 chars)");
        } 
        if(b.length > 14) {
            return (false, "Subdomain is too long (max 14 chars)");
        }
        
        for (uint i; i < b.length; i++) {
            bytes1 char = b[i];
            if (!(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x2D) //-
            ) {
                return (false, "Subdomain contains invalid characters. Only a-z, 0-9, - are allowed.");
            }
        }

        return (true, "");
    }

    /**
     * For a given subdomain of <domain2>.<domain>.eth, compute its namehash.
     * If not subdomain is given, return the namehash of <domain2>.<domain>.eth
     */
    function computeSubdomainNameHash(string memory subdomain) public view returns (bytes32) {
        bytes32 emptyNamehash = 0x00;
        bytes32 topdomainNamehash = keccak256(abi.encodePacked(emptyNamehash, keccak256(abi.encodePacked(topdomain))));
		bytes32 domainNamehash = keccak256(abi.encodePacked(topdomainNamehash, keccak256(abi.encodePacked(domain))));
        bytes32 domain2Namehash = keccak256(abi.encodePacked(domainNamehash, keccak256(abi.encodePacked(domain2))));

        if(bytes(subdomain).length == 0) {
            return domain2Namehash;
        }
		
        return keccak256(abi.encodePacked(domain2Namehash, keccak256(abi.encodePacked(subdomain))));
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

    struct DetailedToken {
        uint tokenId;
        address contractAddress;
        string subdomain;
        string tokenSVG;
    }
    function detailedTokensOfOwner(address user, uint startIndex, uint count) public view returns (DetailedToken[] memory tokens) {
        uint tokenCount = balanceOf(user);
        require(startIndex == 0 || startIndex < tokenCount, "Index out of bounds");
        
        if(count == 0) {
            count = tokenCount - startIndex;
        }
        else if(startIndex + count > tokenCount) {
            count = tokenCount - startIndex;
        }

        tokens = new DetailedToken[](count);
        for(uint i = 0; i < count; i++) {
            uint tokenId = tokenOfOwnerByIndex(user, i + startIndex);
            tokens[i] = DetailedToken({
                tokenId: tokenId,
                contractAddress: address(websites[tokenId]),
                subdomain: websiteToSubdomain[websites[tokenId]],
                tokenSVG: factoryToken.tokenSVG(tokenId)
            });
        }

        return tokens;
    }

    function detailedTokens(uint startIndex, uint count) public view returns (DetailedToken[] memory tokens) {
        uint tokenCount = totalSupply();
        require(startIndex == 0 || startIndex < tokenCount, "Index out of bounds");
        
        if(count == 0) {
            count = tokenCount - startIndex;
        }
        else if(startIndex + count > tokenCount) {
            count = tokenCount - startIndex;
        }

        tokens = new DetailedToken[](count);
        for(uint i = 0; i < count; i++) {
            tokens[i] = DetailedToken({
                tokenId: i + startIndex,
                contractAddress: address(websites[i + startIndex]),
                subdomain: websiteToSubdomain[websites[i + startIndex]],
                tokenSVG: factoryToken.tokenSVG(i + startIndex)
            });
        }

        return tokens;
    }

    function detailedToken(uint tokenId) public view returns (DetailedToken memory token) {
        return DetailedToken({
            tokenId: tokenId,
            contractAddress: address(websites[tokenId]),
            subdomain: websiteToSubdomain[websites[tokenId]],
            tokenSVG: factoryToken.tokenSVG(tokenId)
        });
    }

    function tokenWeb3Address(uint tokenId) public view returns (string memory) {
        require(tokenId < websites.length, "Token does not exist");

        string memory web3Address = string.concat(
            "web3://", 
            LibStrings.toHexString(address(websites[tokenId])));

        uint chainId = block.chainid;
        if(chainId > 1) {
            web3Address = string.concat(web3Address, ":", LibStrings.toString(chainId));
        }

        return web3Address;
    }

    //
    // Admin
    //

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    /**
     * Update the website implementation of newly minted websites.
     * Existing websites are not affected.
     */
    function setWebsiteImplementation(ClonableOCWebsite _websiteImplementation) public onlyOwner {
        websiteImplementation = _websiteImplementation;
    }

    /**
     * Update the contract handling the generation of ERC721 token images.
     */
    function setFactoryToken(OCWebsiteFactoryToken _factoryToken) public onlyOwner {
        factoryToken = _factoryToken;
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
