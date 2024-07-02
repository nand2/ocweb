// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { SettingsLockable } from "../library/SettingsLockable.sol";

import "./ResourceRequestWebsite.sol";

contract ProxyWebsite is ResourceRequestWebsite, SettingsLockable {
  ResourceRequestWebsite[] public proxiedWebsites;

  constructor() {}

  function addProxiedWebsite(ResourceRequestWebsite website) public onlyOwner settingsUnlocked {
    proxiedWebsites.push(website);
  }

  function getProxiedWebsites() public view returns (ResourceRequestWebsite[] memory) {
    return proxiedWebsites;
  }

  function removeProxiedWebsite(uint index) public onlyOwner settingsUnlocked {
    if(index >= proxiedWebsites.length) {
      revert IndexOutOfBounds();
    }

    proxiedWebsites[index] = proxiedWebsites[proxiedWebsites.length - 1];
    proxiedWebsites.pop();
  }

  function _getProxiedWebsites() internal virtual view returns (ResourceRequestWebsite[] memory) {
    return proxiedWebsites;
  }

  function _processWeb3Request(string[] memory resource, KeyValue[] memory params) internal override virtual view returns (uint statusCode, string memory body, KeyValue[] memory headers, string[] memory internalRedirectResource, KeyValue[] memory internalRedirectParams) {

    ResourceRequestWebsite[] memory websites = _getProxiedWebsites();
    for (uint i = 0; i < websites.length; i++) {
      ResourceRequestWebsite website = websites[i];
      (statusCode, body, headers) = website.request(resource, params);
      if (statusCode != 0 && statusCode != 404) {
        return (statusCode, body, headers, internalRedirectResource, internalRedirectParams);
      }
    }

    (statusCode, body, headers, internalRedirectResource, internalRedirectParams) = super._processWeb3Request(resource, params);
  }
}