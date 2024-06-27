// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { SSTORE2 } from "solady/utils/SSTORE2.sol";
import { LibStrings } from "../library/LibStrings.sol";

import "../interfaces/IDecentralizedApp.sol";
import "../interfaces/IFileInfos.sol";
import "../interfaces/IStorageBackend.sol";
import "../interfaces/IFrontendLibrary.sol";

import "./VersionableStaticWebsiteBase.sol";
import "./FrontendLibrary.sol";

contract VersionableStaticWebsite is VersionableStaticWebsiteBase, FrontendLibrary {
    function getFrontendLibrary() public view override returns (IFrontendLibrary) {
        return this;
    }

    function getLiveFrontendVersionIndex() public override view returns (uint256) {
        return getDefaultFrontendIndex();
    }

    function _processWeb3Request(string[] memory resource, KeyValue[] memory params) internal virtual override view returns (uint statusCode, string memory body, KeyValue[] memory headers, string[] memory internalRedirectResource, KeyValue[] memory internalRedirectParams) {

        (statusCode, body, headers, internalRedirectResource, internalRedirectParams) = StaticWebsiteBase._processWeb3Request(resource, params);
        if (statusCode != 0 || internalRedirectResource.length > 0) {
            return (statusCode, body, headers, internalRedirectResource, internalRedirectParams);
        }

        (statusCode, body, headers, internalRedirectResource, internalRedirectParams) = super._processWeb3Request(resource, params);
    }
}