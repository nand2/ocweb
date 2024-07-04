// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ResourceRequestWebsite.sol";
import "../library/LibStrings.sol";

/**
 * Simple proxy to view non-live frontend versions (which need to be authorized
 * by the owner of the target contract). 
 */
contract ClonableFrontendVersionViewer {
    IDecentralizedApp public target;
    uint public frontendVersionIndex;

    function initialize(IDecentralizedApp _target, uint _frontendVersionIndex) public {
        require(address(target) == address(0), "Already initialized");
        target = _target;
        frontendVersionIndex = _frontendVersionIndex;
    }

    function _processWeb3Request(string[] memory resource, KeyValue[] memory params) internal virtual view returns (uint statusCode, string memory body, KeyValue[] memory headers) {
        
        // We prefix the resource with /__frontend_version/{frontendVersionIndex}
        string[] memory newResource = new string[](resource.length + 2);
        newResource[0] = "__frontend_version";
        newResource[1] = LibStrings.toString(frontendVersionIndex);
        for(uint i = 0; i < resource.length; i++) {
            newResource[i + 2] = resource[i];
        }

        // Call the target contract with the new resource
        return target.request(newResource, params);
    }
}