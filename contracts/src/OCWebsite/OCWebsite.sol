// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { LibStrings } from "../library/LibStrings.sol";

import "../interfaces/IDecentralizedApp.sol";
import "../interfaces/IFileInfos.sol";
import "../interfaces/IStorageBackend.sol";

import "./VersionableStaticWebsite.sol";
import "./ContractAddressesWebsite.sol";
import "./ProxyWebsite.sol";

contract OCWebsite is VersionableStaticWebsite {

    constructor() VersionableStaticWebsite() {
    }

    
}
