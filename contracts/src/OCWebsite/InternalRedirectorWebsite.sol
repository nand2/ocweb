// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Ownable } from "../library/Ownable.sol";

import "./ResourceRequestWebsite.sol";

contract InternalRedirectorWebsite is ResourceRequestWebsite, Ownable {
  string[] public globalInternalRedirectResource;
  KeyValue[] public globalInternalRedirectParams;

  constructor() {}

  function setGlobalInternalRedirect(string[] memory resource, KeyValue[] memory params) public onlyOwner {
    delete globalInternalRedirectResource;
    for(uint i = 0; i < resource.length; i++) {
      globalInternalRedirectResource.push(resource[i]);
    }

    delete globalInternalRedirectParams;
    for(uint i = 0; i < params.length; i++) {
      globalInternalRedirectParams.push(params[i]);
    }
  }

  function _processWeb3Request(string[] memory resource, KeyValue[] memory params) internal override virtual view returns (uint statusCode, string memory body, KeyValue[] memory headers, string[] memory internalRedirectResource, KeyValue[] memory internalRedirectParams) {
    if(globalInternalRedirectResource.length > 0) {
      return (0, "", new KeyValue[](0), globalInternalRedirectResource, globalInternalRedirectParams);
    }

    (statusCode, body, headers, internalRedirectResource, internalRedirectParams) =  super._processWeb3Request(resource, params);
  }

}