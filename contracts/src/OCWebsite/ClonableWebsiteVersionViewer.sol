// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ResourceRequestWebsite.sol";
import "../library/LibStrings.sol";

/**
 * Simple proxy to view non-live frontend versions (which need to be authorized
 * by the owner of the target contract). 
 */
contract ClonableWebsiteVersionViewer is ResourceRequestWebsite {
    IDecentralizedApp public target;
    uint public websiteVersionIndex;

    function initialize(IDecentralizedApp _target, uint _websiteVersionIndex) public {
        require(address(target) == address(0), "Already initialized");
        target = _target;
        websiteVersionIndex = _websiteVersionIndex;
    }

    function request(string[] memory resource, KeyValue[] memory params) external override view returns (uint statusCode, string memory body, KeyValue[] memory headers) {
        
        // We prefix the resource with /__website_version/{websiteVersionIndex}
        string[] memory newResource = new string[](resource.length + 2);
        newResource[0] = "__website_version";
        newResource[1] = LibStrings.toString(websiteVersionIndex);
        for(uint i = 0; i < resource.length; i++) {
            newResource[i + 2] = resource[i];
        }

        // Call the target contract with the new resource
        return target.request(newResource, params);
    }
}