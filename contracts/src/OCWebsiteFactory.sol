// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import { LibStrings } from "./library/LibStrings.sol";
import "./OCWebsite/OCWebsite.sol";
import "./OCWebsite/ClonableOCWebsite.sol";
import "./OCWebsiteFactoryToken.sol";
import "./interfaces/IStorageBackend.sol";

interface IFactoryExtension {
  function getName() external view returns (string memory);
}

contract OCWebsiteFactory is ERC721Enumerable {
    OCWebsite public immutable factoryFrontend;
    OCWebsiteFactoryToken public immutable factoryToken;

    OCWebsite public immutable websiteImplementation;

    OCWebsite[] public websites;
    mapping(OCWebsite=> uint) public websiteToIndex;
    event WebsiteCreated(uint indexed websiteId, address website);

    string public topdomain;
    string public domain;

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
        string topdomain;
        string domain;
        OCWebsite factoryFrontend;
        OCWebsiteFactoryToken factoryToken;
        ClonableOCWebsite websiteImplementation;
    }
    constructor(ConstructorParams memory _params) ERC721Enumerable("OCWebsite", "OCW") {
        owner = msg.sender;

        topdomain = _params.topdomain;
        domain = _params.domain;

        factoryFrontend = _params.factoryFrontend;
        factoryToken = _params.factoryToken;
        websiteImplementation = _params.websiteImplementation;

        // Adding some backlinks
        // factoryFrontend.setBlogFactory(this);
        factoryToken.setWebsiteFactory(this);
    }

    /**
     * Add a new website
     */
    function addWebsite() public payable returns(address) {

        ClonableOCWebsite newWebsite = ClonableOCWebsite(Clones.clone(address(websiteImplementation)));

        newWebsite.initialize(this);
        websites.push(newWebsite);
        websiteToIndex[newWebsite] = websites.length - 1;

        // Mint an ERC721 token
        _safeMint(msg.sender, websites.length - 1);

        emit WebsiteCreated(websites.length - 1, address(newWebsite));

        return address(newWebsite);
    }


    /**
     * For frontend: Get a batch of parameters in a single call
     */
    // function getParameters() public view returns (string memory _topdomain, string memory _domain, address _frontend, address _blogImplementation, uint subdomainFee) {
    //     return (topdomain, domain, address(factoryFrontend), address(blogImplementation), getSubdomainFee());
    // }

    // /**
    //  * For frontend: Get the list of blogs
    //  */
    // struct BlogInfo {
    //     uint256 id;
    //     address blogAddress;
    //     address blogFrontendAddress;
    //     string subdomain;
    //     string title;
    //     string description;
    //     uint256 postCount;
    // }
    // function getBlogInfoList(uint startIndex, uint limit) public view returns (BlogInfo[] memory blogInfos, uint256 blogCount) {
    //     uint256 blogsCount = blogs.length;
    //     uint256 actualLimit = limit;
    //     if(startIndex >= blogsCount) {
    //         actualLimit = 0;
    //     } else if(startIndex + limit > blogsCount) {
    //         actualLimit = blogsCount - startIndex;
    //     }

    //     blogInfos = new BlogInfo[](actualLimit);
    //     for(uint i = 0; i < actualLimit; i++) {
    //         DBlog blog = blogs[startIndex + i];
    //         blogInfos[i] = BlogInfo({
    //             id: startIndex + i,
    //             blogAddress: address(blog),
    //             blogFrontendAddress: address(blog.frontend()),
    //             subdomain: blog.subdomain(),
    //             title: blog.title(),
    //             description: blog.description(),
    //             postCount: blog.getPostCount()
    //         });
    //     }

    //     return (blogInfos, blogsCount);
    // }

    // function getBlogAddress(uint256 index) public view returns (address) {
    //     require(index < blogs.length, "Blog does not exist");

    //     return address(blogs[index]);
    // }
    
    // function getBlogCount() public view returns (uint256) {
    //     return blogs.length;
    // }


    //
    // Storage backends
    //

    function addStorageBackend(IStorageBackend storageBackend) public onlyOwner {
        // Make sure it is not inserted yet
        // Make sure name is unique
        for(uint i = 0; i < storageBackends.length; i++) {
            require(address(storageBackends[i]) != address(storageBackend), "Storage backend already added");
            require(LibStrings.compare(storageBackends[i].backendName(), storageBackend.backendName()) == false, "Storage backend name already used");
        }

        storageBackends.push(storageBackend);
    }

    function getStorageBackendIndexByName(string memory name) public view returns (uint16 index) {
        bool found = false;
        for(uint16 i = 0; i < storageBackends.length; i++) {
            if(LibStrings.compare(storageBackends[i].backendName(), name)) {
                index = i;
                found = true;
            }
        }
        require(found, "Storage backend not found");

        return index;
    }

    function getStorageBackendByName(string memory name) public view returns (IStorageBackend) {
        return storageBackends[getStorageBackendIndexByName(name)];
    }

    function getStorageBackendNames() public view returns (string[] memory) {
        string[] memory names = new string[](storageBackends.length);
        for(uint i = 0; i < storageBackends.length; i++) {
            names[i] = storageBackends[i].backendName();
        }

        return names;
    }


    //
    // ERC721
    //

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(tokenId < websites.length, "Token does not exist");

        return factoryToken.tokenURI(tokenId);
    }

    function tokenSVG(uint tokenId) public view returns (string memory) {
        require(tokenId < websites.length, "Token does not exist");

        return factoryToken.tokenSVG(tokenId);
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
