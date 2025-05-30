// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../interfaces/IVersionableWebsite.sol";
import "../../library/LibStrings.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract InjectedVariablesPlugin is ERC165, IVersionableWebsitePlugin {
    struct KeyValueVariable {
        string key;
        string value;
    }
    mapping(IVersionableWebsite => mapping(uint => KeyValueVariable[])) public variables;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return
            interfaceId == type(IVersionableWebsitePlugin).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function infos() external view returns (Infos memory) {
        return
            Infos({
                name: "injectedVariables",
                version: "0.1.0",
                title: "Injected Variables",
                subTitle: "Variables accessible via the /variables.json path",
                author: "nand",
                homepage: "web3://ocweb.eth/",
                dependencies: new IVersionableWebsitePlugin[](0),
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
        if(resource.length == 1 && LibStrings.compare(resource[0], "variables.json")) {
            // We output all the static contract addresses and ourselves
            // Manual JSON serialization, safe with the vars we encode
            if(block.chainid == 1) {
                body = string.concat('{'
                    '"self":"', LibStrings.toHexString(address(website)), '"');
            }
            else {
                body = string.concat('{'
                    '"self":"', LibStrings.toHexString(address(website)), ':', LibStrings.toString(block.chainid), '"');
            }

            KeyValueVariable[] memory injectedVariables = variables[website][websiteVersionIndex];
            for(uint i = 0; i < injectedVariables.length; i++) {
                body = string.concat(body, ','
                '"', injectedVariables[i].key, '":"', injectedVariables[i].value, '"');
            }
            body = string.concat(body, '}');
            
            statusCode = 200;
            headers = new KeyValue[](3);
            headers[0].key = "Content-type";
            headers[0].value = "application/json";
            headers[1].key = "Cache-control";
            headers[1].value = "evm-events";
            headers[2].key = "ETag";
            headers[2].value = LibStrings.toHexString(uint(keccak256(abi.encodePacked(body))), 32);
            return (statusCode, body, headers);
        }
    }

    function copyFrontendSettings(IVersionableWebsite website, uint fromFrontendIndex, uint toFrontendIndex) public {
        require(address(website) == msg.sender);

        KeyValueVariable[] storage vars = variables[website][fromFrontendIndex];
        for (uint i = 0; i < vars.length; i++) {
            variables[website][toFrontendIndex].push(vars[i]);
        }
    }

    function addVariable(IVersionableWebsite website, uint websiteVersionIndex, string memory key, string memory value) public {
        require(address(website) == msg.sender || website.owner() == msg.sender, "Not the owner");

        require(website.isLocked() == false, "Website is locked");

        require(websiteVersionIndex < website.getWebsiteVersionCount(), "Website version out of bounds");
        IVersionableWebsite.WebsiteVersion memory websiteVersion = website.getWebsiteVersion(websiteVersionIndex);
        require(websiteVersion.locked == false, "Website version is locked");

        // Reserved keys: "self"
        require(LibStrings.compare(key, "self") == false, "Key reserved");
        // Ensure the key is not used yet
        KeyValueVariable[] storage vars = variables[website][websiteVersionIndex];
        for (uint i = 0; i < vars.length; i++) {
            require(LibStrings.compare(vars[i].key, key) == false, "Key already used");
        }

        vars.push(KeyValueVariable({key: key, value: value}));

        // Send an event to clear the cache of the file
        string[] memory prefixedPaths = new string[](1);
        prefixedPaths[0] = "/variables.json";
        website.clearPathCache(websiteVersionIndex, prefixedPaths);
    }

    function getVariables(IVersionableWebsite website, uint websiteVersionIndex) public view returns (KeyValueVariable[] memory) {
        return variables[website][websiteVersionIndex];
    }

    function removeVariable(IVersionableWebsite website, uint websiteVersionIndex, string memory key) public {
        require(address(website) == msg.sender || website.owner() == msg.sender, "Not the owner");

        require(website.isLocked() == false, "Website is locked");

        require(websiteVersionIndex < website.getWebsiteVersionCount(), "Website version out of bounds");
        IVersionableWebsite.WebsiteVersion memory websiteVersion = website.getWebsiteVersion(websiteVersionIndex);
        require(websiteVersion.locked == false, "Website version is locked");

        KeyValueVariable[] storage vars = variables[website][websiteVersionIndex];
        for (uint i = 0; i < vars.length; i++) {
            if(LibStrings.compare(vars[i].key, key)) {
                vars[i] = vars[vars.length - 1];
                vars.pop();
                return;
            }
        }

        // Send an event to clear the cache of the file
        string[] memory prefixedPaths = new string[](1);
        prefixedPaths[0] = "/variables.json";
        website.clearPathCache(websiteVersionIndex, prefixedPaths);
    }
}