// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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

    function _processWeb3Request(string[] memory resource, KeyValue[] memory params) internal override(GlobalInternalRedirectorWebsite, ProxyWebsite, ContractAddressesWebsite, VersionableStaticWebsite) view returns (uint statusCode, string memory body, KeyValue[] memory headers, string[] memory internalRedirectResource, KeyValue[] memory internalRedirectParams) {

        (statusCode, body, headers, internalRedirectResource, internalRedirectParams) = super._processWeb3Request(resource, params);
    }
}
