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

contract VersionableStaticWebsite is VersionableStaticWebsiteBase {
    // function getFrontendLibrary() public view override returns (IFrontendLibrary) {
    //     return this;
    // }

    // function getLiveFrontendVersionIndex() public override view returns (uint256) {
    //     return getDefaultFrontendIndex();
    // }

    // function _processWeb3Request(string[] memory resource, KeyValue[] memory params) internal virtual override view returns (uint statusCode, string memory body, KeyValue[] memory headers) {

    //     (statusCode, body, headers) = VersionableStaticWebsiteBase._processWeb3Request(resource, params);
    //     if (statusCode != 0) {
    //         return (statusCode, body, headers);
    //     }

    //     (statusCode, body, headers) = super._processWeb3Request(resource, params);
    // }
}