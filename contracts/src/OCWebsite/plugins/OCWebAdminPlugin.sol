// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../../interfaces/IVersionableWebsite.sol";
import "../../library/LibStrings.sol";
import "../../interfaces/IDecentralizedApp.sol";

contract OCWebAdminPlugin is ERC165, IVersionableWebsitePlugin {
    IDecentralizedApp public adminWebsite;
    IVersionableWebsitePlugin public injectedVariablesPlugin;

    constructor(IDecentralizedApp _adminWebsite, IVersionableWebsitePlugin _injectedVariablesPlugin) {
        adminWebsite = _adminWebsite;
        injectedVariablesPlugin = _injectedVariablesPlugin;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return
            interfaceId == type(IVersionableWebsitePlugin).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function infos() external view returns (Infos memory) {
        IVersionableWebsitePlugin[] memory dependencies = new IVersionableWebsitePlugin[](1);
        dependencies[0] = injectedVariablesPlugin;

        return
            Infos({
                name: "ocWebAdmin",
                version: "0.1.1",
                title: "Admin interface",
                subTitle: "Served at the /admin/ path",
                author: "nand",
                homepage: "web3://ocweb.eth/",
                dependencies: dependencies,
                adminPanels: new AdminPanel[](0)
            });
    }

    function rewriteWeb3Request(IVersionableWebsite website, uint websiteVersionIndex, string[] memory resource, KeyValue[] memory params) external view returns (bool rewritten, string[] memory newResource, KeyValue[] memory newParams) {
        return (false, new string[](0), new KeyValue[](0));
    }

    function processWeb3Request(
        IVersionableWebsite website,
        uint websiteVersionIndex,
        string[] memory resource,
        KeyValue[] memory params
    )
        external view override returns (uint statusCode, string memory body, KeyValue[] memory headers)
    {
        if (resource.length >= 1 && LibStrings.compare(resource[0], "admin")) {

            string[] memory newResource = new string[](resource.length - 1);
            for(uint j = 1; j < resource.length; j++) {
                newResource[j - 1] = resource[j];
            }

            (statusCode, body, headers) = adminWebsite.request(newResource, params);

            // If there is a "Cache-control: evm-events" header, we will replace it with 
            // "Cache-control: evm-events=<addressOfAdminWebsite><newResourcePath>"
            // That way, we indicate that the contract emitting the cache clearing events is 
            // the admin website
            for(uint i = 0; i < headers.length; i++) {
                if(LibStrings.compare(headers[i].key, "Cache-control") && LibStrings.compare(headers[i].value, "evm-events")) {
                    string memory path = "/";
                    for(uint j = 0; j < newResource.length; j++) {
                        path = string.concat(path, newResource[j]);
                        if(j < newResource.length - 1) {
                            path = string.concat(path, "/");
                        }
                    }

                    headers[i].value = string.concat("evm-events=\"", LibStrings.toHexString(address(adminWebsite)), path, "\"");
                }
            }

            return (statusCode, body, headers);
        }
    }

    function copyFrontendSettings(IVersionableWebsite website, uint fromFrontendIndex, uint toFrontendIndex) public {
        require(address(website) == msg.sender);
    }
}