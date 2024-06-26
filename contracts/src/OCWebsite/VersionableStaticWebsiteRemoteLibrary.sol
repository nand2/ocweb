// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { SSTORE2 } from "solady/utils/SSTORE2.sol";
import { LibStrings } from "../library/LibStrings.sol";

import "../interfaces/IDecentralizedApp.sol";
import "../interfaces/IFileInfos.sol";
import "../interfaces/IStorageBackend.sol";
import "../interfaces/IFrontendLibrary.sol";

import "./VersionableStaticWebsiteBase.sol";

contract VersionableStaticWebsiteRemoteLibrary is VersionableStaticWebsiteBase {

    IFrontendLibrary public frontendLibrary;

    bool public useNonDefaultFrontend;
    uint public overridenFrontendIndex;
  
    constructor(IFrontendLibrary _frontendLibrary) {
        frontendLibrary = _frontendLibrary;
    }

    function getFrontendLibrary() public view override returns (IFrontendLibrary) {
        return frontendLibrary;
    }

    function getLiveFrontendVersionIndex() public view override returns (uint256) {
        if(useNonDefaultFrontend) {
            return overridenFrontendIndex;
        }
        return frontendLibrary.getDefaultFrontendIndex();
    }
}