// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { SSTORE2 } from "solady/utils/SSTORE2.sol";
import { LibStrings } from "../library/LibStrings.sol";

import "../interfaces/IDecentralizedApp.sol";
import "../interfaces/IFileInfos.sol";
import "../interfaces/IStorageBackend.sol";
import "../interfaces/IFrontendLibrary.sol";

import "./StaticWebsiteBase.sol";

abstract contract VersionableStaticWebsiteBase is StaticWebsiteBase {

    /**
     * Hook: Get the frontend library to use
     */
    function getFrontendLibrary() public view virtual returns (IFrontendLibrary);

    /**
     * Hook: Get the frontend version to use
     */
    function getLiveFrontendVersionIndex() public virtual view returns (uint256);

    function getLiveFrontendVersion() public view override returns (FrontendFilesSet memory) {
        return getFrontendLibrary().getFrontendVersion(getLiveFrontendVersionIndex());
    }
}