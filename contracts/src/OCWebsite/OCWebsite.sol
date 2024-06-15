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

contract OCWebsite is FrontendLibrary, StaticWebsite {

    constructor(address owner) FrontendLibrary(owner) StaticWebsite(this) {
    }

}
