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

    function getLiveFrontendVersion() public view override returns (FrontendFilesSet memory) {
        return getFrontendVersion(getDefaultFrontendIndex());
    }
}