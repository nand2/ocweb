// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ResourceRequestWebsite.sol";
import "../library/LibStrings.sol";
import "../interfaces/IVersionableWebsite.sol";
import "../interfaces/IERC7761.sol";

/**
 * Simple proxy to view non-live frontend versions (which need to be authorized
 * by the owner of the target contract). 
 */
contract ClonableWebsiteVersionViewer is IVersionableWebsiteViewer, ResourceRequestWebsite {
    IVersionableWebsite public target;
    uint public websiteVersionIndex;

    function initialize(IVersionableWebsite _target, uint _websiteVersionIndex) public {
        require(address(target) == address(0), "Already initialized");
        target = _target;
        websiteVersionIndex = _websiteVersionIndex;
    }

    function request(string[] memory resource, KeyValue[] memory params) external override(ResourceRequestWebsite, IDecentralizedApp) view returns (uint statusCode, string memory body, KeyValue[] memory headers) {

        // Call the target contract with the new resource
        return target.requestWebsiteVersion(websiteVersionIndex, resource, params);
    }

    /**
     * ERC-7761 support: Plugins can call this function to emit the clear path cache event
     * Paths must be relative to the website root e.g. "/", "/index.html", "/css/style.css", ...
     */
    function clearPathCache(string[] memory paths) public {
        // Only the target contract can call this function
        require(msg.sender == address(target), "Only the target contract can call this function");
        
        emit ClearPathCache(paths);
    }
}