// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Ownable } from "../library/Ownable.sol";

import "./ResourceRequestWebsite.sol";

contract ProxyWebsite is ResourceRequestWebsite, Ownable {
  ResourceRequestWebsite[] public proxiedWebsites;
  bool public proxiedWebsitesLocked = false;

  constructor() {}

  function addProxiedWebsite(ResourceRequestWebsite website) public onlyOwner {
    require(proxiedWebsitesLocked == false, "Locked");
    proxiedWebsites.push(website);
  }

  function getProxiedWebsites() public view returns (ResourceRequestWebsite[] memory) {
    return proxiedWebsites;
  }

  function removeProxiedWebsite(uint index) public onlyOwner {
    require(proxiedWebsitesLocked == false, "Locked");
    require(index < proxiedWebsites.length, "Index out of bounds");

    proxiedWebsites[index] = proxiedWebsites[proxiedWebsites.length - 1];
    proxiedWebsites.pop();
  }

  function lockProxiedWebsites() public onlyOwner {
    require(proxiedWebsitesLocked == false, "Locked");
    proxiedWebsitesLocked = true;
  }

  function _getProxiedWebsites() internal virtual view returns (ResourceRequestWebsite[] memory) {
    return proxiedWebsites;
  }

  function _processWeb3Request(string[] memory resource, KeyValue[] memory params) internal override virtual view returns (uint statusCode, string memory body, KeyValue[] memory headers) {

    ResourceRequestWebsite[] memory websites = _getProxiedWebsites();
    for (uint i = 0; i < websites.length; i++) {
      ResourceRequestWebsite website = websites[i];
      (statusCode, body, headers) = website.request(resource, params);
      if (statusCode != 0 && statusCode != 404) {
        return (statusCode, body, headers);
      }
    }

    (statusCode, body, headers) = super._processWeb3Request(resource, params);
  }
}