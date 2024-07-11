// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../interfaces/IVersionableWebsite.sol";
import "../../library/LibStrings.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract ProxiedWebsitesPlugin is ERC165, IVersionableWebsitePlugin {
    struct ProxiedWebsite {
        // An web3:// resource request mode website, cf ERC-6944 / ERC-5219
        IDecentralizedApp website;
        string[] localPrefix;
        string[] remotePrefix;
    }
    mapping(IVersionableWebsite => mapping(uint => ProxiedWebsite[])) public proxiedWebsites;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return
            interfaceId == type(IVersionableWebsitePlugin).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function infos() external view returns (Infos memory) {
        return
            Infos({
                name: "proxiedWebsites",
                version: "0.1.0",
                title: "Mappings to external websites",
                subTitle: "Serve content from other websites",
                author: "nand",
                homepage: "web3://ocweb.eth/"
            });
    }

    function rewriteWeb3Request(IVersionableWebsite website, uint websiteVersionIndex, string[] memory resource, KeyValue[] memory params) external view returns (bool rewritten, string[] memory newResource, KeyValue[] memory newParams) {
        return (false, new string[](0), new KeyValue[](0));
    }

    function processWeb3RequestBeforeStaticContent(
        IVersionableWebsite website,
        uint websiteVersionIndex,
        string[] memory resource,
        KeyValue[] memory params
    )
        external view override returns (uint statusCode, string memory body, KeyValue[] memory headers)
    {
        return (0, "", new KeyValue[](0));
    }

    function processWeb3RequestAfterStaticContent(
        IVersionableWebsite website,
        uint websiteVersionIndex,
        string[] memory resource,
        KeyValue[] memory params
    )
        external view override returns (uint statusCode, string memory body, KeyValue[] memory headers)
    {
        ProxiedWebsite[] storage frontendProxiedWebsites = proxiedWebsites[website][websiteVersionIndex];

        for(uint i = 0; i < frontendProxiedWebsites.length; i++) {
            ProxiedWebsite memory proxiedWebsite = frontendProxiedWebsites[i];
            if(resource.length < proxiedWebsite.localPrefix.length) {
                continue;
            }

            bool prefixMatch = true;
            for(uint j = 0; j < proxiedWebsite.localPrefix.length; j++) {
                if(LibStrings.compare(resource[j], proxiedWebsite.localPrefix[j]) == false) {
                    prefixMatch = false;
                    break;
                }
            }

            if(prefixMatch) {
                string[] memory newResource = new string[](resource.length - proxiedWebsite.localPrefix.length + proxiedWebsite.remotePrefix.length);
                for(uint j = 0; j < proxiedWebsite.remotePrefix.length; j++) {
                    newResource[j] = proxiedWebsite.remotePrefix[j];
                }
                for(uint j = 0; j < resource.length - proxiedWebsite.localPrefix.length; j++) {
                    newResource[j + proxiedWebsite.remotePrefix.length] = resource[j + proxiedWebsite.localPrefix.length];
                }

                (statusCode, body, headers) = proxiedWebsite.website.request(newResource, params);

                if (statusCode != 0 && statusCode != 404) {
                    return (statusCode, body, headers);
                }
            }
        }
    }

    function copyFrontendSettings(IVersionableWebsite website, uint fromFrontendIndex, uint toFrontendIndex) public {
        require(address(website) == msg.sender);

        ProxiedWebsite[] storage vars = proxiedWebsites[website][fromFrontendIndex];
        for (uint i = 0; i < vars.length; i++) {
            proxiedWebsites[website][toFrontendIndex].push(vars[i]);
        }
    }

    function addProxiedWebsite(IVersionableWebsite website, uint websiteVersionIndex, IDecentralizedApp proxiedWebsite, string[] memory localPrefix, string[] memory remotePrefix) public {
        require(address(website) == msg.sender || website.owner() == msg.sender, "Not the owner");

        require(website.isLocked() == false, "Website is locked");

        require(websiteVersionIndex < website.getWebsiteVersionCount(), "Website version out of bounds");
        IVersionableWebsite.WebsiteVersion memory websiteVersion = website.getWebsiteVersion(websiteVersionIndex);
        require(websiteVersion.locked == false, "Website version is locked");

        // Ensure the localPrefix is not used yet
        ProxiedWebsite[] storage frontendProxiedWebsites = proxiedWebsites[website][websiteVersionIndex];
        for (uint i = 0; i < frontendProxiedWebsites.length; i++) {
            if(frontendProxiedWebsites[i].localPrefix.length == localPrefix.length) {
                bool matched = true;
                for(uint j = 0; j < localPrefix.length; j++) {
                    if(LibStrings.compare(frontendProxiedWebsites[i].localPrefix[j], localPrefix[j]) == false) {
                        matched = false;
                        break;
                    }
                }
                require(matched == false, "Local prefix already used");
            }
        }

        frontendProxiedWebsites.push(ProxiedWebsite({website: proxiedWebsite, localPrefix: localPrefix, remotePrefix: remotePrefix}));
    }

    function getProxiedWebsites(IVersionableWebsite website, uint websiteVersionIndex) public view returns (ProxiedWebsite[] memory) {
        return proxiedWebsites[website][websiteVersionIndex];
    }

    function removeProxiedWebsite(IVersionableWebsite website, uint websiteVersionIndex, uint index) public {
        require(address(website) == msg.sender || website.owner() == msg.sender, "Not the owner");

        require(website.isLocked() == false, "Website is locked");

        require(websiteVersionIndex < website.getWebsiteVersionCount(), "Website version out of bounds");
        IVersionableWebsite.WebsiteVersion memory websiteVersion = website.getWebsiteVersion(websiteVersionIndex);
        require(websiteVersion.locked == false, "Website version is locked");

        ProxiedWebsite[] storage frontendProxiedWebsites = proxiedWebsites[website][websiteVersionIndex];
        require(index < frontendProxiedWebsites.length, "Index out of bounds");

        frontendProxiedWebsites[index] = frontendProxiedWebsites[frontendProxiedWebsites.length - 1];
        frontendProxiedWebsites.pop();
    }
}