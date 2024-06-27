// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { SSTORE2 } from "solady/utils/SSTORE2.sol";
import { LibStrings } from "../library/LibStrings.sol";

import "../interfaces/IDecentralizedApp.sol";
import "../interfaces/IFileInfos.sol";
import "../interfaces/IStorageBackend.sol";

import "./StaticWebsiteBase.sol";
import "./VersionableStaticWebsite.sol";
import "./ContractAddressesWebsite.sol";
import "./ProxyWebsite.sol";
import "./GlobalInternalRedirectorWebsite.sol";

contract OCWebsite is GlobalInternalRedirectorWebsite, ProxyWebsite, ContractAddressesWebsite, VersionableStaticWebsite {

    constructor() VersionableStaticWebsite() ContractAddressesWebsite() ProxyWebsite() GlobalInternalRedirectorWebsite() {
    }

    function _processWeb3Request(string[] memory resource, KeyValue[] memory params) internal override(GlobalInternalRedirectorWebsite, ProxyWebsite, ContractAddressesWebsite, StaticWebsiteBase) view returns (uint statusCode, string memory body, KeyValue[] memory headers, string[] memory internalRedirectResource, KeyValue[] memory internalRedirectParams) {

        (statusCode, body, headers, internalRedirectResource, internalRedirectParams) = StaticWebsiteBase._processWeb3Request(resource, params);
        if(statusCode > 0 || internalRedirectResource.length > 0) {
            return (statusCode, body, headers, internalRedirectResource, internalRedirectParams);
        }

        (statusCode, body, headers, internalRedirectResource, internalRedirectParams) = ContractAddressesWebsite._processWeb3Request(resource, params);
        if(statusCode > 0 || internalRedirectResource.length > 0) {
            return (statusCode, body, headers, internalRedirectResource, internalRedirectParams);
        }

        (statusCode, body, headers, internalRedirectResource, internalRedirectParams) = ProxyWebsite._processWeb3Request(resource, params);
        if(statusCode > 0 || internalRedirectResource.length > 0) {
            return (statusCode, body, headers, internalRedirectResource, internalRedirectParams);
        }

        (statusCode, body, headers, internalRedirectResource, internalRedirectParams) = GlobalInternalRedirectorWebsite._processWeb3Request(resource, params);
        if(statusCode > 0 || internalRedirectResource.length > 0) {
            return (statusCode, body, headers, internalRedirectResource, internalRedirectParams);
        }

        return (404, "", new KeyValue[](0), new string[](0), new KeyValue[](0));
    }
}
