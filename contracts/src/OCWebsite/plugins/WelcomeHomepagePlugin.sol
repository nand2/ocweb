// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../../interfaces/IVersionableWebsite.sol";
import "../../library/LibStrings.sol";
import "../../interfaces/IDecentralizedApp.sol";

contract WelcomeHomepagePlugin is ERC165, IVersionableWebsitePlugin {
    IDecentralizedApp public adminWebsite;

    constructor(IDecentralizedApp _adminWebsite) {
        adminWebsite = _adminWebsite;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return
            interfaceId == type(IVersionableWebsitePlugin).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function infos() external view returns (Infos memory) {
        return
            Infos({
                name: "welcomeHomepage",
                version: "0.1.0",
                title: "Welcome Homepage",
                subTitle: "Remove when starting to build your website!",
                author: "nand",
                homepage: "",
                dependencies: new IVersionableWebsitePlugin[](0)
            });
    }

    function rewriteWeb3Request(IVersionableWebsite website, uint frontendIndex, string[] memory resource, KeyValue[] memory params) external view returns (bool rewritten, string[] memory newResource, KeyValue[] memory newParams) {
        return (false, new string[](0), new KeyValue[](0));
    }

    function processWeb3Request(
        IVersionableWebsite website,
        uint frontendIndex,
        string[] memory resource,
        KeyValue[] memory params
    )
        external view override returns (uint statusCode, string memory body, KeyValue[] memory headers)
    {
        // Only override index.html (which is packaged with the JS and CSS)
        if(resource.length == 0 || (resource.length == 1 && LibStrings.compare(resource[0], "index.html"))) {

            (statusCode, body, headers) = adminWebsite.request(new string[](0), params);

            return (statusCode, body, headers);
        }
    }

    function copyFrontendSettings(IVersionableWebsite website, uint fromFrontendIndex, uint toFrontendIndex) public {
    }
}