// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { SSTORE2 } from "solady/utils/SSTORE2.sol";
import { LibStrings } from "../library/LibStrings.sol";

import "../interfaces/IDecentralizedApp.sol";
import "../interfaces/IFileInfos.sol";
import "../interfaces/IStorageBackend.sol";
import "../interfaces/IFrontendLibrary.sol";

import './VersionableStaticWebsiteBase.sol';
import './FrontendLibrary.sol';

abstract contract VersionableStaticWebsite is VersionableStaticWebsiteBase, FrontendLibrary {

    constructor(ClonableFrontendVersionViewer _frontendVersionViewerImplementation) VersionableStaticWebsiteBase(_frontendVersionViewerImplementation) FrontendLibrary() {
    }

    function getLiveFrontendIndex() public view override returns (uint256) {
        return getDefaultFrontendIndex();
    }

    function getFrontendLibrary() public view override returns (IFrontendLibrary) {
        return this;
    }

}