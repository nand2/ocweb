// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { LibStrings } from "../../library/LibStrings.sol";

import "../../interfaces/IDecentralizedApp.sol";
import "../../interfaces/IFileInfos.sol";
import "../../interfaces/IStorageBackend.sol";
import "../../interfaces/IVersionableWebsite.sol";

import "./VersionableWebsiteV1.sol";

contract OCWebsiteV1 is VersionableWebsiteV1 {
    bytes4 public constant IVersionableWebsiteInterfaceId = type(IVersionableWebsite).interfaceId;
    uint public constant IVersionableWebsiteInterfaceImplementationVersion = 1;

    constructor(ClonableWebsiteVersionViewer _websiteVersionViewerImplementation) VersionableWebsiteV1(_websiteVersionViewerImplementation) {
    }

    
}
