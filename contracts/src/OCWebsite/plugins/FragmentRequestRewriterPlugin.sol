// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../interfaces/IVersionableWebsite.sol";
import "../../library/LibStrings.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract FragmentRequestRewriterPlugin is ERC165, IVersionableWebsitePlugin {
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
                name: "fragmentRequestRewriter",
                version: "0.1.0",
                title: "Fragment request rewriter",
                subTitle: "Temporary: Serve index.html on /#/",
                author: "nand",
                homepage: ""
            });
    }

    function rewriteWeb3Request(IVersionableWebsite website, uint frontendIndex, string[] memory resource, KeyValue[] memory params) external view returns (bool rewritten, string[] memory newResource, KeyValue[] memory newParams) {
        if(resource.length == 1 && LibStrings.compare(resource[0], "#")) {
            return (true, new string[](0), new KeyValue[](0));
        }

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
        return (0, "", new KeyValue[](0));
    }

    function copyFrontendSettings(IVersionableWebsite website, uint fromFrontendIndex, uint toFrontendIndex) public {
        require(address(website) == msg.sender || website.owner() == msg.sender, "Not the owner");
    }
}