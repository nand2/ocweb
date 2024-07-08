// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IDecentralizedApp, KeyValue } from "./IDecentralizedApp.sol";
import { IFrontendLibrary, FrontendFilesSet } from "./IFrontendLibrary.sol";
import { IOwnable } from "./IOwnable.sol";

interface IVersionableStaticWebsite is IDecentralizedApp, IOwnable {
    function getLiveFrontendIndex() external view returns (uint256);
    function getFrontendLibrary() external view returns (IFrontendLibrary);
    // Shortcut for frontends
    function getLiveFrontendVersion() external view returns (FrontendFilesSet memory frontendVersion, uint256 frontendIndex);

    function addPlugin(uint frontendIndex, IVersionableStaticWebsitePlugin plugin) external;
    struct IVersionableStaticWebsitePluginWithInfos {
        IVersionableStaticWebsitePlugin plugin;
        IVersionableStaticWebsitePlugin.Infos infos;
    }
    function getPlugins(uint frontendIndex) external view returns (IVersionableStaticWebsitePluginWithInfos[] memory pluginWithInfos);
    function removePlugin(uint frontendIndex, address plugin) external;
}

interface IVersionableStaticWebsitePlugin {
    struct Infos {
        // Technical name
        string name;
        // Version of the plugin
        string version;
        // Display name
        string title;
        string subTitle;
        // Author
        string author;
        // Point to a web3:// address of the homepage, where it can be configured
        string homepage;
    }
    function infos() external view returns (Infos memory);

    function processWeb3RequestBeforeStaticContent(IVersionableStaticWebsite website, uint frontendIndex, string[] memory resource, KeyValue[] memory params) external view returns (uint statusCode, string memory body, KeyValue[] memory headers);

    function processWeb3RequestAfterStaticContent(IVersionableStaticWebsite website, uint frontendIndex, string[] memory resource, KeyValue[] memory params) external view returns (uint statusCode, string memory body, KeyValue[] memory headers);

    function copyFrontendSettings(IVersionableStaticWebsite website, uint fromFrontendIndex, uint toFrontendIndex) external;
}

