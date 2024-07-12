// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../interfaces/IVersionableWebsite.sol";
import "../../library/LibStrings.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract WelcomeHomepagePlugin is ERC165, IVersionableWebsitePlugin {

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
                homepage: ""
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
        if(resource.length == 0) {
            body = "<html><body>"
                "<h1>TODO: Welcome to your on-chain website!</h1>"
                "<p>This is the default homepage of your website.</p>"
                "<p>You can go to /admin to administer your website (TODO, will link to the pre-opened ocweb.eth website customized for 1 website)</p>"
                "<p>TODO: Add explanations, examples about web3://</p>"
                "<p>Remove this plugin when you start building your website.</p>"
            "</body></html>";
            return (200, body, new KeyValue[](0));
        }

        return (0, "", new KeyValue[](0));
    }

    function copyFrontendSettings(IVersionableWebsite website, uint fromFrontendIndex, uint toFrontendIndex) public {
    }
}