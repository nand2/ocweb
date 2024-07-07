// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../interfaces/IVersionableStaticWebsite.sol";
import "../../library/LibStrings.sol";

contract ProxiedWebsitesPlugin is IVersionableStaticWebsitePlugin {
    struct ProxiedWebsite {
        // An web3:// resource request mode website, cf ERC-6944 / ERC-5219
        IDecentralizedApp website;
        string[] localPrefix;
        string[] remotePrefix;
    }
    mapping(IVersionableStaticWebsite => mapping(uint => ProxiedWebsite[])) public proxiedWebsites;

    function infos() external view returns (Infos memory) {
        return
            Infos({
                name: "proxiedWebsites",
                version: "0.1.0",
                title: "Mappings to external websites",
                subTitle: "Serve content from other websites",
                author: "nand",
                homepage: "web3://ocweb.eth"
            });
    }

    function processWeb3Request(
        IVersionableStaticWebsite website,
        uint frontendIndex,
        string[] memory resource,
        KeyValue[] memory params
    )
        public view override returns (uint statusCode, string memory body, KeyValue[] memory headers)
    {
        ProxiedWebsite[] storage frontendProxiedWebsites = proxiedWebsites[website][frontendIndex];

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

    function copyFrontendSettings(IVersionableStaticWebsite website, uint fromFrontendIndex, uint toFrontendIndex) public {
        require(website.owner() == msg.sender, "Not the owner");

        ProxiedWebsite[] storage vars = proxiedWebsites[website][fromFrontendIndex];
        for (uint i = 0; i < vars.length; i++) {
            proxiedWebsites[website][toFrontendIndex].push(vars[i]);
        }
    }

    function addProxiedWebsite(IVersionableStaticWebsite website, uint frontendIndex, IDecentralizedApp proxiedWebsite, string[] memory localPrefix, string[] memory remotePrefix) public {
        require(website.owner() == msg.sender, "Not the owner");

        IFrontendLibrary frontendLibrary = website.getFrontendLibrary();
        require(frontendLibrary.isLocked() == false, "Frontend library is locked");

        require(frontendIndex < frontendLibrary.getFrontendVersionCount(), "Frontend index out of bounds");
        FrontendFilesSet memory frontendVersion = frontendLibrary.getFrontendVersion(frontendIndex);
        require(frontendVersion.locked == false, "Frontend version is locked");

        // Ensure the localPrefix is not used yet
        ProxiedWebsite[] storage frontendProxiedWebsites = proxiedWebsites[website][frontendIndex];
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

    function getProxiedWebsites(IVersionableStaticWebsite website, uint frontendIndex) public view returns (ProxiedWebsite[] memory) {
        return proxiedWebsites[website][frontendIndex];
    }

    function removeProxiedWebsite(IVersionableStaticWebsite website, uint frontendIndex, uint index) public {
        require(website.owner() == msg.sender, "Not the owner");

        IFrontendLibrary frontendLibrary = website.getFrontendLibrary();
        require(frontendLibrary.isLocked() == false, "Frontend library is locked");

        require(frontendIndex < frontendLibrary.getFrontendVersionCount(), "Frontend index out of bounds");
        FrontendFilesSet memory frontendVersion = frontendLibrary.getFrontendVersion(frontendIndex);
        require(frontendVersion.locked == false, "Frontend version is locked");

        ProxiedWebsite[] storage frontendProxiedWebsites = proxiedWebsites[website][frontendIndex];
        require(index < frontendProxiedWebsites.length, "Index out of bounds");

        frontendProxiedWebsites[index] = frontendProxiedWebsites[frontendProxiedWebsites.length - 1];
        frontendProxiedWebsites.pop();
    }
}