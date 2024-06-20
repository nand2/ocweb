// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { SSTORE2 } from "solady/utils/SSTORE2.sol";
import { LibStrings } from "../library/LibStrings.sol";

import "../interfaces/IDecentralizedApp.sol";
import "../interfaces/IFileInfos.sol";
import "../interfaces/IFrontendLibrary.sol";
import "../interfaces/IStorageBackend.sol";

import "./FrontendLibrary.sol";
import "./StaticWebsite.sol";
import "./ContractAddressesWebsite.sol";
import "./ProxyWebsite.sol";

contract OCWebsite is FrontendLibrary, StaticWebsite, ContractAddressesWebsite, ProxyWebsite {

    constructor() FrontendLibrary() StaticWebsite(this) ContractAddressesWebsite() ProxyWebsite() {
    }

    function _processWeb3Request(string[] memory resource, KeyValue[] memory params) internal override(StaticWebsite, ContractAddressesWebsite, ProxyWebsite) view returns (uint statusCode, string memory body, KeyValue[] memory headers) {

        (statusCode, body, headers) = super._processWeb3Request(resource, params);
    }
}
